#!/bin/bash
# Audiens Fit — launcher macOS
# Criado por Daniel Bastos · Data Design Inteligência de Comunicação — MIT
# Funciona na RAIZ do pendrive (posição instalada) ou dentro do repositório
BASE="$(cd "$(dirname "$0")" && pwd)"
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
export OLLAMA_MODELS="${OLLAMA_MODELS:-$BASE/modelos}"

echo "═══════════════════════════════════════════════"
echo "  Audiens Fit — Data Design"
echo "  Durante a análise, evite abrir aplicativos"
echo "  pesados: o modelo usa a maior parte da RAM."
echo "═══════════════════════════════════════════════"

# Exclusão mútua com o Chat Offline (porta 5002)
if curl -s --max-time 2 http://localhost:5002/ >/dev/null 2>&1; then
  echo "O Chat Offline está aberto. Os dois não rodam juntos (RAM)."
  read -p "Encerrar o Chat Offline e continuar? [s/N] " r
  [ "$r" = "s" ] || exit 0
  pkill -f "chat/app/servidor.py" 2>/dev/null; sleep 1
fi

# Ollama: prioriza o binário do pendrive; o do sistema é fallback
if ! curl -s --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
  OLLAMA_BIN="$BASE/runtime-mac/ollama"
  [ -x "$OLLAMA_BIN" ] || OLLAMA_BIN="$(command -v ollama || true)"
  if [ ! -x "$OLLAMA_BIN" ]; then
    echo "ERRO: Ollama não encontrado. Rode o instalador primeiro."
    read -p "Pressione Enter para fechar."; exit 1
  fi
  echo "Iniciando Ollama…"
  "$OLLAMA_BIN" serve >/dev/null 2>&1 &
  for i in $(seq 1 30); do
    curl -s --max-time 1 http://localhost:11434/api/tags >/dev/null 2>&1 && break; sleep 1
  done
fi

PY="$BASE/runtime-mac/python/bin/python3"
[ -x "$PY" ] || PY="$BASE/runtime-mac/venv/bin/python"
if [ ! -x "$PY" ]; then
  echo "ERRO: Python do pendrive não encontrado. Rode o instalador primeiro."
  read -p "Pressione Enter para fechar."; exit 1
fi

echo "Iniciando Audiens Fit… (primeira carga do modelo pode levar 1-3 min em pendrive)"
( sleep 3; open "http://localhost:5001" ) &
cd "$APP"
exec "$PY" -m app.servidor
