require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))
require 'mechanize'


lf = LanguageFinder.new(Mechanize.new) do |f|
  f.agent.get("http://www.wikipedia.org/wiki/List_of_programming_languages").search("#mw-content-text table.multicol li a").each do |a|
    f.language_links << a.attributes['href'].value
  end
end

lf.start_batch_search(20)
lf.create_json('languages.json')
lf.create_d3_format('languages.json','data_source.json')
