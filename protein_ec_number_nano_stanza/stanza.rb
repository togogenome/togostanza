class ProteinEcNumberNanoStanza < TogoStanza::Stanza::Base
  property :feature do |tax_id, gene_id|
    query("http://dev.togogenome.org/sparql", <<-SPARQL.strip_heredoc).first
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX up: <http://purl.uniprot.org/core/>

      SELECT ?ec_number
      FROM <http://togogenome.org/graph/uniprot>
      FROM <http://togogenome.org/graph/tgup>
      WHERE {
        {
          SELECT ?protein
          {
            <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
              rdfs:seeAlso ?id_upid .
            ?id_upid rdfs:seeAlso ?protein .
            ?protein a up:Protein ;
              up:reviewed ?reviewed .
          } ORDER BY DESC(?reviewed) LIMIT 1
        }
        ?protein up:recommendedName ?recommended_name_node .
        ?recommended_name_node up:ecName ?ec_number .
      }
    SPARQL
  end
end
