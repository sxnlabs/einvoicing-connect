# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Pennylane customer resolution — resolve customer before import via `external_reference`, creation and find-or-create helpers to prevent duplicate customers on repeated invoices

## [0.3.0] - 2026-08-07

### Added
- `Connect::FR::Pennylane::Client#customer_by_reference`, `#create_company_customer`,
  `#create_individual_customer` and `#find_or_create_customer` — resolving the
  customer before the import, keyed on the caller's own `external_reference`.

  Pennylane does not match a customer from the imported document. A Factur-X
  submitted without `invoice_options[:customer_id]` lands as `"incomplete"`
  with `customer: nil` whatever SIRET or VAT number it carries — verified
  against the real API, before and after the identifier scheme was corrected
  in `einvoicing` 0.9.2, and the outcome is the same. Resolving through a
  stable reference rather than a name keeps a second invoice for the same
  customer from creating a second customer.

## [0.2.0] - 2026-08-03

### Added
- `Connect::FR::Pennylane` — Pennylane connector: Factur-X e-invoice import, API key and OAuth2 credentials, invoice status lookup, sandbox environment
- `Connect::FR::Directory` — consultation of the central e-invoicing directory (the PPF directory) to resolve a recipient's reception platform and routing code from a SIREN/SIRET. Preview: endpoint/response shape configurable pending the final DGFiP/AIFE API specification.
- `cpro-account` header support for Chorus Pro API (technical account)
- README and MIT LICENSE bundled with the gem

### Changed
- Connectors scoped by country namespace: `Einvoicing::PPF::*` and `Einvoicing::FR::SiretLookup` moved to `Einvoicing::Connect::FR::*` (breaking change for 0.1.0 users)
- Codebase aligned on `rubocop-rails-omakase` standards

### Fixed
- `Connect::FR::Pennylane::Adapter` was shipped but never required from the gem entry point, so the constant was missing at runtime

## [0.1.0] - 2026-03-16

### Added
- `Einvoicing::PPF` — PPF/Chorus Pro client (OAuth2, invoice submission)
- `Einvoicing::FR::SiretLookup` — SIRET lookup via French government API
- Locale strings extracted into `config/locales/*.yml` (English + French)
