# frozen_string_literal: true

# Must load before anything under lib/, or the files already required by the
# time SimpleCov starts are reported as entirely uncovered.
require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  enable_coverage :branch

  # A ratchet, not a target: these are the numbers this suite already reaches,
  # rounded down. Raise them when coverage improves, never lower them to make a
  # branch pass — an uncovered line is a missing test, not a threshold problem.
  #
  # It only applies to a full run. Running one file — in a TDD loop, from an
  # editor, in a pre-commit hook — would otherwise exit non-zero on coverage
  # with every test passing.
  #
  # And in CI only on the leg that sets COVERAGE_GATE. The branch table the
  # Coverage module produces is not identical across Ruby versions, and with
  # four branches of headroom the 3.2 leg could drop under the floor without a
  # line of code changing.
  # Any argument at all means a partial run: a file, an absolute path from an
  # editor, `-e "example name"`, `-t @tag`. Testing for a "spec/" prefix missed
  # every form but the first and gated a filtered subset against the whole
  # suite's floor.
  full_run = ARGV.empty?
  gated = ENV["CI"] ? ENV["COVERAGE_GATE"] == "1" : true

  minimum_coverage line: 98, branch: 75 if full_run && gated
end

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
