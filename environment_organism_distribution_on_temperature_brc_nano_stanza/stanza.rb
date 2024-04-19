class EnvironmentOrganismDistributionOnTemperatureBrcNanoStanza < TogoStanza::Stanza::Base
  property :num_orgs_with_temperature_range do |meo_id|
    brc_results = query("http://sparql-app.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX mpo: <http://purl.jp/bio/10/mpo/>
    PREFIX mccv: <http://purl.jp/bio/10/mccv#>
    PREFIX meo: <http://purl.jp/bio/11/meo/>
    PREFIX sio: <http://semanticscience.org/resource/>

    SELECT DISTINCT ?strain_id ?opt_temp_brc ?min_temp_brc ?max_temp_brc
    FROM <http://togogenome.org/graph/nbrc>
    FROM <http://togogenome.org/graph/jcm>
    FROM <http://togogenome.org/graph/meo0.9>
    WHERE {
      {
        SELECT DISTINCT (?strain) as ?strain_id
        {
          VALUES ?search_meo_id { meo:#{meo_id} }
          VALUES ?mep_prop { sio:SIO_000008 mccv:MCCV_000071 } #diffrence nbrc/jcm
          ?search_meo_id a owl:Class .
          ?meo_id rdfs:subClassOf* ?search_meo_id .
           ?isolated_from ?mep_prop  ?meo_id .
           ?strain mccv:MCCV_000028/mccv:MCCV_000072 ?isolated_from .
        }
      }
      OPTIONAL {
        { # nbrc
          ?strain_id sio:SIO_000216 ?blank .
          ?blank rdf:type mpo:MPO_00102 ;
            sio:SIO_000300  ?opt_temp_brc .
        }
        UNION
        { # jcm
          ?strain_id mccv:MCCV_000073/sio:SIO_000216 ?blank .
          ?blank a mpo:MPO_00102 ;
          sio:SIO_000300 ?opt_temp_brc .
        }
      }
      OPTIONAL {
        ?strain_id sio:SIO_000216 ?blank .
        ?blank rdf:type mpo:MPO_00104 ;
          sio:SIO_000300  ?min_temp_brc .
      }
      OPTIONAL {
        ?strain_id sio:SIO_000216 ?blank .
        ?blank rdf:type mpo:MPO_00103 ;
          sio:SIO_000300  ?max_temp_brc .
      }
    }
    SPARQL

    gold_results = query("http://sparql-app.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX mpo: <http://purl.jp/bio/01/mpo#>
    PREFIX mccv: <http://purl.jp/bio/01/mccv#>
    PREFIX meo: <http://purl.jp/bio/11/meo/>

    SELECT DISTINCT ?tax_id ?opt_temp ?min_temp ?max_temp ?l
    FROM <http://togogenome.org/graph/gold>
    FROM <http://togogenome.org/graph/mpo>
    FROM <http://togogenome.org/graph/meo0.9>
    WHERE {
      VALUES ?meo_mapping { meo:MEO_0000437 meo:MEO_0000440 } .
      ?descendant rdfs:subClassOf* meo:#{meo_id} .
      ?gold ?meo_mapping ?descendant .
      OPTIONAL {?gold mccv:MCCV_000020 ?tax_id}
      OPTIONAL {?tax_id mpo:MPO_10009 ?opt_temp}
      OPTIONAL {?tax_id mpo:MPO_10010 ?min_temp}
      OPTIONAL {?tax_id mpo:MPO_10011 ?max_temp}
      OPTIONAL {?tax_id mpo:MPO_10003 ?growth_temp_range .
                ?growth_temp_range rdfs:label ?label .
                FILTER(lang(?label) = "en")
                BIND(str(?label) AS ?l)}
      BIND (COALESCE(?opt_temp, ?min_temp, ?max_temp,
                     ?growth_temp_range, ?l, <NA>) AS ?temperature)
      FILTER (regex(?tax_id, "identifiers.org") &&
              (!(?temperature = <NA>) || bound(?growth_temp_range)))
    }
    SPARQL

    results = brc_results.concat(gold_results)

    category2num = {Mesophile: 0, Thermophile: 0, Psychrophile: 0}
    results.each do |result|
      category = find_category(result)
      if category2num.key?(category)
        category2num[category] += 1
      end
    end
    category2num
  end

  def find_category(hash)
    opt_temp = 0.0
    if hash.key?(:l)
      category_by_label(hash[:l])
    elsif hash.key?(:opt_temp) || hash.key?(:opt_temp_brc)
      opt_temp = hash.key?(:opt_temp) ? hash[:opt_temp].to_f : hash[:opt_temp_brc].to_f
      category_by_range(opt_temp, opt_temp)
    elsif hash.key?(:min_temp) && hash.key?(:max_temp)
      category_by_range(hash[:min_temp].to_f, hash[:max_temp].to_f)
    elsif hash.key?(:min_temp_brc) && hash.key?(:max_temp_brc)
      category_by_range(hash[:min_temp_brc].to_f, hash[:max_temp_brc].to_f)
    else
      :NA
    end
  end

  def category_by_label(label)
    case label
    when "Mesophile", "Psychrophile", "Thermophile"
      label.to_sym
    when "Thermophilic"
      :Thermophile
    when "Hyperthermophilic"
      :Thermophile
    when "Hyperthermophile"
      :Thermophile
    else
      :NA
    end
  end

  def category_by_range(min, max)
    if min >= 20 && max <= 45
      :Mesophile
    elsif min > 45
      :Thermophile
    elsif max < 10
      :Psychrophile
    else
      :NA
    end
  end
end
