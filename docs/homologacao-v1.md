# Homologação da V1

## Acesso e segurança

- [ ] Executar `supabase/schema.sql` no projeto de produção.
- [ ] Inserir exatamente os dois e-mails em `authorized_users`.
- [ ] Confirmar que um terceiro e-mail autenticado não consegue entrar.
- [ ] Confirmar recuperação de senha, troca de e-mail e reautenticação.
- [ ] Trocar a senha PostgreSQL usada durante o desenvolvimento.
- [ ] Configurar SMTP e templates de e-mail no painel Supabase.

## Conferência funcional

- [ ] Validar a lista de colaboradores e bancas com o RH.
- [ ] Lançar um mês real completo para pelo menos dois colaboradores.
- [ ] Conferir faltas com e sem desconto.
- [ ] Conferir incentivos de pontuação 1, 2 e 3.
- [ ] Conferir caixas positivos, negativos e descontos em folha.
- [ ] Corrigir um fechamento com justificativa e validar a auditoria.
- [ ] Cancelar um fechamento e confirmar que ele saiu dos totais.
- [ ] Alterar temporariamente uma banca e conferir o histórico.
- [ ] Comparar o passivo final com o cálculo manual do RH.

## Relatórios

- [ ] Gerar relatório geral por período.
- [ ] Gerar relatório por banca e por colaborador.
- [ ] Abrir o PDF e conferir acentos, páginas e valores.
- [ ] Abrir o Excel e conferir as três abas e valores numéricos.

## Operação

- [ ] Criar um backup com `tools/backup_supabase.ps1`.
- [ ] Restaurar esse backup em um projeto de teste.
- [ ] Instalar a V1 em uma máquina limpa.
- [ ] Atualizar uma instalação anterior usando o manifesto remoto.
- [ ] Registrar a aprovação final do responsável do cliente.
