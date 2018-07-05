class OrganismMediumInformationStanza < TogoStanza::Stanza::Base
  property :medium_information do |tax_id|
    medium_list = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>
      PREFIX taxid: <http://identifiers.org/taxonomy/>

      SELECT DISTINCT ?medium_id ?medium_type_label ?medium_name
      FROM <http://togogenome.org/graph/brc>
      FROM <http://togogenome.org/graph/gmo>
      WHERE
      {
        { SELECT DISTINCT ?medium
          {
            ?strain_id mccv:MCCV_000056 taxid:#{tax_id} .
            ?strain_id mccv:MCCV_000018 ?medium .
          }
        }
        ?medium gmo:GMO_000101 ?medium_id .
        ?medium gmo:GMO_000111 ?medium_type .
        ?medium_type rdfs:label ?medium_type_label FILTER (lang(?medium_type_label) = "en") .
        OPTIONAL { ?medium gmo:GMO_000102 ?medium_name } .
      }
    SPARQL

    ingredient_list = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
#      DEFINE sql:select-option "order"
# TODO: Uncomment the above line when endpoint data is update.
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX gmo: <http://purl.jp/bio/11/gmo#>
      PREFIX taxid: <http://identifiers.org/taxonomy/>

      SELECT ?medium_id ?classification (STR(?class_lbl) AS ?class_label)
        ?ingredient (STR(?ingredient_lbl) AS ?ingredient_label)
      FROM <http://togogenome.org/graph/brc>
      FROM <http://togogenome.org/graph/gmo>
      WHERE
      {
        VALUES ?classification { gmo:GMO_000015 gmo:GMO_000016 gmo:GMO_000008 gmo:GMO_000009 }
        { SELECT DISTINCT ?medium
          {
            ?strain_id mccv:MCCV_000056 taxid:#{tax_id} .
            ?strain_id mccv:MCCV_000018 ?medium .
          }
        }
        ?medium gmo:GMO_000101 ?medium_id .
        ?medium gmo:GMO_000104 ?ingredient .
        ?ingredient rdfs:subClassOf* ?classification .
        ?ingredient rdfs:label ?ingredient_lbl FILTER (lang(?ingredient_lbl) = "en") .
        ?classification rdfs:label ?class_lbl .
      } ORDER BY ?classification
    SPARQL

    ## Delete ingredient from GMO_000015(Defined components) if it's member of the GMO_000009(Water)
    ## SPARQL can also do the same processing as this. But There is bug of MINUS in Virtuoso.
    ##  See: http://wiki.lifesciencedb.jp/mw/index.php/BH12.12/TogoStanzaQuery/v201402#medium_classification.28.E6.94.B9.E8.89.AF.E7.89.88.29
    classes_by_medium = ingredient_list.group_by {|hash| hash[:medium_id] }
    classes_by_medium.each {|medium_id, class_info|
      class_info.delete_if {|item|
        item[:classification].split("#").last == "GMO_000015" \
        && ((class_info.find { |item2| item2[:classification].split("#").last == "GMO_000009" \
             && item[:ingredient] == item2[:ingredient]}) != nil)
      }
    }

    ingredients = ingredient_list.group_by {|hash| hash[:medium_id] }
    ingredients_classes = ["GMO_000015", "GMO_000016", "GMO_000008", "GMO_000009"]
    result = medium_list.map {|hash|
      row = []
      row.push({:row_key => "Medium ID", :row_value => hash[:medium_id]})
      row.push({:row_key => "Medium name", :row_value => hash[:medium_name]})
      row.push({:row_key => "Medium type", :row_value => hash[:medium_type_label]})
      ingredients_classes.each{ |classes|
        classifications = classes_by_medium[hash[:medium_id]].find_all {|item| item[:classification].split("#").last == classes }
        ingredients = ''
        classifications.each_with_index {|item, index|
          ingredients += item[:ingredient_label]
          if index != classifications.length - 1
            ingredients += ', '
          end
        }
        row.push({:row_key => classifications.first[:class_label], :row_value => ingredients})
      }
      row
    }
    result
  end
end
