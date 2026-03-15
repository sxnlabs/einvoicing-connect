# frozen_string_literal: true

require "spec_helper"

RSpec.describe Einvoicing::Connect::FR::Pennylane::Adapter do
  subject(:payload) { described_class.new(invoice).to_payload }

  let(:buyer) do
    Einvoicing::Party.new(
      name:         "Client SA",
      siret:        "55203253400017",
      street:       "1 rue de la Paix",
      city:         "Paris",
      postal_code:  "75001",
      country_code: "FR"
    )
  end

  let(:seller) do
    Einvoicing::Party.new(name: "Acme SAS", siret: "35600000000048")
  end

  let(:line) do
    Einvoicing::LineItem.new(
      description: "Software consulting",
      quantity:    5,
      unit_price:  200.00,
      vat_rate:    0.20
    )
  end

  let(:invoice) do
    Einvoicing::Invoice.new(
      invoice_number: "INV-2024-001",
      issue_date:     Date.new(2024, 1, 15),
      due_date:       Date.new(2024, 2, 15),
      seller:         seller,
      buyer:          buyer,
      lines:          [ line ]
    )
  end


  describe "#to_payload" do
    let(:ci) { payload[:customer_invoice] }

    it "wraps the invoice under customer_invoice key" do
      expect(payload).to have_key(:customer_invoice)
    end

    it "maps issue_date to date as ISO-8601" do
      expect(ci[:date]).to eq("2024-01-15")
    end

    it "maps due_date to deadline as ISO-8601" do
      expect(ci[:deadline]).to eq("2024-02-15")
    end

    it "maps invoice_number" do
      expect(ci[:invoice_number]).to eq("INV-2024-001")
    end

    it "sets currency to EUR by default" do
      expect(ci[:currency]).to eq("EUR")
    end

    it "includes line_items_attributes" do
      expect(ci[:line_items_attributes]).to be_an(Array)
      expect(ci[:line_items_attributes].length).to eq(1)
    end

    it "includes customer_attributes" do
      expect(ci[:customer_attributes]).to be_a(Hash)
    end

    context "when due_date is nil" do
      let(:invoice) do
        Einvoicing::Invoice.new(
          invoice_number: "INV-2024-002",
          issue_date:     Date.new(2024, 1, 15),
          seller:         seller,
          buyer:          buyer,
          lines:          [ line ]
        )
      end

      it "sets deadline to nil" do
        expect(ci[:deadline]).to be_nil
      end
    end
  end

  describe "line items" do
    subject(:line_item) { payload[:customer_invoice][:line_items_attributes].first }

    it "maps description to label" do
      expect(line_item[:label]).to eq("Software consulting")
    end

    it "maps quantity" do
      expect(line_item[:quantity]).to eq(5)
    end

    it "maps unit_price" do
      expect(line_item[:unit_price]).to eq(200.00)
    end

    it "converts vat_rate to percentage string" do
      expect(line_item[:vat_rate]).to eq("20.0")
    end
  end

  describe "customer attributes" do
    subject(:customer) { payload[:customer_invoice][:customer_attributes] }

    it "maps buyer name" do
      expect(customer[:name]).to eq("Client SA")
    end

    it "maps siret to reg_no" do
      expect(customer[:reg_no]).to eq("55203253400017")
    end

    it "maps street to address" do
      expect(customer[:address]).to eq("1 rue de la Paix")
    end

    it "maps city" do
      expect(customer[:city]).to eq("Paris")
    end

    it "maps postal_code" do
      expect(customer[:postal_code]).to eq("75001")
    end

    it "maps country_code to country_alpha2" do
      expect(customer[:country_alpha2]).to eq("FR")
    end

    context "when buyer has only siren (no siret)" do
      let(:buyer) { Einvoicing::Party.new(name: "Client SA", siren: "552032534") }

      it "falls back to siren for reg_no" do
        expect(customer[:reg_no]).to eq("552032534")
      end
    end

    context "when buyer has no country_code" do
      let(:buyer) do
        Einvoicing::Party.new(name: "Client SA", siret: "55203253400017",
                              country_code: nil)
      end

      it "defaults country_alpha2 to FR" do
        # Party sets country_code: "FR" by default, so override via with
        buyer_no_country = buyer.with(country_code: nil)
        invoice_no_country = Einvoicing::Invoice.new(
          invoice_number: "INV-X",
          issue_date:     Date.new(2024, 1, 15),
          seller:         seller,
          buyer:          buyer_no_country,
          lines:          [ line ]
        )
        result = described_class.new(invoice_no_country).to_payload
        expect(result[:customer_invoice][:customer_attributes][:country_alpha2]).to eq("FR")
      end
    end
  end
end
