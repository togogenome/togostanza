class GenomePlotStanza < TogoStanza::Stanza::Base
  property :selected_taxonomy_id do |tax_id|
    tax_id
  end

  resource :taxonomy do
    habitat_list =[]
    summary_list = []
    genome_list = []

    query1 = Thread.new {
      habitat_list = query("http://dev.togogenome.org/sparql-app",<<-SPARQL.strip_heredoc)
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX meo: <http://purl.jp/bio/11/meo/>
        PREFIX mccv: <http://purl.jp/bio/01/mccv#>

        SELECT ?tax (GROUP_CONCAT(DISTINCT ?label; SEPARATOR = ", ") AS ?habitat)
        FROM <http://togogenome.org/graph/gold>
        FROM <http://togogenome.org/graph/meo>
        WHERE
        {
          VALUES ?p_env { meo:MEO_0000437 meo:MEO_0000440 }
          ?gold mccv:MCCV_000020 ?tax FILTER regex(?tax, "^http://identifiers.org/") .
          ?gold ?p_env ?meo .
          ?meo a owl:Class ;
            rdfs:subClassOf* ?parent .
            ?parent rdfs:label ?label .
          ?parent meo:MEO_0000442 "1" .
        } GROUP BY ?tax
      SPARQL
    }

    query2 = Thread.new {
      genome_list = query("http://dev.togogenome.org/sparql-app",<<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX mccv: <http://purl.jp/bio/01/mccv#>
        PREFIX mpo: <http://purl.jp/bio/01/mpo#>
        PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
        PREFIX stats: <http://togogenome.org/stats/>
        PREFIX tax: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>
        PREFIX id_tax: <http://identifiers.org/taxonomy/>

        SELECT
          ?tax ?organism_name ?genome_length
          (GROUP_CONCAT(DISTINCT ?cell_shape_label; SEPARATOR = ", ") AS ?cell_shape_label)
          (GROUP_CONCAT(DISTINCT ?temp_range_label; SEPARATOR = ", ") AS ?temp_range_label)
          (GROUP_CONCAT(DISTINCT ?oxy_req_label; SEPARATOR = ", ") AS ?oxy_req_label)
          ?opt_temp ?min_temp ?max_temp ?opt_ph ?min_ph ?max_ph
        FROM <http://togogenome.org/graph/refseq>
        FROM <http://togogenome.org/graph/mpo>
        FROM <http://togogenome.org/graph/gold>
        FROM <http://togogenome.org/graph/stats>
        FROM <http://togogenome.org/graph/tgtax>
        FROM <http://togogenome.org/graph/taxonomy>
        {
          GRAPH <http://togogenome.org/graph/tgtax> {
            ?tax rdfs:subClassOf ?tax_scope.
            FILTER(?tax_scope IN (id_tax:2, id_tax:2157)) #bacteria or archaea
          }
          GRAPH <http://togogenome.org/graph/stats> {
            ?tax stats:sequence_length ?genome_length .
          }
          OPTIONAL { ?tax mpo:MPO_10001/rdfs:label ?cell_shape_label  FILTER (lang(?cell_shape_label) = "en") . }
          OPTIONAL { ?tax mpo:MPO_10003/rdfs:label ?temp_range_label  FILTER (lang(?temp_range_label) = "en") . }
          OPTIONAL { ?tax mpo:MPO_10002/rdfs:label ?oxy_req_label FILTER (lang(?oxy_req_label) = "en") . }
          OPTIONAL { ?tax mpo:MPO_10009 ?opt_temp . }
          OPTIONAL { ?tax mpo:MPO_10010 ?min_temp . }
          OPTIONAL { ?tax mpo:MPO_10011 ?max_temp . }
          OPTIONAL { ?tax mpo:MPO_10005 ?opt_ph . }
          OPTIONAL { ?tax mpo:MPO_10006 ?min_ph . }
          OPTIONAL { ?tax mpo:MPO_10007 ?max_ph . }
          ?tax tax:scientificName ?organism_name
        } GROUP BY ?tax ?organism_name ?genome_length ?opt_temp ?min_temp ?max_temp ?opt_ph ?min_ph ?max_ph
      SPARQL
    }

    #gene #pseudogene #rrna #trna #ncrna
    query3 = Thread.new {
      summary_list = query("http://dev.togogenome.org/sparql-app",<<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX togo: <http://togogenome.org/stats/>
        PREFIX tax: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>
        PREFIX id_tax: <http://identifiers.org/taxonomy/>

        SELECT DISTINCT ?tax ?num_gene ?num_pseudo ?num_rrna ?num_trna ?num_ncrna
        WHERE
        {
          GRAPH <http://togogenome.org/graph/tgtax> {
            ?tax rdfs:subClassOf ?tax_scope.
            FILTER(?tax_scope IN (id_tax:2, id_tax:2157)) #bacteria or archaea
          }
          GRAPH <http://togogenome.org/graph/stats> {
            ?tax togo:gene ?num_gene ;
              togo:pseudogene ?num_pseudo ;
              togo:rrna ?num_rrna ;
              togo:trna ?num_trna ;
              togo:ncrna ?num_ncrna .
          }
        }
      SPARQL
    }

    query1.join
    query2.join
    query3.join

    #habitat
    habitat_hash = {}
    habitat_list.each do |entity|
      habitat_hash[entity[:tax]] = entity[:habitat].split(", ").sort.join(", ")
    end
    habitat_list = nil

    #gene #pseudogene #rrna #trna #ncrna
    gene_hash ={}
    pseudo_hash ={}
    rrna_hash ={}
    trna_hash ={}
    ncrna_hash ={}
    summary_list.each do |entity|
      gene_hash[entity[:tax]] = entity[:num_gene]
      pseudo_hash[entity[:tax]] = entity[:num_pseudo]
      rrna_hash[entity[:tax]] = entity[:num_rrna]
      trna_hash[entity[:tax]] = entity[:num_trna]
      ncrna_hash[entity[:tax]] = entity[:num_ncrna]
    end
    gene_list = nil

    ##merge all data
    result_list = []
    result_list = genome_list.map {|hash|
      habitat_label = habitat_hash.key?(hash[:tax]) ? habitat_hash[hash[:tax]] :'no data'
      gene = gene_hash.key?(hash[:tax]) ? gene_hash[hash[:tax]] : '0'
      pseudo = pseudo_hash.key?(hash[:tax]) ? pseudo_hash[hash[:tax]] : '0'
      rrna = rrna_hash.key?(hash[:tax]) ? rrna_hash[hash[:tax]] : '0'
      trna = trna_hash.key?(hash[:tax]) ? trna_hash[hash[:tax]] : '0'
      ncrna = ncrna_hash.key?(hash[:tax]) ? ncrna_hash[hash[:tax]] : '0'
      hash.merge(
        habitat: habitat_label,
        num_gene: gene,
        num_pseudo: pseudo,
        num_rrna: rrna,
        num_trna: trna,
        num_ncrna: ncrna,
        size: hash[:genome_length]
      )
    }
    result_list.delete_if {|entity| entity[:num_gene] == '0'}

    result_list
  end
end
