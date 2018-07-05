class MicrobialPhenotypeEnvironmentCompositionStanza < TogoStanza::Stanza::Base
  SPARQL_ENDPOINT_URL = 'http://dev.togogenome.org/sparql-app'

  property :general do |mpo_id|
    result = query(SPARQL_ENDPOINT_URL, <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mpo:  <http://purl.jp/bio/01/mpo#>
      SELECT ?label
      WHERE {
        mpo:#{mpo_id} rdfs:label ?label .
        FILTER(LANG(?label) = "en")
      }
    SPARQL

    (result.nil?) ? [] : result.first
  end

  property :features do |mpo_id|
    query(SPARQL_ENDPOINT_URL, <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mpo:  <http://purl.jp/bio/01/mpo#>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>
      PREFIX tax: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>

      SELECT
       ?environment
       (REPLACE(STR(?meo), 'http://purl.jp/bio/11/meo/', '') AS ?meo_id)
       COUNT(DISTINCT(?tax_id)) AS ?cnt
      FROM <http://togogenome.org/graph/taxonomy>
      FROM <http://togogenome.org/graph/gold>
      FROM <http://togogenome.org/graph/mpo>
      FROM <http://togogenome.org/graph/meo>
      WHERE
      {
        VALUES ?mpo_id { mpo:#{mpo_id} }
        ?mpo_list rdfs:subClassOf* ?mpo_id .
        ?tax_id ?mpo_prop ?mpo_list .
        ?tax_id a tax:Taxon .
        OPTIONAL
       {
          ?gold mccv:MCCV_000020 ?tax_id .
          ?gold meo:MEO_0000437  ?meo .
          ?meo rdfs:label ?environment .
        }
      } GROUP BY ?meo ?environment ORDER BY DESC(?cnt)
    SPARQL
  end
end
