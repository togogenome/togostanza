class Protein3dStructureNanoStanza < TogoStanza::Stanza::Base
  property :pdb do |tax_id, gene_id|
    result = query("http://togogenome.org/sparql-app", <<-SPARQL.strip_heredoc).first
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX up: <http://purl.uniprot.org/core/>

      SELECT ?protein ?pdb_uri
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
        ?protein rdfs:seeAlso ?pdb_uri .
        ?pdb_uri a up:Structure_Resource .
      }
    SPARQL

    if result
      result.merge(img_url: "http://www.rcsb.org/pdb/images/#{result[:pdb_uri][-4, 4].downcase!}_bio_r_500.jpg")
    else
      nil
    end
  end
end
