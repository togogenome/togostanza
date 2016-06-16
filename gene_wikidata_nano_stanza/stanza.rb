class GeneWikidataNanoStanza < TogoStanza::Stanza::Base
  property :title do
    "Wikidata"
  end

  property :result do |tax_id, gene_id|
    results = query("https://query.wikidata.org/bigdata/namespace/wdq/sparql", <<-SPARQL.strip_heredoc)
      PREFIX wd: <http://www.wikidata.org/entity/>
      PREFIX wdt: <http://www.wikidata.org/prop/direct/>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

      SELECT DISTINCT ?species ?taxid ?gene ?gene_id
      WHERE
      {
        VALUES ?taxid { "#{tax_id}" }
        VALUES ?gene_id { "#{gene_id}"@en "#{gene_id}" }

        ?gene rdfs:label | wdt:P2393 ?gene_id .
        {
          ?gene wdt:P703 ?species . # P703 Found in taxon
        }
        UNION
        {
           ?gene wdt:P703 ?species2 . # P703 Found in taxon
           ?species2 wdt:P460 ?species . # Same as
        }
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
