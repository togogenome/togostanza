class EnvironmentInhabitantsStatisticsBrcStanza < TogoStanza::Stanza::Base
  property :inhabitants_statistics do |meo_id|
    results = query("http://sparql-app.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mccv: <http://purl.jp/bio/10/mccv#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>
      PREFIX sio:  <http://semanticscience.org/resource/>

      SELECT ?type ?cnt
      FROM <http://togogenome.org/graph/gold>
      FROM <http://togogenome.org/graph/meo0.9>
      FROM <http://togogenome.org/graph/nbrc>
      FROM <http://togogenome.org/graph/jcm>
      WHERE
      {
        {
          SELECT ("NBRC" AS ?type) (COUNT(DISTINCT ?strain) AS ?cnt)
          {
            VALUES ?search_meo_id { meo:#{meo_id} }
            ?search_meo_id a owl:Class .
            ?meo_id rdfs:subClassOf* ?search_meo_id .
            ?strain mccv:MCCV_000028/mccv:MCCV_000072/sio:SIO_000008 ?meo_id .
          }
        }
        UNION
        {
          SELECT ("JCM" AS ?type) (COUNT(DISTINCT ?strain) AS ?cnt)
          {
            VALUES ?search_meo_id { meo:#{meo_id} }
            ?search_meo_id a owl:Class .
            ?meo_id rdfs:subClassOf* ?search_meo_id .
            ?strain mccv:MCCV_000028/mccv:MCCV_000072/mccv:MCCV_000071 ?meo_id .

          }
        }
        UNION
        {
          SELECT ("GOLD" AS ?type) (COUNT(DISTINCT ?gold) AS ?cnt)
          {
            VALUES ?meo_mapping { meo:MEO_0000437 meo:MEO_0000440 }
            ?gold_meo_id rdfs:subClassOf* meo:#{meo_id} .
            ?gold ?meo_mapping ?gold_meo_id .
          }
        }
      }
    SPARQL
  end
end
