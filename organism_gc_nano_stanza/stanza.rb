require 'open-uri'

class OrganismGcNanoStanza < TogoStanza::Stanza::Base
  property :title do
    "GC%"
  end

  property :atgc do |tax_id|
    # http://localhost:9292/stanza/organism_gc_nano?tax_id=192222

    results = query('http://dev.togogenome.org/sparql-app', <<-SPARQL.strip_heredoc)
      PREFIX taxid:<http://identifiers.org/taxonomy/>
      PREFIX stats: <http://togogenome.org/stats/>

      SELECT ?gc ?at
      WHERE
      {
        GRAPH <http://togogenome.org/graph/stats> {
          VALUES ?tax_id { taxid:#{tax_id} }
          ?tax_id stats:gc_count ?gc ;
            stats:at_count ?at .
        }
      }
    SPARQL
    if results.nil? || results.size == 0
      nil
      next
    end
    gc = results.first[:gc].to_i
    at = results.first[:at].to_i
    unless (sum = gc + at).zero?
      {
        gc_percentage: calc_percent(gc, sum) ,
        at_percentage: calc_percent(at, sum)
      }
    else
      nil
    end
  end

  def calc_percent(val, sum)
    (val.to_f / sum.to_f * 100.0).to_i
  end
end
