# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "einvoicing", path: "../einvoicing"

# parallel 2.x requires Ruby >= 3.3, this gem supports >= 3.2 (gemspec).
# Pulled in transitively by rubocop.
gem "parallel", "< 2.0", group: :development
