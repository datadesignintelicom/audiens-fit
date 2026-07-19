#!/bin/bash
# Audiens Fit — instalador macOS
# Monta a estrutura no destino (pendrive ou pasta local):
#   destino/audiens-fit  destino/modelos  destino/runtime-mac
# Uso: ./instalar-pendrive.command /Volumes/SEU_PENDRIVE
set -e
DESTINO="${1:-}"
[ -z "$DESTINO" ] && { echo "Uso: $0 /Volumes/SEU_PENDRIVE (ou uma pasta local)"; exit 1; }
ORIGEM="$(cd "$(dirname "$0")/.." && pwd)"
echo "── Audiens Fit: instalando em $DESTINO ──"

mkdir -p "$DESTINO/modelos" "$DESTINO/runtime-mac"
rsync -a --exclude runtime-mac --exclude runtime-win "$ORIGEM/" "$DESTINO/audiens-fit/"

# Python: exige python3 no sistema (macOS: instala via Command Line Tools)
command -v python3 >/dev/null || { echo "ERRO: python3 não encontrado. Instale o Xcode CLT: xcode-select --install"; exit 1; }
echo "Criando venv (--copies: compatível com exFAT, sem symlinks)…"
python3 -m venv --copies "$DESTINO/runtime-mac/venv"
"$DESTINO/runtime-mac/venv/bin/pip" install -q --upgrade pip
"$DESTINO/runtime-mac/venv/bin/pip" install -q -r "$ORIGEM/requirements.txt"

# Ollama: usa o do sistema se existir; senão instrui
if ! command -v ollama >/dev/null; then
  echo "AVISO: Ollama não está instalado. Baixe em https://ollama.com/download"
  echo "       (uma vez instalado, rode este instalador de novo para baixar os modelos)"
else
  echo "Baixando modelos para o pendrive (perfil normal; turbo é opcional)…"
  OLLAMA_MODELS="$DESTINO/modelos" ollama pull qwen3:4b-instruct
  read -p "Baixar também o modelo turbo qwen3:8b (5.2 GB, para máquinas de 16 GB+)? [s/N] " r
  [ "$r" = "s" ] && OLLAMA_MODELS="$DESTINO/modelos" ollama pull qwen3:8b
fi

cp "$ORIGEM/launchers/Audiens Fit.command" "$DESTINO/"
cp "$ORIGEM/launchers/Encerrar Audiens.command" "$DESTINO/"
chmod +x "$DESTINO/"*.command
echo "── Pronto. Abra 'Audiens Fit.command' na raiz de $DESTINO ──"
