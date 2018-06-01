class EnvironmentInhabitantsStatisticsStanza < TogoStanza::Stanza::Base
  property :inhabitants_statistics do |meo_id|
    results = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>

      SELECT ?type ?cnt
      FROM <http://togogenome.org/graph/gold>
      FROM <http://togogenome.org/graph/meo>
      FROM <http://togogenome.org/graph/brc>
      WHERE
      {
        {
          SELECT ("GOLD" AS ?type) (COUNT(DISTINCT ?gold) AS ?cnt)
          {
            VALUES ?meo_mapping { meo:MEO_0000437 meo:MEO_0000440 }
            ?gold_meo_id rdfs:subClassOf* meo:#{meo_id} .
            ?gold ?meo_mapping ?gold_meo_id .
          }
        }
        UNION
        {
          SELECT ?type (COUNT(DISTINCT ?strain) AS ?cnt)
          {
            VALUES ?meo_strain_mapping { mccv:MCCV_000059 mccv:MCCV_000060 }
            ?strain_meo_id rdfs:subClassOf* meo:#{meo_id} .
            ?strain ?meo_strain_mapping ?strain_meo_id .
            BIND (IF(STRSTARTS(STR(?strain), "http://www.nbrc.nite.go.jp/"), "NBRC",IF(STRSTARTS(STR(?strain), "http://www.jcm.riken.go.jp/"),"JCM","")) AS ?type) .
          } GROUP BY ?type
        }
      }
    SPARQL
  end
end
