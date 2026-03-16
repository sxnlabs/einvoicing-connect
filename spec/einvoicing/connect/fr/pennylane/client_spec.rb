# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe Einvoicing::Connect::FR::Pennylane::Client do
  let(:api_key_creds) { Einvoicing::Connect::FR::Pennylane::Credentials.api_key("test_api_key") }
  let(:client)        { described_class.new(credentials: api_key_creds) }

  describe "#submit_einvoice" do
    let(:pdf_bytes) { "%PDF-1.4 fake pdf content".b }

    context "without invoice_options" do
      before do
        stub_request(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .with(headers: { "Authorization" => "Bearer test_api_key" })
          .to_return(status:  201,
                     body:    { id: 7, status: "processing" }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "returns the parsed response" do
        result = client.submit_einvoice(pdf_bytes)
        expect(result["id"]).to eq(7)
        expect(result["status"]).to eq("processing")
      end

      it "POSTs to the e-invoice import endpoint" do
        client.submit_einvoice(pdf_bytes)
        expect(WebMock).to have_requested(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports").once
      end

      it "sends a multipart/form-data request" do
        client.submit_einvoice(pdf_bytes)
        expect(WebMock).to have_requested(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .with { |req| req.headers["Content-Type"].start_with?("multipart/form-data") }
      end

      it "includes the PDF filename in the request body" do
        client.submit_einvoice(pdf_bytes)
        expect(WebMock).to have_requested(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .with { |req| req.body.include?("factur-x.pdf") }
      end

      it "never calls the OAuth token endpoint in API key mode" do
        client.submit_einvoice(pdf_bytes)
        expect(WebMock).not_to have_requested(:post,
          "https://app.pennylane.com/oauth/token")
      end
    end

    context "with invoice_options" do
      before do
        stub_request(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .to_return(status: 201, body: { id: 8 }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "includes invoice_options as a JSON part in the multipart body" do
        opts = { customer: { name: "Acme" } }
        client.submit_einvoice(pdf_bytes, invoice_options: opts)
        expect(WebMock).to have_requested(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .with { |req| req.body.include?("invoice_options") && req.body.include?("Acme") }
      end
    end

    context "when the API returns 401" do
      before do
        stub_request(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .to_return(status: 401, body: { error: "unauthorized" }.to_json)
      end

      it "raises AuthError" do
        expect { client.submit_einvoice(pdf_bytes) }
          .to raise_error(Einvoicing::Connect::FR::Pennylane::AuthError)
      end
    end

    context "when the API returns 422" do
      before do
        stub_request(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .to_return(status: 422, body: { error: "invalid file" }.to_json)
      end

      it "raises SubmissionError with the status code" do
        expect { client.submit_einvoice(pdf_bytes) }
          .to raise_error(Einvoicing::Connect::FR::Pennylane::SubmissionError, /422/)
      end
    end

    context "sandbox mode" do
      let(:sandbox_client) { described_class.new(credentials: api_key_creds, sandbox: true) }

      before do
        stub_request(:post,
          "https://sandbox.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .to_return(status: 201, body: { id: 1 }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "uses the sandbox URL" do
        sandbox_client.submit_einvoice(pdf_bytes)
        expect(WebMock).to have_requested(:post,
          "https://sandbox.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports").once
      end
    end
  end

  describe "#invoice_status" do
    before do
      stub_request(:get, "https://app.pennylane.com/api/external/v2/customer_invoices/42")
        .with(headers: { "Authorization" => "Bearer test_api_key" })
        .to_return(status:  200,
                   body:    { id: 42, status: "sent" }.to_json,
                   headers: { "Content-Type" => "application/json" })
    end

    it "returns the parsed response" do
      result = client.invoice_status(42)
      expect(result["status"]).to eq("sent")
    end
  end

  describe "OAuth2 mode" do
    let(:oauth_creds) do
      Einvoicing::Connect::FR::Pennylane::Credentials.oauth(
        access_token:  "initial_token",
        refresh_token: "refresh_tok",
        client_id:     "client_123",
        client_secret: "secret_abc",
        expires_at:    Time.now + 3600
      )
    end
    let(:oauth_client) { described_class.new(credentials: oauth_creds) }
    let(:pdf_bytes)    { "%PDF-1.4 fake pdf".b }

    before do
      stub_request(:post,
        "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
        .with(headers: { "Authorization" => "Bearer initial_token" })
        .to_return(status:  201,
                   body:    { id: 99 }.to_json,
                   headers: { "Content-Type" => "application/json" })
    end

    it "uses the access token as the Bearer token" do
      oauth_client.submit_einvoice(pdf_bytes)
      expect(WebMock).to have_requested(:post,
        "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
        .with(headers: { "Authorization" => "Bearer initial_token" })
    end

    it "does not call the token endpoint when the token is fresh" do
      oauth_client.submit_einvoice(pdf_bytes)
      expect(WebMock).not_to have_requested(:post, "https://app.pennylane.com/oauth/token")
    end

    context "when the access token is expired" do
      let(:oauth_creds) do
        Einvoicing::Connect::FR::Pennylane::Credentials.oauth(
          access_token:  "expired_token",
          refresh_token: "refresh_tok",
          client_id:     "client_123",
          client_secret: "secret_abc",
          expires_at:    Time.now - 1
        )
      end

      before do
        stub_request(:post, "https://app.pennylane.com/oauth/token")
          .with(body: hash_including("grant_type" => "refresh_token",
                                    "refresh_token" => "refresh_tok"))
          .to_return(status:  200,
                     body:    { access_token: "new_token", expires_in: 3600 }.to_json,
                     headers: { "Content-Type" => "application/json" })
        stub_request(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .with(headers: { "Authorization" => "Bearer new_token" })
          .to_return(status:  201,
                     body:    { id: 10 }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "refreshes the token before the request" do
        oauth_client.submit_einvoice(pdf_bytes)
        expect(WebMock).to have_requested(:post, "https://app.pennylane.com/oauth/token").once
      end

      it "uses the new token for the API call" do
        oauth_client.submit_einvoice(pdf_bytes)
        expect(WebMock).to have_requested(:post,
          "https://app.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .with(headers: { "Authorization" => "Bearer new_token" })
      end

      it "updates the credentials with the new access_token" do
        oauth_client.submit_einvoice(pdf_bytes)
        expect(oauth_creds.access_token).to eq("new_token")
      end

      it "updates the credentials with a future expires_at" do
        oauth_client.submit_einvoice(pdf_bytes)
        expect(oauth_creds.expires_at).to be > Time.now
      end

      it "rotates the refresh_token when the response includes one" do
        stub_request(:post, "https://app.pennylane.com/oauth/token")
          .to_return(status:  200,
                     body:    { access_token: "new_token", refresh_token: "new_refresh",
                                expires_in: 3600 }.to_json,
                     headers: { "Content-Type" => "application/json" })
        oauth_client.submit_einvoice(pdf_bytes)
        expect(oauth_creds.refresh_token).to eq("new_refresh")
      end
    end

    context "when token refresh fails" do
      let(:oauth_creds) do
        Einvoicing::Connect::FR::Pennylane::Credentials.oauth(
          access_token:  "expired",
          refresh_token: "bad_refresh",
          client_id:     "client_123",
          client_secret: "secret_abc",
          expires_at:    Time.now - 1
        )
      end

      before do
        stub_request(:post, "https://app.pennylane.com/oauth/token")
          .to_return(status: 401, body: { error: "invalid_grant" }.to_json)
      end

      it "raises OAuthError" do
        expect { oauth_client.submit_einvoice(pdf_bytes) }
          .to raise_error(Einvoicing::Connect::FR::Pennylane::OAuthError, /OAuth token refresh failed/)
      end
    end

    context "sandbox OAuth2" do
      let(:sandbox_oauth_creds) do
        Einvoicing::Connect::FR::Pennylane::Credentials.oauth(
          access_token:  "sandbox_token",
          refresh_token: "sandbox_refresh",
          client_id:     "client_123",
          client_secret: "secret_abc",
          expires_at:    Time.now - 1
        )
      end
      let(:sandbox_oauth_client) { described_class.new(credentials: sandbox_oauth_creds, sandbox: true) }

      before do
        stub_request(:post, "https://sandbox.pennylane.com/oauth/token")
          .to_return(status:  200,
                     body:    { access_token: "new_sandbox_token", expires_in: 3600 }.to_json,
                     headers: { "Content-Type" => "application/json" })
        stub_request(:post,
          "https://sandbox.pennylane.com/api/external/v2/customer_invoices/e_invoices/imports")
          .to_return(status: 201, body: { id: 1 }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "uses the sandbox token endpoint" do
        sandbox_oauth_client.submit_einvoice(pdf_bytes)
        expect(WebMock).to have_requested(:post,
          "https://sandbox.pennylane.com/oauth/token").once
      end
    end
  end
end
