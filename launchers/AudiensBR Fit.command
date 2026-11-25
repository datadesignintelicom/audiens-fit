#!/bin/bash
# AudiensBR Fit — launcher macOS
# Criado por Daniel Bastos · Data Design Inteligência de Comunicação — MIT
# Funciona na RAIZ do pendrive (posição instalada) ou dentro do repositório
BASE="$(cd "$(dirname "$0")" && pwd -P)"
if [ -d "$BASE/audiens-fit/app" ]; then
  :                                   # raiz do pendrive (instalado)
elif [ -d "$BASE/../app" ]; then
  BASE="$(cd "$BASE/.." && pwd)"      # rodando de launchers/ dentro do repo
fi
APP="$BASE/audiens-fit"
[ -d "$APP/app" ] || APP="$BASE"
if [ ! -d "$APP/app" ]; then
  echo "ERRO: pasta do aplicativo não encontrada ao lado deste atalho."
  read -p "Pressione Enter para fechar."; exit 1
fi
# Porta dedicada 11435: isola de qualquer Ollama do sistema (ex.: o do
# AudiensBR completo) — nunca reaproveita silenciosamente um servidor alheio
export OLLAMA_HOST=127.0.0.1:11435
export OLLAMA_URL="http://$OLLAMA_HOST"
# Forçado (não apenas "se ainda não definido"): máquinas que já têm
# OLLAMA_MODELS no shell para outro fim (ex.: o AudiensBR completo) não podem
# vazar essa pasta para o pendrive, que precisa ficar sempre isolado
export OLLAMA_MODELS="$BASE/modelos"
# Sem o modelo turbo baixado, usa o perfil normal mesmo com 16 GB de RAM
if [ -z "$AUDIENS_FIT_PERFIL" ] && [ ! -e "$OLLAMA_MODELS/manifests/registry.ollama.ai/library/qwen3/8b" ]; then
  export AUDIENS_FIT_PERFIL=normal
fi

echo "═══════════════════════════════════════════════"
echo "  AudiensBR Fit — Data Design"
echo "  Durante a análise, evite abrir aplicativos"
echo "  pesados: o modelo usa a maior parte da RAM."
echo "═══════════════════════════════════════════════"

# Identificação precisa de processos: servidor = Python rodando
# "-m app.servidor" com a pasta de trabalho do app (outros apps do mesmo
# pendrive usam esse nome de módulo: o nome sozinho não distingue um do outro);
# porta = só quem ESCUTA nela, nunca clientes conectados (ex.: o navegador)
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
pids_outros() {  # servidores em outras pastas desta mesma raiz (Chat Offline)
  for p in $(pgrep -f -- "-m app.servidor"); do
    case "$(ps -o comm= -p "$p" 2>/dev/null)" in *[Pp]ython*) ;; *) continue;; esac
    case "$(lsof -a -p "$p" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')" in
      "$APP") ;; "$BASE"/*) echo "$p";;
    esac
  done
}
encerrar_e_esperar() {
  [ -n "$*" ] || return 0
  kill $* 2>/dev/null
  for i in 1 2 3 4 5 6 7 8 9 10; do
    vivos=""; for p in $*; do kill -0 "$p" 2>/dev/null && vivos="$vivos $p"; done
    [ -z "$vivos" ] && return 0; sleep 0.5
  done
  echo "Aviso: processo(s)$vivos não encerraram em 5 s."
}

# Fit já aberto (em qualquer porta): só reabre o navegador, sem subir outro
if [ -n "$(pids_servidor "$APP")" ]; then
  echo "O AudiensBR Fit já está aberto. Abrindo o navegador…"
  open "http://localhost:5001"; exit 0
fi

# Exclusão mútua com o Chat Offline: servidor (qualquer porta) E o Ollama dele
# (11436), senão o modelo do chat continua ocupando a RAM
CHAT_PIDS="$(pids_outros) $(pid_ollama 11436)"
if [ -n "$(echo $CHAT_PIDS)" ]; then
  echo "O Chat Offline está aberto. Os dois não rodam juntos (RAM)."
  read -p "Encerrar o Chat Offline e continuar? [s/N] " r
  [ "$r" = "s" ] || exit 0
  encerrar_e_esperar $CHAT_PIDS
fi

# Ollama: prioriza o binário do pendrive; o do sistema é fallback (mas
# sempre isolado na porta 11435, nunca compartilha o servidor de outro app)
if ! curl -s --max-time 2 "http://$OLLAMA_HOST/api/tags" >/dev/null 2>&1; then
  OLLAMA_BIN="$BASE/runtime-mac/ollama"
  [ -x "$OLLAMA_BIN" ] || OLLAMA_BIN="$(command -v ollama || true)"
  if [ ! -x "$OLLAMA_BIN" ]; then
    echo "ERRO: Ollama não encontrado. Rode o instalador primeiro."
    read -p "Pressione Enter para fechar."; exit 1
  fi
  echo "Iniciando Ollama (porta dedicada 11435)…"
  "$OLLAMA_BIN" serve >/dev/null 2>&1 &
  for i in $(seq 1 30); do
    curl -s --max-time 1 "http://$OLLAMA_HOST/api/tags" >/dev/null 2>&1 && break; sleep 1
  done
fi

PY="$BASE/runtime-mac/python/bin/python3"
[ -x "$PY" ] || PY="$BASE/runtime-mac/venv/bin/python"
if [ ! -x "$PY" ]; then
  echo "ERRO: Python do pendrive não encontrado. Rode o instalador primeiro."
  read -p "Pressione Enter para fechar."; exit 1
fi

echo "Iniciando AudiensBR Fit… (primeira carga do modelo pode levar 1-3 min em pendrive)"
( sleep 3; open "http://localhost:5001" ) &
cd "$APP"
exec "$PY" -m app.servidor
