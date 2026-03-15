# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe Einvoicing::Connect::FR::Pennylane::Client do
  let(:api_key) { "test_api_key" }
  let(:client)  { described_class.new(api_key: api_key) }

  let(:invoice) do
    Einvoicing::Invoice.new(
      invoice_number: "INV-2024-001",
      issue_date:     Date.new(2024, 1, 15),
      due_date:       Date.new(2024, 2, 15),
      seller:         Einvoicing::Party.new(name: "Acme SAS", siret: "35600000000048"),
      buyer:          Einvoicing::Party.new(
        name:         "Client SA",
        siret:        "55203253400017",
        street:       "1 rue de la Paix",
        city:         "Paris",
        postal_code:  "75001"
      ),
      lines: [
        Einvoicing::LineItem.new(
          description: "Software consulting",
          quantity:    5,
          unit_price:  200.00,
          vat_rate:    0.20
        )
      ]
    )
  end

  describe "#submit_invoice" do
    context "when submission succeeds" do
      before do
        stub_request(:post, "https://app.pennylane.com/api/external/v2/customer_invoices")
          .with(
            headers: {
              "Authorization" => "Bearer test_api_key",
              "Content-Type"  => "application/json"
            }
          )
          .to_return(
            status:  201,
            body:    { id: 42, status: "draft", url: "https://app.pennylane.com/invoices/42" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns the parsed response body" do
        result = client.submit_invoice(invoice)
        expect(result["id"]).to eq(42)
        expect(result["status"]).to eq("draft")
      end

      it "POSTs to the correct endpoint" do
        client.submit_invoice(invoice)
        expect(WebMock).to have_requested(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices").once
      end
    end

    context "when the API returns 401" do
      before do
        stub_request(:post, "https://app.pennylane.com/api/external/v2/customer_invoices")
          .to_return(status: 401, body: { error: "unauthorized" }.to_json)
      end

      it "raises AuthError" do
        expect { client.submit_invoice(invoice) }
          .to raise_error(Einvoicing::Connect::FR::Pennylane::AuthError, /authentication failed/)
      end
    end

    context "when the API returns 422" do
      before do
        stub_request(:post, "https://app.pennylane.com/api/external/v2/customer_invoices")
          .to_return(status: 422, body: { errors: [ "invoice_number is blank" ] }.to_json)
      end

      it "raises SubmissionError" do
        expect { client.submit_invoice(invoice) }
          .to raise_error(Einvoicing::Connect::FR::Pennylane::SubmissionError, /submission failed/)
      end

      it "includes status code in the error message" do
        expect { client.submit_invoice(invoice) }
          .to raise_error(Einvoicing::Connect::FR::Pennylane::SubmissionError, /422/)
      end
    end
  end

  describe "#invoice_status" do
    context "when the request succeeds" do
      before do
        stub_request(:get, "https://app.pennylane.com/api/external/v2/customer_invoices/42")
          .with(headers: { "Authorization" => "Bearer test_api_key" })
          .to_return(
            status:  200,
            body:    { id: 42, status: "sent" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns the parsed response" do
        result = client.invoice_status(42)
        expect(result["status"]).to eq("sent")
      end
    end
  end

  describe "sandbox mode" do
    let(:sandbox_client) { described_class.new(api_key: api_key, sandbox: true) }

    before do
      stub_request(:post, "https://sandbox.pennylane.com/api/external/v2/customer_invoices")
        .to_return(
          status:  201,
          body:    { id: 1 }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "uses the sandbox URL" do
      sandbox_client.submit_invoice(invoice)
      expect(WebMock).to have_requested(:post,
        "https://sandbox.pennylane.com/api/external/v2/customer_invoices").once
    end
  end
end
