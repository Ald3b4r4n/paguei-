# Research: Correção do erro ao registrar receita

## Contexto

A tela de Nova Transação valida que `accountId` é obrigatório, mas atualmente não oferece um campo de seleção de conta no fluxo de criação. Isso gera erro de validação (`Selecione uma conta`) sem ação possível para o usuário concluir o cadastro.

## Decision 1: Tornar a conta obrigatória e visível no formulário

- Decision: Adicionar um seletor de conta no formulário de `transaction_form_screen.dart` para criação de receita e despesa.
- Rationale: O domínio exige `accountId` para `Transaction.create`; a UI deve sempre expor esse requisito de forma explícita para evitar erro bloqueante.
- Alternatives considered:
  - Não mostrar campo e inferir conta por contexto de navegação: rejeitado por ser frágil e não cobrir entrada via rota direta `/transacoes/nova`.
  - Manter validação apenas no submit com banner genérico: rejeitado por UX ambígua e baixa descobribilidade.

## Decision 2: Estratégia de seleção padrão da conta

- Decision: Pré-selecionar conta automaticamente apenas quando existir exatamente uma conta ativa; com duas ou mais contas, exigir escolha explícita do usuário.
- Rationale: Reduz atrito no caso simples (1 conta) e evita salvar em conta incorreta no caso ambíguo (múltiplas contas).
- Alternatives considered:
  - Sempre pré-selecionar a primeira conta: rejeitado por risco de lançamento em conta errada.
  - Nunca pré-selecionar: rejeitado por adicionar cliques desnecessários no cenário de conta única.

## Decision 3: Comportamento sem contas ativas

- Decision: Exibir estado orientativo quando lista de contas estiver vazia, desabilitar `Registrar` e oferecer atalho para criar conta.
- Rationale: Remove tentativa frustrada de submit e fornece caminho de resolução direto.
- Alternatives considered:
  - Permitir submit e falhar com erro: rejeitado por repetição de falha já reportada.
  - Criar conta implícita automática: rejeitado por inserir dados sem confirmação explícita do usuário.

## Decision 4: Padrão de componente para o seletor

- Decision: Reutilizar o padrão de `DropdownButtonFormField` já usado em `transfer_form_screen.dart` e formulários de boletos.
- Rationale: Mantém consistência visual/comportamental e reduz risco de divergências de validação.
- Alternatives considered:
  - Criar novo bottom sheet customizado de contas: rejeitado por custo maior sem ganho funcional para este bugfix.

## Decision 5: Estratégia de testes de regressão

- Decision: Adicionar testes de widget focados no fluxo de Receita para os cenários: conta válida, conta ausente e zero contas.
- Rationale: Reproduz exatamente a falha do usuário em nível de UI e garante prevenção de regressão.
- Alternatives considered:
  - Somente teste manual: rejeitado por baixa confiabilidade para regressão contínua.
  - Somente teste de integração end-to-end: rejeitado por custo/tempo maior para validar regra local de formulário.

## Dependências e padrões confirmados

- `accountsStreamProvider` já é a fonte reativa de contas ativas na camada de apresentação.
- `CreateTransactionUseCase` e `TransactionRepository` já aceitam `accountId` obrigatório, sem necessidade de mudança em domínio/dados.
- Solução permanece offline-first, mantendo persistência local com Drift e sem dependência remota.
