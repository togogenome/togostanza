class OrganismNamesStanza < TogoStanza::Stanza::Base
  property :organism_name_list do |tax_id|
    results = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX tax: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>
      PREFIX taxid: <http://identifiers.org/taxonomy/>

      SELECT ?name_type ?name_type_label ?name
      FROM <http://togogenome.org/graph/taxonomy>
      WHERE
      {
        VALUES ?name_type
        {
          tax:scientificName tax:synonym tax:preferredSynonym tax:acronym tax:preferredAcronym tax:anamorph tax:teleomorph
          tax:misnomer tax:commonName tax:preferredCommonName tax:inPart tax:includes tax:equivalentName
          tax:genbankSynonym tax:genbankCommonName tax:authority tax:misspelling
        }
        taxid:#{ tax_id } ?name_type ?name .
        ?name_type rdfs:label ?name_type_label .
      }
    SPARQL

    result = results.map {|hash|
      name = hash[:name].gsub("\\","")
      name_label = hash[:name_type_label].capitalize
      hash.merge(
        name_label: name_label,
        name: name
      )
    }.group_by {|hash| hash[:name_type] }

    #Order by kind of synonym
    order_array = ["scientificName", "synonym", "preferredSynonym", "acronym", "preferredAcronym",
                   "anamorph", "teleomorph", "misnomer", "commonName", "preferredCommonName",
                   "inPart", "includes", "equivalentName", "genbankSynonym", "genbankCommonName", "authority", "misspelling" ]
    taxo_prefix = "http://ddbj.nig.ac.jp/ontologies/taxonomy/"
    orderd_result = []
    hoge = order_array.each {|item|
      key = taxo_prefix + item
      unless result[key].nil? then
        orderd_result.push(result[key])
      end
    }
    orderd_result
  end
end
