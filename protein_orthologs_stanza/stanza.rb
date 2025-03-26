class ProteinOrthologsStanza < TogoStanza::Stanza::Base
  property :orthologs do |tax_id, gene_id|
    protein_attributes = query("https://sparql-app.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX up: <http://purl.uniprot.org/core/>

      SELECT ?protein
      FROM <http://togogenome.org/graph/tgup>
      FROM <http://togogenome.org/graph/uniprot>
      WHERE
      {
        <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
          rdfs:seeAlso ?id_upid .
        ?id_upid rdfs:seeAlso ?protein .
        ?protein a up:Protein ;
          up:reviewed ?reviewed .
      } ORDER BY DESC(?reviewed) LIMIT 1
    SPARQL

    if protein_attributes.nil? || protein_attributes.size.zero?
      next nil
    end

    uniprot_uri = protein_attributes.first[:protein]
    ortholog_uris = query("http://bias5-db.nibb.ac.jp:8047/sparql/", <<-SPARQL.strip_heredoc)
      PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
      PREFIX orth: <http://purl.jp/bio/11/orth#>
      PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>

      SELECT DISTINCT ?protein
      WHERE
      {
        ?group a orth:OrthologGroup ;
          orth:inDataset mbgdr:default ;
          orth:member/orth:gene/mbgd:uniprot <#{uniprot_uri}> ;
          orth:member/orth:gene/mbgd:uniprot ?protein .
      }
    SPARQL

    if ortholog_uris.nil? || ortholog_uris.size.zero?
      next nil
    end

    ortholog_uris.map {|hash|
      hash[:protein_label] = hash[:protein].gsub('http://purl.uniprot.org/uniprot/','')
    }
    ortholog_uris.last[:is_last_data] = true
    ortholog_uris
  end
end
