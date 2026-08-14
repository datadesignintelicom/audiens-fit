# Metodologia — Audiens Fit

Criado por Daniel Bastos · Data Design Inteligência de Comunicação — CC-BY-NC-4.0

## Pipeline

1. **Triagem não-verbal** (determinística): comentários com menos de 5
   caracteres úteis são classificados por tabela de polaridade de emojis,
   sem chamada de modelo. Declarado na nota metodológica.
2. **Sentimento binário contextual** (modelo, lotes de 25): cada comentário é
   classificado como favorável, contrário ou não claro EM RELAÇÃO AO CONTEÚDO
   descrito no contexto — nunca pela polaridade literal das palavras. Ironia é
   detectada por sinais textuais explícitos e integrada à posição final.
   Falha de lote vira "não claro" e é CONTADA, nunca disfarçada de dado.
3. **Síntese descritiva** (modelo, amostra estratificada por sentimento):
   resumo, rótulos de percepções (emocionais), temas (assuntos) e
   posicionamentos (argumentos; desligáveis via AUDIENS_FIT_POSICIONAMENTOS=0).
   O modelo é instruído a nunca criar rótulos para dar aparência de equilíbrio.
4. **Shares por contagem real** (modelo, lotes): cada rótulo é aplicado ao
   corpus inteiro; a atribuição nunca é forçada (opção "nenhum" sempre
   disponível) e a cobertura real (% classificado) é declarada no relatório.
5. **Verbatims**: casamento lexical entre rótulo e comentários com fronteira
   de palavra, preferindo sentimento coerente com a valência do rótulo; sem
   candidato coerente, o verbatim fica vazio — nunca um exemplo contraditório.
   Menções a perfis são anonimizadas (`@n*****`) antes de o comentário virar
   exemplo: a menção de abertura, que endereça outro comentarista em vez de
   dizer algo, é removida, e as do meio do texto viram inicial mais
   asteriscos. Comentário com menção deixou de ser descartado por isso — a
   nota metodológica do relatório declara quando algum exemplo foi alterado.

## Lotes e amostragem (o que significa "lote X de Y")

A classificação — sentimento, percepções, temas e posicionamentos — percorre
o corpus INTEIRO, em lotes de 25 comentários por chamada de modelo. Num
corpus de 1.000 comentários, a fase de sentimento tem 40 lotes, e cada bloco
de rótulos percorre os 40 de novo. Todos os percentuais do relatório são
contagem real sobre a totalidade, nunca extrapolação: essa é a razão da
duração das análises grandes.

A única amostragem do Audiens Fit é a da síntese interpretativa, por limite
físico da janela do modelo: uma amostra estratificada por sentimento (100
comentários no perfil normal, 120 no turbo; `amostra_sintese` em
`app/config.py`), sorteada com seed fixo, serve apenas para NOMEAR os
rótulos. Nomeados, eles voltam ao corpus completo para a contagem real.

## Reprodutibilidade

Seed fixo (42) na geração e na amostragem: a mesma planilha com o mesmo
contexto produz o mesmo relatório. O modelo usado, o perfil (normal/turbo) e
as falhas de lote constam na nota metodológica de cada análise.

## Limitações declaradas

- Modelos compactos (4B) são mais fracos em temas e em nuances raras de
  ironia do que modelos maiores; o perfil turbo (8B) reduz a diferença.
- Perguntas ao corpus retornam ESTIMATIVAS qualitativas com citações; para
  percentuais precisos, use a análise completa.
- A qualidade do contexto fornecido importa: descreva o conteúdo e o que
  "apoiar" significa naquele caso.
