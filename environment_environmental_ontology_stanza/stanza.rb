class EnvironmentEnvironmentalOntologyStanza < TogoStanza::Stanza::Base
  property :select_meo_style do |meo_id|
      select_meo_style = meo_id.blank? ? "" : "#" + meo_id + ".node text \{fill:red;font-size:20px;\}"
  end

  property :select_meo_id do |meo_id|
      select_meo_id = meo_id
  end

  resource :meo_ontology_tree do
    results = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>
      PREFIX owl: <http://www.w3.org/2002/07/owl#>

      SELECT ?meo_id ?label ?definition ?parent
      FROM <http://togogenome.org/graph/meo>
      WHERE
      {
       ?meo_id a owl:Class .
       OPTIONAL {?meo_id rdfs:label ?label}
       OPTIONAL {?meo_id meo:MEO_0000443 ?definition}
       OPTIONAL {?meo_id rdfs:subClassOf ?parent}
      }
    SPARQL
    root = {:meo_id => "http://www.w3.org/2002/07/owl#Thing", :label => "Thing", :definition => "root", :parent => "root"}
    results.push(root)
    results.map {|hash|
      hash.merge(
        :tag_id => hash[:meo_id].split('/').last.split('#').last,
        :link => "http://togogenome.org/environment/" + hash[:meo_id].split('/').last.split('#').last
      )
    }
  end
end
