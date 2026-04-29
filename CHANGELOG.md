# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-16

### Added
- `Connect::FR::PPF` — PPF/Chorus Pro client (OAuth2, invoice submission)
- `Connect::FR::SiretLookup` — SIRET lookup via French government API
- `Connect::FR::Pennylane` — Pennylane connector (e-invoice push + Factur-X import)
- `cpro-account` header support for Chorus Pro API (technical account)
- MIT LICENSE bundled with the gem

### Changed
- Codebase aligned on `rubocop-rails-omakase` standards
- Locale strings extracted into `config/locales/*.yml` (English + French)
- Connectors scoped by country namespace (`Connect::FR::*`)
