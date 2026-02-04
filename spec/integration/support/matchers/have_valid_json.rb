# frozen_string_literal: true

require 'json'

RSpec::Matchers.define :have_valid_json do
  match do |file_path|
    return true unless File.exist?(file_path)

    JSON.parse(File.read(file_path))
    true
  rescue JSON::ParserError => e
    @error = e.message
    false
  end

  failure_message do |file_path|
    "expected #{file_path} to contain valid JSON, but got: #{@error}"
  end
end
