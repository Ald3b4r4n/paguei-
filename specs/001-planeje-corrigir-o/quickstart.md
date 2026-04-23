# Quickstart: Validar correção de registro de receita

## Pré-requisitos

1. Executar dependências do projeto:
   - `flutter pub get`
2. Garantir código gerado atualizado:
   - `dart run build_runner build --delete-conflicting-outputs`

## Validação automatizada

1. Rodar testes de widget da tela de transação:
   - `flutter test test/presentation/transactions/transaction_form_screen_test.dart`
2. Rodar análise estática:
   - `flutter analyze`

## Validação manual (cenário principal)

1. Abrir app em desenvolvimento:
   - `flutter run --target lib/main_development.dart`
2. Criar pelo menos uma conta ativa (caso ainda não exista).
3. Navegar para Transações > Nova Transação.
4. Selecionar `Receita`.
5. Preencher:
   - Valor: `100`
   - Descrição: `Padaria`
   - Data: hoje
   - Conta: selecionar uma conta ativa no campo `Conta`
6. Tocar em `Registrar`.
7. Resultado esperado:
   - Tela fecha sem banner de erro.
   - Nova transação aparece na lista mensal.
   - Saldo da conta selecionada aumenta no valor lançado.
   - O lançamento fica associado à conta escolhida.

## Validação manual (cenários de borda)

1. Múltiplas contas e nenhuma selecionada:
   - Resultado esperado: campo `Conta` visível, mensagem `Selecione uma conta` no próprio campo e sem salvar.
2. Apenas uma conta ativa:
   - Resultado esperado: conta já vem selecionada por padrão e `Registrar` funciona sem seleção manual.
3. Zero contas ativas:
   - Resultado esperado: formulário mostra `Nenhuma conta ativa`, oferece `Criar conta` e bloqueia submit.
