# frozen_string_literal: true

require 'yaml'

RSpec::Matchers.define :have_valid_yaml do
  match do |file_path|
    return true unless File.exist?(file_path)

    content = File.read(file_path)
    # Skip ERB-templated files
    return true if content.include?('<%')

    YAML.safe_load(content, permitted_classes: [Symbol])
    true
  rescue Psych::SyntaxError => e
    @error = e.message
    false
  end

  failure_message do |file_path|
    "expected #{file_path} to contain valid YAML, but got: #{@error}"
  end
end
