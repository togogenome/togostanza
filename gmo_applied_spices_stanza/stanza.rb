class GmoAppliedSpicesStanza < TogoStanza::Stanza::Base
  property :applied_spices_list do |medium_id|
    query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>
      SELECT ?gmo_title ?label ?tax ?taxonomy_id
      WHERE {
        ?gmo gmo:GMO_000101 "#{medium_id}" .
        ?gmo gmo:GMO_000102 ?gmo_title .
        ?brc mccv:MCCV_000018 ?gmo .
        ?brc mccv:MCCV_000056 ?tax .
        OPTIONAL { ?tax rdfs:label ?label . }
        BIND('http://identifiers.org/taxonomy/' AS ?identifer) .
        BIND( REPLACE(STR(?tax), ?identifer, '') AS ?taxonomy_id ) .
        FILTER( CONTAINS(STR(?tax), ?identifer) )
      }
      ORDER BY ?label
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
