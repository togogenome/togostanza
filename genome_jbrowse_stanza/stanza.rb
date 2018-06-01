class GenomeJbrowseStanza < TogoStanza::Stanza::Base
  property :select_tax_id do |tax_id, gene_id|
    results = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX obo: <http://purl.obolibrary.org/obo/>

      SELECT DISTINCT (REPLACE(STR(?taxonomy),"http://identifiers.org/taxonomy/","") AS ?tax_id)
      WHERE
      {
        {
          SELECT ?feature_uri
          {
            GRAPH <http://togogenome.org/graph/tgup>
            {
              <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?feature_uri .
            }
          } ORDER BY ?feature_uri LIMIT 1
        }
        GRAPH <http://togogenome.org/graph/refseq>
        {
           ?feature_uri  obo:RO_0002162 ?taxonomy
        }
      }
    SPARQL

    (results.length == 1) ? results.first[:tax_id] : nil
  end

  property :display_range do |tax_id, gene_id|
    result = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc).first
      DEFINE sql:select-option "order"
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX obo: <http://purl.obolibrary.org/obo/>
      PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
      PREFIX faldo: <http://biohackathon.org/resource/faldo#>

      SELECT ?seq_label ?start ?end ?seq_length
      WHERE
      {
        {
          SELECT ?feature_uri
          {
            GRAPH <http://togogenome.org/graph/tgup>
            {
              <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?feature_uri .
            }
          } ORDER BY ?feature_uri LIMIT 1
        }
        GRAPH <http://togogenome.org/graph/refseq>
        {
          ?feature_uri insdc:location  ?insdc_location ;
            faldo:location  ?faldo .
          ?faldo faldo:begin/faldo:position ?start .
          ?faldo faldo:end/faldo:position ?end .

          ?feature_uri obo:so_part_of* ?seq .
          ?refseq insdc:sequence ?seq ;
            insdc:sequence_version ?seq_label .
          ?seq insdc:sequence_length ?seq_length
        }
      }
    SPARQL

    if result.nil? || result.size.zero?
     result = nil
     next
    end

    first, last, seq_length, seq_label = result.values_at(:start, :end, :seq_length, :seq_label)

    start_pos, end_pos = [first.to_i, last.to_i].minmax
    gene_length = (end_pos - start_pos).abs + 1
    display_start_pos = [1, start_pos - (gene_length*5)].max
    display_end_pos = [end_pos + (gene_length*5), seq_length.to_i].min

    {ref: seq_label, disp_start: display_start_pos, disp_end: display_end_pos }
  end
end
