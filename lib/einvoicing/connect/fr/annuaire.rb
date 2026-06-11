# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module Einvoicing
  module Connect
    module FR
      # Consultation of the central e-invoicing directory (annuaire du PPF / AIFE).
      #
      # Given a French SIREN or SIRET, resolves the recipient's e-invoicing
      # routing information: the registered reception platform (PDP / plateforme
      # agréée) and its technical routing code. This is the lookup an issuing
      # platform performs to know *where* to deliver an invoice for a company.
      #
      # NOTE: The official DGFiP/AIFE annuaire API specification is not yet final.
      # The reform pilot opened on 2026-02-27, with general availability on
      # 2026-09-01. The endpoint and response shape below follow the published
      # interoperability framework and are expected to evolve — point
      # +Annuaire.api_url=+ at the production endpoint once it is confirmed.
      module Annuaire
        # Placeholder endpoint, overridable via Annuaire.api_url= or per call.
        DEFAULT_API_URL = "https://annuaire.facturation.gouv.fr/api/v1/destinataires" unless defined?(DEFAULT_API_URL)

        class << self
          attr_writer :api_url

          def api_url
            @api_url ||= DEFAULT_API_URL
          end
        end

        # Look up the routing information for a recipient identified by SIREN
        # (9 digits) or SIRET (14 digits).
        #
        # Returns a Hash on success, or nil on any error / no match:
        #   {
        #     identifier:    "55203253400017",
        #     maille:        "SIRET",          # or "SIREN"
        #     routing_code:  "PDP000123",      # technical routing code
        #     platform_id:   "0000000000000",  # PDP/PA registration id
        #     platform_name: "Acme PDP",
        #     status:        "active"
        #   }
        def self.lookup(identifier, api_url: self.api_url)
          id = identifier.to_s.gsub(/\s/, "")
          return nil unless id.match?(/\A\d{9}(\d{5})?\z/)

          uri = URI(api_url)
          uri.query = URI.encode_www_form(identifiant: id)

          response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                     open_timeout: 5, read_timeout: 10) do |http|
            http.get(uri.request_uri)
          end

          return nil unless response.code == "200"

          parse(JSON.parse(response.body))
        rescue StandardError
          nil
        end

        # Resolve the routing information for a Party, preferring its SIRET and
        # falling back to its SIREN. Returns the routing Hash or nil.
        def self.route(party, api_url: self.api_url)
          identifier = party.siret.to_s.strip
          identifier = party.siren.to_s.strip if identifier.empty? && party.respond_to?(:siren)
          return nil if identifier.empty?

          lookup(identifier, api_url: api_url)
        end

        # Internal: map an annuaire API payload to our routing Hash.
        def self.parse(data)
          entry = data.is_a?(Hash) ? (data["destinataire"] || data["results"]&.first || data) : nil
          return nil unless entry.is_a?(Hash)

          routing_code = entry["codeRoutage"] || entry["routing_code"]
          return nil if routing_code.to_s.empty?

          {
            identifier:    entry["identifiant"] || entry["identifier"],
            maille:        entry["maille"],
            routing_code:  routing_code,
            platform_id:   entry["idPlateforme"] || entry["platform_id"],
            platform_name: entry["nomPlateforme"] || entry["platform_name"],
            status:        entry["statut"] || entry["status"]
          }
        end
        private_class_method :parse
      end
    end
  end
end
