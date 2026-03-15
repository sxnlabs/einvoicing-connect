# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Einvoicing
  module Connect
    module FR
      module Pennylane
        class Client
          BASE_URL    = "https://app.pennylane.com/api/external/v2"
          SANDBOX_URL = "https://sandbox.pennylane.com/api/external/v2"

          def initialize(api_key:, sandbox: false)
            @api_key  = api_key
            @base_url = sandbox ? SANDBOX_URL : BASE_URL
          end

          # Submit an invoice (Einvoicing::Invoice object).
          # Returns the parsed response body hash.
          def submit_invoice(invoice)
            payload = Adapter.new(invoice).to_payload
            post("/customer_invoices", payload)
          end

          # Get invoice status by Pennylane invoice ID.
          def invoice_status(id)
            get("/customer_invoices/#{id}")
          end

          private

          def post(path, body)
            uri  = URI("#{@base_url}#{path}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            req = Net::HTTP::Post.new(uri)
            req["Authorization"] = "Bearer #{@api_key}"
            req["Content-Type"]  = "application/json"
            req.body = JSON.generate(body)
            handle_response(http.request(req))
          end

          def get(path)
            uri  = URI("#{@base_url}#{path}")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            req = Net::HTTP::Get.new(uri)
            req["Authorization"] = "Bearer #{@api_key}"
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
