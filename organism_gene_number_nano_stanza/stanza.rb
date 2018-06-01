class OrganismGeneNumberNanoStanza < TogoStanza::Stanza::Base
  property :genome_stats do |tax_id|
    result = query('http://dev.togogenome.org/sparql-app', <<-SPARQL.strip_heredoc).first
      PREFIX tgstat:<http://togogenome.org/stats/>
      PREFIX taxid:<http://identifiers.org/taxonomy/>

      SELECT DISTINCT ?gene_number ?rrna_number ?trna_number ?ncrna_number
      FROM <http://togogenome.org/graph/stats>
      WHERE
      {
        taxid:#{tax_id} tgstat:gene ?gene_number ;
        tgstat:rrna ?rrna_number ;
        tgstat:trna ?trna_number ;
        tgstat:ncrna ?ncrna_number .
      }
    SPARQL
  end
end
