require 'net/http'
require 'uri'

class NucleotideSequenceStanza < TogoStanza::Stanza::Base
  property :nucleotide_sequences do |tax_id, gene_id|
    # At first selects a feature of gene.
    results = query("http://dev.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX obo:    <http://purl.obolibrary.org/obo/>
      PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
      PREFIX uniprot: <http://purl.uniprot.org/core/>

      SELECT ?nuc_seq_pos
      {
        {
          SELECT ?feature
          {
            VALUES ?tggene { <http://togogenome.org/gene/#{tax_id}:#{gene_id}> }
            {
              GRAPH <http://togogenome.org/graph/tgup>
              {
                ?tggene skos:exactMatch ?gene ;
                  rdfs:seeAlso/rdfs:seeAlso ?uniprot .
              }
              GRAPH <http://togogenome.org/graph/uniprot>
              {
                ?uniprot a uniprot:Protein ;
                  uniprot:sequence ?isoform .
                ?isoform rdf:value ?protein_seq .
              }
              GRAPH <http://togogenome.org/graph/refseq>
              {
                VALUES ?feature_type { insdc:Coding_Sequence }
                ?feature obo:so_part_of ?gene ;
                  a ?feature_type ;
                  insdc:translation ?translation .
              }
              FILTER (?protein_seq = ?translation)
            }
            UNION
            {
              GRAPH <http://togogenome.org/graph/tgup>
              {
                ?tggene skos:exactMatch ?gene .
              }
              GRAPH <http://togogenome.org/graph/refseq>
              {
                VALUES ?feature_type { insdc:Transfer_RNA insdc:Ribosomal_RNA insdc:Non_Coding_RNA }
                ?feature obo:so_part_of ?gene ;
                  insdc:location ?insdc_location ;
                  a ?feature_type .
              }
            }
          } LIMIT 1
        }
        GRAPH <http://togogenome.org/graph/refseq>
        {
          ?feature insdc:location ?insdc_location ;
            obo:so_part_of/obo:so_part_of/^insdc:sequence/insdc:sequence_version ?refseq_ver  .
          BIND (CONCAT("http://togows.dbcls.jp/entry/nucleotide/", ?refseq_ver,"/seq/", ?insdc_location) AS ?nuc_seq_pos)
        }
      }
    SPARQL

    if results.nil? || results.size == 0
      nil
      next
    end

    results.map {|hash|
      hash.merge(
        value: get_sequence_from_togows(hash[:nuc_seq_pos]).upcase
      )
    }.first
  end

  #Returns sequence characters from the TogoWS API.
  def get_sequence_from_togows(togows_url)
    url = URI.parse(togows_url)
    path = Net::HTTP::Get.new(url.path)
    Net::HTTP.start(url.host, url.port) {|http|
      res = http.request(path)
      res.body
    }
  end
end
