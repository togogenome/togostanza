class ProteinOntologiesStanza < TogoStanza::Stanza::Base
  property :keywords do |tax_id, gene_id|
    keywords = query("http://dev.togogenome.org/sparql-sd", <<-SPARQL.strip_heredoc)
      
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX up: <http://purl.uniprot.org/core/>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

      SELECT DISTINCT ?root_name ?concept (GROUP_CONCAT(?name; SEPARATOR = ", ") AS ?names)
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
                 up:classifiedWith ?concept .
        ?concept rdf:type up:Concept .
        FILTER contains(str(?concept), 'keywords') .

        ?concept ?label ?name FILTER (?label = skos:prefLabel || ?label = skos:altLabel).
        ?concept rdfs:subClassOf* ?parents .
        ?parents skos:prefLabel ?root_name .
        FILTER (str(?root_name) IN ('Biological process', 'Cellular component', 'Domain', 'Ligand', 'Molecular function', 'Technical term')) .
      }
      GROUP BY ?root_name ?concept
      ORDER BY ?root_name ?concept ?names
    SPARQL

    keywords.group_by {|keyword|
      keyword[:root_name].gsub(/ /, '_').underscore
    }
  end

  property :gene_ontlogies do |tax_id, gene_id|
    ## [{:root_name=>"biological_process", :name=>"response to herbicide"},
    ##  {:root_name=>"biological_process", :name=>"photosynthetic electron transport in photosystem II"},
    ##  {:root_name=>"molecular_function", :name=>"oxidoreductase activity"},
    ##  ...]
    gene_ontlogies = query("http://dev.togogenome.org/sparql-sd", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX up: <http://purl.uniprot.org/core/>
      PREFIX taxonomy: <http://purl.uniprot.org/taxonomy/>

      SELECT DISTINCT ?name ?root_name ?obo_go_uri
      FROM <http://togogenome.org/graph/uniprot>
      FROM <http://togogenome.org/graph/tgup>
      FROM <http://togogenome.org/graph/go>
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
                 up:classifiedWith ?obo_go_uri .
        ?obo_go_uri rdfs:label ?name .
        ?obo_go_uri rdfs:subClassOf* ?parents .
        ?parents rdfs:label ?root_name .
        FILTER (str(?root_name) IN ('biological_process', 'cellular_component', 'molecular_function')) .
      }
    SPARQL

    gene_ontlogies.map {|hash|
      hash.merge(url: hash[:obo_go_uri].gsub(/http:\/\/purl\.obolibrary\.org\/obo\/GO_/, 'http://www.ebi.ac.uk/QuickGO/GTerm?id=GO:'))
    }.group_by {|go| go[:root_name] }
  end
end
