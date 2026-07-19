# ---------------------------------------------------------------------------
# Audiens Fit — servidor.py
# Flask enxuto: análise por planilha, progresso por polling e perguntas
# sobre o corpus. Sem SSE, sem coleta embutida — planilha-first.
#
# Criado por Daniel Bastos · Data Design Inteligência de Comunicação — MIT
# ---------------------------------------------------------------------------

import threading
import time
import uuid

from flask import Flask, Response, jsonify, render_template, request

from .config import PERFIL, PORTA
from .exportador import gerar_xlsx
from .importador import extrair_comentarios
from .motor import analisar, ollama_disponivel, perguntar

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 30 * 1024 * 1024

_sessoes = {}          # id → {"pct", "fase", "resultado"|None, "erro"|None}
_corpora = {}          # id → {"textos", "contexto"}  (fonte da aba Perguntas)
_trava = threading.Lock()


@app.get("/")
def pagina():
    return render_template("index.html", perfil=PERFIL)


@app.get("/estado")
def estado():
    return jsonify({"ollama": ollama_disponivel(), "perfil": PERFIL})


@app.post("/analisar")
def iniciar_analise():
    arquivo = request.files.get("arquivo")
    contexto = (request.form.get("contexto") or "").strip()
    if not arquivo:
        return jsonify({"erro": "Nenhum arquivo enviado."}), 400
    try:
        textos, aviso = extrair_comentarios(arquivo.read(), arquivo.filename)
    except ValueError as e:
        return jsonify({"erro": str(e)}), 422

    sid = uuid.uuid4().hex[:12]
    with _trava:
        _sessoes[sid] = {"pct": 0, "fase": "Iniciando…", "resultado": None, "erro": None}
        _corpora[sid] = {"textos": textos, "contexto": contexto}

    def rodar():
        inicio = time.time()

        def emitir(pct, fase):
            with _trava:
                _sessoes[sid].update(pct=pct, fase=fase)
        try:
            resultado = analisar(textos, contexto, progresso=emitir)
            with _trava:
                if "erro" in resultado:
                    _sessoes[sid]["erro"] = resultado["erro"]
                else:
                    resultado["fonte"] = arquivo.filename
                    resultado["contexto"] = contexto
                    if aviso:
                        resultado["aviso_importacao"] = aviso
                    _sessoes[sid]["resultado"] = resultado
            if "erro" not in resultado:
                minutos = (time.time() - inicio) / 60
                print(f"[AUDIENS FIT] análise concluída — {len(textos)} comentários "
                      f"em {minutos:.0f} min. O relatório está aberto no navegador.")
        except Exception as e:
            with _trava:
                _sessoes[sid]["erro"] = f"Erro interno: {e}"

    threading.Thread(target=rodar, daemon=True).start()
    return jsonify({"ok": True, "sessao": sid, "total": len(textos), "aviso": aviso})


@app.get("/progresso/<sid>")
def progresso(sid):
    with _trava:
        s = _sessoes.get(sid)
        if not s:
            return jsonify({"erro": "Sessão não encontrada."}), 404
        return jsonify(s)


@app.post("/perguntar")
def responder():
    dados = request.get_json(silent=True) or {}
    pergunta = (dados.get("pergunta") or "").strip()
    sid = dados.get("sessao")
    if not pergunta:
        return jsonify({"erro": "Pergunta vazia."}), 400
    with _trava:
        corpus = _corpora.get(sid)
    if not corpus:
        return jsonify({"erro": "Nenhum corpus carregado. Analise uma planilha primeiro."}), 404
    return jsonify(perguntar(pergunta, corpus["textos"], corpus["contexto"]))


@app.get("/exportar/<sid>")
def exportar(sid):
    """XLSX único com duas abas — dispensa permissão de múltiplos downloads."""
    with _trava:
        s = _sessoes.get(sid)
        resultado = s.get("resultado") if s else None
    if not resultado:
        return jsonify({"erro": "Nenhum resultado disponível para exportar."}), 404
    return Response(
        gerar_xlsx(resultado),
        mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=audiensfit_analise.xlsx"})


@app.post("/carregar-corpus")
def carregar_corpus():
    """Carrega planilha só para a aba Perguntas, sem rodar análise."""
    arquivo = request.files.get("arquivo")
    if not arquivo:
        return jsonify({"erro": "Nenhum arquivo enviado."}), 400
    try:
        textos, aviso = extrair_comentarios(arquivo.read(), arquivo.filename)
    except ValueError as e:
        return jsonify({"erro": str(e)}), 422
    sid = uuid.uuid4().hex[:12]
    with _trava:
        _corpora[sid] = {"textos": textos,
                         "contexto": (request.form.get("contexto") or "").strip()}
    return jsonify({"ok": True, "sessao": sid, "total": len(textos), "aviso": aviso})


def principal():
    print(f"[AUDIENS FIT] perfil {PERFIL['nome']} · modelo {PERFIL['modelo']} · "
          f"RAM {PERFIL['ram_gb']} GB · http://localhost:{PORTA}")
    app.run(host="127.0.0.1", port=PORTA, threaded=True)


if __name__ == "__main__":
    principal()
