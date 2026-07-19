# Audiens Fit

**Escuta qualificada de audiências — offline, portátil e auditável.**

Analise planilhas de comentários de redes sociais com IA rodando 100% na sua
máquina: sentimento contextual, percepções, temas, posicionamentos e perguntas
em linguagem natural sobre o corpus. Nenhum dado sai do seu computador.

Criado por **Daniel Bastos · Data Design Inteligência de Comunicação**.

---

## O que ele faz

- **Análise de planilha** (XLSX/CSV): detecta a coluna de comentários sozinho
- **Sentimento contextual**, não literal: "Queremos o produto de volta!" é
  contrário ao anúncio de descontinuação, mesmo com redação positiva
- **Percepções, temas e posicionamentos** com percentuais calculados por
  contagem real e cobertura declarada — atribuição nunca é forçada
- **Perguntas ao corpus**: pergunte "o que dizem sobre o preço?" e receba
  resposta com citações reais dos comentários
- **Exportação CSV**: universo classificado comentário a comentário + resumo
- **Reprodutível**: mesma planilha + mesmo contexto = mesmo resultado (seed fixo)

## Requisitos e o que esperar

| Máquina | Perfil | Modelo | Expectativa |
|---|---|---|---|
| 8 GB RAM (mínimo) | normal | qwen3:4b-instruct | ~500-1.000 comentários/hora em Mac Apple Silicon |
| 16 GB+ RAM | turbo (automático) | qwen3:8b | Mais preciso, mesmo ritmo |
| Windows sem GPU dedicada | normal | qwen3:4b-instruct | **Lento** (CPU pura): reserve horas para corpus grande |

**Durante a análise**: o modelo ocupa a maior parte da RAM. Feche navegador
com muitas abas e aplicativos pesados, especialmente em máquinas de 8 GB.
A máquina continua utilizável para tarefas leves. Pendrive rápido (USB 3+)
melhora a partida e a carga do modelo (1-3 min); a análise em si roda na RAM
e não depende da velocidade do pendrive.

## Instalação

1. Instale o [Ollama](https://ollama.com/download) e o Python 3.10+
2. Baixe este repositório (Code → Download ZIP) e descompacte
3. Rode o instalador apontando o destino (pendrive ou pasta):
   - **macOS**: `./instalador/instalar-pendrive.command /Volumes/SEU_PENDRIVE`
   - **Windows**: `instalador\instalar-pendrive.bat E:\`
4. Abra **Audiens Fit** (`.command` no Mac, `.bat` no Windows) na raiz do destino

O pendrive deve estar em **exFAT** (padrão de fábrica) para funcionar em
Mac e Windows. Para encerrar liberando a RAM, use **Encerrar Audiens**.

> ⚠️ **Aviso sobre antivírus (Windows)**: arquivos `.bat` podem ser sinalizados
> pelo SmartScreen ou por antivírus como suspeitos, porque scripts de lote são
> um formato comum de malware. Os deste projeto são texto aberto — clique com
> o botão direito → Editar para ler exatamente o que fazem antes de executar.
> Se o SmartScreen bloquear: "Mais informações" → "Executar assim mesmo".

## Personalizando os prompts

Toda a metodologia de interpretação vive em **`prompts/prompts.json`** — um
arquivo de texto editável, sem tocar em código. Ajuste o tom, as regras e as
definições para o seu caso; preserve os `{placeholders}` entre chaves, que o
sistema preenche em tempo de execução. Se o JSON quebrar, o servidor avisa a
linha do erro na partida. Os prompts originais estão sob CC-BY-NC-4.0: uso e
modificação livres para fins não comerciais, com atribuição.

## Metodologia em uma linha

Classificação em lotes com modelo local (Ollama), atribuição nunca forçada,
cobertura real declarada em cada bloco, verbatims por casamento lexical com
coerência de sentimento, e seed fixo para reprodutibilidade. Detalhes em
[`docs/metodologia.md`](docs/metodologia.md).

## Licenças

- **Código**: [MIT](LICENSE) — use, modifique e redistribua com atribuição
- **Prompts, metodologia e documentação**: [CC-BY-NC-4.0](LICENSE-CONTEUDO) —
  livres para uso **não comercial** com atribuição; para uso comercial,
  contate Data Design Inteligência de Comunicação
- A identificação "Criado por Daniel Bastos · Data Design" na interface e
  nestes arquivos deve ser preservada (condição de atribuição das licenças)

## Projetos relacionados

- **Audiens** (versão completa, com coleta multiplataforma): ferramenta interna
  da Data Design — este repositório é a edição portátil e aberta
- **Chat Offline**: chat multi-modelo independente para o mesmo pendrive
  (repositório próprio)
