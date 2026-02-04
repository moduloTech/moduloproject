# frozen_string_literal: true

require 'open3'

RSpec::Matchers.define :have_valid_shell_syntax do
  match do |file_path|
    return true unless File.exist?(file_path)

    first_line = begin
      File.open(file_path, &:readline).strip
    rescue StandardError
      ''
    end
    shell = first_line.include?('bash') ? 'bash' : 'sh'

    output, status = Open3.capture2e(shell, '-n', file_path)
    @error = output unless status.success?
    status.success?
  end

  failure_message do |file_path|
    "expected #{file_path} to have valid shell syntax, but got: #{@error}"
  end
end
