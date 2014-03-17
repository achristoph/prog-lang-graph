require 'json'
require 'uri'

file = open('languages.json')
json = file.read
languages_with_influenced = JSON.parse(json)
p h.size
data_source = []
languages_with_fluenced.each do |k,v|
  v["fluenced"].each do |l|
    data_source << {source: URI.decode(k), target: URI.decode(l), count:v["fluenced"].size}
  end
end

open('data_source.json','w') do |f|
  f.write(JSON.pretty_generate(data_source))
end
