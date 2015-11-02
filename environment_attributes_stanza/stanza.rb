class EnvironmentAttributesStanza < TogoStanza::Stanza::Base
  property :environment_attr do |meo_id|
    results = query("http://togogenome.org/sparql", 'query.hbs')

    results.first
  end
end
