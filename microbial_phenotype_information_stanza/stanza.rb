class MicrobialPhenotypeInformationStanza < TogoStanza::Stanza::Base
  SPARQL_ENDPOINT_URL = 'http://dev.togogenome.org/sparql-app'

  property :features do |mpo_id|
    query = <<-SPARQL.strip_heredoc
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mpo:  <http://purl.jp/bio/01/mpo#>
      PREFIX taxonomy:  <http://ddbj.nig.ac.jp/ontologies/taxonomy/>

      SELECT distinct ?subject ?taxonomy_id ?title Group_Concat(?pheno,', ') AS ?pheno_merged ?genus
      FROM <http://togogenome.org/graph/taxonomy>
      FROM <http://togogenome.org/graph/gold>
      FROM <http://togogenome.org/graph/mpo>
      WHERE {
        ?list rdfs:subClassOf* mpo:#{mpo_id} .
        ?subject ?pre ?list .
        OPTIONAL {
          ?subject rdfs:subClassOf* ?list2 .
          ?list2 taxonomy:rank taxonomy:Genus .
          ?list2 rdfs:label ?genus .
        }
        OPTIONAL { ?subject rdfs:label ?title } .
        OPTIONAL { ?list rdfs:label ?pheno . FILTER( LANG(?pheno) != "ja" )}
        BIND('http://identifiers.org/taxonomy/' AS ?identifer) .
        BIND( REPLACE(STR(?subject), ?identifer, '') AS ?taxonomy_id ) .
        FILTER( CONTAINS(STR(?subject),?identifer) )
      }
      ORDER BY ?genus ?title
    SPARQL

    result = query(SPARQL_ENDPOINT_URL, query)

    result.partition {|item| item[:title] }.flatten # move last in empty title data
      .group_by {|item| item[:genus] } # genus grouping
      .map {|key, val| {row_key: key, row_value: val} }
      .partition {|item| item[:row_key] }.flatten # move last in empty genus data
  end
end
