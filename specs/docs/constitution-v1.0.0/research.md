# Pesquisa de Tecnologias: Paguei? — Fundação do Projeto

**Data**: 2026-04-19
**Branch**: `docs/constitution-v1.0.0`
**Escopo**: Decisões técnicas para toda a base do aplicativo Paguei?

---

## 1. Skills Recomendadas (antigravity-awesome-skills)

### Seleção Estratégica por Fase

| Skill | Repositório | Fase de Uso | Justificativa |
|---|---|---|---|
| `flutter-expert` | antigravity | 1–7 | Desenvolvimento Flutter/Dart com arquitetura avançada |
| `nerdzao-elite` | antigravity | 1–7 | Workflow completo: planejamento, arquitetura, TDD e UX |
| `tdd-workflow` | antigravity | 1–7 | Ciclo Red→Green→Refactor obrigatório pela Constituição |
| `mobile-design` | antigravity | 2, 5 | Design mobile-first, touch-first, responsivo |
| `product-design` | antigravity | 2–5 | Sistema visual de nível fintech, design tokens, UX flows |
| `ux-flow` | antigravity | 2–5 | Fluxos de tela com padrões hub-and-spoke e progressive disclosure |
| `kpi-dashboard-design` | antigravity | 2, 6 | Padrões de dashboards financeiros eficazes |
| `007` | antigravity | 1, 9 | Auditoria de segurança OWASP, modelagem STRIDE |
| `payment-integration` | antigravity | 3 | Integração com fluxos de pagamento e PIX |
| `nanobana2` / `imagen` | antigravity | 5 | Geração de assets de onboarding e ilustrações |
| `product-inventor` | antigravity | Pré-fase | Pensamento de produto, storytelling, psicologia cognitiva |
| `mobile-developer` | antigravity | 1–3 | Padrões de arquitetura offline-first e sync |
| `hig-components-system` | antigravity | 5 | Notificações e Live Activities no iOS |
| `documentation` | antigravity | Todas | Manutenção de docs, ADRs e CHANGELOG |

---

## 2. Gerenciamento de Estado

### Decisão: `flutter_riverpod ^3.3.1`

**Rationale**: Riverpod 3.x entrega segurança em tempo de compilação, providers async-first e
gerenciamento automático de ciclo de vida — sem a cerimônia event→state do BLoC.
Para uma equipe pequena construindo um app de finanças pessoais, a ergonomia do Riverpod
reduz o tempo de debugging e facilita a rastreabilidade de estado imutável.

**Alternativas descartadas**:
- **BLoC 9.x**: Excessivo para o contexto; produtivo apenas em equipes grandes com trilha
  de auditoria obrigatória por reguladores.
- **Provider**: Deprecado em favor do Riverpod pelo próprio criador (Remi Rousselet).
- **GetX**: Viola o Princípio II (Clean Architecture) ao misturar DI, routing e estado.

**Pacotes**:
```yaml
flutter_riverpod: ^3.3.1
riverpod_annotation: ^3.3.1
riverpod_generator: ^2.x.x  # code generation
```

---

## 3. Banco de Dados Local

### Decisão: `drift ^2.32.1`

**Rationale**: É a única escolha defensável para um app de finanças que exige integridade de
dados, evolução de schema com migrações versionadas, type-safety em tempo de compilação e
streams reativos para UI.

**Comparativo**:

| Critério | Drift | Isar | Hive | sqflite |
|---|---|---|---|---|
| Status | ✅ Ativo | ❌ Abandonado | ⚠ Estagnado | ✅ Ativo |
| Migrações tipadas | ✅ | Parcial | ❌ | Manual |
| Type-safety | ✅ Compilação | ✅ | ✅ | ❌ |
| Streams reativos | ✅ | ✅ | ✅ | ❌ |
| Backup/Export | ✅ Via SQL | Parcial | ❌ Nativo | ✅ Via SQL |
| Criptografia | ✅ SQLCipher | ✅ | Parcial | Plugin externo |

> **Isar está morto.** A issue #1689 do GitHub ("Isar is dead, long live Isar") confirma
> abandono pelo autor original. O core em Rust torna forks de comunidade inviáveis.

**Pacotes**:
```yaml
drift: ^2.32.1
sqlite3_flutter_libs: ^0.5.0

dev_dependencies:
  drift_dev: ^2.32.1
  build_runner: ^2.4.0
```

---

## 4. OCR e Leitura de Boletos

### Decisão: `google_mlkit_text_recognition ^0.15.1` + `mobile_scanner ^7.2.0`

**Estratégia de dois caminhos**:

| Fonte | Tecnologia | Motivo |
|---|---|---|
| Câmera ao vivo (barcode/QR) | `mobile_scanner` | Nativo CameraX + AVFoundation; suporte ITF, Code 128, QR |
| Imagem/PDF (extração de texto) | `google_mlkit_text_recognition` | On-device, < 50ms, sem chamada de rede |
| PDF (extração programática) | `syncfusion_flutter_pdf` | Única lib Dart que extrai texto de PDF sem renderizar |
| Câmera ao vivo (texto) | `camera` + ML Kit | Reconhecimento de texto em frames ao vivo |

**Por que não Tesseract**: 10–50x mais lento, requer assets de treinamento (~20MB), qualidade
inferior em texto impresso de baixo contraste (típico em boletos físicos).

**Por que mobile_scanner venceu**: `qr_code_scanner` e wrappers ZXing estão abandonados sem
manutenção. `mobile_scanner 7.x` usa os mesmos stacks nativos do app de câmera do sistema
operacional; 740k downloads semanais, 2.26k likes.

**Pacotes**:
```yaml
google_mlkit_text_recognition: ^0.15.1
mobile_scanner: ^7.2.0
camera: ^0.11.2
syncfusion_flutter_pdf: ^33.1.49  # licença community gratuita até $1M faturamento
```

---

## 5. Notificações

### Decisão: `flutter_local_notifications ^21.0.0`

**Rationale**: 7.29k likes, 1.61M downloads semanais, padrão consolidado do ecossistema
Flutter. Suporta Android full-screen intent (alertas de vencimento heads-up), iOS critical
alerts (com permissão da Apple) e scheduling de notificações recorrentes.

**awesome_notifications descartado**: Sub-1.0 (v0.11.0 após anos), API instável com breaking
changes que removeram streams e adicionaram callbacks estáticos globais — incompatível com
a disciplina de estado imutável do Princípio VIII.

**Alertas por e-mail**: Integração via Formspree ou API de e-mail transacional (Resend,
Mailersend) acionada por trigger CLI/backend bridge isolado na camada `data/`. O domínio
não conhece o canal de entrega.

**Pacotes**:
```yaml
flutter_local_notifications: ^21.0.0
timezone: ^0.9.0  # para notificações agendadas com fuso horário
```

---

## 6. Gráficos e Visualizações

### Decisão: `fl_chart ^1.2.0`

**Rationale**: MIT License sem restrições comerciais; Flutter Favorite implícito; 7.1k likes;
1.2M downloads semanais. Suporta todos os tipos necessários: linha (gastos ao longo do tempo),
barra (categorias), pizza (distribuição), scatter (projeções). Syncfusion Charts é superior
tecnicamente mas carrega obrigação de licença comercial após $1M.

**Limite de desempenho**: fl_chart degrada visivelmente acima de ~5.000 pontos de dados.
Benchmark obrigatório antes da v1.0 se histórico de transações ultrapassar 3 anos.

```yaml
fl_chart: ^1.2.0
```

---

## 7. Segurança e Privacidade

### Decisão: `flutter_secure_storage ^10.0.0` + criptografia do Drift

**Estratégia em camadas**:

| Dados | Armazenamento | Mecanismo |
|---|---|---|
| Tokens, chaves | `flutter_secure_storage` | Android Keystore + iOS Keychain |
| Banco de dados | Drift + SQLCipher | Criptografia AES-256 em repouso |
| Dados em memória | Estado Riverpod imutável | Sem referências mutáveis expostas |

**Biometria**: `local_auth ^3.0.1` (publicado pelo flutter.dev); usa Face ID, Touch ID e
impressão digital com fallback para PIN. Não há alternativa viável.

```yaml
flutter_secure_storage: ^10.0.0
local_auth: ^3.0.1
```

---

## 8. Animações e UX Premium

### Decisão: `flutter_animate ^4.5.2` + `lottie ^3.3.3`

**Estratégia complementar**:

| Caso de uso | Pacote | Motivo |
|---|---|---|
| Microinterações (counters, slides, shimmer) | `flutter_animate` | Flutter Favorite, API encadeada, puro Dart |
| Estados de sucesso/erro (pagamento confirmado) | `lottie` | Qualidade After Effects, 4.54k likes |
| Ilustrações interativas (onboarding) | `lottie` | Arquivos `.json` do LottieFiles |

**Rive descartado**: Requer designer com expertise específica em Rive; overkill para uma
equipe pequena sem animador dedicado.

```yaml
flutter_animate: ^4.5.2
lottie: ^3.3.3
```

---

## 9. Geração de Assets com IA

### Workflow de Asset Generation

**Ferramenta primária**: `nanobana2` skill (Gemini CLI) para geração iterativa de:
- Ilustrações de onboarding (SVG/PNG)
- Ícones de categoria (estilo flat, paleta da marca)
- Estados vazios (empty states)
- Banners do dashboard
- Assets da App Store (screenshots, feature graphic)

**Workflow proposto**:
```
1. Definir design tokens (cores, tipografia) → docs/design-system.md
2. Gerar prompt master por tipo de asset → .specify/prompts/assets/
3. Executar nanobana2 com prompt + paleta
4. Revisar e iterar (max 3 iterações por asset)
5. Exportar para assets/images/ com naming convention
6. Registrar no pubspec.yaml
```

**Naming convention**:
```
assets/
├── images/
│   ├── onboarding/    # onboarding_step_1.png, ...
│   ├── categories/    # cat_food.svg, cat_transport.svg, ...
│   ├── empty/         # empty_bills.svg, empty_transactions.svg
│   └── banners/       # dashboard_banner_default.png
├── animations/        # success_payment.json, loading_coins.json
└── icons/             # app_icon.png, notification_icon.png
```

---

## 10. Navegação

### Decisão: `go_router ^14.x`

**Rationale**: Solução oficial do Flutter team; deep linking nativo; compatible com Riverpod
via `GoRouterRefresh`; shell routes para bottom navigation com state preservation.

```yaml
go_router: ^14.0.0
```

---

## 11. Internacionalização e Formatação

### Decisão: `intl ^0.20.x` + `flutter_localizations`

Formatação pt-BR obrigatória pelo Princípio V:
- Moeda: `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`
- Data: `DateFormat('dd/MM/yyyy', 'pt_BR')`
- Número: `NumberFormat('#.##0,00', 'pt_BR')`

```yaml
intl: ^0.20.0
flutter_localizations:
  sdk: flutter
```

---

## 12. Stack Completa de Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Arquitetura & Estado
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^3.3.1

  # Banco de dados
  drift: ^2.32.1
  sqlite3_flutter_libs: ^0.5.0

  # Navegação
  go_router: ^14.0.0

  # OCR & Scanner
  google_mlkit_text_recognition: ^0.15.1
  mobile_scanner: ^7.2.0
  camera: ^0.11.2
  syncfusion_flutter_pdf: ^33.1.49

  # Notificações
  flutter_local_notifications: ^21.0.0
  timezone: ^0.9.0

  # Gráficos
  fl_chart: ^1.2.0

  # Segurança
  flutter_secure_storage: ^10.0.0
  local_auth: ^3.0.1

  # Animações
  flutter_animate: ^4.5.2
  lottie: ^3.3.3

  # Utilitários
  intl: ^0.20.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  path_provider: ^2.1.0
  share_plus: ^10.0.0       # compartilhar código de boleto
  url_launcher: ^6.3.0      # abrir app do banco
  file_picker: ^8.0.0       # upload de PDF/TXT
  permission_handler: ^11.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.32.1
  build_runner: ^2.4.0
  riverpod_generator: ^2.x.x
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  mocktail: ^1.0.0
  golden_toolkit: ^0.15.0
  flutter_lints: ^5.0.0
```

---

## Riscos Identificados

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Syncfusion licença expirar | Baixa | Alto | Manter email de registro; revisar em cada release |
| fl_chart lento com histórico longo | Média | Médio | Paginar queries no Drift; lazy loading |
| ML Kit OCR falhar em boletos de baixa qualidade | Alta | Médio | Fallback para entrada manual; UI de confirmação |
| mobile_scanner permissões negadas | Alta | Alto | UX de onboarding de permissões; fallback upload de imagem |
| Drift migração com erro em produção | Baixa | Crítico | Testes de migração obrigatórios; backup antes de migrar |
