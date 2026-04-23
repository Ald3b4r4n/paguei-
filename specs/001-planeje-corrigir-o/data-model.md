# Data Model: Correção de registro de receita

## Visão geral

Esta feature não introduz novas tabelas nem altera entidades de domínio persistidas. O foco é ajustar o modelo de estado da UI para garantir que `accountId` esteja definido antes do submit.

## Entidades existentes reutilizadas

### Account

- Fonte: `accountsStreamProvider`
- Campos relevantes:
  - `id: String`
  - `name: String`
  - `isArchived: bool`
- Regra: apenas contas ativas são elegíveis para seleção no formulário.

### Transaction

- Fonte: `Transaction.create` / `CreateTransactionUseCase`
- Campos obrigatórios relevantes:
  - `id: String`
  - `accountId: String`
  - `type: TransactionType` (`income` ou `expense`)
  - `amount: Money` (> 0)
  - `description: String` (não vazia, máx. 255)
  - `date: DateTime`
- Regra crítica: `accountId` obrigatório para criação.

## Modelo de estado de apresentação

### TransactionFormState (conceitual)

- `selectedType: TransactionType`
- `selectedDate: DateTime`
- `selectedCategoryId: String?`
- `selectedAccountId: String?`
- `isSaving: bool`
- `errorMessage: String?`
- `availableAccounts: List<Account>`

### Regras de validação

- `amount` deve ser numérico e > 0.
- `description` deve ser não vazia e <= 255 caracteres.
- `selectedAccountId` é obrigatório no submit.
- Se `availableAccounts.isEmpty`, submit não deve ser permitido.

## Relacionamentos

- `TransactionFormState.selectedAccountId` referencia `Account.id`.
- `Transaction` criada herda `accountId` selecionado no formulário.

## Transições de estado

1. `Idle`
   - Formulário carregado.
   - Conta pré-selecionada apenas se houver exatamente 1 conta ativa.
2. `Editing`
   - Usuário altera tipo, valor, descrição, data, categoria e conta.
3. `ValidationError`
   - Tentativa de submit sem `selectedAccountId` ou com campos inválidos.
4. `Saving`
   - Chamada ao caso de uso de criação/edição.
5. `Saved`
   - Navegação de volta após sucesso.
6. `SaveError`
   - Erro de validação/domínio ou erro inesperado exibido em banner.

## Impacto em migração

- Nenhum.
- Schema Drift permanece inalterado.
