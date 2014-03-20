require 'json'
require 'uri'
require 'mechanize'

class LanguageFinder
  attr_accessor :languages
  attr_accessor :language_links
  attr_accessor :agent

  def initialize(agent=Mechanize.new, &block)
    @languages = {}
    @language_links = []
    @agent = agent
    block.call(self) if block
  end

  #Search method returns true if path exists, false otherwise
  def search(path)
    language_key = get_language_key(path)

    begin
      page = @agent.get("http://www.wikipedia.org#{path}")
      influenced = get_influenced_languages(page)
      @languages[language_key]= {influenced: [], href: path}

      if not influenced.nil?
        Mutex.new.synchronize do
          find_and_assign_influenced_languages(influenced, language_key,path)
        end
      else
        return false
      end
    rescue Exception => ex
      p ex
    end
    return true
  end

  def find_and_assign_influenced_languages(influenced, language_key, path)
    influenced.search('+td > a').each do |a|
      key = parse_link_to_get_key(a)
      if not key.match(/index.php.*/) #broken link
        @languages[language_key][:influenced] << key
      end
    end
  end

  def parse_link_to_get_key(a)
    link = a.attributes['href'].value
    influenced_path = link.split('/').last
    return URI.decode(influenced_path.split("_(").first)
  end

  def get_influenced_languages(page)
    page.search("table.infobox tr th:contains('Influenced')").last
  end

  def get_language_key(path)
    URI.decode(path.split('/').last.split("_(").first)
  end

  def start_batch_search(num_of_threads)
    threads = []
    count = -1
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

  def create_json(filename)
    json = JSON.pretty_generate(@languages)
    open(filename, 'w') do |f|
      f.write(json)
    end
    return json
  end

  def create_d3_format(source_filename, target_filename)
    json = open(source_filename).read
    data_source = []
    JSON.parse(json).each do |k, v|
      v['influenced'].each do |l|
        data_source << {source: URI.decode(k), target: URI.decode(l), count: v["influenced"].size, href: v["href"]}
      end
    end

    data_source_json = JSON.pretty_generate(data_source)
    open(target_filename, 'w') do |f|
      f.write(data_source_json)
    end
    return data_source_json
  end

end
