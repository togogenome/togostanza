class OrganismHabitatStanza < TogoStanza::Stanza::Base
  property :selected_taxonomy_id do |tax_id|
    tax_id
  end

  resource :environment_tree do |tax_id|
    result = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX idorg:  <http://rdf.identifiers.org/database/>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>
      PREFIX taxid: <http://identifiers.org/taxonomy/>

      SELECT DISTINCT ?linage_meo_id ?label ?parent_meo_id ?is_sampled_meo
      FROM <http://togogenome.org/graph/refseq>
      FROM <http://togogenome.org/graph/gold>
      FROM <http://togogenome.org/graph/meo>
      WHERE
      {
        GRAPH <http://togogenome.org/graph/gold>
        {
          VALUES ?p_env { meo:MEO_0000437 meo:MEO_0000440 }
          ?gold_id mccv:MCCV_000020 taxid:103690.
          ?gold_id ?p_env ?meo_id .
        }
        GRAPH <http://togogenome.org/graph/meo>
        {
          ?meo_id rdfs:subClassOf* ?linage_meo_id .
          OPTIONAL { ?linage_meo_id rdfs:label ?label . }
          OPTIONAL { ?linage_meo_id rdfs:subClassOf ?parent_meo_id .}
          BIND ( IF(?meo_id = ?linage_meo_id, "TRUE","FALSE") AS ?is_sampled_meo) .
        }
      }
    SPARQL
    root = { :linage_meo_id => "http://www.w3.org/2002/07/owl#Thing", :label => "Root", :parent_meo_id => ""}
    result.push(root)
    result
  end
end
