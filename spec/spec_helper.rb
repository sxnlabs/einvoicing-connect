# frozen_string_literal: true

require "einvoicing-connect"
require "webmock/rspec"
require "vcr"

VCR.configure do |c|
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
  c.configure_rspec_metadata!

  # Scrub the real API key from recorded cassettes.
  c.filter_sensitive_data("<PENNYLANE_API_KEY>") { ENV["PENNYLANE_API_KEY"] }

  # Do not record the binary PDF request body — it changes every run.
  # Cassettes match on method + URI only; the response is what we care about.
  c.default_cassette_options = {
    match_requests_on: [ :method, :uri ]
  }
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
