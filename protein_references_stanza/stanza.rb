class ProteinReferencesStanza < TogoStanza::Stanza::Base
  property :references do |tax_id, gene_id|
    pubmed_list = query("https://dev.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX up:   <http://purl.uniprot.org/core/>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

      SELECT DISTINCT ?pmid ?title ?author ?date ?name ?pages ?volume ?same
      FROM <http://togogenome.org/graph/uniprot>
      FROM <http://togogenome.org/graph/tgup>
      WHERE {
        {
          SELECT ?protein
          {
            <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
              rdfs:seeAlso ?id_upid .
            ?id_upid rdfs:seeAlso ?protein .
            ?protein a up:Protein ;
              up:reviewed ?reviewed .
          } ORDER BY DESC(?reviewed) LIMIT 1
        }
        ?protein up:citation ?citation .
        ?citation skos:exactMatch ?pmid .
        FILTER    REGEX (STR(?pmid), "pubmed") .

        ?citation up:title   ?title ;
                  up:author  ?author ;
                  up:date    ?date ;
                  up:name    ?name ;
                  up:pages   ?pages ;
                  up:volume  ?volume ;
                  foaf:primaryTopicOf ?same .
      }
    SPARQL

    # GROUP BY pubmed_id. GROUP_CONCAT() can not be used due to an error("Value of ANY type column too long")
    result_list = []
    pubmed_list.group_by {|row| row[:pmid]}.each do |k, v|
      hash = v.first.dup
      hash[:authors] = v.map {|pubmed_info| pubmed_info[:author]}.join(", ")
      result_list.push(hash)
    end
    result_list.sort!{|a, b| -(a[:date] <=> b[:date])}
    result_list
  end
end
