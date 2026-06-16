# Atualizações Windows

O aplicativo Windows consulta um manifesto remoto no Supabase Storage para
avisar o cliente quando uma nova versão estiver disponível.

Manifesto padrão:

```text
https://libpncdxxgwshnlxicbt.supabase.co/storage/v1/object/public/app-updates/latest.json
```

Bucket recomendado:

```text
app-updates
```

Estrutura sugerida no bucket:

```text
app-updates/
  latest.json
  windows/
    SistemaRGT-Setup-0.1.1.exe
```

## Fluxo de entrega

1. Atualizar `version` no `pubspec.yaml`.
2. Gerar o build/instalador Windows.
3. Subir o instalador no Supabase Storage, dentro de `app-updates/windows/`.
4. Atualizar `updates/latest.json` com a nova versão e o link público do instalador.
5. Subir o `latest.json` no Supabase Storage, substituindo `app-updates/latest.json`.
6. Comitar também o `updates/latest.json` no Git para manter histórico da versão publicada.

Exemplo:

```json
{
  "version": "0.1.1",
  "windows_url": "https://libpncdxxgwshnlxicbt.supabase.co/storage/v1/object/public/app-updates/windows/SistemaRGT-Setup-0.1.1.exe",
  "notes": "Correções no fechamento de caixa e melhorias de auditoria.",
  "mandatory": false
}
```

Quando a versão remota for maior que a versão instalada, o app mostra a tela
`Atualização disponível` e abre o link de download após confirmação do usuário.

## Configuração do bucket

Para esse fluxo funcionar de forma simples, o bucket `app-updates` deve ser
público para leitura. Somente usuários administrativos devem ter permissão para
subir ou substituir arquivos.

O arquivo `supabase/storage.sql` cria o bucket e as políticas iniciais. Execute
esse SQL no Supabase antes de publicar o primeiro instalador.

Não use esse bucket para credenciais, `.env`, backups de banco ou qualquer dado
sensível. Ele deve conter apenas instaladores e manifestos públicos de versão.
