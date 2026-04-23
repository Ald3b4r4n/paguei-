# Feature Specification: Corrigir erro ao registrar receita

**Feature Branch**: `001-planeje-corrigir-o`  
**Created**: 2026-04-22  
**Status**: Draft  
**Input**: User description: "Planeje corrigir o erro que dá quando tento registrar uma receita"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Registrar receita com sucesso (Priority: P1)

Como usuário, quero registrar uma receita na tela Nova Transação sem ser bloqueado por validação de conta invisível, para manter meu saldo atualizado no momento do lançamento.

**Why this priority**: O bug impede a conclusão de um fluxo financeiro essencial e quebra a missão do produto de responder rapidamente ao estado financeiro do usuário.

**Independent Test**: Pode ser testado de forma independente preenchendo valor, descrição, data, tipo Receita e conta válida; ao tocar em Registrar, o caso de uso de criação deve ser chamado com `TransactionType.income` e `accountId` válido.

**Acceptance Scenarios**:

1. **Given** que existem contas ativas e a tela de nova transação foi aberta, **When** o usuário seleciona Receita, preenche campos obrigatórios, seleciona uma conta e toca em Registrar, **Then** a transação é salva e a tela é fechada sem erro.
2. **Given** que o usuário alternou entre Despesa e Receita durante o preenchimento, **When** ele conclui o formulário com conta válida, **Then** o tipo selecionado é respeitado e o salvamento ocorre com sucesso.

---

### User Story 2 - Entender claramente a exigência de conta (Priority: P2)

Como usuário, quero ver e interagir com um seletor de conta obrigatório dentro do formulário, para entender por que o sistema exige uma conta antes de salvar.

**Why this priority**: A mensagem "Selecione uma conta" sem campo correspondente gera fricção, ambiguidade e falha de UX.

**Independent Test**: Pode ser testado com múltiplas contas ativas tentando enviar o formulário sem selecionar conta e validando que o formulário bloqueia envio com feedback no campo e sem chamar o caso de uso.

**Acceptance Scenarios**:

1. **Given** que existem duas ou mais contas ativas, **When** o usuário tenta registrar sem conta selecionada, **Then** o formulário exibe validação "Selecione uma conta" no campo de conta e não salva a transação.

---

### User Story 3 - Tratar ausência de contas ativas (Priority: P3)

Como usuário sem contas cadastradas, quero receber orientação clara antes de tentar registrar receita/despesa, para saber que preciso criar uma conta primeiro.

**Why this priority**: Evita erro recorrente e reduz tentativas frustradas de submissão.

**Independent Test**: Pode ser testado abrindo a tela com stream de contas vazia e verificando estado informativo + ação para criação de conta e submissão desabilitada.

**Acceptance Scenarios**:

1. **Given** que não existem contas ativas, **When** o usuário abre Nova Transação, **Then** o sistema mostra mensagem orientativa e impede submissão até existir conta disponível.

### Edge Cases

- Conta selecionada é arquivada/removida enquanto o formulário está aberto.
- A edição de transação existente deve preservar o `accountId` atual mesmo que o usuário não altere a conta.
- Fluxo com somente uma conta ativa deve minimizar cliques sem escolher conta incorreta automaticamente em cenários ambíguos.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: A tela de Nova Transação DEVE exibir um campo de seleção de conta visível e interativo para transações de receita e despesa.
- **FR-002**: O formulário DEVE impedir o envio quando `accountId` não estiver definido e DEVE exibir feedback de validação no próprio campo de conta.
- **FR-003**: O sistema DEVE enviar `accountId` válido ao `CreateTransactionUseCase` para registros de receita e despesa.
- **FR-004**: Quando existir exatamente uma conta ativa, o formulário DEVE iniciar com essa conta pré-selecionada.
- **FR-005**: Quando não existir conta ativa, o formulário DEVE mostrar estado orientativo e bloquear o envio.
- **FR-006**: A correção NÃO DEVE alterar regras de domínio de `Transaction`, esquema de banco Drift ou contratos de repositório.
- **FR-007**: Devem ser adicionados testes de regressão para garantir que o fluxo de receita não volte a falhar por ausência de conta selecionada.

### Key Entities _(include if feature involves data)_

- **Transaction**: Entidade já existente que exige `accountId`, `type`, `amount`, `description` e `date`; será reutilizada sem alteração estrutural.
- **Account**: Entidade fornecida por `accountsStreamProvider`; fonte dos itens do seletor de conta.
- **Transaction Form State**: Estado de apresentação com campos digitados, tipo selecionado, conta selecionada, mensagens de erro e status de salvamento.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Em teste de widget, ao preencher Receita com conta selecionada, o envio chama o caso de uso de criação exatamente 1 vez sem exibir erro.
- **SC-002**: Em teste de widget com múltiplas contas e sem seleção, o envio é bloqueado e a mensagem "Selecione uma conta" é exibida.
- **SC-003**: Em teste de widget com zero contas, o botão Registrar permanece desabilitado e o usuário recebe orientação para criar conta.
- **SC-004**: Após a correção, os testes existentes de `transaction_form_screen` continuam passando sem regressão de comportamento.

## Assumptions

- `accountId` é obrigatório por definição de domínio e não será flexibilizado.
- `accountsStreamProvider` já entrega apenas contas ativas para uso no formulário.
- A rota para criação de conta (`/contas/nova`) permanece disponível para eventual CTA.
- O escopo desta feature está limitado ao fluxo de criação/edição em `transaction_form_screen.dart` e testes relacionados.
