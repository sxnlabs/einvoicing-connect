# frozen_string_literal: true

module Einvoicing
  module Connect
    module FR
      module Pennylane
        Error           = Class.new(StandardError) unless defined?(Error)
        AuthError       = Class.new(Error) unless defined?(AuthError)
        SubmissionError = Class.new(Error) unless defined?(SubmissionError)
      end
    end
  end
end
