class GmoGenusStanza < TogoStanza::Stanza::Base
  property :genus_list do |medium_id|
    query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>
      PREFIX taxonomy:  <http://ddbj.nig.ac.jp/ontologies/taxonomy/>
      SELECT ?genus ?list2 count(*) AS ?cnt
      WHERE {
        ?gmo gmo:GMO_000101 "#{medium_id}" .
        ?brc mccv:MCCV_000018 ?gmo .
        ?brc mccv:MCCV_000056 ?tax .
        OPTIONAL {
          ?tax rdfs:subClassOf* ?list2 .
          ?list2 taxonomy:rank taxonomy:Genus .
          ?list2 rdfs:label ?genus
        }
        BIND('http://identifiers.org/taxonomy/' AS ?identifer) .
        FILTER( CONTAINS(STR(?tax), ?identifer) )
      }
      ORDER BY DESC(?cnt)
    SPARQL
  end

  property :general_information do |medium_id|
    query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>
      SELECT ?gmo_title
      WHERE {
        ?gmo gmo:GMO_000101 "#{medium_id}" .
        ?gmo gmo:GMO_000102 ?gmo_title .
      }
    SPARQL
  end
end
