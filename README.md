# Audiens Fit

**Escuta qualificada de audiências — offline, portátil e auditável.**

*Read this in [English](README.en.md).*

## Por que não jogar a planilha num chat de IA pago?

Você pode colar mil comentários no chat de um LLM e pedir "resuma". O que
recebe de volta: um texto sem método, sem números verificáveis, percentuais
inventados com cara de exatos, sem layout de relatório, e seus dados
entregues a um servidor de terceiros. O Audiens Fit faz o contrário:

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
- **Percepções, temas e posicionamentos** com contagens reais e verbatims
- **Perguntas ao corpus**: "o que dizem sobre o preço?" → resposta com
  citações reais dos comentários. Funciona sem rodar a análise — e a
  diferença para perguntar a um chat de IA online é que aqui os comentários
  nunca saem da sua máquina
- **Exportação XLSX** em arquivo único com duas abas: universo classificado
  + resumo com funil de cobertura
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

📄 [**Guia visual passo a passo (PDF)**](docs/guia-instalacao-mac.pdf) — com telas do
Mac ilustradas, para quem prefere seguir com imagens em vez de só texto.

📄 [**Guia visual do Windows (PDF)**](docs/guia-instalacao-windows.pdf) — ⚠️ **ainda não
testado numa máquina real**, mostra o funcionamento esperado. Testou e algo não
bateu? Conte pra gente: audiensbrasil@proton.me

O modelo é simples: **a máquina que prepara o pendrive precisa de internet;
a máquina que usa não precisa de nada instalado** — Ollama, Python e os
modelos de IA são baixados automaticamente pelo instalador e vivem no
próprio pendrive.

1. Baixe este repositório (Code → Download ZIP) e descompacte
2. Plugue um pendrive em **exFAT** (padrão de fábrica) com 16 GB livres
   (24 GB para incluir o modelo turbo)
3. Rode o instalador apontando o destino:
   - **macOS**: `./instalar-mac.command /Volumes/SEU_PENDRIVE`
   - **Windows**: `instalar-windows.bat E:\`
4. Em qualquer máquina, abra o aplicativo **Audiens Fit** (ícone "Af") na
   raiz do pendrive — o navegador abre sozinho. Para encerrar liberando a
   RAM, o aplicativo **Encerrar Audiens** (ícone vermelho). Os dois são
   criados pelo instalador na própria máquina, por isso abrem sem o aviso
   do Gatekeeper

Instalar numa pasta do computador em vez de pendrive também funciona: é só
apontar o instalador para ela.

> ⚠️ **Aviso no macOS (Gatekeeper)**: na primeira abertura, o Mac pode dizer
> que *"o item não foi aberto pois a Apple não pode verificar se está livre
> de malware"* — padrão para qualquer script baixado da internet. Solução:
> Ajustes do Sistema → Privacidade e Segurança → botão **"Abrir Mesmo Assim"**
> (aparece logo após a tentativa bloqueada); ou, no Terminal:
> `xattr -d com.apple.quarantine instalar-mac.command "Audiens Fit.command"`.
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

## Quer mais? Conheça o Audiens completo

O Audiens Fit é a edição portátil e aberta do **Audiens**, a plataforma de
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
