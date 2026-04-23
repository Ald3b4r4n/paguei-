# ADR-001: Riverpod como solução de gerenciamento de estado

**Status**: Aceito
**Data**: 2026-04-19
**Decisores**: Equipe Paguei?

---

## Contexto

O aplicativo Paguei? precisa de uma solução de gerenciamento de estado que:
- Seja type-safe em tempo de compilação
- Suporte estado imutável por padrão
- Tenha boa ergonomia para equipes pequenas
- Seja compatível com o padrão offline-first (streams reativos)
- Não exija cerimônia excessiva para operações simples

As principais alternativas consideradas foram **Riverpod 3.x** e **BLoC 9.x**.

---

## Decisão

Adotamos **flutter_riverpod ^3.3.1** com geração de código via **riverpod_annotation** e **riverpod_generator**.

---

## Justificativa

| Critério | Riverpod 3.x | BLoC 9.x |
|---|---|---|
| Type-safety em compilação | ✅ | ✅ |
| Cerimônia para CRUD simples | Baixa | Alta (Event→State) |
| Estado imutável | ✅ nativo | Requer disciplina |
| Testabilidade | ✅ (Provider overrides) | ✅ (BlocTest) |
| Curva de aprendizado | Média | Alta |
| Adequação para equipe pequena | ✅ | ⚠️ Overhead |
| Integração com Drift Streams | Direto via StreamProvider | Requer adaptadores |

**Por que não BLoC**: BLoC é a escolha certa para times grandes em ambientes regulados (bancos, fintechs com compliance obrigatório de trilha de auditoria). Para o Paguei?, que é uma aplicação pessoal com uma equipe pequena, o overhead event→state adicionaria complexidade sem benefício proporcional.

---

## Consequências

- Todos os providers usam `@riverpod` (code gen) ou `Provider`/`AsyncNotifierProvider` explícitos.
- Estado de UI DEVE ser imutável via `@freezed` ou `copyWith`.
- Side effects isolados em `AsyncNotifier.build()` ou use cases invocados pelo notifier.
- Global mutable singletons são proibidos.

---

## Alternativas descartadas

- **Provider**: Deprecado pelo criador em favor do Riverpod.
- **GetX**: Viola Clean Architecture ao misturar DI, routing e estado em um único pacote.
- **Bloc**: Descartado conforme justificativa acima.
