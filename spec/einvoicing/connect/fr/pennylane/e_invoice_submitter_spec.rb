# frozen_string_literal: true

require "spec_helper"

RSpec.describe Einvoicing::Connect::FR::Pennylane::EInvoiceSubmitter do
  let(:creds)      { Einvoicing::Connect::FR::Pennylane::Credentials.api_key("test_api_key") }
  let(:submitter)  { described_class.new(credentials: creds) }
  let(:pdf_bytes)  { "%PDF-1.4 fake pdf".b }
  let(:xml_string) { "<CrossIndustryInvoice/>" }
  let(:facturx_pdf) { "%PDF-1.4 embedded".b }

  let(:invoice) do
    Einvoicing::Invoice.new(
      invoice_number: "INV-2024-001",
      issue_date:     Date.new(2024, 1, 15),
      seller:         Einvoicing::Party.new(name: "Acme SAS", siret: "35600000000048"),
      buyer:          Einvoicing::Party.new(name: "Client SA", siret: "55203253400017"),
      lines: [
        Einvoicing::LineItem.new(description: "Consulting", quantity: 1,
                                 unit_price: 100.0, vat_rate: 0.20)
      ]
    )
  end

  let(:client_double) { instance_double(Einvoicing::Connect::FR::Pennylane::Client) }

  before do
    allow(Einvoicing::Formats::CII).to receive(:generate).with(invoice).and_return(xml_string)
    allow(Einvoicing::Formats::FacturX).to receive(:embed).with(pdf_bytes, xml_string).and_return(facturx_pdf)
    allow(Einvoicing::Connect::FR::Pennylane::Client).to receive(:new).and_return(client_double)
    allow(client_double).to receive(:submit_einvoice).and_return({ "id" => 42 })
  end

  describe "#submit" do
    it "generates CII XML from the invoice" do
      submitter.submit(invoice, pdf: pdf_bytes)
      expect(Einvoicing::Formats::CII).to have_received(:generate).with(invoice)
    end

    it "embeds the XML into the PDF to produce a Factur-X PDF" do
      submitter.submit(invoice, pdf: pdf_bytes)
      expect(Einvoicing::Formats::FacturX).to have_received(:embed).with(pdf_bytes, xml_string)
    end

    it "submits the Factur-X PDF via the client" do
      submitter.submit(invoice, pdf: pdf_bytes)
      expect(client_double).to have_received(:submit_einvoice)
        .with(facturx_pdf, invoice_options: nil)
    end

    it "returns the client response" do
      result = submitter.submit(invoice, pdf: pdf_bytes)
      expect(result).to eq({ "id" => 42 })
    end

    context "with invoice_options" do
      let(:opts) { { customer: { name: "Override" } } }

      it "passes invoice_options through to the client" do
        submitter.submit(invoice, pdf: pdf_bytes, invoice_options: opts)
        expect(client_double).to have_received(:submit_einvoice)
          .with(facturx_pdf, invoice_options: opts)
      end
    end
  end

  describe "credential forwarding" do
    it "passes ApiKey credentials to the client" do
      described_class.new(credentials: creds)
      expect(Einvoicing::Connect::FR::Pennylane::Client).to have_received(:new)
        .with(credentials: creds, sandbox: false)
    end

    it "passes OAuth credentials to the client" do
      oauth_creds = Einvoicing::Connect::FR::Pennylane::Credentials.oauth(
        access_token:  "tok",
        refresh_token: "ref",
        client_id:     "cid",
        client_secret: "sec"
      )
      described_class.new(credentials: oauth_creds)
      expect(Einvoicing::Connect::FR::Pennylane::Client).to have_received(:new)
        .with(credentials: oauth_creds, sandbox: false)
    end

    it "forwards sandbox: true to the client" do
      described_class.new(credentials: creds, sandbox: true)
      expect(Einvoicing::Connect::FR::Pennylane::Client).to have_received(:new)
        .with(credentials: creds, sandbox: true)
    end
  end
end
