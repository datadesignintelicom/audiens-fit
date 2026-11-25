#!/bin/bash
# Encerra o AudiensBR Fit e libera a RAM — e SÓ o Fit: outros apps do mesmo
# pendrive usam o mesmo nome de módulo (app.servidor), então o servidor é
# identificado pela pasta. Encerra também o Ollama do Fit: aberto, ele segura
# arquivos do pendrive e impede a ejeção.
# Porta dedicada 11435: nunca mexe no Ollama de outro app (ex.: o AudiensBR
# completo, que pode estar em análise nesse momento).
BASE="$(cd "$(dirname "$0")" && pwd -P)"
if [ ! -d "$BASE/audiens-fit/app" ] && [ -d "$BASE/../app" ]; then
  BASE="$(cd "$BASE/.." && pwd -P)"   # rodando de launchers/ dentro do repo
fi
APP="$BASE/audiens-fit"
[ -d "$APP/app" ] || APP="$BASE"

pids_servidor() {
  for p in $(pgrep -f -- "-m app.servidor"); do
    case "$(ps -o comm= -p "$p" 2>/dev/null)" in *[Pp]ython*) ;; *) continue;; esac
    [ "$(lsof -a -p "$p" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')" = "$1" ] && echo "$p"
  done
}
pid_ollama() {   # $1 porta: só quem escuta nela E é o Ollama
  for p in $(lsof -ti "tcp:$1" -sTCP:LISTEN 2>/dev/null); do
    case "$(ps -o comm= -p "$p" 2>/dev/null)" in *ollama*) echo "$p";; esac
  done
}

FIT="$(pids_servidor "$APP")"
OLLAMA_FIT="$(pid_ollama 11435)"
PIDS="$(echo $FIT $OLLAMA_FIT)"
if [ -z "$PIDS" ]; then
  echo "O AudiensBR Fit não está aberto. Nada a encerrar."
  exit 0
fi
if [ -n "$OLLAMA_FIT" ]; then
  # Descarrega os modelos antes de encerrar o próprio Ollama
  curl -s --max-time 5 http://127.0.0.1:11435/api/generate -d '{"model":"qwen3:4b-instruct","keep_alive":0}' >/dev/null 2>&1
  curl -s --max-time 5 http://127.0.0.1:11435/api/generate -d '{"model":"qwen3:8b","keep_alive":0}' >/dev/null 2>&1
fi
kill $PIDS 2>/dev/null
for i in $(seq 1 20); do
  vivos=""; for p in $PIDS; do kill -0 "$p" 2>/dev/null && vivos="$vivos $p"; done
  [ -z "$vivos" ] && break; sleep 0.5
done
if [ -n "$vivos" ]; then
  echo "Aviso: processo(s)$vivos ainda abertos após 10 s. Aguarde e rode de novo."
  exit 1
fi
echo "AudiensBR Fit encerrado e RAM liberada. Pode fechar esta janela."
