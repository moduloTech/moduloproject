# frozen_string_literal: true

RSpec.describe Moduloproject do
  it 'has a version number' do
    expect(Moduloproject::VERSION).not_to be_nil
  end

  it 'has version 3.0.1' do
    expect(Moduloproject::VERSION).to eq('3.0.1')
  end
end
