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
  VOL=""
  case "$0" in
    /Volumes/*) VOL="/Volumes/$(echo "$0" | cut -d/ -f3)" ;;   # script dentro do volume
  esac
  if [ -z "$VOL" ]; then
    # Rodando de uma pasta comum (ex: Downloads): procura volumes externos
    # montados e, havendo exatamente um, oferece-o como destino
    CANDIDATOS=()
    for v in /Volumes/*; do
      [ -d "$v" ] && [ "$(readlink "$v" 2>/dev/null)" != "/" ] && [ -w "$v" ] && CANDIDATOS+=("$v")
    done
    [ "${#CANDIDATOS[@]}" = "1" ] && VOL="${CANDIDATOS[0]}"
    # Vários volumes externos montados: lista e deixa escolher pelo número
    if [ -z "$VOL" ] && [ "${#CANDIDATOS[@]}" -gt 1 ]; then
      echo "Nenhum destino informado. Volumes externos montados:"
      i=1
      for v in "${CANDIDATOS[@]}"; do echo "  $i) $v"; i=$((i+1)); done
      read -p "Número do volume de destino (Enter cancela): " n
      case "$n" in
        ""|*[!0-9]*) ;;
        *) [ "$n" -ge 1 ] && [ "$n" -le "${#CANDIDATOS[@]}" ] && DESTINO="${CANDIDATOS[$((n-1))]}" ;;
      esac
    fi
  fi
  if [ -n "$VOL" ] && [ -z "$DESTINO" ]; then
    echo "Nenhum destino informado."
    read -p "Instalar o Audiens Fit em $VOL? [s/N] " r
    [ "$r" = "s" ] && DESTINO="$VOL"
  fi
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
for item in app prompts docs launchers recursos requirements.txt README.md README.en.md \
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

# ── Aplicativos com ícone na raiz do pendrive ──
# Gerados aqui (não vêm no ZIP): arquivos criados localmente não carregam a
# marca de quarentena, então o duplo clique não dispara o aviso do Gatekeeper.
criar_app() {   # $1 nome do app · $2 .command alvo · $3 .icns
  local APP="$DESTINO/$1.app"
  rm -rf "$APP"
  mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
  cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$1</string>
  <key>CFBundleDisplayName</key><string>$1</string>
  <key>CFBundleExecutable</key><string>abrir</string>
  <key>CFBundleIconFile</key><string>icone</string>
  <key>CFBundleIdentifier</key><string>com.datadesign.$(echo "$1" | tr -d ' ' | tr '[:upper:]' '[:lower:]')</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
</dict></plist>
PLIST
  cat > "$APP/Contents/MacOS/abrir" <<ABRIR
#!/bin/bash
RAIZ="\$(cd "\$(dirname "\$0")/../../.." && pwd)"
exec open -a Terminal "\$RAIZ/$2"
ABRIR
  chmod +x "$APP/Contents/MacOS/abrir"
  cp "$DESTINO/audiens-fit/recursos/$3" "$APP/Contents/Resources/icone.icns"
  xattr -cr "$APP" 2>/dev/null || true
}
if [ -f "$DESTINO/audiens-fit/recursos/audiens-fit.icns" ]; then
  echo "→ Criando os aplicativos com ícone…"
  criar_app "Audiens Fit" "Audiens Fit.command" "audiens-fit.icns"
  criar_app "Encerrar Audiens" "Encerrar Audiens.command" "encerrar-audiens.icns"
fi

echo "══ Instalação concluída. ══"
echo "Para usar: abra o aplicativo 'Audiens Fit' (ícone Af) na raiz de $DESTINO —"
echo "neste Mac agora, ou em qualquer outro depois (leve o pendrive plugado)."
read -p "Abrir o Audiens Fit agora? [s/N] " r
[ "$r" = "s" ] && exec "$DESTINO/Audiens Fit.command"
