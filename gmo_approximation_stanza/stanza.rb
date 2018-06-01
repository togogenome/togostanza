class GmoApproximationStanza < TogoStanza::Stanza::Base
  SPARQL_ENDPOINT_URL = 'http://dev.togogenome.org/sparql-app'

  property :medium_information do |medium_id|
    query = <<-SPARQL.strip_heredoc
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>
      SELECT distinct ?desc
      FROM <http://togogenome.org/graph/brc>
      WHERE {
        ?brc gmo:GMO_000101 "#{medium_id}" .
        ?brc gmo:GMO_000102 ?desc .
      }
    SPARQL

    result = query(SPARQL_ENDPOINT_URL, query)

    unless result.empty?
      result.first[:med_id] = medium_id
    end

    result
  end

  property :medium_score do |medium_id|
    # Score List
    query = <<-SPARQL.strip_heredoc
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>
      SELECT ?subject ?medium_id ?title ?index AS ?index2 COUNT(?object) AS ?count2 ?original (ROUND((2.0*?index)/(COUNT(?object)+?original)*1000.0)/10.0) AS ?score
      FROM <http://togogenome.org/graph/brc>
      FROM <http://togogenome.org/graph/gmo>
      WHERE {
        {
          SELECT ?subject ?medium_id ?title SUM(?found) AS ?index WHERE {
          SELECT ?subject ?medium_id ?title ?list MAX(?found_src) AS ?found
            WHERE {
              ?key gmo:GMO_000101 "#{medium_id}" .
              ?subject gmo:GMO_000101 ?medium_id .
              ?subject gmo:GMO_000104 ?list .
              MINUS { ?key gmo:GMO_000104 ?list }

              ?list rdfs:subClassOf* ?cla .
              FILTER( isURI(?cla) && ?cla IN (gmo:GMO_000015, gmo:GMO_000016) )

              OPTIONAL { ?subject gmo:GMO_000102 ?title }.

              ?list rdfs:label ?label .
              FILTER( LANG(?label) != "ja" ) .

              {
                SELECT distinct ?search_keys
                WHERE {
                  ?brc gmo:GMO_000101 "#{medium_id}" .
                  ?brc gmo:GMO_000104 ?s .
                  ?s rdfs:subClassOf* ?cla .
                  FILTER( isURI(?cla) && ?cla IN (gmo:GMO_000015,gmo:GMO_000016) )
                  ?s rdfs:label ?label .
                  FILTER( LANG(?label) != "ja" )
                  BIND( REPLACE(LCASE(?label), "(monohydrate|dihydrate|trihydrate|tetrahydrate|pentahydrate|hexahydrate|hesahydrate|heptahydrate|heptaphydreate|octahydrate|nanohydrate|n-hydrate|x-hydrate)", "") AS ?search_keys)
                }
              } .
              BIND( CONTAINS(LCASE(?label), ?search_keys) AS ?found_src ) .
              FILTER( ?found_src != 0 ) .
            }
            ORDER BY ?subject ?list}
        }
        UNION {
          SELECT ?subject ?medium_id ?title SUM(?found) AS ?index WHERE {
            ?key gmo:GMO_000101 "#{medium_id}" .
            ?key gmo:GMO_000104 ?list .
            ?list rdfs:subClassOf* ?cla .
            FILTER( isURI(?cla) && ?cla IN (gmo:GMO_000015,gmo:GMO_000016) )
            ?subject gmo:GMO_000104 ?list .
            ?subject gmo:GMO_000101 ?medium_id .
            FILTER( ?subject != ?key )

            OPTIONAL { ?subject gmo:GMO_000102 ?title }.
            BIND( 1 AS ?found ) .
          }
        } .
        OPTIONAL {
          SELECT COUNT(distinct ?oriobj) AS ?original WHERE {
            ?orisub gmo:GMO_000101 "#{medium_id}" .
            ?orisub gmo:GMO_000104 ?oriobj .
            ?oriobj rdfs:subClassOf* ?cla .
            FILTER( isURI(?cla) && ?cla IN (gmo:GMO_000015, gmo:GMO_000016) )
          }
        }
        OPTIONAL {
          ?subject gmo:GMO_000104 ?object .
          ?object rdfs:subClassOf* ?cla .
          filter( isURI(?cla) && ?cla IN (gmo:GMO_000015, gmo:GMO_000016) )
        } .
      }
      ORDER BY DESC(?score) ?title
    SPARQL

    scorelist = query(SPARQL_ENDPOINT_URL, query)


    # Is Binded Undefined Components from Request Mediums
    query = <<-SPARQL.strip_heredoc
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>
      SELECT DISTINCT COUNT(?brc) AS ?c {
        ?brc gmo:GMO_000101 "#{medium_id}" .
        ?brc gmo:GMO_000104 ?gmo .
        ?gmo rdfs:subClassOf* gmo:GMO_000016 .
      }
    SPARQL

    is_ud = query(SPARQL_ENDPOINT_URL, query)


    # Get Undefined Components Binding List
    query = <<-SPARQL.strip_heredoc
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>
      SELECT DISTINCT ?brc {
        ?brc gmo:GMO_000104 ?gmo .
        ?gmo rdfs:subClassOf* gmo:GMO_000016 .
      }
    SPARQL
    udlist = query(SPARQL_ENDPOINT_URL, query).map {|item| item[:brc] }


    if is_ud.first[:c].to_i.zero?
      # ignore undefined components
      scorelist.delete_if {|item| udlist.index(item[:subject]) }
    else
      # ignore defined components
      scorelist.delete_if {|item| udlist.index(item[:subject]).nil? }
    end

    # format number (ex. 12.0)
    scorelist.map {|item|
      item[:score] = sprintf('%.1f',item[:score])
      item
    }

    scorelist
  end
end
