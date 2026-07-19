#!/bin/bash
# Audiens Fit — launcher macOS
# Criado por Daniel Bastos · Data Design Inteligência de Comunicação — MIT
cd "$(dirname "$0")/.."
RAIZ="$(pwd)"
export OLLAMA_MODELS="${OLLAMA_MODELS:-$RAIZ/../modelos}"

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

# Ollama: usa o do sistema ou o binário do pendrive
if ! curl -s --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; then
  OLLAMA_BIN="$RAIZ/../runtime-mac/ollama"
  [ -x "$OLLAMA_BIN" ] || OLLAMA_BIN="$(command -v ollama || true)"
  if [ ! -x "$OLLAMA_BIN" ]; then
    echo "ERRO: Ollama não encontrado. Rode o instalador primeiro."; read -p ""; exit 1
  fi
  echo "Iniciando Ollama…"
  "$OLLAMA_BIN" serve >/dev/null 2>&1 &
  for i in $(seq 1 30); do
    curl -s --max-time 1 http://localhost:11434/api/tags >/dev/null 2>&1 && break; sleep 1
  done
fi

PY="$RAIZ/../runtime-mac/python/bin/python3"
[ -x "$PY" ] || PY="$RAIZ/../runtime-mac/venv/bin/python"
[ -x "$PY" ] || { echo "ERRO: Python do pendrive não encontrado. Rode o instalador."; read -p ""; exit 1; }

echo "Iniciando Audiens Fit… (primeira carga do modelo pode levar 1-3 min em pendrive)"
( sleep 3; open "http://localhost:5001" ) &
exec "$PY" -m app.servidor
