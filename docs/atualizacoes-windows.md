# Atualizações Windows

O aplicativo Windows consulta um manifesto remoto para avisar o cliente quando
uma nova versão estiver disponível.

Manifesto padrão:

```text
https://raw.githubusercontent.com/dahan1981/sistema-rgt/main/updates/latest.json
```

## Fluxo de entrega

1. Atualizar `version` no `pubspec.yaml`.
2. Gerar o build/instalador Windows.
3. Publicar o instalador no GitHub Releases.
4. Atualizar `updates/latest.json` com a nova versão e o link do instalador.
5. Subir o `latest.json` no Git.

Exemplo:

```json
{
  "version": "0.1.1",
  "windows_url": "https://github.com/dahan1981/sistema-rgt/releases/download/v0.1.1/SistemaRGT-Setup.exe",
  "notes": "Correções no fechamento de caixa e melhorias de auditoria.",
  "mandatory": false
}
```

Quando a versão remota for maior que a versão instalada, o app mostra a tela
`Atualização disponível` e abre o link de download após confirmação do usuário.
