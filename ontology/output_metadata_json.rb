#!/usr/bin/env ruby

require 'json'

if ARGV.size < 1
  STDERR.puts "Usage: output_metadata_json.rb [output file path]"
  exit 1
end


def jsonld_keys(obj, prefix)
  case obj
  when Array
    obj.map{|e| jsonld_keys(e, prefix)}
  when Hash
    obj.inject({}) do |hash, (k, v)|
      hash[prefix + ':' + k] = jsonld_keys(v, prefix)
      hash
    end
  else
    obj
  end
end

base_dir = File.expand_path("../..", __FILE__)
stanza_list = []
Dir.glob("#{base_dir}/*_stanza/metadata.json").each do |file|
  metadata = JSON.parse(File.read(file))
 
  jsonld_metadata = {}
  stanza_id = metadata.delete('id')
  # deprecated stanzas
  if stanza_id == 'genome_genomic_context' || stanza_id == 'js_stanza_wrapper' || stanza_id == 'organism_gene_list'
    next
  end

  # @id
  jsonld_metadata['@id'] = 'http://togostanza.org/stanza/' + stanza_id
  # add prefix to jsonld
  jsonld_metadata.merge!(jsonld_keys(metadata, 'stanza'))
  # usage
  usage_param_list = []
  jsonld_metadata['stanza:parameter'].each do |param|
    usage_param_list.push(param['stanza:key'] + '="' + param['stanza:example'] + '"')
  end
  jsonld_metadata['stanza:usage'] = "<div data-stanza=\"http://togostanza.org/stanza/#{stanza_id}\" #{usage_param_list.join(' ')}></div>"
  # delete param prefix 'data-stanza-' and '-' to '_'
  jsonld_metadata['stanza:parameter'].each do |param|
     param['stanza:key'] = param['stanza:key'].gsub('data-stanza-','').gsub('-', '_')
  end
  jsonld_metadata['stanza:implemented'] = "ruby"
  jsonld_metadata['stanza:host'] = "http://togostanza.org/stanza/"
  stanza_list.push(jsonld_metadata)
end

metadata_json = {
  '@context': { 'stanza': "http://togostanza.org/resource/stanza#"},
  'stanza:stanzas': stanza_list
}

# output json file
output_file_path = ARGV[0]
if output_file_path =~ /^\//
  output_file = output_file_path
else
  output_file = File.expand_path("../#{output_file_path}", __FILE__)
end
File.open(output_file, mode = "w") do |f|
  f.puts JSON.pretty_generate(metadata_json)
end
