class OrganismWikidataNanoStanza < TogoStanza::Stanza::Base
  property :title do
    "Wikidata"
  end

  property :result do |tax_id|
    results = query("https://query.wikidata.org/bigdata/namespace/wdq/sparql", <<-SPARQL.strip_heredoc)
      PREFIX wd: <http://www.wikidata.org/entity/>
      PREFIX wdt: <http://www.wikidata.org/prop/direct/>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

      SELECT DISTINCT ?species ?taxid
      WHERE {
        VALUES ?taxid { "#{tax_id}" }
        ?species wdt:P685 ?taxid .
      }
    SPARQL

    if results.nil? || results.size == 0
      nil
    else
      result = results.first
      result[:item] = result[:species].sub(/.*\//, '')
      result
    end
  end
end
