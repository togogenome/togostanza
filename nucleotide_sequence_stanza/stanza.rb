require 'net/http'
require 'uri'

class NucleotideSequenceStanza < TogoStanza::Stanza::Base
  property :nucleotide_sequences do |tax_id, gene_id|
    feature_list1 = []
    feature_list2 = []
    feature_list3 = []
    feature_list4 = []
    query1 = Thread.new {
      feature_list1 = query("http://sparql-app.togogenome.org/sparql",<<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX obo:    <http://purl.obolibrary.org/obo/>
        PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
        PREFIX uniprot: <http://purl.uniprot.org/core/>

        SELECT ?feature ?priority ?reviewed
        { 
          GRAPH <http://togogenome.org/graph/tgup>
          {
            VALUES ?tggene { <http://togogenome.org/gene/#{tax_id}:#{gene_id}> }
            ?tggene skos:exactMatch ?gene ;
              rdfs:seeAlso/rdfs:seeAlso ?uniprot .
          }
          GRAPH <http://togogenome.org/graph/uniprot>
          {
            ?uniprot a uniprot:Protein ;
              uniprot:reviewed ?reviewed ;
              uniprot:sequence ?isoform .
            ?isoform rdf:type uniprot:Simple_Sequence ;
              rdf:value ?protein_seq .
          }
          GRAPH <http://togogenome.org/graph/refseq>
          {
            VALUES ?feature_type { insdc:Coding_Sequence }
            ?feature obo:so_part_of ?gene ;
              a ?feature_type ;
              insdc:translation ?translation .
            VALUES ?priority { 1 }
          }
          FILTER (?protein_seq = ?translation)
        } ORDER BY DESC(?reviewed)
      SPARQL
    }
    query2 = Thread.new {
      feature_list2 = query("http://sparql-app.togogenome.org/sparql",<<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX obo:    <http://purl.obolibrary.org/obo/>
        PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
        PREFIX uniprot: <http://purl.uniprot.org/core/>

        SELECT ?feature ?priority ?reviewed
        { 
          GRAPH <http://togogenome.org/graph/tgup>
          {
            VALUES ?tggene { <http://togogenome.org/gene/#{tax_id}:#{gene_id}> }
            ?tggene skos:exactMatch ?gene ;
              rdfs:seeAlso/rdfs:seeAlso ?uniprot .
          }
          GRAPH <http://togogenome.org/graph/uniprot>
          {
            ?uniprot a uniprot:Protein ;
              uniprot:reviewed ?reviewed ;
              uniprot:sequence ?isoform .
            ?isoform rdf:type uniprot:Simple_Sequence ;
              rdf:value ?protein_seq .
          }
          GRAPH <http://togogenome.org/graph/refseq>
          {
            VALUES ?feature_type { insdc:Coding_Sequence }
            ?feature obo:so_part_of ?gene ;
              a ?feature_type ;
              insdc:translation ?translation .
            VALUES ?priority { 1 }
          }
          FILTER (?protein_seq = ?translation)
        } ORDER BY DESC(?reviewed)
      SPARQL
    }
    query3 = Thread.new {
      feature_list3 = query("http://sparql-app.togogenome.org/sparql",<<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX obo:    <http://purl.obolibrary.org/obo/>
        PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
        PREFIX uniprot: <http://purl.uniprot.org/core/>
 
        SELECT ?feature ?priority ?reviewed
        { 
          GRAPH <http://togogenome.org/graph/tgup>
          {
            VALUES ?tggene { <http://togogenome.org/gene/#{tax_id}:#{gene_id}> }
            ?tggene skos:exactMatch ?gene .
          }
          GRAPH <http://togogenome.org/graph/refseq>
          {
            VALUES ?feature_type { insdc:Coding_Sequence }
            ?feature obo:so_part_of ?gene ;
              a ?feature_type .
            VALUES ?reviewed { 0 }
            VALUES ?priority { 3 }
          }
        }
      SPARQL
    }
    query4 = Thread.new {
      feature_list4 = query("http://sparql-app.togogenome.org/sparql",<<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX obo:    <http://purl.obolibrary.org/obo/>
        PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
        PREFIX uniprot: <http://purl.uniprot.org/core/>
 
        SELECT ?feature ?priority ?reviewed
        { 
          GRAPH <http://togogenome.org/graph/tgup>
          {
            VALUES ?tggene { <http://togogenome.org/gene/#{tax_id}:#{gene_id}> }
            ?tggene skos:exactMatch ?gene .
          }
          GRAPH <http://togogenome.org/graph/refseq>
          {
            VALUES ?feature_type { insdc:Transfer_RNA insdc:Ribosomal_RNA insdc:Non_Coding_RNA }
            ?feature obo:so_part_of ?gene ;
              insdc:location ?insdc_location ;
              a ?feature_type .
            VALUES ?reviewed { 0 }
            VALUES ?priority { 4 }
          }
        }
      SPARQL
    }
    query1.join
    query2.join
    query3.join
    query4.join
    # 一つのクエリでUNIONで繋ぐと返ってこなくなったのでクエリを分割

    # priority, reviewed の順で最初の1 featureを選択
    feature_list1.concat(feature_list2)
    feature_list1.concat(feature_list3)
    feature_list1.concat(feature_list4)
    if feature_list1.size == 0
      nil
      next
    end
    feature = feature_list1.first[:feature]

    results = query("http://sparql-app.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX obo:    <http://purl.obolibrary.org/obo/>
      PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>

      SELECT ?nuc_seq_pos
      FROM <http://togogenome.org/graph/refseq>
      {
        {
          <#{feature}> insdc:location ?insdc_location ;
            obo:so_part_of/obo:so_part_of/^insdc:sequence/insdc:sequence_version ?refseq_ver  .
          BIND (CONCAT("http://togows.dbcls.jp/entry/nucleotide/", ?refseq_ver,"/seq/", ?insdc_location) AS ?nuc_seq_pos)
        }
      }
    SPARQL

    if results.nil? || results.size == 0
      nil
      next
    end

    results.map {|hash|
      hash.merge(
        value: get_sequence_from_togows(hash[:nuc_seq_pos]).upcase
      )
    }.first
  end

  #Returns sequence characters from the TogoWS API.
  def get_sequence_from_togows(togows_url)
    url = URI.parse(togows_url)
    path = Net::HTTP::Get.new(url.path)
    Net::HTTP.start(url.host, url.port) {|http|
      res = http.request(path)
      res.body
    }
  end
end
