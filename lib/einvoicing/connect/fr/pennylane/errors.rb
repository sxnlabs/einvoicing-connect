# frozen_string_literal: true

module Einvoicing
  module Connect
    module FR
      module Pennylane
        Error           = Class.new(StandardError) unless defined?(Error)
        AuthError       = Class.new(Error) unless defined?(AuthError)
        OAuthError      = Class.new(Error) unless defined?(OAuthError)
        SubmissionError = Class.new(Error) unless defined?(SubmissionError)
      end
    end
  end
end
