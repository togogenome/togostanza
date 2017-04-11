require 'net/http'
require 'uri'
require 'bio'

class GeneAttributesStanza < TogoStanza::Stanza::Base
  property :gene_attributes do |tax_id, gene_id|
    results = query("http://togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX obo:    <http://purl.obolibrary.org/obo/>
      PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
      PREFIX uniprot: <http://purl.uniprot.org/core/>
      PREFIX faldo: <http://biohackathon.org/resource/faldo#>

      SELECT DISTINCT
        ?locus_tag ?gene_type_label ?gene_name
        ?refseq_link ?seq_label ?seq_type_label ?refseq_label ?organism ?tax_link
        ?strand ?insdc_location
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
          #feature info
          VALUES ?feature_type { obo:SO_0000316 obo:SO_0000252 obo:SO_0000253 obo:SO_0000655 } #CDS,rRNA,tRNA,ncRNA
          ?feature rdfs:subClassOf ?feature_type ;
            rdfs:label ?gene_label .

          #sequence / organism info
          ?feature obo:so_part_of* ?seq .
          ?seq rdfs:subClassOf ?seq_type .
          ?refseq_link insdc:sequence ?seq ;
            insdc:definition ?seq_label ;
            insdc:sequence_version ?refseq_label ;
            insdc:sequence_version ?refseq_ver ;
            insdc:organism ?organism .
          ?feature obo:RO_0002162 ?tax_link .

          #location info
          ?feature insdc:location  ?insdc_location ;
            faldo:location  ?faldo .
          ?faldo faldo:begin/rdf:type ?strand_type .

          OPTIONAL { ?feature insdc:gene ?gene_name }
          OPTIONAL { ?feature insdc:locus_tag ?locus_tag }
        }
        GRAPH <http://togogenome.org/graph/so>
        {
          ?feature_type rdfs:label ?gene_type_label .
          ?seq_type rdfs:label ?seq_type_label .
        }
        GRAPH <http://togogenome.org/graph/faldo>
        {
          ?strand_type rdfs:subClassOf faldo:StrandedPosition ;
            rdfs:label ?strand .
        }
      }
    SPARQL

    results.map {|hash|
      hash.merge(
        :seq_length => Bio::Locations.new(hash[:insdc_location]).length
      )
    }.first
  end
end
