# UI Contract: Nova Transação (Receita/Despesa)

## Interface

- Tela: `TransactionFormScreen`
- Rota de criação: `/transacoes/nova`
- Atores: usuário final do app

## Entradas do formulário

- `type`: `expense` ou `income` (obrigatório)
- `amount`: decimal positivo (obrigatório)
- `description`: texto não vazio, máx. 255 (obrigatório)
- `date`: data válida (obrigatório)
- `accountId`: conta ativa selecionada (obrigatório)
- `categoryId`: opcional
- `notes`: opcional

## Regras de validação e mensagens

- Sem valor: `Informe o valor`
- Valor <= 0: `Valor deve ser maior que zero`
- Sem descrição: `Informe a descrição`
- Descrição > 255: `Máximo de 255 caracteres`
- Sem conta: `Selecione uma conta`

## Contrato de submissão

Quando válido, a tela DEVE chamar:

- `CreateTransactionUseCase.execute(...)` no modo criação
- `UpdateTransactionUseCase.execute(...)` no modo edição

Payload mínimo para criação:

- `id`: UUID
- `accountId`: String não vazia
- `type`: `TransactionType.income` ou `TransactionType.expense`
- `amount`: `Money`
- `description`: String
- `date`: DateTime
- `categoryId`: String?
- `notes`: String?

## Comportamento de estados

- `isSaving = true`: botão de submit desabilitado + indicador de progresso
- Erro de validação/domínio: banner de erro visível
- Sucesso: retorno para tela anterior (`context.pop()`)

## Cenários especiais

- Uma conta ativa: conta pré-selecionada automaticamente
- Múltiplas contas: usuário deve escolher explicitamente
- Zero contas: submit desabilitado e orientação para criar conta

## Não objetivos

- Alterar schema de banco de dados
- Alterar entidade de domínio `Transaction`
- Alterar regras de saldo fora do fluxo já existente
