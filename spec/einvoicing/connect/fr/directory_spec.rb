# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe Einvoicing::Connect::FR::Directory do
  let(:api_url) { described_class.api_url }

  let(:success_body) do
    {
      "destinataire" => {
        "identifiant"   => "55203253400017",
        "maille"        => "SIRET",
        "codeRoutage"   => "PDP000123",
        "idPlateforme"  => "0000000000018",
        "nomPlateforme" => "Acme PDP",
        "statut"        => "active"
      }
    }.to_json
  end

  let(:no_routing_body) do
    { "destinataire" => { "identifiant" => "55203253400017", "codeRoutage" => nil } }.to_json
  end

  describe ".lookup" do
    it "returns routing info for a valid SIRET" do
      stub_request(:get, api_url).with(query: hash_including("identifiant" => "55203253400017"))
        .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

      result = described_class.lookup("55203253400017")
      expect(result[:routing_code]).to eq("PDP000123")
      expect(result[:platform_name]).to eq("Acme PDP")
      expect(result[:level]).to eq("SIRET")
    end

    it "accepts a 9-digit SIREN" do
      stub_request(:get, api_url).with(query: hash_including("identifiant" => "552032534"))
        .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

      expect(described_class.lookup("552032534")).to be_a(Hash)
    end

    it "strips whitespace from the identifier" do
      stub_request(:get, api_url).with(query: hash_including("identifiant" => "55203253400017"))
        .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

      expect(described_class.lookup("552 032 534 00017")).to be_a(Hash)
    end

    it "returns nil when no routing code is present" do
      stub_request(:get, api_url).with(query: hash_including("identifiant" => "55203253400017"))
        .to_return(status: 200, body: no_routing_body, headers: { "Content-Type" => "application/json" })

      expect(described_class.lookup("55203253400017")).to be_nil
    end

    it "returns nil for a wrong format" do
      expect(described_class.lookup("not-an-id")).to be_nil
    end

    it "returns nil for nil input" do
      expect(described_class.lookup(nil)).to be_nil
    end

    it "returns nil on HTTP error" do
      stub_request(:get, api_url).with(query: hash_including("identifiant" => "55203253400017"))
        .to_return(status: 500)
      expect(described_class.lookup("55203253400017")).to be_nil
    end
  end

  describe ".route" do
    it "looks up using the party SIRET" do
      stub_request(:get, api_url).with(query: hash_including("identifiant" => "55203253400017"))
        .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

      party  = Einvoicing::Party.new(name: "Client SA", siret: "55203253400017")
      result = described_class.route(party)
      expect(result[:routing_code]).to eq("PDP000123")
    end

    it "falls back to the party SIREN when SIRET is blank" do
      stub_request(:get, api_url).with(query: hash_including("identifiant" => "552032534"))
        .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

      party = Einvoicing::Party.new(name: "Client SA", siren: "552032534")
      expect(described_class.route(party)).to be_a(Hash)
    end

    it "returns nil when the party has no identifier" do
      party = Einvoicing::Party.new(name: "Client SA")
      expect(described_class.route(party)).to be_nil
    end
  end
end
