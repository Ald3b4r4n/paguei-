# Guia de Início Rápido: Paguei?

**Data**: 2026-04-19
**Flutter SDK**: ≥ 3.22.0 | **Dart**: ≥ 3.4.0

---

## Pré-requisitos

```bash
# Verificar instalação do Flutter
flutter --version   # deve ser ≥ 3.22.0

# Ferramentas necessárias
# - Android Studio ou Xcode (para builds nativas)
# - VS Code com extensão Flutter ou IntelliJ IDEA
# - Java 17+ (para build Android)
```

---

## Configuração Inicial

```bash
# 1. Clonar o repositório
git clone <repo-url>
cd paguei

# 2. Instalar dependências
flutter pub get

# 3. Gerar código (Drift + Riverpod + Freezed)
dart run build_runner build --delete-conflicting-outputs

# 4. Verificar configuração
flutter analyze
flutter test
```

---

## Executar em Desenvolvimento

```bash
# Android (emulador ou dispositivo)
flutter run --flavor development

# iOS (simulator)
flutter run --flavor development --target lib/main_development.dart

# Modo debug padrão
flutter run
```

---

## Executar Testes

```bash
# Todos os testes
flutter test

# Apenas testes de domínio
flutter test test/domain/

# Apenas testes de aplicação
flutter test test/application/

# Testes com cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Testes golden
flutter test --update-goldens  # atualizar goldens
flutter test test/golden/       # verificar goldens

# Testes de integração (dispositivo conectado necessário)
flutter test integration_test/
```

---

## Validação de Qualidade

```bash
# Análise estática
flutter analyze

# Formatação
dart format . --set-exit-if-changed

# Lint
flutter pub run custom_lint

# Cobertura mínima (CI gate)
# Domain ≥ 95%, Application ≥ 90%, Data ≥ 80%
```

---

## Build de Produção

```bash
# Android APK
flutter build apk --flavor production

# Android App Bundle (Google Play)
flutter build appbundle --flavor production

# iOS IPA
flutter build ipa --flavor production
```

---

## Estrutura de Ambiente

```
lib/
├── main.dart              # produção
├── main_development.dart  # desenvolvimento
└── main_staging.dart      # homologação
```

---

## Licença Syncfusion

Antes do primeiro build de produção, registrar chave de licença gratuita:

```dart
// Em main.dart, antes de runApp()
SyncfusionLicense.registerLicense('SUA_CHAVE_AQUI');
```

Registrar em: https://www.syncfusion.com/products/communitylicense
