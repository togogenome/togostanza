class OrganismCrossReferencesStanza < TogoStanza::Stanza::Base
  property :link_list do |tax_id|
    link_list = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX tax: <http://identifiers.org/taxonomy/>
      PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX obo: <http://purl.obolibrary.org/obo/>

      SELECT DISTINCT ?type_label ?link
      WHERE
      {
        {
          GRAPH <http://togogenome.org/graph/gold>
          {
            ?link mccv:MCCV_000020 tax:#{tax_id} .
             BIND ("GOLD" AS ?type_label) .
          }
        }
        UNION
        {
          GRAPH  <http://togogenome.org/graph/refseq>
          {
            ?sequence obo:RO_0002162 tax:#{tax_id} .
            ?refseq insdc:sequence ?sequence .
            ?refseq a insdc:Entry ;
              rdfs:seeAlso ?link .
            ?link a ?type .
            FILTER(STRSTARTS(STR(?type), "http://ddbj.nig.ac.jp/ontologies/nucleotide/" ) && (?type != insdc:Entry)) .
            BIND (REPLACE(STR(?type), "http://ddbj.nig.ac.jp/ontologies/nucleotide/", "") AS ?type_label)
          }
        }
      } ORDER BY ?type_label ?link
    SPARQL

    link_list.map {|hash|
      xref_id = hash[:link].split('/').last.split('?').last.split('#').last.split('=').last
      puts xref_id
      hash.merge(:xref_db => hash[:type_label], :xref_id => xref_id)
    }.group_by{|hash| hash[:xref_db] }.map {|hash|
      hash.last.last.merge!(:is_last_data => true) #flag for separator character
      hash.last
    }

  end
end
