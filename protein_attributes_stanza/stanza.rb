class ProteinAttributesStanza < TogoStanza::Stanza::Base
  property :attributes do |tax_id, gene_id|
    protein_attributes = query("http://dev.togogenome.org/sparql-sd", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX up: <http://purl.uniprot.org/core/>

      SELECT DISTINCT ?sequence ?fragment ?precursor ?existence_label
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
                 up:sequence ?seq .

        # Sequence
        OPTIONAL {
          ?seq rdf:value ?sequence .
        }

        # Sequence status
        OPTIONAL {
          ?seq up:fragment ?fragment .
        }

        # Sequence processing
        OPTIONAL {
          ?seq up:precursor ?precursor .
        }

        # Protein existence
        OPTIONAL {
          ?protein up:existence ?existence .
          ?existence rdfs:label ?existence_label .
        }
      }
    SPARQL

    # こういうロジック(length, sequence_status)をこっちに持つのはどうなんだろう?
    # でも,UniProt では取れ無さそう(?)
    # 要ご相談
    protein_attributes.map {|attrs|
      attrs.merge(
        sequence_length:     attrs[:sequence].try(:length),
        sequence_status:     sequence_status(attrs[:fragment].to_s),
        sequence_processing: is_true?(attrs[:precursor]) ? 'precursor' : nil
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
