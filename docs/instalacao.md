# Instalação detalhada — Audiens Fit

## Pré-requisitos (uma vez, com internet)
1. **Ollama**: https://ollama.com/download (Mac ou Windows)
2. **Python 3.10+**: macOS `xcode-select --install`; Windows https://python.org
   (marque "Add Python to PATH")

## Instalar no pendrive
- Pendrive em exFAT (padrão de fábrica serve). 16 GB livres para o perfil
  normal; 24 GB se incluir o modelo turbo.
- macOS: `./instalador/instalar-pendrive.command /Volumes/SEU_PENDRIVE`
- Windows: `instalador\instalar-pendrive.bat E:\`
- O instalador copia o app, cria o ambiente Python no pendrive e baixa os
  modelos para a pasta `modelos/`.

## Rodar
Duplo clique em **Audiens Fit** na raiz do pendrive. O navegador abre sozinho
em http://localhost:5001. Primeira carga do modelo: 1-3 minutos em pendrive.

## Encerrar
**Encerrar Audiens** derruba o servidor e descarrega os modelos da RAM.

## Problemas comuns
- ".command não abre" (Mac): botão direito → Abrir na primeira vez
  (Gatekeeper), ou `xattr -d com.apple.quarantine "Audiens Fit.command"`.
- ".bat bloqueado" (Windows): SmartScreen → "Mais informações" → "Executar
  assim mesmo". Veja o aviso no README.
- "Ollama não encontrado": instale o Ollama e rode o instalador de novo.
