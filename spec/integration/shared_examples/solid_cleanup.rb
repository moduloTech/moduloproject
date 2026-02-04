# frozen_string_literal: true

RSpec.shared_examples 'solid cleanup' do |combination|
  next unless combination.supports_skip_solid?

  describe 'solid file cleanup' do
    solid_files = %w[
      config/cache.yml
      config/queue.yml
      config/recurring.yml
      db/cache_schema.rb
      db/queue_schema.rb
      db/cable_schema.rb
    ]

    if combination.skip_solid_passed?
      # --skip-solid was passed: no solid files should exist at all
      solid_files.each do |file|
        it "does not have #{file} (--skip-solid passed)" do
          expect(File.exist?(File.join(project_root, file))).to be false
        end
      end
    elsif combination.needs_solid_cleanup?
      # Mixed: solid files should have been cleaned up
      solid_files.each do |file|
        it "does not have #{file} (cleaned up by SolidCleanup)" do
          expect(File.exist?(File.join(project_root, file))).to be false
        end
      end
    elsif combination.all_solid?
      # All solid backends: solid files should still exist
      solid_files.each do |file|
        it "has #{file} (all solid backends)" do
          expect(File.exist?(File.join(project_root, file))).to be true
        end
      end
    end
  end
end
