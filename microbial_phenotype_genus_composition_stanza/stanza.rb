class MicrobialPhenotypeGenusCompositionStanza < TogoStanza::Stanza::Base
  SPARQL_ENDPOINT_URL = 'http://dev.togogenome.org/sparql-app'

  property :general do |mpo_id|
    result = query(SPARQL_ENDPOINT_URL, <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mpo:  <http://purl.jp/bio/01/mpo#>
      SELECT ?label
      WHERE {
       mpo:#{mpo_id} rdfs:label ?label .
       FILTER( LANG(?label) != "ja" )
      }
    SPARQL

    (result.nil?) ? [] : result.first
  end

  property :features do |mpo_id|
    query = <<-SPARQL.strip_heredoc
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mpo: <http://purl.jp/bio/01/mpo#>
      PREFIX taxonomy: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>

      SELECT DISTINCT ?genus ?list2 count(*) AS ?cnt
      FROM <http://togogenome.org/graph/taxonomy>
      FROM <http://togogenome.org/graph/gold>
      FROM <http://togogenome.org/graph/mpo>
      WHERE {
        ?mpo_list rdfs:subClassOf* mpo:#{mpo_id} .
        ?subject ?pre ?mpo_list .
        BIND('http://identifiers.org/taxonomy/' AS ?identifer) .
        FILTER( CONTAINS(STR(?subject),?identifer) ) .
        OPTIONAL {
          ?subject rdfs:subClassOf* ?list2 .
          ?list2 taxonomy:rank taxonomy:Genus .
          ?list2 rdfs:label ?genus
          FILTER( LANG(?genus) != "ja" )
        }
      }
      GROUP BY ?genus ?list2
      ORDER BY DESC(?cnt)
    SPARQL

    query(SPARQL_ENDPOINT_URL, query)
  end
end
