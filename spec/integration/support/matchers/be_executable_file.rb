# frozen_string_literal: true

RSpec::Matchers.define :be_executable_file do
  match do |file_path|
    File.exist?(file_path) && File.executable?(file_path)
  end

  failure_message do |file_path|
    if File.exist?(file_path)
      "expected #{file_path} to be executable"
    else
      "expected #{file_path} to exist"
    end
  end
end
