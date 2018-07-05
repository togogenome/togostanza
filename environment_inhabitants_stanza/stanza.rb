class EnvironmentInhabitantsStanza < TogoStanza::Stanza::Base
  property :inhabitants_statistics do |meo_id|
    gold_list = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>
      PREFIX taxo: <http://ddbj.nig.ac.jp/ontologies/taxonomy#>

      SELECT
       (?gold AS ?source_link)
       (REPLACE(STR(?gold) ,"http://www.genomesonline.org/cgi-bin/GOLD/GOLDCards.cgi\\\\?goldstamp=" ,"" ) AS ?source_id)
       ?organism_name (REPLACE(STR(?tax_id) ,"http://identifiers.org/taxonomy/" ,"" ) AS ?tax_no) ("" AS ?isolation)
       (GROUP_CONCAT(DISTINCT ?env; SEPARATOR = "||") AS ?env_links)
      FROM <http://togogenome.org/graph/gold>
      FROM <http://togogenome.org/graph/meo>
      FROM <http://togogenome.org/graph/taxonomy>
      {
        VALUES ?meo_mapping { meo:MEO_0000437 meo:MEO_0000440 }
        ?meo_id rdfs:subClassOf* meo:#{meo_id} .
        ?gold ?meo_mapping ?meo_id .
        ?meo_id rdfs:label ?meo_label .
        BIND (CONCAT(REPLACE(STR(?meo_id),"http://purl.jp/bio/11/meo/",""), ?meo_label) AS ?env )
        OPTIONAL
        {
          ?gold mccv:MCCV_000020 ?tax_id .
          ?tax_id taxo:scientificName ?organism_name
        }
      } GROUP BY ?gold ?tax_id ?organism_name
    SPARQL

    strain_list = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>

      SELECT (?strain_id AS ?source_link) (?strain_number AS ?source_id) (?strain_name AS ?organism_name)
        (GROUP_CONCAT(DISTINCT ?tax_no; SEPARATOR = "||") AS ?tax_no)
        ?isolation (GROUP_CONCAT(DISTINCT ?env; SEPARATOR = "||") AS ?env_links)
      FROM <http://togogenome.org/graph/taxonomy>
      FROM <http://togogenome.org/graph/brc>
      FROM <http://togogenome.org/graph/meo>
      WHERE
      {
        VALUES ?related_type { mccv:MCCV_000056 mccv:MCCV_000022 mccv:MCCV_000057 }
        { SELECT DISTINCT ?strain_id
          {
            VALUES ?meo_mapping { mccv:MCCV_000059 mccv:MCCV_000060 }
            ?meo_id rdfs:subClassOf* meo:#{meo_id} .
            ?strain_id ?meo_mapping ?meo_id .
            ?strain_id rdf:type mccv:MCCV_000001 .
          }
        }
        OPTIONAL { ?strain_id mccv:MCCV_000010 ?strain_number . }
        OPTIONAL { ?strain_id mccv:MCCV_000012 ?strain_name . }
        OPTIONAL { ?strain_id mccv:MCCV_000030 ?isolation . }
        OPTIONAL
        {
          ?strain_id mccv:MCCV_000059|mccv:MCCV_000060 ?meo_id .
          ?meo_id rdfs:label ?meo_label .
          BIND (CONCAT(REPLACE(STR(?meo_id),"http://purl.jp/bio/11/meo/",""), ?meo_label) AS ?env )
        }
        OPTIONAL
        {
          ?strain_id ?related_type ?tax_id FILTER (STRSTARTS(STR(?tax_id),"http://identifiers.org/")) .
          BIND (REPLACE(STR(?tax_id),"http://identifiers.org/taxonomy/","") AS ?tax_no) .
        }
      } GROUP BY ?strain_id ?strain_number ?strain_name ?isolation ORDER BY DESC (?source_id)
    SPARQL

    source_list = gold_list.concat(strain_list)

    source_list.map {|hash|
      # Pads numbers with 0 to make NBRC's CAT id the 8 length.
      if hash[:source_id].start_with?("NBRC")
        url_parts = hash[:source_link].split("=")
        cat_id = url_parts.last.rjust(8, "0")
        hash[:source_link] = url_parts[0..-2].push(cat_id).join("=")
      end
      unless hash[:env_links] == "" then
        env_link_array = hash[:env_links].split("||")
        hash[:env_link_array] = env_link_array.map {|env_text|
          meo_info = { :meo_id => env_text.slice!(0, 11), :meo_label => env_text }
        }
        hash[:env_link_array].last[:is_last_data] = true
        unless hash[:tax_no].nil? then
          tax_no_array = hash[:tax_no].split("||")
          if tax_no_array.length > 0
            hash[:tax_no_array] = tax_no_array.map {|tax_no|
              tax = {:tax_no => tax_no }
            }
            hash[:tax_no_array].last[:is_last_data] = true
          end
        end
      end
    }
    source_list
  end
end
