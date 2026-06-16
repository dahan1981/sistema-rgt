# Escopo técnico inicial

Este documento traduz o PDF de demonstrativo mensal em módulos de aplicativo.

## Módulos do aplicativo

- Painel global por banca/unidade, com filtros de banca e colaborador, e métricas consolidadas.
- Autenticação e permissões por perfil.
- Cadastro editável de colaboradores.
- Vínculo do colaborador com unidade, com histórico de alterações temporárias de banca por data.
- Demonstrativo mensal por colaborador, com lançamento de fechamento de caixa na mesma tela.
- Lançamento de vales, faltas com data para histórico, incentivos e bonificações.
- Controle de caixa positivo e negativo com data e descrição.
- Fechamento de caixa por data, unidade e colaborador.
- Marcação de caixa negativo para desconto em folha salarial.
- Cálculo do passivo circulante final.
- Exportação futura de PDF e Excel.
- Auditoria de alterações.

## Base inicial de colaboradores

- Laranjeiras: Daniele, Kethelyn.
- Largo: Priscila, Flávia.
- Geral: Denis.
- KTT1: Anna, Rafaela.
- KTT2: Patrick, Breno, Danilo.
- KTT3: Cainã, Gabriela.
- KTT4: Brenda, Dimas, Brendel.
- ADM: Luiz, Fabiana, Wesley, Jean, João, Nise, Thais.

## Relatórios

Ao iniciar a geração de relatório, o RH deve escolher em uma caixa de seleção
quais blocos entram no documento:

- Demonstrativo mensal do colaborador.
- Fechamento de caixa geral.
- Fechamento de caixa por colaborador.

O fechamento geral deve consolidar o mês vigente até a data atual. O fechamento
por colaborador deve respeitar o colaborador selecionado no aplicativo.

## Regra de cálculo inicial

O app calcula localmente:

```text
receitas = incentivo + bonificação + fechamento de caixa positivo
despesas = vales + desconto por faltas + caixa negativo
passivo final = previsão salarial + receitas - despesas
```

O desconto por faltas usa `previsão salarial / 30 * quantidade de faltas marcadas como despesa`. Cada falta registrada deve permitir escolher individualmente se entra ou não como despesa.

## Fechamento de caixa no demonstrativo mensal

O RH deve conseguir lançar caixas positivos e negativos informando:

- Data do fechamento.
- Unidade.
- Colaborador.
- Tipo do caixa: positivo ou negativo.
- Valor.
- Descrição.
- Para caixa negativo, se deve descontar de folha salarial.

A banca do caixa deve ser resolvida pela banca efetiva do colaborador na data do lançamento. Se existir alteração temporária cadastrada para aquela data, o caixa fica vinculado à banca temporária; caso contrário, usa a banca de cadastro.

A página de fechamento mostra o total mensal até a data vigente, respeitando o filtro atual de unidade e colaborador.

Cada fechamento deve refletir no resumo financeiro do colaborador como
`Fechamento de caixa parcial`. Caixas positivos entram como receita do período.
Caixas negativos entram no saldo parcial; quando marcados para desconto em folha,
também entram como despesa do demonstrativo mensal.

## Integração Supabase

O app Flutter usa somente a URL pública do projeto Supabase e a publishable key.
A string PostgreSQL não deve ser colocada no aplicativo, pois ela carrega senha
de banco e deve ficar restrita a scripts administrativos, migrações e ambiente
seguro de backend.

No Windows local, o arquivo ignorado pelo Git `tools/start_windows.local.ps1`
define `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` antes do build. Em outros
ambientes, passe os mesmos valores via `--dart-define`.

Quando for usar a URL PostgreSQL em ferramenta de banco, a senha precisa estar
codificada na URL. Como a senha termina com `@`, esse caractere deve ser enviado
como `%40`; caso contrário, o cliente interpreta o `@` como separador do host.

Formato seguro para documentação:

```text
postgresql://postgres.<project-ref>:<senha-com-%40>@aws-1-us-west-2.pooler.supabase.com:6543/postgres
```

As regras sensíveis devem ficar em SQL ou Edge Functions. O app pode continuar
mostrando o cálculo em tempo real, mas o valor oficial salvo e auditado deve vir
do backend.
