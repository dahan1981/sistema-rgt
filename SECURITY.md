# Segurança

Este projeto não deve versionar credenciais reais.

## Regras

- Não commitar `.env`, `.env.local`, strings PostgreSQL, senhas, service role keys, certificados ou chaves privadas.
- O app Flutter deve usar somente `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`.
- A URL PostgreSQL deve ficar restrita a migrações, scripts administrativos ou ambiente seguro de backend.
- Senhas em URLs precisam ser codificadas. O caractere `@` deve ser enviado como `%40`.
- Antes de publicar ou compartilhar builds, revisar `git status --short` e procurar credenciais com `rg`.

## Arquivos locais

Use `.env.example` como modelo e mantenha os valores reais em `.env` ou em variáveis do sistema.
No Windows, `tools/start_windows.local.ps1` também é local e ignorado pelo Git.
