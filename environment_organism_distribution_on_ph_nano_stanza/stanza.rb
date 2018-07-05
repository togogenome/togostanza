class EnvironmentOrganismDistributionOnPhNanoStanza < TogoStanza::Stanza::Base
  property :list do |meo_id|
    results = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mpo: <http://purl.jp/bio/01/mpo#>
      PREFIX mccv: <http://purl.jp/bio/01/mccv#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>

      SELECT ?tax_id ?opt_ph ?min_ph ?max_ph
      FROM <http://togogenome.org/graph/gold>
      FROM <http://togogenome.org/graph/mpo>
      FROM <http://togogenome.org/graph/meo>
      FROM <http://togogenome.org/graph/mccv>
      WHERE {
        VALUES ?meo_mapping { meo:MEO_0000437 meo:MEO_0000440 } .
        ?descendant rdfs:subClassOf* meo:#{meo_id} .
        ?gold ?meo_mapping ?descendant .
        ?gold mccv:MCCV_000020 ?tax_id .
        OPTIONAL {?tax_id mpo:MPO_10005 ?opt_ph}
        OPTIONAL {?tax_id mpo:MPO_10006 ?min_ph}
        OPTIONAL {?tax_id mpo:MPO_10007 ?max_ph}
        BIND (COALESCE(?opt_ph, ?min_ph, ?max_ph, <NopH>) AS ?ph)
        FILTER (regex(?tax_id, "identifiers.org") && !(?ph = <NopH>))
      }
    SPARQL
    mapping = { 0=>:ph0_2, 1=>:ph2_4, 2=>:ph4_6, 3=>:ph6_8, 4=>:ph8_10, 5=>:ph10_12, 6=>:ph12_14, 7=> :ph14 }
    ph2orgs = { ph0_2: 0, ph2_4: 0 ,ph4_6: 0, ph6_8: 0, ph8_10: 0, ph10_12: 0, ph12_14: 0, ph14: 0 }

    results.each do |rslt|
      if rslt.key?(:opt_ph)
        ph_range = (rslt[:opt_ph].to_f / 2).floor
      elsif rslt.key?(:min_ph) && rslt.key?(:max_ph)
        ph_range = ((rslt[:min_ph].to_f + rslt[:max_ph].to_f)/ 4).floor
      else
        raise('must not happen')
      end

      ph2orgs[mapping[ph_range]] += 1
    end
    ph2orgs
  end
end
