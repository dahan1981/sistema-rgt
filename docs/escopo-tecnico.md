# Escopo tecnico inicial

Este documento traduz o PDF de demonstrativo mensal em modulos de aplicativo.

## Modulos do aplicativo

- Painel global por banca/unidade, com filtro e metricas consolidadas.
- Autenticacao e permissoes por perfil.
- Cadastro de colaboradores.
- Vinculo do colaborador com unidade.
- Demonstrativo mensal por colaborador.
- Lancamento de vales, faltas, incentivos, dobra e domingo compensatorio.
- Controle de caixa positivo e negativo com data e descricao.
- Fechamento de caixa por data, unidade e colaborador.
- Marcacao de caixa negativo para desconto em folha salarial.
- Calculo do passivo circulante final.
- Exportacao futura de PDF e Excel.
- Auditoria de alteracoes.

## Relatorios

Ao iniciar a geracao de relatorio, o RH deve escolher em uma caixa de selecao
quais blocos entram no documento:

- Demonstrativo mensal do colaborador.
- Fechamento de caixa geral.
- Fechamento de caixa por colaborador.

O fechamento geral deve consolidar o mes vigente ate a data atual. O fechamento
por colaborador deve respeitar o colaborador selecionado no aplicativo.

## Regra de calculo inicial

O app calcula localmente:

```text
receitas = incentivo + domingo + dobra + bonificacao + caixa positivo
despesas = vales + desconto por faltas + caixa negativo
passivo final = previsao salarial + receitas - despesas
```

O desconto por faltas usa `previsao salarial / 30 * quantidade de faltas` quando a opcao de lancar faltas como despesa esta ativa.

## Fechamento de caixa

O RH deve conseguir lancar caixas positivos e negativos informando:

- Data do fechamento.
- Unidade.
- Colaborador.
- Tipo do caixa: positivo ou negativo.
- Valor.
- Descricao.
- Para caixa negativo, se deve descontar de folha salarial.

A pagina de fechamento mostra o total mensal ate a data vigente, respeitando o filtro atual de unidade e colaborador.

Cada fechamento deve refletir no resumo financeiro do colaborador como
`Fechamento de caixa parcial`. Caixas positivos entram como receita do periodo.
Caixas negativos entram no saldo parcial; quando marcados para desconto em folha,
tambem entram como despesa do demonstrativo mensal.

## Integracao Supabase futura

As regras sensiveis devem migrar para SQL ou Edge Functions quando o Supabase for integrado. O app deve continuar mostrando o calculo em tempo real, mas o valor oficial salvo e auditado deve vir do backend.
