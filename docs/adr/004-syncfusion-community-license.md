# ADR-004: syncfusion_flutter_pdf com Licença Community

**Status**: Aceito
**Data**: 2026-04-19
**Decisores**: Equipe Paguei?

---

## Contexto

Para o módulo de leitura de boletos (Fase 3), precisamos extrair texto programaticamente de arquivos PDF. Isso é diferente de renderizar PDFs — precisamos do texto extraído para aplicar heurísticas de parsing de boleto.

---

## Decisão

Usar **syncfusion_flutter_pdf ^33.1.49** com **licença community gratuita**.

---

## Justificativa

Alternativas avaliadas:
- **pdfx**: Pacote de renderização, não extrai texto como string programável.
- **native_pdf_renderer**: Idem — foca em renderização de páginas como imagens.
- **pdf** (dint/dart_pdf): Focado em criação de PDFs, não extração.
- **syncfusion_flutter_pdf**: Única biblioteca Dart com API de extração de texto (`PdfTextExtractor`).

### Condições da licença community

A licença community da Syncfusion é **gratuita** para:
- Faturamento anual abaixo de USD $1 milhão
- Menos de 5 desenvolvedores no projeto

**Ação obrigatória antes do release**: Registrar chave em https://www.syncfusion.com/products/communitylicense e adicionar ao `main.dart`:
```dart
SyncfusionLicense.registerLicense('SUA_CHAVE_AQUI');
```

A chave deve ser armazenada de forma segura (variável de ambiente no CI, não no código).

---

## Consequências

- `SyncfusionLicense.registerLicense()` DEVE ser chamado antes de `runApp()`.
- A chave de licença NUNCA deve ser commitada no repositório.
- Checklist de release inclui verificação de licença registrada.
- Se o projeto ultrapassar os limites da community, migrar para licença comercial.
