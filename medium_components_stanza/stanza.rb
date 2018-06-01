class MediumComponentsStanza < TogoStanza::Stanza::Base
  property :medium_information do |medium_id|
    medium_list = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>

      SELECT DISTINCT ?medium ?medium_id ?medium_type_label ?medium_name
      FROM <http://togogenome.org/graph/brc>
      FROM <http://togogenome.org/graph/gmo>
      WHERE
      {
        ?medium gmo:GMO_000101 ?medium_id .
        ?medium gmo:GMO_000111 ?medium_type .
        ?medium_type rdfs:label ?medium_type_label FILTER (lang(?medium_type_label) = "en") .
        OPTIONAL { ?medium gmo:GMO_000102 ?medium_name } .
        filter( ?medium_id = "#{medium_id}" )
      }
    SPARQL

    ingredient_list = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>

      SELECT ?medium_id ?classification ?class_label ?ingredient as ?ingredient_id ?ingredient_label ?link_pubchem ?link_chebi ?link_snomedct ?link_mesh ?link_wikipedia
      FROM <http://togogenome.org/graph/brc>
      FROM <http://togogenome.org/graph/gmo>
      WHERE {
        VALUES ?classification { gmo:GMO_000015 gmo:GMO_000016 gmo:GMO_000008 gmo:GMO_000009 }
        ?medium gmo:GMO_000101 ?medium_id .
        ?medium gmo:GMO_000104 ?ingredient .
        ?ingredient rdfs:subClassOf* ?classification .
        ?ingredient rdfs:label ?ingredient_label FILTER (lang(?ingredient_label) = "en") .
        OPTIONAL{ ?ingredient rdfs:seeAlso ?link_pubchem   FILTER( contains(str(?link_pubchem)   ,'http://www.ncbi.nlm.nih.gov/pccompound/') ) . }
        OPTIONAL{ ?ingredient rdfs:seeAlso ?link_chebi     FILTER( contains(str(?link_chebi)     ,'http://purl.obolibrary.org/obo/CHEBI_') ) . }
        OPTIONAL{ ?ingredient rdfs:seeAlso ?link_snomedct  FILTER( contains(str(?link_snomedct)  ,'http://purl.bioontology.org/ontology/SNOMEDCT/') ) . }
        OPTIONAL{ ?ingredient rdfs:seeAlso ?link_mesh      FILTER( contains(str(?link_mesh)      ,'http://purl.bioontology.org/ontology/MSH/') ) . }
        OPTIONAL{ ?ingredient rdfs:seeAlso ?link_wikipedia FILTER( contains(str(?link_wikipedia) ,'http://en.wikipedia.org/') ) . }
        ?classification rdfs:label ?class_label .
        filter( ?medium_id = "#{medium_id}" )
      }
      GROUP BY ?medium_id ?classification ?class_label
      ORDER BY ?class_label ?ingredient_label
    SPARQL

    ingredients = ingredient_list.group_by {|hash| hash[:medium_id] }
    ingredients_classes = ["GMO_000015", "GMO_000016", "GMO_000008", "GMO_000009"]
    result = medium_list.map {|hash|
      row = [
        {row_key: "Medium ID",   row_value: hash[:medium_id],         row_href: hash[:medium], is_array: false},
        {row_key: "Medium name", row_value: hash[:medium_name],       row_href: "",            is_array: false},
        {row_key: "Medium type", row_value: hash[:medium_type_label], row_href: "",            is_array: false}
      ]

      classed_ingredients = ingredients[hash[:medium_id]].group_by {|ingred| ingred[:classification].split("#").last}

      # Defined components delete (Solidifying components and Water)
      if classed_ingredients["GMO_000015"]
        classed_ingredients["GMO_000015"].delete_if {|item|
          ret_solid = classed_ingredients["GMO_000008"].any? {|d| item[:ingredient_id] == d[:ingredient_id] } if classed_ingredients["GMO_000008"]
          ret_water = classed_ingredients["GMO_000009"].any? {|d| item[:ingredient_id] == d[:ingredient_id] } if classed_ingredients["GMO_000009"]
          ret_solid || ret_water
        }
      end

      # Undefined components delete (Solidifying components and Water)
      if classed_ingredients["GMO_000016"]
        classed_ingredients["GMO_000016"].delete_if {|item|
          ret_solid = classed_ingredients["GMO_000008"].any? {|d| item[:ingredient_id] == d[:ingredient_id] } if classed_ingredients["GMO_000008"]
          ret_water = classed_ingredients["GMO_000009"].any? {|d| item[:ingredient_id] == d[:ingredient_id] } if classed_ingredients["GMO_000009"]
          ret_solid || ret_water
        }
      end

      # empty hash key is delete
      classed_ingredients.delete_if {|_key, val| val.empty? }

      ingredients_classes.each {|classes|
        classification = classed_ingredients[classes]
        next unless classification

        listrow = {row_key: classification.at(0).fetch(:class_label, ""), row_value: [], row_href: [], is_array: true}

        classification.each {|ingres|
          listrow[:row_value].push({
            label: ingres[:ingredient_label],
            pubchem: ingres[:link_pubchem],
            chebi: ingres[:link_chebi],
            snomedct: ingres[:link_snomedct],
            mesh: ingres[:link_mesh],
            wikipedia: ingres[:link_wikipedia],
          })
        }
        row.push(listrow)
      }
      row
    }
    result
  end
end
