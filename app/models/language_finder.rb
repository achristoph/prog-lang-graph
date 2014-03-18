require 'mechanize'
require 'json'
require 'uri'

class LanguageFinder
  attr_accessor :languages
  attr_accessor :language_links
  attr_accessor :agent

  def initialize
    @languages = {}
    @language_links = []
    @agent = Mechanize.new
    yield(self) if block_given?
  end

  def search(path)
    language_key = URI.decode(path.split('/').last.split("_(").first)
    p language_key

    begin
      page = @agent.get("http://www.wikipedia.org#{path}")
    rescue Exception => ex
      retry if ex.message == "can't add a new key into hash during iteration"
      return
    end

    @languages[language_key]= {influenced: [], href:path}

    influenced = page.search("table.infobox tr th:contains('Influenced')").last

    if not influenced.nil?
      influenced.search("+td > a").each do |a|
        link = a.attributes['href'].value
        influenced_path = link.split('/').last
        key = influenced_path.split("_(").first
        if not key.match(/index.php.*/) #broken link
          @languages[language_key][:influenced] << URI.decode(key)
        end
      end
    end
  end

  def start_batch_search(num_of_threads)
    threads = []
    count = 0
    while count < @language_links.size
      1.upto(num_of_threads) do |i|
        break if count+i >= @language_links.size
        threads << Thread.new do
          search(@language_links[count+i])
        end
      end

      threads.each do |thread|
        thread.join unless thread.nil?
      end

      threads = []
      count += num_of_threads
    end
  end

  def create_json
    open('languages.json', 'w') do |f|
      f.write(JSON.pretty_generate(@languages))
    end
  end

  def create_d3_format
    json = open('languages.json').read
    data_source = []

    JSON.parse(json).each do |k,v|
      v["influenced"].each do |l|
        data_source << {source: URI.decode(k), target: URI.decode(l), count:v["influenced"].size, href:v["href"]}
      end
    end

    open('data_source.json','w') do |f|
      f.write(JSON.pretty_generate(data_source))
    end
  end
end
