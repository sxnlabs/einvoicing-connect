# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "securerandom"

module Einvoicing
  module Connect
    module FR
      module Pennylane
        class Client
          BASE_URL    = "https://app.pennylane.com/api/external/v2"
          SANDBOX_URL = "https://sandbox.pennylane.com/api/external/v2"

          OAUTH_TOKEN_PATH  = "/oauth/token"
          OAUTH_BASE_URL    = "https://app.pennylane.com"
          OAUTH_SANDBOX_URL = "https://sandbox.pennylane.com"

          def initialize(credentials:, sandbox: false)
            @credentials = credentials
            @base_url    = sandbox ? SANDBOX_URL : BASE_URL
            @oauth_base  = sandbox ? OAUTH_SANDBOX_URL : OAUTH_BASE_URL
          end

          # Submit a Factur-X PDF binary to the e-invoice import endpoint.
          # invoice_options: optional Hash pre-filling customer/line data.
          def submit_einvoice(facturx_pdf, filename: "factur-x.pdf", invoice_options: nil)
            post_multipart("/customer_invoices/e_invoices/imports",
                           file: facturx_pdf, filename: filename,
                           invoice_options: invoice_options)
          end

          # Get invoice status by Pennylane invoice ID.
          def invoice_status(id)
            get("/customer_invoices/#{id}")
          end

          private

          def current_token
            case @credentials
            when Credentials::OAuth
              refresh_oauth_token! if @credentials.expired?
              @credentials.access_token
            when Credentials::ApiKey
              @credentials.api_key
            end
          end

          def refresh_oauth_token!
            uri = URI("#{@oauth_base}#{OAUTH_TOKEN_PATH}")
            req = Net::HTTP::Post.new(uri)
            req["Content-Type"] = "application/x-www-form-urlencoded"
            req.body = URI.encode_www_form(
              grant_type:    "refresh_token",
              refresh_token: @credentials.refresh_token,
              client_id:     @credentials.client_id,
              client_secret: @credentials.client_secret
            )
            res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
            unless res.is_a?(Net::HTTPSuccess)
              raise OAuthError, ::I18n.t("einvoicing.connect.pennylane.oauth_failed",
                                         code: res.code, body: res.body.to_s[0, 200])
            end

            data = JSON.parse(res.body)
            @credentials.access_token  = data["access_token"]
            @credentials.refresh_token = data["refresh_token"] if data["refresh_token"]
            @credentials.expires_at    = Time.now + data.fetch("expires_in", 3600).to_i - 60
          end

          def post(path, body)
            uri  = URI("#{@base_url}#{path}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            req = Net::HTTP::Post.new(uri)
            req["Authorization"] = "Bearer #{current_token}"
            req["Content-Type"]  = "application/json"
            req.body = JSON.generate(body)
            handle_response(http.request(req))
          end

          def post_multipart(path, file:, filename:, invoice_options: nil)
            boundary = "RubyBoundary#{SecureRandom.hex(16)}"
            uri      = URI("#{@base_url}#{path}")
            http     = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            req = Net::HTTP::Post.new(uri)
            req["Authorization"] = "Bearer #{current_token}"
            req["Content-Type"]  = "multipart/form-data; boundary=#{boundary}"
            req.body = build_multipart_body(boundary, file: file, filename: filename,
                                            invoice_options: invoice_options)
            handle_response(http.request(req))
          end

          def build_multipart_body(boundary, file:, filename:, invoice_options:)
            body = +""
            body << "--#{boundary}\r\n"
            body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
            body << "Content-Type: application/pdf\r\n\r\n"
            body << file.b
            body << "\r\n"
            if invoice_options
              body << "--#{boundary}\r\n"
              body << "Content-Disposition: form-data; name=\"invoice_options\"\r\n"
              body << "Content-Type: application/json\r\n\r\n"
              body << JSON.generate(invoice_options)
              body << "\r\n"
            end
            body << "--#{boundary}--\r\n"
            body.force_encoding("BINARY")
          end

          def get(path)
            uri  = URI("#{@base_url}#{path}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            req = Net::HTTP::Get.new(uri)
            req["Authorization"] = "Bearer #{current_token}"
            handle_response(http.request(req))
          end

          def handle_response(response)
            body = JSON.parse(response.body) rescue {}
            case response.code.to_i
            when 200..299
              body
            when 401
              raise AuthError, ::I18n.t("einvoicing.connect.pennylane.auth_failed")
            else
              raise SubmissionError, ::I18n.t("einvoicing.connect.pennylane.submission_failed",
                                              code: response.code,
                                              body: response.body.to_s[0, 200])
            end
          end
        end
      end
    end
  end
end
