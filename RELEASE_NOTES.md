# Release Notes — Paguei? v1.0.0

**Data de lançamento**: 21 de abril de 2026  
**Plataformas**: Android (API 26+) · iOS (17+)  
**Pacote**: `br.com.paguei`

---

## O que é o Paguei?

Paguei? é um gerenciador financeiro pessoal 100% offline, feito para o mercado brasileiro. Controle contas, boletos, dívidas, fundos de reserva, transações e receba lembretes — sem nenhum dado enviado para servidores.

---

## Funcionalidades do lançamento

### 💳 Contas e Carteiras
- Crie, edite e desative contas bancárias e carteiras digitais
- Saldo inicial configurável com nome, cor e ícone personalizados
- Visualização do saldo consolidado no dashboard

### 💰 Transações
- Registre receitas e despesas com categorias
- Filtro mensal e busca por descrição
- Exportação CSV com encoding UTF-8 BOM (compatível com Excel)
- Transferências entre contas

### 📄 Boletos
- Escaneie código de barras via câmera (mobile_scanner)
- Reconhecimento OCR de boletos em imagem, PDF e TXT
- Revisão pré-preenchida antes de salvar
- Lembretes automáticos de vencimento
- Copie a linha digitável com um toque

### 🏦 Fundos e Reservas
- Crie fundos com meta de valor e acompanhe o progresso
- Aporte e retiradas com histórico
- Visualização no painel de Resumo

### 💳 Dívidas
- Registre dívidas com credor, valor total e parcelas
- Registre pagamentos e acompanhe o saldo restante
- Status automático: ativa → quitada ao atingir 100%

### 📊 Resumo Financeiro
- Receitas e despesas do mês atual
- Top 3 fundos com barra de progresso
- Dívidas ativas em aberto
- Acesso rápido a gerenciamento completo

### ⚙️ Ajustes
- Backup local com compartilhamento externo
- Restauração de backup
- Exportação CSV completa (transações, boletos, dívidas)
- Preferências de notificação
- Gerenciamento de contas, fundos e dívidas via ajustes

### 🔔 Notificações
- Lembretes de vencimento de boletos (configuráveis)
- Notificações de metas de fundo atingidas

### 🔒 Privacidade
- Armazenamento 100% local (SQLite via Drift)
- Nenhum dado enviado para servidores externos
- Consentimento de coleta de dados anônimos (LGPD)
- Opção de opt-out a qualquer momento

---

## Stack Técnica

| Camada | Tecnologia |
|--------|-----------|
| Framework | Flutter 3.27+ / Dart 3.5+ |
| Estado | Riverpod 3.x |
| Banco de dados | Drift 2.x (SQLite) |
| Navegação | GoRouter 14 |
| OCR | Google ML Kit Text Recognition |
| Scanner | mobile_scanner 7.x |
| PDF | Syncfusion Flutter PDF (Community License) |
| Notificações | flutter_local_notifications |
| Gráficos | fl_chart |
| Segurança | flutter_secure_storage |

---

## Pré-requisitos para Build

```bash
# 1. Instalar dependências
flutter pub get

# 2. Gerar código (Drift DAOs + Freezed models)
dart run build_runner build --delete-conflicting-outputs

# 3. Verificar análise
flutter analyze

# 4. Executar testes
flutter test

# 5. Build release Android
flutter build apk --release --target lib/main.dart
flutter build appbundle --release --target lib/main.dart

# 6. Build release iOS
flutter build ios --release --target lib/main.dart
```

---

## Arquitetura

Clean Architecture em 5 camadas:

```
lib/
├── core/         # Utils, errors, logging, DI, constants
├── domain/       # Entities, value objects, repository interfaces
├── application/  # Use cases (um por arquivo)
├── data/         # Drift DAOs, repository implementations, models
└── presentation/ # Riverpod providers, screens, widgets, router
```

---

## Limitações conhecidas (v1.0.0)

- Tela de detalhe de boleto individual não implementada (navega para lista)
- Assinaturas recorrentes (US8) não incluídas nesta versão
- Painel de resumo financeiro avançado (US9) planejado para v1.1
- Exportação CSV de boletos e dívidas planejada para v1.1
- Sincronização em nuvem não planejada (app offline-first por design)

---

## Changelog

### v1.0.0 (2026-04-21)
- Lançamento inicial
- Todas as funcionalidades de Fase 1 (Fundação) e Fase 2 (Finanças Core) completas
- Fase 3 (Scanner & OCR) completa
- Fase 4 (Notificações, Backup, Analytics) completa
- Telas: Dashboard, Boletos, Transações, Resumo, Ajustes, Contas, Fundos, Dívidas
- Router com 5 abas + rotas full-screen completas

---

*Desenvolvido com ❤️ para controle financeiro pessoal em português brasileiro.*
