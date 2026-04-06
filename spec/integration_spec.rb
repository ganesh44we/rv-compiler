require 'spec_helper'

RSpec.describe 'RV Compiler Integration', type: :integration do
  let(:python_showcase) { File.expand_path('../../biggest.py', __FILE__) }
  let(:ruby_showcase) { File.expand_path('../../biggest.rb', __FILE__) }
  let(:science_showcase) { File.expand_path('../../science.py', __FILE__) }

  describe 'Python Frontend' do
    it 'successfully compiles and executes the Mega Showcase' do
      result = run_rv("#{python_showcase} --run")
      expect(result[:status].success?).to be true
      expect(result[:stdout]).to include("--- [RV] MEGA SHOWCASE COMPLETE ---")
      expect(result[:stdout]).to include("Factorial of 5 (Recursion):")
      expect(result[:stdout]).to include("I am Nexus v2.0")
    end

    it 'successfully compiles and executes the Data Science Showcase' do
      result = run_rv("#{science_showcase} --run")
      expect(result[:status].success?).to be true
      expect(result[:stdout]).to include("--- [RV] DATA SCIENCE MODE COMPLETE ---")
      expect(result[:stdout]).to include("Average Score (NumPy .mean()):")
    end
  end

  describe 'Ruby Frontend' do
    it 'successfully compiles and executes the Ruby Mega Showcase' do
      result = run_rv("#{ruby_showcase} --run")
      expect(result[:status].success?).to be true
      expect(result[:stdout]).to include("--- [RV] RUBY MEGA SHOWCASE COMPLETE ---")
      expect(result[:stdout]).to include("Ruby Factorial(5):")
      expect(result[:stdout]).to include("Stats for 10,000 Ruby-generated rows:")
    end
  end

  describe 'Error Handling' do
    it 'reports visual syntax errors with carets' do
      bad_code = File.expand_path('../../bad_code.py', __FILE__)
      result = run_rv(bad_code)
      expect(result[:status].success?).to be false
      expect(result[:stderr]).to include("[RV Compile Error]")
      expect(result[:stderr]).to include("^")
    end
  end
end
