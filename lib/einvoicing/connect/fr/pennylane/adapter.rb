# frozen_string_literal: true

module Einvoicing
  module Connect
    module FR
      module Pennylane
        class Adapter
          def initialize(invoice)
            @invoice = invoice
          end

          # Maps Einvoicing::Invoice to Pennylane customer_invoices payload
          def to_payload
            {
              customer_invoice: {
                date:                  @invoice.issue_date.iso8601,
                deadline:              @invoice.due_date&.iso8601,
                invoice_number:        @invoice.invoice_number,
                currency:              @invoice.currency || "EUR",
                line_items_attributes: line_items,
                customer_attributes:   customer
              }
            }
          end

          private

          def line_items
            @invoice.lines.map do |line|
              {
                label:      line.description,
                quantity:   line.quantity,
                unit_price: line.unit_price,
                vat_rate:   (line.vat_rate * 100).round(2).to_s
              }
            end
          end

          def customer
            b = @invoice.buyer
            {
              name:           b.name,
              reg_no:         b.siret || b.siren,
              address:        b.street,
              city:           b.city,
              postal_code:    b.postal_code,
              country_alpha2: b.country_code || "FR"
            }
          end
        end
      end
    end
  end
end
