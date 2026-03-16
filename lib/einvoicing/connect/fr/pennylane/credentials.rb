# frozen_string_literal: true

module Einvoicing
  module Connect
    module FR
      module Pennylane
        # Encapsulates Pennylane API authentication credentials.
        #
        # Two modes are supported:
        #
        # 1. Static API key — for Companies and Firms using a personal access token:
        #      creds = Pennylane::Credentials.api_key("tok_xxx")
        #
        # 2. OAuth2 — for Integration Partners using the authorization code flow:
        #      creds = Pennylane::Credentials.oauth(
        #        access_token:  "...",
        #        refresh_token: "...",
        #        client_id:     "...",
        #        client_secret: "...",
        #        expires_at:    Time.now + 3600   # optional
        #      )
        #
        # OAuth credentials are mutable: when the Client refreshes an expired access
        # token it updates the object in place. The calling application can read back
        # the updated tokens after any API call and persist them.
        module Credentials
          def self.api_key(key)
            ApiKey.new(key)
          end

          def self.oauth(access_token:, refresh_token:, client_id:, client_secret:,
                         expires_at: nil)
            OAuth.new(
              access_token:  access_token,
              refresh_token: refresh_token,
              client_id:     client_id,
              client_secret: client_secret,
              expires_at:    expires_at
            )
          end

          # Static personal access token — never expires.
          class ApiKey
            attr_reader :api_key

            def initialize(key)
              @api_key = key
            end
          end

          # OAuth2 access + refresh token pair. Mutable so the Client can update
          # tokens in place after a refresh, making the new values available to the
          # caller for persistence.
          class OAuth
            attr_reader   :client_id, :client_secret
            attr_accessor :access_token, :refresh_token, :expires_at

            def initialize(access_token:, refresh_token:, client_id:, client_secret:,
                           expires_at: nil)
              @access_token  = access_token
              @refresh_token = refresh_token
              @client_id     = client_id
              @client_secret = client_secret
              @expires_at    = expires_at
            end

            def expired?
              expires_at.nil? || Time.now >= expires_at
            end
          end
        end
      end
    end
  end
end
