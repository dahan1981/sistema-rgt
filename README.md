# Sistema RGT

Aplicativo Flutter para controle mensal de entradas, saídas, incentivos,
fechamentos de caixa e histórico de colaboradores.

Versão atual: `0.9.0+3`, candidata à homologação da V1.

## Stack

| Parte | Tecnologia | Linguagem |
| --- | --- | --- |
| Aplicativo mobile | Flutter | Dart |
| Aplicativo Windows | Flutter Desktop | Dart |
| Banco de dados | Supabase / PostgreSQL | SQL |
| Autenticação | Supabase Auth | Dart |
| Permissões | Supabase RLS | SQL |
| Relatórios | PDF e Excel | Dart |

## Funcionalidades

- Painel global por banca e colaborador.
- Cadastro e alteração temporária de banca com histórico.
- Demonstrativo mensal por competência.
- Lançamento de faltas com seleção individual de despesa.
- Fechamento de caixa positivo e negativo.
- Desconto em folha para caixas negativos.
- Persistência transacional do demonstrativo mensal.
- Auditoria de inclusões, alterações e exclusões.
- Relatórios por competência, período, banca e colaboradores.
- Exportação dos relatórios em PDF e Excel.
- Atualizações Windows distribuídas pelo Supabase Storage.
- Acesso restrito a e-mails previamente autorizados.
- Correção e cancelamento auditável de fechamentos de caixa.
- Validação SHA-256 dos instaladores de atualização.

Os campos financeiros iniciam vazios. O aplicativo não preenche valores de
exemplo quando ainda não existe demonstrativo no banco.

## Configuração do Supabase

1. Execute `supabase/schema.sql` no SQL Editor do projeto.
2. Autorize os dois usuários conforme `supabase/authorize-users.example.sql`.
3. Execute `supabase/storage.sql` para preparar as atualizações Windows.
4. Configure os templates de `supabase/email-templates.md` no painel do Auth.
5. Copie `tools/start_windows.local.ps1` para o ambiente local e informe apenas
   a publishable key. Esse arquivo é ignorado pelo Git.

Nunca coloque senha PostgreSQL, `service_role` ou outras credenciais privadas
no aplicativo.

## Desenvolvimento

```powershell
flutter pub get
flutter test
flutter analyze
```

No Windows, use `tools/start_windows.ps1` para compilar e abrir o aplicativo
com as configurações locais e o manifesto de atualização.
