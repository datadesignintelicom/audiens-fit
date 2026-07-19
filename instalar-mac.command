#!/bin/bash
# ---------------------------------------------------------------------------
# Audiens Fit — instalador macOS (pendrive autossuficiente)
#
# A máquina que PREPARA o pendrive precisa de internet: este script baixa
# tudo sozinho (Ollama standalone, Python relocável e os modelos de IA).
# A máquina que USA o pendrive não precisa de NADA instalado.
#
# Uso: ./instalar-pendrive.command /Volumes/SEU_PENDRIVE
# Variáveis opcionais:
#   AUDIENS_INSTALAR_SEM_MODELOS=1   pula o download dos modelos
#
# Criado por Daniel Bastos · Data Design Inteligência de Comunicação — MIT
# ---------------------------------------------------------------------------
set -e
DESTINO="${1:-}"
# Duplo clique (sem argumento): se o script está dentro de um volume externo,
# oferece instalar na raiz desse volume — o gesto natural no Mac
if [ -z "$DESTINO" ]; then
  case "$0" in
    /Volumes/*)
      VOL="/Volumes/$(echo "$0" | cut -d/ -f3)"
      echo "Nenhum destino informado."
      read -p "Instalar o Audiens Fit em $VOL? [s/N] " r
      [ "$r" = "s" ] && DESTINO="$VOL"
      ;;
  esac
fi
[ -z "$DESTINO" ] && { echo "Uso: $0 /Volumes/SEU_PENDRIVE (ou uma pasta local)"; read -p "Pressione Enter para fechar."; exit 1; }
ORIGEM="$(cd "$(dirname "$0")" && pwd)"
RT="$DESTINO/runtime-mac"
echo "══ Audiens Fit: instalando em $DESTINO ══"

mkdir -p "$DESTINO/modelos" "$RT"
echo "→ Copiando o aplicativo…"
# Cópia por lista explícita: imune a pastas de sistema (.Spotlight-V100 etc.)
# e ao caso de o ZIP ter sido extraído direto na raiz do pendrive
mkdir -p "$DESTINO/audiens-fit"
for item in app prompts docs launchers requirements.txt README.md README.en.md \
            LICENSE LICENSE-CONTEUDO NOTICE instalar-mac.command instalar-windows.bat; do
  [ -e "$ORIGEM/$item" ] && rsync -a "$ORIGEM/$item" "$DESTINO/audiens-fit/"
done
[ -d "$DESTINO/audiens-fit/app" ] || { echo "ERRO: arquivos do projeto não encontrados junto ao instalador."; exit 1; }

# ── Python relocável (vive no pendrive; máquina de uso não precisa ter) ──
if [ ! -x "$RT/python/bin/python3" ]; then
  ARQ="cpython-3.12.8%2B20241206-$( [ "$(uname -m)" = "arm64" ] && echo aarch64 || echo x86_64 )-apple-darwin-install_only.tar.gz"
  echo "→ Baixando Python relocável ($(uname -m))…"
  curl -L --progress-bar -o /tmp/audiens-python.tgz \
    "https://github.com/astral-sh/python-build-standalone/releases/download/20241206/$ARQ"
  tar -xzf /tmp/audiens-python.tgz -C "$RT" && rm /tmp/audiens-python.tgz
fi
echo "→ Instalando dependências no pendrive…"
"$RT/python/bin/python3" -m pip install -q --upgrade pip
"$RT/python/bin/python3" -m pip install -q -r "$ORIGEM/requirements.txt"

# ── Ollama standalone (vive no pendrive) ──
if [ ! -x "$RT/ollama" ]; then
  echo "→ Baixando Ollama standalone…"
  curl -L --progress-bar -o /tmp/audiens-ollama.tgz \
    "https://github.com/ollama/ollama/releases/latest/download/ollama-darwin.tgz"
  tar -xzf /tmp/audiens-ollama.tgz -C "$RT" && rm /tmp/audiens-ollama.tgz
  [ -x "$RT/ollama" ] || { echo "ERRO: binário do Ollama não encontrado após extração."; exit 1; }
fi

# ── Modelos de IA (baixados automaticamente — nada é manual) ──
if [ "$AUDIENS_INSTALAR_SEM_MODELOS" != "1" ]; then
  echo "→ Baixando o modelo do perfil normal (qwen3:4b-instruct, ~2.5 GB)…"
  OLLAMA_MODELS="$DESTINO/modelos" "$RT/ollama" serve >/dev/null 2>&1 &
  PID_OLLAMA=$!
  for i in $(seq 1 30); do
    curl -s --max-time 1 http://localhost:11434/api/tags >/dev/null 2>&1 && break; sleep 1
  done
  OLLAMA_MODELS="$DESTINO/modelos" "$RT/ollama" pull qwen3:4b-instruct
  read -p "Baixar também o modelo turbo qwen3:8b (5.2 GB, máquinas de 16 GB+)? [s/N] " r
  [ "$r" = "s" ] && OLLAMA_MODELS="$DESTINO/modelos" "$RT/ollama" pull qwen3:8b
  kill $PID_OLLAMA 2>/dev/null || true
fi

cp "$ORIGEM/launchers/Audiens Fit.command" "$DESTINO/"
cp "$ORIGEM/launchers/Encerrar Audiens.command" "$DESTINO/"
chmod +x "$DESTINO/"*.command
echo "══ Pronto. Ejete o pendrive; em qualquer Mac, abra 'Audiens Fit.command'. ══"
