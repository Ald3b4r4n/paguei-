# Paguei? — Guia de Desenvolvimento

**Projeto**: Paguei? — Controle financeiro pessoal pt-BR
**Stack**: Flutter 3.22+ / Dart 3.4+ / Riverpod 3.x / Drift 2.x
**Arquitetura**: Clean Architecture em 5 camadas (core/domain/application/data/presentation)

---

## Passos obrigatórios após clonar

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## Executar

```bash
flutter run --target lib/main_development.dart   # desenvolvimento
flutter run --target lib/main.dart               # produção
```

## Testes

```bash
flutter test                          # todos os testes
flutter test test/domain/             # apenas domain
flutter test test/data/database/      # migrações Drift
flutter test --coverage               # com cobertura
```

## Regras de camada (não violar)

- `domain/` NÃO importa Flutter nem infraestrutura
- `presentation/` NÃO acessa repositórios diretamente
- Use cases em `application/`, nunca em widgets
- Estado via Riverpod, imutável com Freezed

## Tecnologias ativas

- Estado: `flutter_riverpod ^3.3.1`
- Banco: `drift ^2.32.1` (SQLite, schema v1, 10 tabelas)
- Navegação: `go_router ^14.0.0` (ShellRoute + 5 abas)
- OCR: `google_mlkit_text_recognition ^0.15.1`
- Scanner: `mobile_scanner ^7.2.0`
- PDF: `syncfusion_flutter_pdf ^33.1.49` (licença community)
- Notificações: `flutter_local_notifications ^21.0.0`
- Gráficos: `fl_chart ^1.2.0`
- Segurança: `flutter_secure_storage ^10.0.0`
- Animações: `flutter_animate ^4.5.2` + `lottie ^3.3.3`

## Formatação pt-BR

```dart
CurrencyFormatter.format(1234.56)  // → "R$ 1.234,56"
DateFormatter.formatShort(date)    // → "19/04/2026"
```

## Convenções

- Nomes explícitos, sem abreviações
- Um use case por arquivo
- Testes antes da implementação (TDD)
- `ConfirmationDialog` obrigatório em ações destrutivas
- Saldo nunca ambíguo — usar LoadingSkeleton enquanto carrega

## Estrutura de pastas

```
lib/
├── core/       # utils, errors, logging, di, constants
├── domain/     # entities, value_objects, repositories (interfaces)
├── application/ # use cases
├── data/       # database, repositories (impl), datasources, models
└── presentation/ # theme, router, features, shared widgets
```

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
