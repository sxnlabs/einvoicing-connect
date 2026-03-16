# frozen_string_literal: true

require "spec_helper"

RSpec.describe Einvoicing::Connect::FR::Pennylane::Credentials do
  describe ".api_key" do
    subject(:creds) { described_class.api_key("tok_abc") }

    it "returns an ApiKey instance" do
      expect(creds).to be_a(described_class::ApiKey)
    end

    it "exposes the api_key" do
      expect(creds.api_key).to eq("tok_abc")
    end
  end

  describe ".oauth" do
    subject(:creds) do
      described_class.oauth(
        access_token:  "at",
        refresh_token: "rt",
        client_id:     "cid",
        client_secret: "sec"
      )
    end

    it "returns an OAuth instance" do
      expect(creds).to be_a(described_class::OAuth)
    end

    it "exposes access_token" do
      expect(creds.access_token).to eq("at")
    end

    it "exposes refresh_token" do
      expect(creds.refresh_token).to eq("rt")
    end

    it "exposes client_id and client_secret" do
      expect(creds.client_id).to eq("cid")
      expect(creds.client_secret).to eq("sec")
    end

    it "defaults expires_at to nil" do
      expect(creds.expires_at).to be_nil
    end

    it "accepts an explicit expires_at" do
      t     = Time.now + 3600
      creds = described_class.oauth(access_token: "at", refresh_token: "rt",
                                    client_id: "cid", client_secret: "sec",
                                    expires_at: t)
      expect(creds.expires_at).to eq(t)
    end
  end

  describe "Credentials::OAuth" do
    let(:creds) do
      described_class::OAuth.new(
        access_token:  "at",
        refresh_token: "rt",
        client_id:     "cid",
        client_secret: "sec"
      )
    end

    describe "#expired?" do
      it "is true when expires_at is nil" do
        expect(creds.expired?).to be(true)
      end

      it "is true when expires_at is in the past" do
        creds.expires_at = Time.now - 1
        expect(creds.expired?).to be(true)
      end

      it "is false when expires_at is in the future" do
        creds.expires_at = Time.now + 3600
        expect(creds.expired?).to be(false)
      end
    end

    it "allows updating access_token in place" do
      creds.access_token = "new_token"
      expect(creds.access_token).to eq("new_token")
    end

    it "allows updating refresh_token in place" do
      creds.refresh_token = "new_refresh"
      expect(creds.refresh_token).to eq("new_refresh")
    end
  end
end
