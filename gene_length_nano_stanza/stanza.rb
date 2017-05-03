require 'bio'
class GeneLengthNanoStanza < TogoStanza::Stanza::Base
  property :title do
    "Gene length"
  end

  property :result do |tax_id, gene_id|
    # At first selects a feature of gene.
    results = query("http://dev.togogenome.org/sparql-sd", <<-SPARQL.strip_heredoc)
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX obo:    <http://purl.obolibrary.org/obo/>
      PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
      PREFIX uniprot: <http://purl.uniprot.org/core/>

      SELECT ?insdc_location
      FROM <http://togogenome.org/graph/tgup>
      FROM <http://togogenome.org/graph/uniprot>
      FROM <http://togogenome.org/graph/refseq>
      {
        {
          SELECT ?feature
          {
            {
              <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
                rdfs:seeAlso/rdfs:seeAlso ?uniprot .
              ?uniprot a uniprot:Protein ;
                uniprot:sequence ?isoform .
              ?isoform rdf:value ?protein_seq .
              ?feature obo:so_part_of ?gene ;
                a insdc:Coding_Sequence ;
                insdc:translation ?translation .
              FILTER (?protein_seq = ?translation)
            }
            UNION
            {
              VALUES ?feature_type { insdc:Transfer_RNA insdc:Ribosomal_RNA insdc:Non_Coding_RNA }
              <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene .
              ?feature obo:so_part_of ?gene ;
                insdc:location ?insdc_location ;
                a ?feature_type .
            }
          } LIMIT 1
        }
        ?feature insdc:location ?insdc_location .
      }
    SPARQL

    if results.nil? || results.size == 0
      nil
      next
    end

    results.map {|hash|
      length = Bio::Locations.new(hash[:insdc_location]).length
      hash.merge(
        gene_length: length
      )
    }.first
  end
end
