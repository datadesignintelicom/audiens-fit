# ---------------------------------------------------------------------------
# Audiens Fit — motor.py
# Pipeline de análise compacto, calibrado para modelos 4B:
#   0. Atalho determinístico para comentários não-verbais (tabela de emojis)
#   1. Sentimento binário CONTEXTUAL em lote (favorável/contrário/não claro),
#      com ironia integrada na mesma chamada — sem DistilBERT, sem torch
#   2. Síntese única descritiva (amostra estratificada)
#   3. Classificação de shares: percepções (multi), temas (único+N),
#      posicionamentos (opcional) — atribuição nunca forçada, cobertura real
#   4. Verbatim por casamento lexical com fronteira de palavra e coerência
#
# Criado por Daniel Bastos · Data Design Inteligência de Comunicação
# Código sob licença MIT; prompts (prompts/prompts.json) sob CC-BY-NC-4.0.
# ---------------------------------------------------------------------------

import json
import random
import re
from collections import Counter

import requests

from .config import BATCH_SIZE, OLLAMA_URL, PERFIL, POSICIONAMENTOS_ATIVOS, PROMPTS, SEED

# ── Atalho não-verbal: polaridade por emoji, sem chamada de modelo ─────────

_EMOJIS_POSITIVOS = set("❤🧡💛💚💙💜🤎🖤🤍💕💞💓💗💖💘💝😍🥰😻👏🙌👍🔥✨🌟💯🎉🥳😂🤣😊😁😀🙏💪🫶😉🤩")
_EMOJIS_NEGATIVOS = set("💩🤮🤢🤡👎😡🤬😠💔🚮🗑❌😤😒🙄😞😔😭😢")

_STOP_MIN = {
    "a", "o", "e", "de", "da", "do", "das", "dos", "em", "no", "na", "que", "com",
    "por", "para", "um", "uma", "os", "as", "se", "não", "mais", "muito", "como",
    "mas", "foi", "ser", "são", "the", "and", "for", "you", "este", "essa", "isso",
    "pra", "pro", "já", "tem", "vai", "ele", "ela", "eu", "nos", "sobre",
}


def _chars_uteis(texto):
    return len(re.sub(r"[^\w]", "", texto, flags=re.UNICODE))


def _polaridade_emoji(texto):
    """Para comentário não-verbal: decide pelo saldo de emojis. Sem modelo."""
    pos = sum(1 for ch in texto if ch in _EMOJIS_POSITIVOS)
    neg = sum(1 for ch in texto if ch in _EMOJIS_NEGATIVOS)
    if pos > neg:
        return "favoravel"
    if neg > pos:
        return "contrario"
    return "nao_claro"


# ── Chamadas ao Ollama ─────────────────────────────────────────────────────

def _gerar(prompt, num_ctx=None, num_predict=None, temperatura=0.1, timeout=300):
    corpo = {
        "model":   PERFIL["modelo"],
        "prompt":  prompt,
        "stream":  False,
        "options": {"temperature": temperatura, "num_ctx": num_ctx or PERFIL["num_ctx"], "seed": SEED},
        "think":   False,
    }
    if num_predict:
        corpo["options"]["num_predict"] = num_predict
    resp = requests.post(f"{OLLAMA_URL}/api/generate", json=corpo, timeout=timeout)
    return resp.json().get("response", "")


def _extrair_json(texto):
    m = re.search(r"\{.*\}", texto, re.DOTALL)
    if not m:
        return None
    try:
        return json.loads(m.group())
    except Exception:
        return None


# Modelos 4B ocasionalmente quebram um único item do JSON de lote; o parse
# tudo-ou-nada descartava o lote inteiro. Os salvadores abaixo recuperam as
# entradas válidas por regex e deixam apenas o item quebrado sem classificar.

def _salvar_sentimentos(texto):
    achados = re.findall(
        r'"(\d+)"\s*:\s*\{\s*"s"\s*:\s*"([a-zA-Z])"\s*(?:,\s*"i"\s*:\s*(true|false))?',
        texto)
    return {k: {"s": v.lower(), "i": i == "true"} for k, v, i in achados} or None


def _salvar_unicos(texto):
    achados = re.findall(r'"(\d+)"\s*:\s*"?(N|\d+)"?', texto)
    return {k: (v if v == "N" else int(v)) for k, v in achados} or None


def _salvar_listas(texto):
    achados = re.findall(r'"(\d+)"\s*:\s*\[([^\]]*)\]', texto)
    saida = {}
    for k, corpo in achados:
        saida[k] = [int(x) for x in re.findall(r"\d+", corpo)]
    return saida or None


def ollama_disponivel():
    try:
        return requests.get(f"{OLLAMA_URL}/api/tags", timeout=5).status_code == 200
    except Exception:
        return False


# ── Camada 1: sentimento binário contextual em lote ────────────────────────

def _classificar_sentimento(textos_verbais, indices, contexto, emitir):
    """
    Retorna dict indice_global → {"s": favoravel|contrario|nao_claro, "i": bool}.
    Falha de lote marca "erro" (contada na cobertura, nunca vira dado).
    """
    resultados = {}
    mapa_s = {"f": "favoravel", "c": "contrario", "n": "nao_claro"}
    lotes = [list(zip(indices, textos_verbais))[i:i + BATCH_SIZE]
             for i in range(0, len(indices), BATCH_SIZE)]
    for li, lote in enumerate(lotes):
        emitir(5 + round(li / max(1, len(lotes)) * 55),
               f"Avaliando posição dos comentários… lote {li + 1} de {len(lotes)}")
        linhas = "\n".join(f'{k}: "{t[:150]}"' for k, (_, t) in enumerate(lote))
        prompt = PROMPTS["sentimento_lote"].format(contexto=contexto or "não informado",
                                                   comentarios=linhas)
        try:
            bruto = _gerar(prompt, num_predict=1200, timeout=240)
            dados = _extrair_json(bruto) or _salvar_sentimentos(bruto)
        except Exception:
            dados = None
        for k, (gi, _) in enumerate(lote):
            item = (dados or {}).get(str(k))
            if isinstance(item, dict) and str(item.get("s", "")).lower() in mapa_s:
                resultados[gi] = {"s": mapa_s[str(item["s"]).lower()],
                                  "i": bool(item.get("i"))}
            else:
                resultados[gi] = {"s": "nao_claro", "i": False, "erro": True}
    return resultados


# ── Síntese única descritiva ───────────────────────────────────────────────

def _sintetizar(itens, contexto, emitir):
    rng = random.Random(SEED)
    alvo = PERFIL["amostra_sintese"]
    if len(itens) > alvo:
        grupos = {}
        for it in itens:
            grupos.setdefault(it["sentimento"], []).append(it)
        amostra = []
        for lista in grupos.values():
            n = max(1, round(len(lista) / len(itens) * alvo))
            amostra += rng.sample(lista, min(n, len(lista)))
    else:
        amostra = itens
    linhas = "\n".join(f'- "{it["texto"][:120]}"' for it in amostra)
    bloco_pos = PROMPTS["sintese_bloco_posicionamentos"] if POSICIONAMENTOS_ATIVOS else ""
    emitir(62, "Interpretando o que a audiência diz…")
    prompt = PROMPTS["sintese"].format(contexto=contexto or "não informado",
                                       n_total=len(amostra), amostra=linhas,
                                       bloco_posicionamentos=bloco_pos)
    dados = _extrair_json(_gerar(prompt, num_ctx=PERFIL["num_ctx_sintese"],
                                 temperatura=0.2, timeout=420))
    return dados or {}


def _limpar_rotulos(campo, maximo=6):
    vistos, saida = set(), []
    for item in campo if isinstance(campo, list) else []:
        rotulo = (item.get("label") if isinstance(item, dict) else str(item)).strip()
        if rotulo and rotulo.lower() not in vistos:
            vistos.add(rotulo.lower())
            saida.append(rotulo)
    return saida[:maximo]


# ── Classificadores de share (atribuição nunca forçada) ────────────────────

def _classificar_lote(chave_prompt, rotulos, itens, contexto, multi=False):
    """Retorna (atribuicoes: dict gi→lista|int, lotes_falhos)."""
    atribuicoes, falhos = {}, 0
    lista_rotulos = "\n".join(f"{i}: {r}" for i, r in enumerate(rotulos))
    lotes = [itens[i:i + BATCH_SIZE] for i in range(0, len(itens), BATCH_SIZE)]
    for lote in lotes:
        linhas = "\n".join(f'{k}: {it["texto"][:150]}' for k, it in enumerate(lote))
        prompt = PROMPTS[chave_prompt].format(contexto=contexto or "não informado",
                                              rotulos=lista_rotulos, comentarios=linhas)
        try:
            bruto = _gerar(prompt, num_predict=800, timeout=240)
            dados = _extrair_json(bruto)
            if dados is None:
                dados = _salvar_listas(bruto) if multi else _salvar_unicos(bruto)
        except Exception:
            dados = None
        if dados is None:
            falhos += 1
            continue
        for k, it in enumerate(lote):
            val = dados.get(str(k))
            if multi:
                if isinstance(val, list):
                    validos = [int(v) for v in val
                               if (isinstance(v, int) or (isinstance(v, str) and v.isdigit()))
                               and 0 <= int(v) < len(rotulos)]
                    if validos:
                        atribuicoes[it["i"]] = validos
            else:
                if isinstance(val, str) and val.strip().isdigit():
                    val = int(val)
                if isinstance(val, int) and 0 <= val < len(rotulos):
                    atribuicoes[it["i"]] = val
    return atribuicoes, falhos


# ── Verbatim: fronteira de palavra + coerência de posição ──────────────────

_NEG_PISTAS = ["raiva", "indign", "critic", "descon", "cetic", "deboche", "revolt",
               "medo", "trist", "frustra", "preocup", "protest", "insatisf", "vergonh",
               "desprez", "lament", "absurd", "falta", "negativ"]
_POS_PISTAS = ["alegria", "apoio", "aprov", "celebra", "confian", "entusiasm",
               "elogio", "amor", "orgulho", "esperan", "gratid", "satisf", "positiv"]


def _valencia(rotulo):
    r = rotulo.lower()
    if any(p in r for p in _NEG_PISTAS):
        return "contrario"
    if any(p in r for p in _POS_PISTAS):
        return "favoravel"
    return None


def _verbatim(rotulo, itens, usados):
    termos = {t for t in re.findall(r"\b\w{4,}\b", rotulo.lower()) if t not in _STOP_MIN}
    if not termos:
        return ""
    padroes = [re.compile(r"\b" + re.escape(t)) for t in termos]
    valencia = _valencia(rotulo)
    candidatos = []
    for it in itens:
        txt = it["texto"]
        if len(txt.strip()) < 20 or re.search(r"@\w+", txt) or txt in usados:
            continue
        pontos = sum(1 for p in padroes if p.search(txt.lower()))
        if pontos:
            coerente = 1 if (valencia is None or it["sentimento"] == valencia) else 0
            candidatos.append((coerente, pontos, txt))
    if not candidatos:
        return ""
    candidatos.sort(key=lambda c: (c[0], c[1], -abs(len(c[2]) - 100)), reverse=True)
    if valencia is not None and candidatos[0][0] == 0:
        return ""   # sem candidato coerente: melhor nenhum verbatim que um contraditório
    return candidatos[0][2]


# ── Orquestrador ───────────────────────────────────────────────────────────

def analisar(textos, contexto="", progresso=None):
    """
    Analisa a lista de comentários e retorna o resultado completo.
    `progresso(pct, fase)` é chamado ao longo do caminho, se fornecido.
    """
    emitir = progresso or (lambda pct, fase: None)
    textos = [str(t).strip() for t in textos if str(t).strip()]
    total = len(textos)
    if not total:
        return {"erro": "Nenhum comentário válido."}
    if not ollama_disponivel():
        return {"erro": "Ollama não está acessível. Abra o Audiens Fit pelo atalho do pendrive."}

    emitir(2, "Separando comentários verbais e não-verbais…")
    itens = []
    indices_verbais, textos_verbais = [], []
    nao_verbais = 0
    for i, t in enumerate(textos):
        if _chars_uteis(t) < 5:
            nao_verbais += 1
            itens.append({"i": i, "texto": t, "sentimento": _polaridade_emoji(t),
                          "ironia": False, "via": "emoji"})
        else:
            itens.append({"i": i, "texto": t, "sentimento": None, "ironia": False, "via": "modelo"})
            indices_verbais.append(i)
            textos_verbais.append(t)

    sentimentos = _classificar_sentimento(textos_verbais, indices_verbais, contexto, emitir)
    falhas_sentimento = 0
    for gi, resultado in sentimentos.items():
        itens[gi]["sentimento"] = resultado["s"]
        itens[gi]["ironia"] = resultado["i"]
        # Regra determinística: ironia detectada + posição favorável = o
        # sentido real é contrário (definição de sarcasmo). Corrige o padrão
        # do 4B de detectar a ironia e esquecer de inverter a posição.
        if resultado["i"] and itens[gi]["sentimento"] == "favoravel":
            itens[gi]["sentimento"] = "contrario"
        if resultado.get("erro"):
            falhas_sentimento += 1

    contagem = Counter(it["sentimento"] for it in itens)
    favoraveis, contrarios = contagem.get("favoravel", 0), contagem.get("contrario", 0)
    definidos = favoraveis + contrarios
    receptividade = round(favoraveis / definidos * 100) if definidos else 50

    sintese_bruta = _sintetizar(itens, contexto, emitir)
    resumo = str(sintese_bruta.get("resumo") or "Não foi possível gerar interpretação.")
    percepcoes_rotulos = _limpar_rotulos(sintese_bruta.get("percepcoes"))
    temas_rotulos = _limpar_rotulos(sintese_bruta.get("temas"))
    pos_rotulos = _limpar_rotulos(sintese_bruta.get("posicionamentos"), 4) if POSICIONAMENTOS_ATIVOS else []

    cobertura = {}
    percepcoes = []
    if percepcoes_rotulos:
        emitir(78, "Mapeando o que a audiência sente…")
        atrib, falhos = _classificar_lote("percepcoes_lote", percepcoes_rotulos, itens, contexto, multi=True)
        contagens = Counter(pi for lista in atrib.values() for pi in lista)
        usados = set()
        for pi, _ in contagens.most_common():
            exemplo = _verbatim(percepcoes_rotulos[pi], itens, usados)
            if exemplo:
                usados.add(exemplo)
            percepcoes.append({"label": percepcoes_rotulos[pi], "n": contagens[pi],
                               "pct": round(contagens[pi] / total * 100, 1),
                               "exemplo": exemplo})
        for gi, lista in atrib.items():
            itens[gi]["percepcoes"] = [percepcoes_rotulos[pi] for pi in lista]
        cobertura["percepcoes"] = {"classificados": len(atrib), "total": total, "lotes_falhos": falhos}

    temas = []
    if temas_rotulos:
        emitir(88, "Organizando os assuntos centrais…")
        atrib, falhos = _classificar_lote("temas_lote", temas_rotulos, itens, contexto)
        contagens = Counter(atrib.values())
        base = sum(contagens.values())
        for ti, n in contagens.most_common():
            temas.append({"label": temas_rotulos[ti], "n": n,
                          "pct": round(n / base * 100, 1) if base else 0})
        for gi, ti in atrib.items():
            itens[gi]["tema"] = temas_rotulos[ti]
        cobertura["temas"] = {"classificados": base, "total": total, "lotes_falhos": falhos}

    posicionamentos = []
    if pos_rotulos:
        emitir(94, "Identificando os argumentos do debate…")
        atrib, falhos = _classificar_lote("posicionamentos_lote", pos_rotulos, itens, contexto)
        contagens = Counter(atrib.values())
        for pi, n in contagens.most_common():
            membros = [gi for gi, v in atrib.items() if v == pi]
            favor = sum(1 for gi in membros if itens[gi]["sentimento"] == "favoravel")
            contra = sum(1 for gi in membros if itens[gi]["sentimento"] == "contrario")
            tom = "favoravel" if favor > contra else "contrario" if contra > favor else "neutro"
            posicionamentos.append({"label": pos_rotulos[pi], "n": n,
                                    "pct": round(n / total * 100, 1), "tom": tom})
        for gi, pi in atrib.items():
            itens[gi]["posicionamento"] = pos_rotulos[pi]
        cobertura["posicionamentos"] = {"classificados": len(atrib), "total": total, "lotes_falhos": falhos}

    # Nuvem de palavras — determinística, sem NLTK (stopwords embutidas)
    freq = Counter()
    for t in textos:
        for tok in re.findall(r"\b\w{3,}\b", t.lower()):
            if tok not in _STOP_MIN:
                freq[tok] += 1
    nuvem = [{"palavra": p, "frequencia": n} for p, n in freq.most_common(10)]

    emitir(99, "Preparando o resultado…")
    return {
        "total": total,
        "receptividade": receptividade,
        "distribuicao": {
            "favoravel": favoraveis, "contrario": contrarios,
            "nao_claro": contagem.get("nao_claro", 0),
        },
        "ironicos": sum(1 for it in itens if it["ironia"]),
        "nao_verbais": nao_verbais,
        "resumo": resumo,
        "percepcoes": percepcoes,
        "temas": temas,
        "posicionamentos": posicionamentos,
        "nuvem": nuvem,
        "cobertura": cobertura,
        "detalhes": itens,
        "metodologia": {
            "perfil": PERFIL["nome"], "modelo": PERFIL["modelo"],
            "ram_gb": PERFIL["ram_gb"], "seed": SEED,
            "falhas_sentimento": falhas_sentimento,
            "posicionamentos_ativos": POSICIONAMENTOS_ATIVOS,
        },
    }


# ── Perguntas sobre o corpus (recuperação lexical + resposta citada) ───────

def perguntar(pergunta, textos, contexto=""):
    termos = {t for t in re.findall(r"\b\w{4,}\b", pergunta.lower()) if t not in _STOP_MIN}
    if termos:
        padroes = [re.compile(r"\b" + re.escape(t)) for t in termos]
        pontuados = []
        for t in textos:
            pontos = sum(1 for p in padroes if p.search(str(t).lower()))
            if pontos:
                pontuados.append((pontos, str(t)))
        pontuados.sort(key=lambda x: (x[0], len(x[1])), reverse=True)
        recuperados = [t for _, t in pontuados[:80]]
    else:
        recuperados = []
    if not recuperados:   # pergunta genérica: amostra representativa
        rng = random.Random(SEED)
        recuperados = [str(t) for t in (rng.sample(textos, 80) if len(textos) > 80 else textos)]
    linhas = "\n".join(f'- "{t[:200]}"' for t in recuperados)
    prompt = PROMPTS["perguntas"].format(contexto=contexto or "não informado",
                                         n_recuperados=len(recuperados), n_total=len(textos),
                                         comentarios=linhas, pergunta=pergunta[:400])
    try:
        resposta = _gerar(prompt, num_ctx=PERFIL["num_ctx_sintese"], temperatura=0.2, timeout=240)
        return {"resposta": resposta.strip(), "recuperados": len(recuperados), "total": len(textos)}
    except Exception as e:
        return {"erro": f"Falha ao consultar o modelo: {e}"}
