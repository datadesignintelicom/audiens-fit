# Instalação detalhada — Audiens Fit

## O modelo de instalação
- A máquina que **prepara** o pendrive precisa de internet: o instalador
  baixa automaticamente o Ollama (standalone), o Python (relocável) e os
  modelos de IA — tudo passa a viver no pendrive. Nada é manual.
- A máquina que **usa** o pendrive não precisa de nada instalado.

## Instalar no pendrive
- Pendrive em exFAT (padrão de fábrica). 16 GB livres para o perfil normal;
  24 GB para incluir o modelo turbo (qwen3:8b, oferecido pelo instalador).
- macOS: `./instalador/instalar-pendrive.command /Volumes/SEU_PENDRIVE`
- Windows: `instalador\instalar-pendrive.bat E:\` (ainda não testado)
- Também funciona apontando para uma pasta do computador.

## Rodar
Duplo clique em **Audiens Fit** na raiz do pendrive, em qualquer máquina.
O navegador abre sozinho em http://localhost:5001. Primeira carga do
modelo: 1-3 minutos em pendrive.

## Encerrar
**Encerrar Audiens** derruba o servidor e descarrega os modelos da RAM.

## Problemas comuns
- ".command não abre" (Mac): botão direito → Abrir na primeira vez
  (Gatekeeper), ou `xattr -d com.apple.quarantine "Audiens Fit.command"`.
- ".bat bloqueado" (Windows): SmartScreen → "Mais informações" → "Executar
  assim mesmo". Veja o aviso no README.
- Máquinas Intel (Mac) usam o Python x86_64 baixado pelo instalador — o
  pendrive preparado num Mac Apple Silicon roda em Apple Silicon; para
  cobrir os dois, rode o instalador uma vez em cada arquitetura.
