require 'rails_helper'

describe LiquidInterpolatable::Filters::ExtractDomain do
  before do
    @context = Liquid::Context.new
    @filter = Object.new
    @filter.extend(LiquidInterpolatable::Filters::ExtractDomain)
  end

  it 'extracts domain from http url' do
    expect(@filter.extract_domain('http://www.example.com/path')).to eq('www.example.com')
  end

  it 'extracts domain from https url' do
    expect(@filter.extract_domain('https://sub.example.co.uk/path?q=1')).to eq('sub.example.co.uk')
  end

  it 'strips www when requested with true' do
    expect(@filter.extract_domain('https://www.example.com/path', true)).to eq('example.com')
  end

  it 'strips www when requested with "true" string' do
    expect(@filter.extract_domain('https://www.example.com/path', 'true')).to eq('example.com')
  end

  it 'does not strip www when requested with false' do
    expect(@filter.extract_domain('https://www.example.com/path', false)).to eq('www.example.com')
  end

  it 'returns input if not http/https/ftp' do
    expect(@filter.extract_domain('mailto:test@example.com')).to eq('mailto:test@example.com')
    expect(@filter.extract_domain('example.com')).to eq('example.com')
  end

  it 'returns input on invalid uri' do
    expect(@filter.extract_domain('http://[invalid]/path')).to eq('http://[invalid]/path')
  end

  it 'returns blank for blank input' do
    expect(@filter.extract_domain('')).to eq('')
    expect(@filter.extract_domain(nil)).to be_nil
  end
end
