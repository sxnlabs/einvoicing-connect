# frozen_string_literal: true

require "i18n"

module Einvoicing
  module Connect
    module I18nSetup
      def self.setup
        ::I18n.load_path += Dir[File.join(__dir__, "../../../config/locales/*.yml")]
        ::I18n.backend.load_translations
      end
    end
  end
end

Einvoicing::Connect::I18nSetup.setup
