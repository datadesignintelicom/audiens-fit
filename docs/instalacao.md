# Instalação detalhada — Audiens Fit

Guias visuais, tela por tela: [Mac](guia-instalacao-mac.pdf) ·
[Windows](guia-instalacao-windows.pdf) *(caminho ainda não testado numa
máquina real — veja a ressalva abaixo)*.

## O modelo de instalação
- **No Mac**: a máquina que **prepara** o pendrive precisa de internet — o
  instalador baixa automaticamente o Ollama (standalone), o Python
  (relocável) e os modelos de IA, tudo passa a viver no pendrive. A máquina
  que **usa** depois não precisa de nada instalado.
- **No Windows** (ainda não testado numa máquina real): o instalador cria
  um ambiente Python (venv) que referencia o Python já instalado na
  máquina, não uma cópia completa — e o binário do Ollama não é copiado
  para o pendrive. Por isso, hoje, **toda máquina que for usar o pendrive
  no Windows precisa ter Python e Ollama instalados nela**, não só a que
  preparou. Testou e quer ajudar a fechar essa lacuna? audiensbrasil@proton.me

## Instalar no pendrive
- Pendrive em exFAT (padrão de fábrica). 16 GB livres para o perfil normal;
  24 GB para incluir o modelo turbo (qwen3:8b, oferecido pelo instalador).
- macOS: `./instalar-mac.command /Volumes/SEU_PENDRIVE`
- Windows: `instalar-windows.bat E:\` (ainda não testado numa máquina real)
- Também funciona apontando para uma pasta do computador.

## Rodar
Duplo clique em **Audiens Fit** na raiz do pendrive, em qualquer máquina.
O navegador abre sozinho em http://localhost:5001. Primeira carga do
modelo: 1-3 minutos em pendrive.

## Encerrar
**Encerrar Audiens** derruba o servidor e descarrega os modelos da RAM.

## Problemas comuns
- "O item não foi aberto pois a Apple não pode verificar se está livre de
  malware" (Mac/Gatekeeper): Ajustes do Sistema → Privacidade e Segurança →
  "Abrir Mesmo Assim" logo após a tentativa; ou
  `xattr -d com.apple.quarantine instalar-mac.command "Audiens Fit.command"`.
- ".bat bloqueado" (Windows): SmartScreen → "Mais informações" → "Executar
  assim mesmo". Veja o aviso no README.
- Máquinas Intel (Mac) usam o Python x86_64 baixado pelo instalador — o
  pendrive preparado num Mac Apple Silicon roda em Apple Silicon; para
  cobrir os dois, rode o instalador uma vez em cada arquitetura.
