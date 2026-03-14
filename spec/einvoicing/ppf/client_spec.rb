# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe Einvoicing::PPF::Client do
  let(:client_id)     { "test_client_id" }
  let(:client_secret) { "test_client_secret" }
  let(:client)        { described_class.new(client_id: client_id, client_secret: client_secret, sandbox: true) }

  let(:token_response) do
    { access_token: "tok_abc123", expires_in: 3600, token_type: "Bearer" }.to_json
  end

  def stub_token
    stub_request(:post, "https://sandbox-oauth.piste.gouv.fr/api/oauth/token")
      .to_return(status: 200, body: token_response, headers: { "Content-Type" => "application/json" })
  end

  describe "#access_token" do
    it "fetches a token on first call" do
      stub_token
      expect(client.access_token).to eq("tok_abc123")
    end

    it "reuses the cached token before expiry" do
      stub_token
      client.access_token # first call
      client.access_token # second call — must not make another HTTP request
      expect(WebMock).to have_requested(:post, "https://sandbox-oauth.piste.gouv.fr/api/oauth/token").once
    end

    it "refreshes the token when expired" do
      stub_token
      client.access_token
      # Force expiry
      client.instance_variable_set(:@token_expires_at, Time.now - 1)
      client.access_token
      expect(WebMock).to have_requested(:post, "https://sandbox-oauth.piste.gouv.fr/api/oauth/token").twice
    end

    it "raises AuthenticationError when OAuth request fails" do
      stub_request(:post, "https://sandbox-oauth.piste.gouv.fr/api/oauth/token")
        .to_return(status: 400, body: "Bad Request")
      expect { client.access_token }.to raise_error(Einvoicing::PPF::AuthenticationError, /OAuth token request failed/)
    end
  end

  describe "#find_structure" do
    before { stub_token }

    it "POSTs to the correct endpoint with Bearer token" do
      stub_request(:post, "https://sandbox-api.piste.gouv.fr/cpro/factures/v1/rechercher/structure")
        .with(
          body:    { siret: "35600000000000" }.to_json,
          headers: { "Authorization" => "Bearer tok_abc123", "Content-Type" => "application/json;charset=UTF-8" }
        )
        .to_return(status: 200, body: { idStructureCPP: 42 }.to_json, headers: { "Content-Type" => "application/json" })

      result = client.find_structure(siret: "35600000000000")
      expect(result["idStructureCPP"]).to eq(42)
    end
  end

  describe "#handle_response (via find_structure)" do
    before { stub_token }

    it "raises AuthenticationError on 401" do
      stub_request(:post, "https://sandbox-api.piste.gouv.fr/cpro/factures/v1/rechercher/structure")
        .to_return(status: 401, body: { error: "unauthorized" }.to_json)
      expect { client.find_structure(siret: "35600000000000") }
        .to raise_error(Einvoicing::PPF::AuthenticationError, /Unauthorized/)
    end

    it "raises AuthorizationError on 403" do
      stub_request(:post, "https://sandbox-api.piste.gouv.fr/cpro/factures/v1/rechercher/structure")
        .to_return(status: 403, body: { error: "forbidden" }.to_json)
      expect { client.find_structure(siret: "35600000000000") }
        .to raise_error(Einvoicing::PPF::AuthorizationError, /Forbidden/)
    end

    it "raises NotFoundError on 404" do
      stub_request(:post, "https://sandbox-api.piste.gouv.fr/cpro/factures/v1/rechercher/structure")
        .to_return(status: 404, body: { error: "not found" }.to_json)
      expect { client.find_structure(siret: "35600000000000") }
        .to raise_error(Einvoicing::PPF::NotFoundError, /Not found/)
    end

    it "raises APIError on 500" do
      stub_request(:post, "https://sandbox-api.piste.gouv.fr/cpro/factures/v1/rechercher/structure")
        .to_return(status: 500, body: "Internal Server Error")
      expect { client.find_structure(siret: "35600000000000") }
        .to raise_error(Einvoicing::PPF::APIError, /API error 500/)
    end
  end

  describe "production mode" do
    let(:prod_client) { described_class.new(client_id: client_id, client_secret: client_secret, sandbox: false) }

    it "uses production OAuth and API URLs" do
      stub_request(:post, "https://oauth.piste.gouv.fr/api/oauth/token")
        .to_return(status: 200, body: token_response, headers: { "Content-Type" => "application/json" })
      stub_request(:post, "https://api.piste.gouv.fr/cpro/factures/v1/rechercher/structure")
        .to_return(status: 200, body: { idStructureCPP: 1 }.to_json, headers: { "Content-Type" => "application/json" })

      prod_client.find_structure(siret: "35600000000000")
      expect(WebMock).to have_requested(:post, "https://oauth.piste.gouv.fr/api/oauth/token").once
      expect(WebMock).to have_requested(:post, "https://api.piste.gouv.fr/cpro/factures/v1/rechercher/structure").once
    end
  end
end
