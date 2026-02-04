# frozen_string_literal: true

RSpec::Matchers.define :contain_gem do |gem_name|
  match do |file_path|
    return false unless File.exist?(file_path)

    content = File.read(file_path)
    content.match?(/gem\s+['"]#{Regexp.escape(gem_name)}['"]/)
  end

  match_when_negated do |file_path|
    return true unless File.exist?(file_path)

    content = File.read(file_path)
    !content.match?(/gem\s+['"]#{Regexp.escape(gem_name)}['"]/)
  end

  failure_message do |file_path|
    "expected #{file_path} to contain gem '#{gem_name}'"
  end

  failure_message_when_negated do |file_path|
    "expected #{file_path} not to contain gem '#{gem_name}'"
  end
end
