class EnvironmentInhabitantsStatisticsNanoStanza < TogoStanza::Stanza::Base
  property :inhabitants_stats do |meo_id|
    query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>
      SELECT (COUNT(DISTINCT ?gold) AS ?cnt)
      FROM <http://togogenome.org/graph/gold>
      FROM <http://togogenome.org/graph/meo>
      WHERE {
        VALUES ?meo_mapping { meo:MEO_0000437 meo:MEO_0000440 }
        # MEO_0000437: sampledFromEnv
        # MEO_0000440: sampledFromOrgan
        ?descendant rdfs:subClassOf* meo:#{meo_id} .
        ?gold ?meo_mapping ?descendant .
      }
    SPARQL
  end
end
