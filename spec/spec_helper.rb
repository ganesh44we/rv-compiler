require 'rspec'
require 'open3'
require 'fileutils'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # RV Helper Methods
  def run_rv(args)
    rv_bin = File.expand_path('../../bin/rv', __FILE__)
    stdout, stderr, status = Open3.capture3("#{rv_bin} #{args}")
    { stdout: stdout, stderr: stderr, status: status }
  end
end
