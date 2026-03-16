# einvoicing-connect

Platform connectors for the [einvoicing](https://www.sxnlabs.com/en/gems/einvoicing/) gem — Pennylane, PPF/Chorus Pro, and SIRET lookup for French e-invoicing.

→ **[Full documentation and guides](https://www.sxnlabs.com/en/gems/einvoicing/)**

## Installation

```ruby
gem "einvoicing-connect"
```

`hexapdf` is required for Factur-X PDF generation (Pennylane connector):

```ruby
gem "hexapdf"
```

## Connectors

### Pennylane (`Connect::FR::Pennylane`)

Submits invoices to [Pennylane](https://www.pennylane.com/) via the Factur-X e-invoice import API. The gem generates a standards-compliant CII XML document, embeds it into your PDF (producing a Factur-X PDF/A-3), and uploads it to Pennylane.

#### Authentication

**Companies and Firms** use a personal access token generated in Pennylane account settings:

```ruby
creds = Einvoicing::Connect::FR::Pennylane::Credentials.api_key("tok_xxx")
```

**Integration Partners** use OAuth2 with an access token + refresh token obtained via the authorization code flow:

```ruby
creds = Einvoicing::Connect::FR::Pennylane::Credentials.oauth(
  access_token:  "...",
  refresh_token: "...",
  client_id:     "...",
  client_secret: "...",
  expires_at:    Time.now + 3600  # optional
)
```

OAuth credentials are mutable — when an expired token is refreshed automatically, `creds.access_token`, `creds.refresh_token`, and `creds.expires_at` are updated in place so you can persist the new values.

#### Submitting an e-invoice

```ruby
require "hexapdf"

creds     = Einvoicing::Connect::FR::Pennylane::Credentials.api_key(ENV["PENNYLANE_API_KEY"])
submitter = Einvoicing::Connect::FR::Pennylane::EInvoiceSubmitter.new(credentials: creds)

invoice = Einvoicing::Invoice.new(
  invoice_number: "INV-2025-001",
  issue_date:     Date.today,
  due_date:       Date.today + 30,
  currency:       "EUR",
  seller:         Einvoicing::Party.new(name: "Acme SAS", siret: "35600000000048"),
  buyer:          Einvoicing::Party.new(
    name:        "Client SA",
    siret:       "55203253400017",
    street:      "1 rue de la Paix",
    city:        "Paris",
    postal_code: "75001"
  ),
  lines: [
    Einvoicing::LineItem.new(description: "Consulting", quantity: 5,
                             unit_price: 800.00, vat_rate: 0.20),
    Einvoicing::LineItem.new(description: "Licence ERP", quantity: 1,
                             unit_price: 1_200.00, vat_rate: 0.20),
    Einvoicing::LineItem.new(description: "Remise fidélité", quantity: 1,
                             unit_price: -200.00, vat_rate: 0.20),
  ]
)

# pdf is the binary content of a PDF (your human-readable invoice document)
pdf    = File.binread("invoice.pdf")
result = submitter.submit(invoice, pdf: pdf)

puts result["id"]  # Pennylane invoice ID
puts result["url"] # Pennylane invoice URL
```

#### Checking invoice status

```ruby
client = Einvoicing::Connect::FR::Pennylane::Client.new(credentials: creds)
status = client.invoice_status(result["id"])
puts status["status"]  # e.g. "processing", "sent"
```

#### Sandbox

Pennylane's sandbox environment uses a separate subdomain:

```ruby
submitter = Einvoicing::Connect::FR::Pennylane::EInvoiceSubmitter.new(
  credentials: creds,
  sandbox:     true
)
```

---

### PPF / Chorus Pro (`Connect::FR::PPF`)

Submits invoices to the French government's Chorus Pro platform (PPF) via the PISTE API.

#### Authentication

Chorus Pro uses OAuth2 client credentials:

```ruby
client = Einvoicing::Connect::FR::PPF::Client.new(
  client_id:     ENV["CPP_CLIENT_ID"],
  client_secret: ENV["CPP_CLIENT_SECRET"],
  sandbox:       true
)
```

For **technical account** (compte technique) submission, add the optional credentials:

```ruby
client = Einvoicing::Connect::FR::PPF::Client.new(
  client_id:          ENV["CPP_CLIENT_ID"],
  client_secret:      ENV["CPP_CLIENT_SECRET"],
  technical_login:    ENV["CPP_TECHNICAL_LOGIN"],
  technical_password: ENV["CPP_TECHNICAL_PASSWORD"]
)
```

#### Submitting an invoice

```ruby
submitter = Einvoicing::Connect::FR::PPF::Submitter.new(client)
result    = submitter.submit(invoice)

puts result["numeroFlux"]  # submission reference
puts result["statut"]      # e.g. "A_TRAITER"
```

Optional parameters:

```ruby
submitter.submit(invoice,
  code_service:      "SRV001",   # Chorus Pro service code
  engagement_number: "ENG-2025"  # buyer engagement/PO number
)
```

The submitter automatically resolves the buyer's `idStructureCPP` from their SIRET via `find_structure` before submitting.

---

### SIRET Lookup (`Connect::FR::SiretLookup`)

Enriches a `Party` with a SIRET from the French government company search API, given only a SIREN.

```ruby
buyer   = Einvoicing::Party.new(name: "Client SA", siren: "552032534")
enriched = Einvoicing::Connect::FR::SiretLookup.enrich!(buyer)
enriched.siret  # => "55203253400017"
```

Returns a new `Party` instance (non-destructive). Returns the original party unchanged if SIRET is already present or the lookup fails.

---

## Error handling

Each connector defines its own error hierarchy:

```
Pennylane::Error
├── Pennylane::AuthError       # invalid API key (401)
├── Pennylane::OAuthError      # token refresh failed
└── Pennylane::SubmissionError # other API errors (4xx/5xx)

PPF::Error
├── PPF::AuthenticationError   # OAuth token request failed
├── PPF::AuthorizationError    # 403 Forbidden
├── PPF::NotFoundError         # 404 Not Found
├── PPF::APIError              # other API errors
└── PPF::ValidationError       # e.g. buyer SIRET not found in Chorus Pro
```

## Re-recording integration test cassettes

Integration tests use VCR cassettes (committed to the repo, token scrubbed). To re-record against the real API:

```bash
PENNYLANE_API_KEY=your_token bundle exec rspec spec/integration/
```

## License

MIT
