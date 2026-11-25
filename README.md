# AudiensBR Fit

**Escuta qualificada de audiências — offline, portátil e auditável.**

*Read this in [English](README.en.md).*

> **Mudança de nome:** o projeto passou a se chamar AudiensBR, com o sufixo do país, para não se confundir com uma ferramenta estrangeira que atua no mesmo segmento.

## Por que não jogar a planilha num chat de IA pago?

Você pode colar mil comentários no chat de um LLM e pedir "resuma". O que
recebe de volta: um texto sem método, sem números verificáveis, percentuais
inventados com cara de exatos, sem layout de relatório, e seus dados
entregues a um servidor de terceiros. O AudiensBR Fit faz o contrário:

- **Metodologia de social listening de verdade**: sentimento medido em
  relação ao conteúdo (protesto com redação positiva conta como contrário),
  percepções e temas com percentuais calculados por **contagem real**,
  cobertura declarada e atribuição nunca forçada
- **Auditável até o fim**: exporte o universo classificado comentário a
  comentário e confira cada número; mesmo corpus + mesmo contexto = mesmo
  resultado (seed fixo)
- **Relatório pronto**, não um parágrafo solto
- **100% offline**: seus dados nunca saem da máquina — roda até de um pendrive

Criado por **Daniel Bastos · Data Design Inteligência de Comunicação**.

Gratuito, sem anúncios e sem rastreio. Se ele te poupou trabalho, apoie o
desenvolvimento: **https://apoia.se/audiensbrasil** (Brasil) ·
**https://ko-fi.com/audiensbrasil** (internacional)

---

## O que ele faz

- **Análise de planilha** (XLSX/CSV): detecta a coluna de comentários sozinho
- **Receptividade contextual** com distribuição favorável/contrário/não claro
- **Interpretação geral** que começa pelo mais frequente e indica o peso de
  cada afirmação em palavras ("muitos", "parte", "alguns"), com as **vozes
  minoritárias** em bloco separado
- **Percepções, temas e posicionamentos** com contagens reais e verbatims.
  Comentários repetidos recebem sempre a mesma classificação
- **Perguntas ao corpus**: "o que dizem sobre o preço?" → resposta com
  citações reais dos comentários. Funciona sem rodar a análise — e a
  diferença para perguntar a um chat de IA online é que aqui os comentários
  nunca saem da sua máquina
- **Exportação XLSX** em arquivo único com duas abas: universo classificado
  + resumo com funil de cobertura e vozes minoritárias
- **Impressão** do relatório direto do navegador (botão Imprimir)

## Requisitos e o que esperar

| Máquina de uso | Perfil | Modelo | Expectativa |
|---|---|---|---|
| Mac Apple Silicon 8 GB | normal | qwen3:4b-instruct | ~1.000 comentários/hora (medido: 1.017 em 58 min num MacBook M1) |
| Mac Apple Silicon 16 GB+ | turbo (automático) | qwen3:8b | Mais preciso, ritmo semelhante |
| Intel/Windows sem GPU dedicada | normal | qwen3:4b-instruct | ~100-250 comentários/hora (estimativa): reserve horas para corpus grande |

O ritmo depende mais do processador do que da RAM: nos chips Apple Silicon o
modelo roda na GPU integrada (Metal); num Intel médio sem GPU dedicada ele
roda só na CPU, cerca de 4 a 8 vezes mais devagar — a estimativa da tabela
ainda não foi medida em máquina real.

**Durante a análise**: o modelo ocupa a maior parte da RAM. Em máquinas de
8 GB, feche o navegador com muitas abas e aplicativos pesados; a máquina
continua utilizável para tarefas leves. Pendrive rápido (USB 3+) acelera a
partida e a carga do modelo (1-3 min); a análise em si roda na RAM e não
depende da velocidade do pendrive.

## Instalação

O AudiensBR Fit foi pensado para **pendrive ou disco externo**, de preferência
rápido: fica tudo em um só lugar e pode ser levado a outro computador. Também
pode ser instalado em uma pasta do computador. No Mac e no Windows, o instalador
baixa tudo o que é necessário, e a máquina de uso não precisa de nada instalado.

**Guias visuais, com as telas ilustradas:**

- 🍎 [**Guia visual passo a passo no Mac (PDF)**](docs/guia-instalacao-mac.pdf)
- 🪟 [**Guia visual passo a passo no Windows (PDF)**](docs/guia-instalacao-windows.pdf)
  — ⚠️ instalação **ainda não testada numa máquina Windows real**; o guia mostra
  o funcionamento esperado. Testou e algo não bateu? Conte pra gente:
  audiensbrasil@proton.me

**O que cada sistema precisa:**

| | Mac | Windows |
|---|---|---|
| Sistema | Apple Silicon ou Intel | Windows 10 (1803 ou mais novo) ou 11 |
| Máquina que **prepara** o pendrive | Internet | Internet |
| Máquina que **usa** o pendrive | Nada instalado | Nada instalado |
| Modelo turbo | Oferecido pelo instalador | Oferecido pelo instalador |
| Abrir | Aplicativo **AudiensBR Fit** (ícone "Af") | **AudiensBR Fit.bat** |
| Encerrar | Aplicativo **Encerrar AudiensBR** (ícone vermelho) | **Encerrar AudiensBR.bat** |

O instalador baixa Ollama, Python e os modelos de IA para dentro do pendrive. Um pendrive preparado no Mac não roda no Windows sem passar também
pelo instalador do Windows. Entre Macs, o pendrive roda na mesma família de
processador em que foi preparado (Apple Silicon ou Intel); para cobrir as duas,
rode o instalador uma vez em cada.

**Antes de começar, nos dois sistemas:**

1. Baixe este repositório (Code → Download ZIP) e descompacte
2. Escolha onde instalar: pendrive ou disco externo em **exFAT** (padrão de
   fábrica), ou uma pasta do computador, com 16 GB livres (24 GB para incluir
   o modelo turbo)

### Instalar no Mac

1. Abra `instalar-mac.command` com duplo clique e escolha o destino quando ele
   perguntar (ou, no Terminal, `./instalar-mac.command /Volumes/SEU_PENDRIVE`).
   Se o Mac bloquear a abertura, veja o aviso do Gatekeeper abaixo
2. Abra o aplicativo **AudiensBR Fit** (ícone "Af") no destino escolhido — o
   navegador abre sozinho
3. Para encerrar, abra o aplicativo **Encerrar AudiensBR** (ícone vermelho).
   Ele libera a RAM e fecha o Ollama do Fit, o que permite ejetar o pendrive

Os dois aplicativos são criados pelo instalador na própria máquina, por isso
abrem sem o aviso do Gatekeeper.

### Instalar no Windows

1. Abra `instalar-windows.bat` com duplo clique e informe o destino quando ele
   perguntar (ou, no Prompt de Comando, `instalar-windows.bat E:\`)
2. Abra **AudiensBR Fit.bat** no destino escolhido — o navegador abre sozinho
3. Para encerrar liberando a RAM, abra **Encerrar AudiensBR.bat**

### Avisos de segurança do sistema

> ⚠️ **Aviso no macOS (Gatekeeper)**: na primeira abertura, o Mac pode dizer
> que *"o item não foi aberto pois a Apple não pode verificar se está livre
> de malware"* — padrão para qualquer script baixado da internet. Solução:
> Ajustes do Sistema → Privacidade e Segurança → botão **"Abrir Mesmo Assim"**
> (aparece logo após a tentativa bloqueada); ou, no Terminal:
> `xattr -d com.apple.quarantine instalar-mac.command "AudiensBR Fit.command"`.
>
> ⚠️ **Aviso sobre antivírus (Windows)**: arquivos `.bat` podem ser
> sinalizados pelo SmartScreen ou por antivírus, porque scripts de lote são
> um formato que malwares também usam. Os deste projeto são texto aberto —
> botão direito → Editar para ler o que fazem antes de executar. Se o
> SmartScreen bloquear: "Mais informações" → "Executar assim mesmo".

## Personalize a metodologia

Todos os prompts de interpretação vivem em **`prompts/prompts.json`** — texto
editável, sem tocar em código. Ajuste tom, regras e definições para o seu
caso; preserve os `{placeholders}`. Se o JSON quebrar, o servidor avisa a
linha do erro na partida. Detalhes do método em
[`docs/metodologia.md`](docs/metodologia.md).

## Quer mais? Conheça o AudiensBR completo

O AudiensBR Fit é a edição portátil e aberta do **AudiensBR**, a plataforma de
escuta da Data Design que vai muito além: coleta direta de múltiplas
plataformas (Instagram, Facebook, YouTube, TikTok, X, Threads, Bluesky,
Reddit e LinkedIn), com volume por post condicionado ao plano contratado no
serviço de coleta, nas redes que exigem intermediário; análise multicamadas
com modelos maiores; auditoria de autenticidade de engajamento (detecção de
atividade coordenada e inorgânica) e relatórios completos de inteligência de
comunicação.

**Interessado em análises profissionais ou em licenciar a tecnologia?**
Fale com a Data Design Inteligência de Comunicação: **audiensbrasil@proton.me**

## Licenças

- **Código**: [MIT](LICENSE)
- **Prompts, metodologia e documentação**: [CC-BY-NC-4.0](LICENSE-CONTEUDO) —
  livres para uso **não comercial** com atribuição; uso comercial mediante
  licença com a Data Design
- A identificação "Criado por Daniel Bastos · Data Design" na interface e
  nestes arquivos é condição de atribuição e deve ser preservada
