# Instalação detalhada — AudiensBR Fit

Guias visuais, tela por tela:

- [Guia visual passo a passo no Mac](guia-instalacao-mac.pdf)
- [Guia visual passo a passo no Windows](guia-instalacao-windows.pdf) *(instalação
  testada numa máquina virtual, ainda não num computador comum)*

## O modelo de instalação
A máquina que **prepara** o pendrive precisa de internet: o instalador baixa
o Ollama, o Python (relocável) e os modelos de IA, e tudo passa a viver no
pendrive. A máquina que **usa** depois não precisa de nada instalado, no Mac
ou no Windows. O do Windows foi testado numa máquina virtual, ainda não num computador comum;
encontrou algo diferente? audiensbrasil@proton.me

## Instalar no pendrive
- Pendrive em exFAT (padrão de fábrica). 16 GB livres para o perfil normal;
  24 GB para incluir o modelo turbo (qwen3:8b, oferecido pelo instalador).
- macOS: duplo clique em `instalar-mac.command`, ou
  `./instalar-mac.command /Volumes/SEU_PENDRIVE` no Terminal.
- Windows: duplo clique em `instalar-windows.bat`, ou `instalar-windows.bat E:\`
  no Prompt de Comando.
- Sem destino informado, o instalador pergunta. Pode ser um disco externo ou
  uma pasta do computador.

## Rodar
Duplo clique em **AudiensBR Fit** (Mac) ou **AudiensBR Fit.bat** (Windows) na
raiz do pendrive. O navegador abre sozinho em http://localhost:5001. Primeira carga do
modelo: 1-3 minutos em pendrive.

## Encerrar
No Mac, **Encerrar AudiensBR** fecha o servidor e o Ollama do Fit, o que libera
a RAM e permite ejetar o pendrive. No Windows,
**Encerrar AudiensBR.bat** faz o mesmo.

## Problemas comuns
- "O item não foi aberto pois a Apple não pode verificar se está livre de
  malware" (Mac/Gatekeeper): Ajustes do Sistema → Privacidade e Segurança →
  "Abrir Mesmo Assim" logo após a tentativa; ou
  `xattr -d com.apple.quarantine instalar-mac.command "AudiensBR Fit.command"`.
- ".bat bloqueado" (Windows): SmartScreen → "Mais informações" → "Executar
  assim mesmo". Veja o aviso no README.
- Máquinas Intel (Mac) usam o Python x86_64 baixado pelo instalador — o
  pendrive preparado num Mac Apple Silicon roda em Apple Silicon; para
  cobrir os dois, rode o instalador uma vez em cada arquitetura.
