# frozen_string_literal: true

module Einvoicing
  module Connect
    module FR
      module Pennylane
        # Orchestrates Factur-X generation and submission to Pennylane's
        # e-invoice import endpoint.
        #
        # Requires the `hexapdf` gem (used internally by Einvoicing::Formats::FacturX).
        #
        # @example Static API key
        #   creds     = Pennylane::Credentials.api_key("tok_xxx")
        #   submitter = EInvoiceSubmitter.new(credentials: creds)
        #   pdf_bytes = File.binread("invoice.pdf")
        #   submitter.submit(invoice, pdf: pdf_bytes)
        #
        # @example OAuth2
        #   creds = Pennylane::Credentials.oauth(
        #     access_token:  "...", refresh_token: "...",
        #     client_id:     "...", client_secret: "..."
        #   )
        #   submitter = EInvoiceSubmitter.new(credentials: creds)
        #   submitter.submit(invoice, pdf: pdf_bytes)
        #   # creds.access_token / creds.refresh_token are updated after a refresh
        class EInvoiceSubmitter
          def initialize(credentials:, sandbox: false)
            @client = Client.new(credentials: credentials, sandbox: sandbox)
          end

          # Generates a Factur-X PDF from +invoice+ and +pdf+, then submits it.
          #
          # @param invoice [Einvoicing::Invoice]
          # @param pdf     [String] binary content of a PDF (human-readable invoice)
          # @param invoice_options [Hash, nil] optional Pennylane pre-fill options
          # @return [Hash] parsed Pennylane API response
          def submit(invoice, pdf:, invoice_options: nil)
            xml         = Einvoicing::Formats::CII.generate(invoice)
            facturx_pdf = Einvoicing::Formats::FacturX.embed(pdf, xml)
            @client.submit_einvoice(facturx_pdf, invoice_options: invoice_options)
          end
        end
      end
    end
  end
end
