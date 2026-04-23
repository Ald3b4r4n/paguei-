# Paguei?

Paguei? e um aplicativo Flutter de controle financeiro pessoal feito para a
realidade brasileira: boletos, PIX, contas bancarias, carteiras, dinheiro vivo,
receitas, despesas, dividas, fundos e lembretes em uma experiencia simples de
usar no dia a dia.

O foco do projeto e clareza financeira sem jargao de contabilidade. Em vez de
pedir "conta" de forma abstrata, o app trabalha com a ideia de onde esta o
dinheiro: Nubank, Caixa, Inter, carteira, poupanca ou dinheiro vivo.

## Status

- App Android em fase beta/install-ready.
- Persistencia local com SQLite via Drift.
- Scanner hibrido para QRCode PIX, codigo de barras de boleto, PDF e imagem.
- Suite automatizada cobrindo dominio, casos de uso, UI e regressoes criticas.

APK release local:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Principais Funcionalidades

### Inicio

- Saldo disponivel consolidado.
- Receitas e despesas do mes atual.
- Boletos pendentes, vencidos e proximos vencimentos.
- Visao simples para entender rapidamente a situacao financeira.

### Transacoes

- Cadastro de receitas, despesas e transferencias.
- Perguntas claras por tipo de movimento:
  - Receita: "Para onde entrou?"
  - Despesa: "De onde saiu?"
  - Transferencia: origem e destino.
- Filtro mensal e filtros por tipo.
- Regressoes cobrindo criacao de receita, despesa e transferencia.

### Locais do Dinheiro

- Cadastro de bancos, carteiras, poupancas e dinheiro vivo.
- Saldo inicial e saldo atual.
- Base para calcular saldo disponivel e movimentacoes.

### Boletos e PIX

- Scanner por camera com dois modos visuais:
  - QRCode PIX com moldura quadrada.
  - Codigo de barras com moldura horizontal.
- Importacao de PDF.
- Leitura de imagem.
- OCR como fallback quando nao existe dado estruturado.
- Revisao antes de salvar, com chips de origem e confianca por campo.
- Parser de linha digitavel e codigo de barras com valor e vencimento
  canonicos.
- Parser EMV/PIX com suporte a:
  - payload bruto;
  - valor, quando presente;
  - chave ou identificador;
  - recebedor;
  - cidade;
  - txid;
  - PIX dinamico via URL do PSP.

### Resumo

- Receitas do mes.
- Despesas do mes.
- Dividas ativas.
- Fundos e progresso de metas.

### Ajustes

- Backup local.
- Exportacao CSV.
- Preferencias de notificacao.
- Feedback por e-mail.
- Diagnosticos.

## Scanner: Ordem de Extracao

O pipeline de leitura segue uma ordem conservadora para evitar dados errados:

1. QRCode PIX detectado pela camera ou imagem.
2. Payload EMV PIX extraido e parseado.
3. PIX dinamico consultado quando o payload aponta para URL de PSP.
4. Codigo de barras ou linha digitavel validado.
5. PDF text/estrutura quando o arquivo permite extracao.
6. OCR apenas como fallback.

Essa ordem evita pegar valores aleatorios de faturas ou textos historicos quando
o boleto ja traz valor e vencimento no codigo validado.

## Stack

| Area | Tecnologia |
| --- | --- |
| App | Flutter / Dart |
| Estado | Riverpod |
| Navegacao | GoRouter |
| Banco local | Drift + SQLite |
| Scanner | mobile_scanner |
| OCR | Google ML Kit Text Recognition |
| PDF | Syncfusion Flutter PDF |
| Notificacoes | flutter_local_notifications |
| Graficos | fl_chart |
| Seguranca local | flutter_secure_storage, local_auth |
| Testes | flutter_test, mocktail, golden_toolkit |

## Arquitetura

O projeto segue uma organizacao inspirada em Clean Architecture:

```text
lib/
├── application/   # casos de uso e servicos de aplicacao
├── core/          # DI, constantes, logging, erros e utilitarios
├── data/          # Drift, datasources, models e repositories concretos
├── domain/        # entidades, value objects e contratos
└── presentation/  # telas, providers, widgets, tema e rotas
```

Regras praticas do projeto:

- Dominio nao depende de Flutter.
- Casos de uso ficam em `application/`.
- UI consome estado por Riverpod.
- Persistencia local fica isolada em `data/`.
- Testes acompanham mudancas relevantes de comportamento.

## Como Rodar

Pre-requisitos:

- Flutter 3.22 ou superior.
- Dart 3.4 ou superior.
- Android Studio ou Android SDK configurado.

Instalar dependencias:

```bash
flutter pub get
```

Gerar codigo:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Rodar o app:

```bash
flutter run --target lib/main.dart
```

## Qualidade

Analise estatica:

```bash
flutter analyze
```

Testes:

```bash
flutter test
```

Build Android release:

```bash
flutter build apk --release --target lib/main.dart
```

APK gerado:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Privacidade

O Paguei? foi desenhado como app offline-first. Os dados financeiros ficam no
armazenamento local do dispositivo. Recursos que abrem e-mail, compartilham
backup ou consultam um PIX dinamico so executam quando o usuario inicia o fluxo
correspondente.

## Documentacao Relacionada

- [Release Notes](RELEASE_NOTES.md)
- [Documentacao](docs/)
- [Specs](specs/)

## Licenca

Projeto privado em desenvolvimento. Definir a licenca antes de distribuicao
publica.
