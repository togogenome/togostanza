class OrganismPathogenInformationStanza < TogoStanza::Stanza::Base
  property :pathogen_list do |tax_id|
    results = query("http://dev.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX pdo: <http://purl.jp/bio/11/pdo/>
      PREFIX taxid: <http://identifiers.org/taxonomy/>
      PREFIX ddbj_tax: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>

      SELECT (REPLACE(STR(?tax_id),"http://identifiers.org/taxonomy/","") AS ?tax_no)
       ?bacterialName (GROUP_CONCAT(DISTINCT ?diseaseName; SEPARATOR = ", ") AS ?diseaseNameSet) ?infectiousType ?strainType
      FROM <http://togogenome.org/graph/taxonomy>
      FROM <http://togogenome.org/graph/pdo_mapping>
      FROM <http://togogenome.org/graph/pdo>
      WHERE
      {
        VALUES ?search_tax { taxid:#{tax_id} }
        ?search_tax a ddbj_tax:Taxon .
        ?tax_id rdfs:subClassOf* ?search_tax ;
          rdfs:label ?bacterialName ;
          pdo:isAssociatedTo ?blank .
        ?blank ?p ?disease FILTER (?p IN(pdo:mayCaused, pdo:isRelatedTo)).
        OPTIONAL { ?tax_id pdo:isAssociatedTo/pdo:infectiousType ?infectiousType . }
        OPTIONAL { ?tax_id pdo:isAssociatedTo/pdo:strainType ?strainType . }
        ?disease rdfs:label ?diseaseName .
      } GROUP BY ?tax_id ?bacterialName ?infectiousType ?strainType
    SPARQL
    results.map {|hash|
      hash.merge(
        tax_link: "http://togogenome.org/organism/" + hash[:tax_no]
      )
    }
  end
end
