class OrganismRelatedDiseaseNanoStanza < TogoStanza::Stanza::Base
  property :list_disease do |tax_id|
    results = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX pdo: <http://purl.jp/bio/11/pdo/>
      PREFIX tax: <http://identifiers.org/taxonomy/>
      SELECT DISTINCT ?pdo_id ?label
      FROM <http://togogenome.org/graph/pdo>
      FROM <http://togogenome.org/graph/pdo_mapping>
      WHERE {
        tax:#{tax_id} pdo:isAssociatedTo ?bk .
        ?bk ?p ?pdo_id .
        ?pdo_id rdfs:label ?label
        FILTER(regex(?pdo_id, "PDO"))
      }
    SPARQL

    if results.empty?
      '/stanza/assets/no_data.svg'
    else
      '/stanza/assets/organism_related_disease_nano/pathogen.svg'
    end
  end
end
