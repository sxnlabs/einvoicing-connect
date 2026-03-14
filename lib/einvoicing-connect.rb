# frozen_string_literal: true

require "einvoicing"
require_relative "einvoicing/connect/version"
require_relative "einvoicing/connect/i18n"
require_relative "einvoicing/fr/siret_lookup"
require_relative "einvoicing/ppf/errors"
require_relative "einvoicing/ppf/client"
require_relative "einvoicing/ppf/invoice_adapter"
require_relative "einvoicing/ppf/submitter"

module Einvoicing
  module Connect
    # einvoicing-connect adds platform connectivity to the einvoicing gem.
    # Requires: gem "einvoicing-connect" in your Gemfile.
  end
end
