class LineageInformationStanza < TogoStanza::Stanza::Base
  property :param_tax_id do |tax_id|
   tax_id
  end

  property :tax_lineage_list do |tax_id|
    results_super = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX taxo: <http://ddbj.nig.ac.jp/ontologies/taxonomy#>
      PREFIX taxid: <http://identifiers.org/taxonomy/>

      SELECT
       (REPLACE(STR(?tax), "http://identifiers.org/taxonomy/", "") AS ?tax_no)
       (?tax AS ?tax_link)
       ?tax_label
       (REPLACE(STR(?rank), "http://ddbj.nig.ac.jp/ontologies/taxonomy#", "") AS ?rank)
      FROM <http://togogenome.org/graph/taxonomy>
      WHERE
      {
        ?search_tax rdfs:label ?o FILTER (?search_tax = taxid:#{tax_id} ) .
        ?search_tax rdfs:subClassOf ?tax OPTION (transitive, t_direction 1, t_min(0), t_step("step_no") as ?step) .
        ?tax rdfs:label ?tax_label .
        OPTIONAL { ?tax taxo:rank ?rank . }
        FILTER(?tax != taxid:1)
      } ORDER BY DESC(?step)
    SPARQL

    results_sub = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX taxo: <http://ddbj.nig.ac.jp/ontologies/taxonomy#>
      PREFIX taxid: <http://identifiers.org/taxonomy/>

      SELECT
       (REPLACE(STR(?tax) ,"http://identifiers.org/taxonomy/" ,"" ) AS ?tax_no)
       (?tax AS ?tax_link)
       ?tax_label
       (REPLACE(STR(?rank) ,"http://ddbj.nig.ac.jp/ontologies/taxonomy#" ,"" ) AS ?rank)
      FROM <http://togogenome.org/graph/taxonomy>
      WHERE
      {
        ?search_tax rdfs:label ?label FILTER (?search_tax = taxid:#{tax_id} ) .
        ?tax rdfs:subClassOf ?search_tax .
        ?tax rdfs:label ?tax_label .
        OPTIONAL { ?tax taxo:rank ?rank . }
      }
    SPARQL

    results_super.concat(results_sub).map {|hash|
      if hash[:tax_no] == tax_id
        selected_tax = 'true'
      end
      if hash[:rank] == 'NoRank'
        hash[:rank] = ''
      end
      hash.merge(
        tax_app_link: 'http://togogenome.org/organism/' + hash[:tax_no],
        selected_tax: selected_tax
      )
    }
  end
end
