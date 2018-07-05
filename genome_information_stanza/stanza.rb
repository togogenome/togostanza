class GenomeInformationStanza < TogoStanza::Stanza::Base
  property :genome_info_list do |tax_id|
    results = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX obo: <http://purl.obolibrary.org/obo/>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
      PREFIX idtax: <http://identifiers.org/taxonomy/>
      PREFIX togo: <http://togogenome.org/stats/>
      PREFIX ass: <http://ddbj.nig.ac.jp/ontologies/assembly/>

      SELECT  DISTINCT ?assembly_id ?assembly_name ?refseq_version ?refseq_link  ?desc ?replicon_type ?sequence_length
       ?gene_cnt ?rrna_cnt ?trna_cnt ?other_cnt
      FROM <http://togogenome.org/graph/refseq>
      FROM <http://togogenome.org/graph/so>
      FROM <http://togogenome.org/graph/stats>
      FROM <http://togogenome.org/graph/assembly_report>
      WHERE
      {
        ?seq obo:RO_0002162 idtax:#{tax_id} .
        ?refseq_link insdc:sequence ?seq ;
          a insdc:Entry ;
          insdc:sequence_version ?refseq_version ;
          insdc:definition ?desc ;
          insdc:sequence ?seq.
        ?seq rdfs:subClassOf/rdfs:label ?replicon_type ;
          insdc:sequence_length ?sequence_length .
        ?refseq_link  togo:gene ?gene_cnt ;
          togo:rrna ?rrna_cnt ;
          togo:trna ?trna_cnt ;
          togo:other ?other_cnt .
        ?refseq_link rdfs:seeAlso ?ass_id .
        ?ass rdfs:seeAlso ?ass_id ;
          ass:assembly_id ?assembly_id ;
          ass:asm_name ?assembly_name .
      } ORDER BY ?assembly_id ?refseq_version
    SPARQL

    results.reverse.group_by {|hash| hash[:assembly_id] }.map {|hash|
      hash.last.sort_by {|hash2|
        hash2[:replicon_type]
      }
    }
  end
end
