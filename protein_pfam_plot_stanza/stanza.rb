class ProteinPfamPlotStanza < TogoStanza::Stanza::Base
  property :pfam_list do |tax_id, gene_id|
    results = query("http://dev.togogenome.org/sparql-app",<<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX up: <http://purl.uniprot.org/core/>
      PREFIX taxonomy: <http://purl.uniprot.org/taxonomy/>

      SELECT DISTINCT (REPLACE(STR(?ref), "http://purl.uniprot.org/pfam/","") AS ?pfam_id)
      FROM <http://togogenome.org/graph/uniprot>
      FROM <http://togogenome.org/graph/tgup>
      WHERE
      {
        {
          SELECT ?protein
          {
            <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
              rdfs:seeAlso ?id_upid .
            ?id_upid rdfs:seeAlso ?protein .
            ?protein a up:Protein ;
              up:reviewed ?reviewed .
          } ORDER BY DESC(?reviewed) LIMIT 1
        }
        ?protein rdfs:seeAlso ?ref .
        ?ref up:database ?database .
        ?database up:abbreviation ?abbr
        FILTER (?abbr ='Pfam').
      }
    SPARQL
    if results == nil || results.size == 0 then
      next nil
    end
    pfam_list = []
    results.each do |entity|
      pfam_hash = {}
      pfam_id = entity[:pfam_id]
      pfam_name_list =  query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX pfam: <http://purl.uniprot.org/pfam/>

        SELECT ?label
        WHERE
        {
          pfam:#{pfam_id} rdfs:comment ?label .
        }
      SPARQL
      pfam_hash[:id] = pfam_id
      if pfam_name_list == nil || pfam_name_list.size == 0 then
        pfam_hash[:name] = ''
      else
        pfam_hash[:name] = pfam_name_list[0][:label]
      end
      pfam_list.push(pfam_hash)
    end
    pfam_list
  end

  property :selected_tax_id do |tax_id, gene_id|
    tax_id =  query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX tax: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>
      SELECT DISTINCT ?tax_no
      FROM <http://togogenome.org/graph/tgup>
      FROM <http://togogenome.org/graph/taxonomy>
      WHERE
      {
        {
          SELECT ?gene
          {
            <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene .
          } ORDER BY ?gene LIMIT 1
        }
        <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
          rdfs:seeAlso ?tax_id .
        ?tax_id a tax:Taxon .
        BIND (REPLACE(STR(?tax_id), "http://identifiers.org/taxonomy/","") AS ?tax_no)
      }
    SPARQL
    tax_id.first[:tax_no]
  end

  property :selected_tax_id do |tax_id|
    tax_id
  end

  property :selected_gene_id do |gene_id|
    gene_id
  end

  resource :plot_data do |tax_id, gene_id|
     habitat_list =[]
     summary_list = []
     genome_list = []
     pfam_list = []
     pfam_summary_list = []

    pfam_list = query("http://dev.togogenome.org/sparql-app",<<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX up: <http://purl.uniprot.org/core/>
      PREFIX taxonomy: <http://purl.uniprot.org/taxonomy/>

      SELECT DISTINCT (REPLACE(STR(?ref), "http://purl.uniprot.org/pfam/","") AS ?pfam_id)
      FROM <http://togogenome.org/graph/uniprot>
      FROM <http://togogenome.org/graph/tgup>
      WHERE
      {
        {
          SELECT ?protein
          {
            <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
              rdfs:seeAlso ?id_upid .
            ?id_upid rdfs:seeAlso ?protein .
            ?protein a up:Protein ;
              up:reviewed ?reviewed .
          } ORDER BY DESC(?reviewed) LIMIT 1
        }
        ?protein rdfs:seeAlso ?ref .
        ?ref up:database ?database .
        ?database up:abbreviation ?abbr
        FILTER (?abbr ='Pfam').
      }
    SPARQL

    if pfam_list == nil || pfam_list.size == 0 then
      pfam_list = []
      next
    end

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
          ?gold mccv:MCCV_000020 ?tax FILTER regex(STR(?tax), "^http://identifiers.org/") .
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

        SELECT ?tax ?num_gene ?num_pseudo ?num_rrna ?num_trna ?num_ncrna
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
    summary_list = nil

    result_hash = {}
    pfam_list.each do |pfam_entity|
      pfam_id = pfam_entity[:pfam_id]
      pfam_summary_list = query("http://dev.togogenome.org/sparql-app",<<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"
        PREFIX sio: <http://semanticscience.org/resource/>
        PREFIX up: <http://purl.uniprot.org/core/>
        PREFIX pfam: <http://purl.uniprot.org/pfam/>
        PREFIX stats: <http://togogenome.org/stats/>

        SELECT
          (REPLACE(STR(?tax), "http://purl.uniprot.org/taxonomy/", "http://identifiers.org/taxonomy/") AS ?tax_id)
          ((SUM(?hits) AS ?num_pfam))
          (COUNT(DISTINCT(?prot_id)) AS ?num_pfam_protein)
        FROM <http://togogenome.org/graph/uniprot>
        FROM <http://togogenome.org/graph/stats>
        WHERE
        {
          pfam:#{pfam_id} stats:pfam_info ?pfam_info .
          ?pfam_info sio:SIO_000068 ?uniprot_id ;
            up:hits ?hits .
          ?uniprot_id up:organism ?tax .
        } GROUP BY ?tax
      SPARQL

      pfam_hash ={}
      pfam_protein_hash ={}
      pfam_summary_list.each do |entity|
        pfam_hash[entity[:tax_id]] = entity[:num_pfam]
        pfam_protein_hash[entity[:tax_id]] = entity[:num_pfam_protein]
      end
      pfam_summary_list = nil

      ##merge all data
      tax_list = []
      tax_list = genome_list.map {|hash|
        habitat_label = habitat_hash.key?(hash[:tax]) ? habitat_hash[hash[:tax]] :'no data'
        gene = gene_hash.key?(hash[:tax]) ? gene_hash[hash[:tax]] : '0'
        pseudo = pseudo_hash.key?(hash[:tax]) ? pseudo_hash[hash[:tax]] : '0'
        rrna = rrna_hash.key?(hash[:tax]) ? rrna_hash[hash[:tax]] : '0'
        trna = trna_hash.key?(hash[:tax]) ? trna_hash[hash[:tax]] : '0'
        ncrna = ncrna_hash.key?(hash[:tax]) ? ncrna_hash[hash[:tax]] : '0'
        pfam = pfam_hash.key?(hash[:tax]) ? pfam_hash[hash[:tax]] : '0'
        pfam_protein = pfam_protein_hash.key?(hash[:tax]) ? pfam_protein_hash[hash[:tax]] : '0'
        hash.merge(
          habitat: habitat_label,
          num_gene: gene,
          num_pseudo: pseudo,
          num_rrna: rrna,
          num_trna: trna,
          num_ncrna: ncrna,
          num_pfam: pfam,
          num_pfam_protein: pfam_protein,
          size: hash[:genome_length]
        )
      }
      tax_list.delete_if {|entity| entity[:num_gene] == '0'}
      result_hash[pfam_id] = tax_list
    end
    [result_hash]
  end
end
