# frozen_string_literal: true

require "einvoicing"
require_relative "einvoicing/connect/version"
require_relative "einvoicing/connect/i18n"
require_relative "einvoicing/connect/fr/ppf/errors"
require_relative "einvoicing/connect/fr/ppf/client"
require_relative "einvoicing/connect/fr/ppf/invoice_adapter"
require_relative "einvoicing/connect/fr/ppf/submitter"
require_relative "einvoicing/connect/fr/siret_lookup"

module Einvoicing
  module Connect
    # einvoicing-connect adds platform connectivity to the einvoicing gem.
    # Requires: gem "einvoicing-connect" in your Gemfile.
  end
end
