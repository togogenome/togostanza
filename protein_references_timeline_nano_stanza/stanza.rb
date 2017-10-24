class ProteinReferencesTimelineNanoStanza < TogoStanza::Stanza::Base
  property :title do
    "Protein references timeline"
  end

  property :references do |tax_id, gene_id, step|
    refs = query('http://togogenome.org/sparql-app', <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX up: <http://purl.uniprot.org/core/>

      # "SAMPLE" for multi-year citation (publish, Epub)(e.g. <http://purl.uniprot.org/citations/20978534> up:date ?date)
      SELECT DISTINCT SAMPLE(?years) AS ?year ?citation
      FROM <http://togogenome.org/graph/uniprot>
      FROM <http://togogenome.org/graph/tgup>
      WHERE {
        {
          SELECT ?gene
          {
            <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene .
          } ORDER BY ?gene LIMIT 1
        }
        <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
          rdfs:seeAlso ?id_upid .
        ?id_upid rdfs:seeAlso ?protein .
        ?protein a up:Protein ;
                 up:citation ?citation.
        ?citation up:date ?date ;
                  a up:Journal_Citation .
        BIND(year(?date) AS ?years)
      } GROUP BY ?citation ORDER BY ?year
    SPARQL

    time = Time.new

    references = (1941..time.year).map {|y|
      {year: y.to_s, citation: ""}
    }
    grouping(references.concat(refs), :year, :citation).map {|y|
      y[:citation].delete_at(0)
      {year: y[:year], counts: y[:citation].size, citations: y[:citation]}
    }
  end
end
