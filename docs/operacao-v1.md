# Operação da V1

## Autorização dos dois usuários

1. Execute `supabase/schema.sql` no SQL Editor ou use
   `tools/apply_supabase_schema.ps1` com `DATABASE_URL` no ambiente.
2. Edite uma cópia local de `supabase/authorize-users.example.sql` com os dois
   e-mails definitivos, sempre em letras minúsculas.
3. Execute o SQL no projeto.
4. Crie ou confirme as duas contas no Supabase Auth.
5. Mantenha `ALLOW_ACCOUNT_SIGNUP=false` nas builds de produção.

## Backup

Instale as ferramentas cliente do PostgreSQL e defina `DATABASE_URL` apenas na
sessão administrativa. Senhas com `@` devem usar `%40` na URL.

```powershell
$env:DATABASE_URL='postgresql://...'
.\tools\backup_supabase.ps1
```

Os arquivos em `backups/` são ignorados pelo Git. Armazene uma cópia cifrada
fora da máquina de operação.

## Restauração

Faça o primeiro teste em outro projeto Supabase. A restauração é bloqueada sem
confirmação explícita:

```powershell
.\tools\restore_supabase.ps1 -BackupFile .\backups\arquivo.dump -ConfirmRestore
```

## Release Windows

Pré-requisitos: Flutter, Inno Setup 6 e, para assinatura digital, Windows SDK.

```powershell
.\tools\release_windows.ps1 -Version 1.0.0 -Notes 'Primeira versão estável'
```

Para publicar diretamente no Supabase Storage, informe a `service_role` apenas
na sessão administrativa e acrescente `-Upload`. Essa chave nunca deve entrar
no aplicativo, no Git ou em arquivos locais compartilhados.

O script gera o instalador, calcula SHA-256 e cria `dist/latest.json`. O
aplicativo valida o hash antes de executar qualquer atualização Windows.
