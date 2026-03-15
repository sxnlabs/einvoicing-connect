# frozen_string_literal: true

module Einvoicing
  module Connect
    module FR
      module PPF
        Error               = Class.new(StandardError) unless defined?(Error)
        AuthenticationError = Class.new(Error) unless defined?(AuthenticationError)
        AuthorizationError  = Class.new(Error) unless defined?(AuthorizationError)
        NotFoundError       = Class.new(Error) unless defined?(NotFoundError)
        APIError            = Class.new(Error) unless defined?(APIError)
        ValidationError     = Class.new(Error) unless defined?(ValidationError)
      end
    end
  end
end
