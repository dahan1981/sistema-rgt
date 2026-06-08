# Sistema RGT

Aplicativo Flutter para controle mensal de entradas, saidas, incentivos e resumo financeiro de colaboradores.

## Stack definida

| Parte | Tecnologia | Linguagem |
| --- | --- | --- |
| App mobile | Flutter | Dart |
| App desktop | Flutter Desktop | Dart |
| Banco futuro | Supabase / PostgreSQL | SQL |
| Login futuro | Supabase Auth | Dart / configuracao |
| Permissoes futuras | Supabase RLS | SQL |
| Automacoes futuras | Supabase Edge Functions | TypeScript |
| Relatorios futuros | Flutter + Edge Functions | Dart / TypeScript |

## Estado atual

Esta primeira versao tem:

- Layout responsivo para mobile e desktop.
- Painel de indicadores.
- Lista de colaboradores por unidade.
- Demonstrativo mensal com formulario financeiro.
- Calculo local do passivo circulante final.
- Estrutura sem dependencia externa, para facilitar a primeira execucao.

## Proximos passos tecnicos

1. Rodar `flutter create . --platforms=android,windows,linux,macos,ios` para gerar os projetos nativos quando o SDK Flutter estiver respondendo.
2. Rodar `flutter pub get`.
3. Integrar Supabase Auth, banco PostgreSQL e RLS.
4. Criar tabelas, funcoes SQL e trilha de auditoria.
5. Adicionar exportacao PDF/Excel.
