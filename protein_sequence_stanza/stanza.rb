class ProteinSequenceStanza < TogoStanza::Stanza::Base
  property :sequences do |tax_id, gene_id|
    sequences = query("http://dev.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX up: <http://purl.uniprot.org/core/>

      SELECT DISTINCT ?up_id ?aminoacid ?mass ?modified ?version ?checksum ?fragment ?precursor ?existence_label
      FROM <http://togogenome.org/graph/uniprot>
      FROM <http://togogenome.org/graph/tgup>
      WHERE {
        {
          SELECT ?gene
          {
            <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene .
          } ORDER BY ?gene LIMIT 1
        }
        <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
          rdfs:seeAlso ?id_upid .
        ?id_upid rdfs:seeAlso ?protein .
        ?protein a up:Protein ;
                 up:sequence ?isoform .

        # (P42166 & P42167) x (P42166-1 & P42167-1) => P42166 - P42166-1, P42167 - P42167-1
        BIND( REPLACE( STR(?protein), "http://purl.uniprot.org/uniprot/", "") AS ?up_id)
        FILTER( REGEX(?isoform, ?up_id))

        ?isoform rdf:value ?aminoacid ;
                 up:mass ?mass ;
                 up:modified ?modified ;
                 up:version ?version ;
                 up:crc64Checksum ?checksum .

        # Sequence status
        OPTIONAL {
          ?isoform up:fragment ?fragment .
        }

        # Sequence processing
        OPTIONAL {
          ?isoform up:precursor ?precursor .
        }

        # Protein existence
        OPTIONAL {
          ?protein up:existence ?existence .
          ?existence rdfs:label ?existence_label .
        }
      }
    SPARQL

    sequences.map {|hash|
      hash.merge(
        sequence_length:     hash[:aminoacid].try(:length),
        sequence_status:     sequence_status(hash[:fragment].to_s),
        sequence_processing: is_true?(hash[:precursor]) ? 'precursor' : nil
      )
    }
  end

  private

  def sequence_status(fragment)
    case fragment
    when 'single', 'multiple'
      'Fragment'
    else
      'Complete'
    end
  end

  def is_true?(val)
    # XXX Owlimだと 'true' が、Virtuosoだと '1' が返ってくるよ...
    val == 'true' || val == '1'
  end
end
