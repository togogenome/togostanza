class GeneWikidataNanoStanza < TogoStanza::Stanza::Base
  property :title do
    "Wikidata"
  end

  property :result do |tax_id, gene_id|
    results = query("https://query.wikidata.org/bigdata/namespace/wdq/sparql", <<-SPARQL.strip_heredoc)
      PREFIX wd: <http://www.wikidata.org/entity/>
      PREFIX wdt: <http://www.wikidata.org/prop/direct/>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

      SELECT DISTINCT ?species ?taxid ?gene ?locustag
      WHERE {
        VALUES ?taxid { "#{tax_id}" }
        VALUES ?lucustag { "#{gene_id}" }
        ?gene wdt:P703 ?species . # P703 Found in taxon
        OPTIONAL { ?gene wdt:P2393 ?locustag }
        ?species wdt:P685 ?taxid .
      }
    SPARQL

    if results.nil? || results.size == 0
      nil
    else
      result = results.first
      result[:item] = result[:gene].sub(/.*\//, '')
      result
    end
  end

end
