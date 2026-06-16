# Templates de e-mail Supabase Auth

Copie estes textos para o painel do Supabase em `Authentication > Emails`.

## Confirm sign up

Assunto:

```text
Confirme seu acesso ao Sistema RGT
```

Mensagem:

```html
<h2>Confirme seu acesso ao Sistema RGT</h2>

<p>Olá,</p>

<p>Recebemos uma solicitação de criação de conta para o Sistema RGT.</p>

<p>Para ativar seu acesso, confirme seu e-mail pelo botão abaixo:</p>

<p>
  <a href="{{ .ConfirmationURL }}">Confirmar meu e-mail</a>
</p>

<p>Se você não solicitou este cadastro, ignore esta mensagem.</p>

<p>Atenciosamente,<br>Equipe RGT</p>
```

## Change email address

Assunto:

```text
Confirme a alteração de e-mail do Sistema RGT
```

Mensagem:

```html
<h2>Confirme a alteração de e-mail</h2>

<p>Olá,</p>

<p>Recebemos uma solicitação para alterar o e-mail da sua conta no Sistema RGT.</p>

<p>Para confirmar a alteração, clique no botão abaixo:</p>

<p>
  <a href="{{ .ConfirmationURL }}">Confirmar novo e-mail</a>
</p>

<p>Se você não solicitou essa alteração, não clique no botão e avise o responsável pelo sistema.</p>

<p>Atenciosamente,<br>Equipe RGT</p>
```

## Reset password

Assunto:

```text
Redefinição de senha do Sistema RGT
```

Mensagem:

```html
<h2>Redefinição de senha</h2>

<p>Olá,</p>

<p>Recebemos uma solicitação para redefinir sua senha no Sistema RGT.</p>

<p>Clique no botão abaixo para criar uma nova senha:</p>

<p>
  <a href="{{ .ConfirmationURL }}">Redefinir minha senha</a>
</p>

<p>Se você não solicitou essa redefinição, ignore esta mensagem.</p>

<p>Atenciosamente,<br>Equipe RGT</p>
```

## Reauthentication

Assunto:

```text
Código de segurança do Sistema RGT
```

Mensagem:

```html
<h2>Código de segurança</h2>

<p>Olá,</p>

<p>Use o código abaixo para confirmar sua identidade no Sistema RGT:</p>

<p style="font-size: 24px; font-weight: bold;">{{ .Token }}</p>

<p>Esse código é necessário para operações sensíveis, como troca de e-mail ou alteração de senha.</p>

<p>Se você não solicitou essa operação, ignore esta mensagem e avise o responsável pelo sistema.</p>

<p>Atenciosamente,<br>Equipe RGT</p>
```
