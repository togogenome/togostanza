class EnvironmentInhabitantsStanza < TogoStanza::Stanza::Base
  property :inhabitants_statistics do |meo_id|
    nbrc_list = query("https://sparql-app.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
    DEFINE sql:select-option "order"
    PREFIX mccv: <http://purl.jp/bio/10/mccv#>
    PREFIX meo: <http://purl.jp/bio/11/meo/>
    PREFIX tax: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>
    PREFIX sio:  <http://semanticscience.org/resource/>
    PREFIX mpo:  <http://purl.jp/bio/10/mpo/>
    PREFIX obo: <http://purl.obolibrary.org/obo/>

    SELECT DISTINCT  (?strain_id AS ?source_link) (?strain_number AS ?source_id) (?strain_name AS ?organism_name)
      (GROUP_CONCAT(DISTINCT ?isolated_from; SEPARATOR = ", ") AS ?isolation)
      (GROUP_CONCAT(DISTINCT ?tax_no; SEPARATOR = "||") AS ?tax_no)
      (GROUP_CONCAT(DISTINCT ?env; SEPARATOR = "||") AS ?env_links)
    FROM <http://togogenome.org/graph/nbrc>
    FROM <http://togogenome.org/graph/meo0.9>
    FROM <http://togogenome.org/graph/taxonomy>
    {
      {
        SELECT DISTINCT (?strain) as ?strain_id
        {
          VALUES ?search_meo_id { meo:#{meo_id} }
          ?search_meo_id a owl:Class .
          ?meo_id rdfs:subClassOf* ?search_meo_id .
          ?strain mccv:MCCV_000028/mccv:MCCV_000072/sio:SIO_000008 ?meo_id .
        }
      }
      OPTIONAL { ?strain_id mccv:MCCV_000010 ?strain_number . }
      OPTIONAL { ?strain_id mccv:MCCV_000012 ?strain_name . }
      OPTIONAL { ?strain_id mccv:MCCV_000028/mccv:MCCV_000072/mccv:MCCV_000030 ?isolated_from . }
      OPTIONAL {
        ?strain_id mccv:MCCV_000028/mccv:MCCV_000072/sio:SIO_000008 ?meo_id .
        ?meo_id rdfs:label ?meo_label .
        BIND (CONCAT(REPLACE(STR(?meo_id),"http://purl.jp/bio/11/meo/",""), ?meo_label) AS ?env )
      }
      OPTIONAL {
        ?strain_id  mccv:MCCV_000065 ?related_tax_id .
        BIND (REPLACE(STR(?related_tax_id),"http://identifiers.org/taxonomy/","") AS ?tax_no) .
      }
    } GROUP BY ?strain_id ?strain_number ?strain_name ORDER BY DESC (?source_id)
    SPARQL

    jcm_list = query("https://sparql-app.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
    DEFINE sql:select-option "order"
    PREFIX mccv: <http://purl.jp/bio/10/mccv#>
    PREFIX taxid: <http://identifiers.org/taxonomy/>
    PREFIX meo: <http://purl.jp/bio/11/meo/>
    PREFIX tax: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>
    PREFIX sio:  <http://semanticscience.org/resource/>
    PREFIX mpo:  <http://purl.jp/bio/10/mpo/>
    PREFIX obo: <http://purl.obolibrary.org/obo/>

    SELECT DISTINCT  (?strain_id AS ?source_link) (?strain_number AS ?source_id) (?strain_name AS ?organism_name)
    (GROUP_CONCAT(DISTINCT ?isolated_from; SEPARATOR = ", ") AS ?isolation)
    (GROUP_CONCAT(DISTINCT ?tax_no; SEPARATOR = "||") AS ?tax_no)
    (GROUP_CONCAT(DISTINCT ?env; SEPARATOR = "||") AS ?env_links)
    FROM <http://togogenome.org/graph/jcm>
    FROM <http://togogenome.org/graph/meo0.9>
    FROM <http://togogenome.org/graph/taxonomy>
    WHERE
    {
      {
        SELECT DISTINCT (?strain) as ?strain_id
        {
          VALUES ?search_meo_id { meo:#{meo_id} }
          ?search_meo_id a owl:Class .
          ?meo_id rdfs:subClassOf* ?search_meo_id .
          ?strain mccv:MCCV_000028/mccv:MCCV_000072/mccv:MCCV_000071 ?meo_id .
        }
      }
      ?strain_id mccv:MCCV_000010 ?strain_number ;
        mccv:MCCV_000012 ?strain_name .
      OPTIONAL { ?strain_id mccv:MCCV_000028/rdfs:label ?isolated_from }
      OPTIONAL {
        ?strain_id mccv:MCCV_000028/mccv:MCCV_000072/mccv:MCCV_000071 ?meo_id .
        ?meo_id rdfs:label ?meo_label .
        BIND (CONCAT(REPLACE(STR(?meo_id),"http://purl.jp/bio/11/meo/",""), ?meo_label) AS ?env )
      }
      VALUES ?related_tax_prop { mccv:MCCV_000020  mccv:MCCV_000023 obo:RO_0002162 }
      OPTIONAL {
        ?strain_id  ?related_tax_prop ?related_tax_id .
        BIND (REPLACE(STR(?related_tax_id),"http://identifiers.org/taxonomy/","") AS ?tax_no) .
      }
    } GROUP BY ?strain_id ?strain_number ?strain_name ORDER BY DESC (?source_id)
    SPARQL
    source_list = nbrc_list + jcm_list

    source_list.map {|hash|
      # Pads numbers with 0 to make NBRC's CAT id the 8 length.
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
    # TODO Add GOLD list
    source_list.sort_by{|row| row[:organism_name]}
  end
end
