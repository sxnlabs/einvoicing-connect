# frozen_string_literal: true

require_relative "lib/einvoicing/connect/version"

Gem::Specification.new do |s|
  s.name        = "einvoicing-connect"
  s.version     = Einvoicing::Connect::VERSION
  s.summary     = "Platform connectors for the einvoicing gem — Pennylane, PPF/Chorus Pro, SIRET lookup"
  s.description = "Adds French e-invoicing platform connectors to the einvoicing gem: Pennylane (Factur-X import), PPF/Chorus Pro submission, and SIRET lookup."
  s.authors     = [ "Nathan Le Ray" ]
  s.email       = [ "nathan@sxnlabs.com" ]
  s.homepage    = "https://www.sxnlabs.com/en/gems/einvoicing/"
  s.license     = "MIT"
  s.metadata    = {
    "homepage_uri"    => "https://www.sxnlabs.com/en/gems/einvoicing/",
    "source_code_uri" => "https://github.com/sxnlabs/einvoicing-connect"
  }
  s.required_ruby_version = ">= 3.2"
  s.files = Dir["lib/**/*.rb"] + Dir["config/locales/*.yml"] + ["README.md", "LICENSE"]
  s.add_dependency "einvoicing", "~> 0.5"
  s.add_development_dependency "rspec",                 "~> 3.13"
  s.add_development_dependency "webmock",               "~> 3.0"
  s.add_development_dependency "vcr",                   "~> 6.0"
  s.add_development_dependency "hexapdf",               "~> 1.0"
  s.add_development_dependency "rubocop",               "~> 1.70"
  s.add_development_dependency "rubocop-rails-omakase"
  s.add_development_dependency "rubocop-rspec",         "~> 3.0"
end
