require 'spec_helper'

describe LanguageFinder do
  include RSpec::Mocks::ExampleMethods

  subject(:language_link_ruby) { 'http://www.wikipedia.org/wiki/Ruby_(programming_language)' }
  subject(:language_link_python) { 'http://www.wikipedia.org/wiki/Python_(programming_language)' }
  subject(:language_links) { [language_link_ruby, language_link_python] }

  subject(:lf) do
    agent = double('agent')
    LanguageFinder.new(agent)
  end

  it 'has its initialization to accept a block' do
    agent = double('agent')
    expect { |block| LanguageFinder.new(&block) }.to yield_control
  end

  it 'initializes language_links' do
    language_finder = LanguageFinder.new do |f|
      language_links.each do |a|
        f.language_links << a
      end
    end
    expect(language_finder.language_links.size).to eq(2)
    expect(language_finder.language_links.first).to eq(language_link_ruby)
    expect(language_finder.language_links.last).to eq(language_link_python)
  end

  it 'parses a language link to a language key' do
    language_key = lf.get_language_key(language_link_ruby)
    expect(language_key).to eq('Ruby')
  end

  it 'handles the exception if the wiki url of the language does not exist' do
    agent = double('agent')
    lf.agent = agent
    allow(agent).to receive(:get).and_raise(RuntimeError, "raises error for non-existent url")
    expect(lf.search(language_link_ruby)).not_to(raise_error)
  end

  it 'returns false if path does not exist' do
    initialize_language_finder_with_agent_double
    allow(lf).to receive(:get_influenced_languages).and_return(nil)
    expect(lf.search('non-existent path')).to eq(false)
  end

  it 'returns true if path exists' do
    initialize_language_finder_with_agent_double
    allow(lf).to receive(:get_influenced_languages).and_return(anything)
    allow(lf).to receive(:find_and_assign_influenced_languages)
    expect(lf.search('non existence path')).to eq(true)
  end

  it 'parses a link with programming_language suffix correctly to get the key' do
    a = double('a')
    link_attributes = double('link_attributes')
    link_href_attribute_value = double('link_href_attribute_value')
    allow(a).to receive(:attributes).and_return(link_attributes)
    allow(link_attributes).to receive(:[]).and_return(link_href_attribute_value)
    allow(link_href_attribute_value).to receive(:value).and_return(language_link_ruby)
    expect(lf.parse_link_to_get_key(a)).to eq('Ruby')
  end

  it 'parses a link with decoded special characters suffix correctly to get the key' do
    a = double('a')
    link_attributes = double('link_attributes')
    link_href_attribute_value = double('link_href_attribute_value')
    allow(a).to receive(:attributes).and_return(link_attributes)
    allow(link_attributes).to receive(:[]).and_return(link_href_attribute_value)
    allow(link_href_attribute_value).to receive(:value).and_return('http://en.wikipedia.org/wiki/C%2B%2B')
    expect(lf.parse_link_to_get_key(a)).to eq("C++")
  end

  it 'finds and assigns influenced languages correctly' do
    influenced = double('influenced')
    language_key = 'Ruby'
    path = '/wiki/Ruby'
    lf.languages[language_key]= {influenced: [], href: path}
    allow(influenced).to receive(:search).and_return(['a link'])
    allow(lf).to receive(:parse_link_to_get_key).and_return('Ruby')
    lf.find_and_assign_influenced_languages(influenced, language_key, path)
    expect(lf.languages[language_key][:influenced].first).to eq('Ruby')
  end

  it 'ignores non-existent influenced language link' do
    influenced = double('influenced')
    language_key = ''
    path = ''
    lf.languages[language_key]= {influenced: [], href: path}
    allow(influenced).to receive(:search).and_return(['a link'])
    allow(lf).to receive(:parse_link_to_get_key).and_return('index.php/abc')
    lf.find_and_assign_influenced_languages(influenced, language_key, path)
    expect(lf.languages[language_key][:influenced].size).to eq(0)
  end

  it 'start batch search' do
    lf.language_links = language_links
    allow(lf).to receive(:search).with(an_instance_of(String))
    expect(lf).to receive(:search).exactly(1).times
    lf.start_batch_search(1)
  end

  it 'creates json output file' do
    lf.languages =
        {A_Sharp: {influenced: ["Aldor"], href: "/wiki/A_Sharp_(Axiom)"}}
    file = Tempfile.new('languages.json')
    begin
      json = lf.create_json(file)
      expect(JSON.parse(json)).to eq({"A_Sharp" => {"influenced" => ["Aldor"], "href" => "/wiki/A_Sharp_(Axiom)"}})
    ensure
      file.close
    end
  end

  it 'creates d3 format' do
    file = Tempfile.new('languages.json')
    begin
      file.write('{ "A_Sharp": {
    "influenced": [
      "Aldor"
    ],
    "href": "/wiki/A_Sharp_(Axiom)"
    } }')
      file.rewind
      d3_json = lf.create_d3_format(file, 'data_source.json')
      expect(JSON.parse(d3_json)).to eq([{"source" => "A_Sharp", "target" => "Aldor", "count" => 1, "href" => "/wiki/A_Sharp_(Axiom)"}])
    ensure
      file.close
    end
  end

  def initialize_language_finder_with_agent_double
    agent = double('agent')
    page = double('page')
    lf.agent = agent
    allow(agent).to receive(:get).with(an_instance_of(String)).and_return(page)
  end

end
