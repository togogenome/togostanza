class OrganismCultureCollectionsStanza < TogoStanza::Stanza::Base
  property :strain_list do |tax_id|
    results = query("https://sparql-app.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREFIX taxid: <http://identifiers.org/taxonomy/>
    PREFIX mccv: <http://purl.jp/bio/10/mccv#>
    PREFIX sio:  <http://semanticscience.org/resource/>
    PREFIX obo: <http://purl.obolibrary.org/obo/>

    SELECT DISTINCT (?strain_id AS ?source_link) (?strain_number AS ?source_id) (?strain_name AS ?organism_name)
      (GROUP_CONCAT(DISTINCT ?isolated_from; SEPARATOR = ", ") AS ?isolation)
      (GROUP_CONCAT(DISTINCT ?env; SEPARATOR = "||") AS ?env_links)
      ?type_strain ?application
      (GROUP_CONCAT(DISTINCT ?other_link; SEPARATOR = ", ") AS ?other_collections)
    FROM <http://togogenome.org/graph/taxonomy>
    FROM <http://togogenome.org/graph/jcm>
    FROM <http://togogenome.org/graph/nbrc>
    FROM <http://togogenome.org/graph/meo0.9>
    WHERE
    {
      { SELECT DISTINCT ?strain_id
        {
          VALUES ?related_tax_prop { mccv:MCCV_000023  mccv:MCCV_000065 }
          ?strain_id  ?related_tax_prop taxid:#{tax_id} .
        }
      }
      OPTIONAL { ?strain_id mccv:MCCV_000010 ?strain_number . }
      OPTIONAL { ?strain_id mccv:MCCV_000012 ?strain_name . }
      OPTIONAL {
        {?strain_id mccv:MCCV_000028/rdfs:label ?isolated_from }
        UNION
        { ?strain_id mccv:MCCV_000028/mccv:MCCV_000072/mccv:MCCV_000030 ?isolated_from . }
      }
      OPTIONAL {
        {
          ?strain_id mccv:MCCV_000028/mccv:MCCV_000072/mccv:MCCV_000071 ?meo_id .
          ?meo_id rdfs:label ?meo_label .
          ?meo_id a owl:Class .
          BIND (CONCAT(REPLACE(STR(?meo_id),"http://purl.jp/bio/11/meo/",""), ?meo_label) AS ?env )
        }
        UNION
        {
          ?strain_id mccv:MCCV_000028/mccv:MCCV_000072/sio:SIO_000008 ?meo_id .
          ?meo_id rdfs:label ?meo_label .
          ?meo_id a owl:Class .
          BIND (CONCAT(REPLACE(STR(?meo_id),"http://purl.jp/bio/11/meo/",""), ?meo_label) AS ?env )
        }
      }
      OPTIONAL { ?strain_id mccv:MCCV_000017 ?type_strain . }
      OPTIONAL { ?strain_id mccv:MCCV_000033 ?application . }
      OPTIONAL {
        { ?strain_id mccv:MCCV_000024/mccv:MCCV_000026 ?other_link .}
        UNION
        { ?strain_id mccv:MCCV_000024/dcterms:identifier ?other_link .}
      }
    }
    SPARQL
    results.map {|hash|
      if hash[:type_strain] == "1" || hash[:type_strain] == true
        hash[:type_strain_label] = "Yes"
      else hash[:type_strain].nil? || hash[:type_strain] == "0" || hash[:type_strain] == false
        hash[:type_strain_label] = "No"
      end
      if hash[:source_id].start_with?("NBRC")
        cat_id = hash[:source_link].split("_").last
        hash[:source_link] = "http://www.nbrc.nite.go.jp/NBRC2/NBRCCatalogueDetailServlet?ID=NBRC&CAT=#{cat_id}"
      end
      if !hash[:organism_name].nil? && hash[:organism_name] =~ /^".*"$/
        hash[:organism_name] = hash[:organism_name][1..-2]
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
    results
  end
end
