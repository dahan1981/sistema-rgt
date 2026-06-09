# Sistema RGT

Aplicativo Flutter para controle mensal de entradas, saídas, incentivos e resumo financeiro de colaboradores.

## Stack definida

| Parte | Tecnologia | Linguagem |
| --- | --- | --- |
| App mobile | Flutter | Dart |
| App desktop | Flutter Desktop | Dart |
| Banco futuro | Supabase / PostgreSQL | SQL |
| Login futuro | Supabase Auth | Dart / configuração |
| Permissões futuras | Supabase RLS | SQL |
| Automações futuras | Supabase Edge Functions | TypeScript |
| Relatórios futuros | Flutter + Edge Functions | Dart / TypeScript |

## Estado atual

Esta primeira versão tem:

- Layout responsivo para mobile e desktop.
- Painel de indicadores.
- Lista de colaboradores por unidade.
- Demonstrativo mensal com formulário financeiro.
- Cálculo local do passivo circulante final.
- Estrutura sem dependência externa, para facilitar a primeira execução.

## Próximos passos técnicos

1. Rodar `flutter create . --platforms=android,windows,linux,macos,ios` para gerar os projetos nativos quando o SDK Flutter estiver respondendo.
2. Rodar `flutter pub get`.
3. Integrar Supabase Auth, banco PostgreSQL e RLS.
4. Criar tabelas, funções SQL e trilha de auditoria.
5. Adicionar exportação PDF/Excel.
