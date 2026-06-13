# Escopo técnico inicial

Este documento traduz o PDF de demonstrativo mensal em módulos de aplicativo.

## Módulos do aplicativo

- Painel global por banca/unidade, com filtros de banca e colaborador, e métricas consolidadas.
- Autenticação e permissões por perfil.
- Cadastro de colaboradores.
- Vínculo do colaborador com unidade.
- Demonstrativo mensal por colaborador.
- Lançamento de vales, faltas com data para histórico, incentivos, dobra e domingo compensatório.
- Controle de caixa positivo e negativo com data e descrição.
- Fechamento de caixa por data, unidade e colaborador.
- Marcação de caixa negativo para desconto em folha salarial.
- Cálculo do passivo circulante final.
- Exportação futura de PDF e Excel.
- Auditoria de alterações.

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
receitas = incentivo + domingo + dobra + bonificação + caixa positivo
despesas = vales + desconto por faltas + caixa negativo
passivo final = previsão salarial + receitas - despesas
```

O desconto por faltas usa `previsão salarial / 30 * quantidade de faltas registradas` quando a opção de lançar faltas como despesa está ativa.

## Fechamento de caixa

O RH deve conseguir lançar caixas positivos e negativos informando:

- Data do fechamento.
- Unidade.
- Colaborador.
- Tipo do caixa: positivo ou negativo.
- Valor.
- Descrição.
- Para caixa negativo, se deve descontar de folha salarial.

A página de fechamento mostra o total mensal até a data vigente, respeitando o filtro atual de unidade e colaborador.

Cada fechamento deve refletir no resumo financeiro do colaborador como
`Fechamento de caixa parcial`. Caixas positivos entram como receita do período.
Caixas negativos entram no saldo parcial; quando marcados para desconto em folha,
também entram como despesa do demonstrativo mensal.

## Integração Supabase futura

As regras sensíveis devem migrar para SQL ou Edge Functions quando o Supabase for integrado. O app deve continuar mostrando o cálculo em tempo real, mas o valor oficial salvo e auditado deve vir do backend.
