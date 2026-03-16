# frozen_string_literal: true

require "spec_helper"
require "hexapdf"

# Integration tests against the Pennylane API using VCR cassettes.
#
# Cassettes are committed to the repository with the API key scrubbed.
# To re-record against the real API:
#
#   PENNYLANE_API_KEY=your_token bundle exec rspec spec/integration/
#
# Without the env var the cassettes are replayed as-is (suitable for CI).
RSpec.describe Einvoicing::Connect::FR::Pennylane::EInvoiceSubmitter, :integration do
  let(:api_key) { ENV.fetch("PENNYLANE_API_KEY", "<PENNYLANE_API_KEY>") }
  let(:creds)   { Einvoicing::Connect::FR::Pennylane::Credentials.api_key(api_key) }

  # Use sandbox: false because the test account uses the production URL.
  let(:submitter) { described_class.new(credentials: creds, sandbox: false) }

  let(:seller) do
    Einvoicing::Party.new(
      name:         "Acme Conseil SAS",
      siret:        "35600000000048",
      street:       "12 rue du Faubourg Saint-Honore",
      city:         "Paris",
      postal_code:  "75008",
      country_code: "FR"
    )
  end

  let(:buyer) do
    Einvoicing::Party.new(
      name:         "Dupont et Associes SARL",
      siret:        "55203253400017",
      street:       "3 allee des Roses",
      city:         "Lyon",
      postal_code:  "69003",
      country_code: "FR"
    )
  end

  let(:invoice) do
    Einvoicing::Invoice.new(
      invoice_number:     "ACME-INTEG-001",
      issue_date:         Date.new(2025, 3, 16),
      due_date:           Date.new(2025, 4, 15),
      currency:           "EUR",
      seller:             seller,
      buyer:              buyer,
      payment_reference:  "ACME-INTEG-001",
      payment_means_code: 30,
      iban:               "FR7630006000011234567890189",
      bic:                "BNPAFRPPXXX",
      lines: [
        Einvoicing::LineItem.new(
          description: "Audit conseil strategique (5j x 800 EUR)",
          quantity:    5,
          unit_price:  800.00,
          vat_rate:    0.20
        ),
        Einvoicing::LineItem.new(
          description: "Licence logiciel ERP - abonnement annuel",
          quantity:    2,
          unit_price:  1_200.00,
          vat_rate:    0.20
        ),
        Einvoicing::LineItem.new(
          description: "Formation utilisateurs",
          quantity:    1,
          unit_price:  450.00,
          vat_rate:    0.10
        ),
        Einvoicing::LineItem.new(
          description: "Remise commerciale fidelite (5%)",
          quantity:    1,
          unit_price:  -400.00,
          vat_rate:    0.20
        ),
        Einvoicing::LineItem.new(
          description: "Remboursement frais de deplacement",
          quantity:    1,
          unit_price:  180.00,
          vat_rate:    0.00
        )
      ]
    )
  end

  let(:pdf) do
    doc    = HexaPDF::Document.new
    page   = doc.pages.add
    canvas = page.canvas
    canvas.font("Helvetica", size: 12)
    canvas.text("FACTURE #{invoice.invoice_number}", at: [ 50, 780 ])
    out = StringIO.new("".b)
    doc.write(out)
    out.string
  end

  # When PENNYLANE_API_KEY is set: record: :new_episodes (live call + save cassette)
  # Otherwise:                      record: :none (replay only, CI-safe)
  let(:vcr_record_mode) { ENV["PENNYLANE_API_KEY"] ? :new_episodes : :none }

  describe "#submit" do
    it "submits a Factur-X e-invoice and returns an invoice id",
       vcr: { cassette_name: "pennylane/submit_einvoice", record: :new_episodes } do
      result = submitter.submit(invoice, pdf: pdf)

      expect(result["id"]).to be_an(Integer)
      expect(result).to have_key("url")
    end
  end
end
