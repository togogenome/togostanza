class OrganismJbrowseStanza < TogoStanza::Stanza::Base
  property :sequence_version do |tax_id|
    results = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
      PREFIX idtax: <http://identifiers.org/taxonomy/>
      PREFIX obo: <http://purl.obolibrary.org/obo/>

      SELECT ?version ?length
      WHERE
      {
        GRAPH <http://togogenome.org/graph/refseq> {
          ?seq obo:RO_0002162 idtax:#{tax_id}  .
          ?refseq_link insdc:sequence ?seq ;
            a insdc:Entry ;
            insdc:sequence_version ?version ;
            insdc:sequence/insdc:sequence_length ?length .
        }
      } ORDER BY DESC(?length) LIMIT 1
    SPARQL

    if results.length > 0 then
      display_start_pos = 1
      display_end_pos = [ results.first[:length].to_i, 200000 ].min
      sequence_version = {tax_id: tax_id, ref: results.first[:version], display_start_pos: display_start_pos, display_end_pos: display_end_pos}
    else
      sequence_version = {tax_id: nil}
    end
    sequence_version
  end
end
