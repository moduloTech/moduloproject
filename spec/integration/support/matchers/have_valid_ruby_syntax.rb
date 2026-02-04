# frozen_string_literal: true

require 'open3'

RSpec::Matchers.define :have_valid_ruby_syntax do
  match do |file_path|
    return true unless File.exist?(file_path)

    content = File.read(file_path)
    # Skip ERB-templated files
    return true if content.include?('<%')

    output, status = Open3.capture2e('ruby', '-c', file_path)
    @error = output unless status.success?
    status.success?
  end

  failure_message do |file_path|
    "expected #{file_path} to have valid Ruby syntax, but got: #{@error}"
  end
end
