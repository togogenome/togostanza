class OrganismGeneListStanza < TogoStanza::Stanza::Base
  property :organism_gene_list do |tax_id|
    endpoint = "http://sparql-app.togogenome.org/sparql"

    ### gene - gene name, position, etc.
    gene_position = query(endpoint, <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"

      PREFIX idtax: <http://identifiers.org/taxonomy/>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX obo: <http://purl.obolibrary.org/obo/>
      PREFIX faldo: <http://biohackathon.org/resource/faldo#>

      SELECT ?gene ?gene_name (REPLACE (REPLACE( STR(?sequence), "#sequence$", ""), "http://identifiers.org/refseq/", "") AS ?seq) ?begin ?end
      WHERE {
        GRAPH <http://togogenome.org/graph/tgup> {
          ?gene rdfs:seeAlso idtax:#{tax_id} ;
            skos:exactMatch ?refseq_gene .
        }
        GRAPH <http://togogenome.org/graph/refseq> {
          ?refseq_gene rdfs:label ?gene_name ;
            obo:so_part_of ?sequence ;
            faldo:location/faldo:begin/faldo:position ?begin ;
            faldo:location/faldo:end/faldo:position ?end .
        }
      }
    SPARQL

    next [].to_json if gene_position.nil? || gene_position.empty?

    ### gene - pseudogene
    gene_pseudo = Thread.new do
      thread = Thread.current
      thread[:result] = query(endpoint, <<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"

        PREFIX idtax: <http://identifiers.org/taxonomy/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>

        SELECT ?gene
        WHERE {
          GRAPH <http://togogenome.org/graph/tgup> {
            ?gene rdfs:seeAlso idtax:#{tax_id} ;
              skos:exactMatch ?refseq_gene .
          }
          GRAPH <http://togogenome.org/graph/refseq> {
            ?refseq_gene insdc:pseudo true .
          }
        }
      SPARQL
    end

    ### gene - tRNA, ncRNA
    gene_rna_product = Thread.new do
      thread = Thread.current
      thread[:result] = query(endpoint, <<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"

        PREFIX idtax: <http://identifiers.org/taxonomy/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX obo: <http://purl.obolibrary.org/obo/>
        PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>

        SELECT ?gene ?product
        WHERE {
          GRAPH <http://togogenome.org/graph/tgup> {
            ?gene rdfs:seeAlso idtax:#{tax_id} ;
              skos:exactMatch ?refseq_gene .
          }
          GRAPH <http://togogenome.org/graph/refseq> {
            ?rna obo:so_part_of ?refseq_gene ;
              a ?type .
            FILTER (?type IN (insdc:Non_Coding_RNA, insdc:Transfer_RNA))
            ?rna insdc:product ?product .
            FILTER(! REGEX(?product, "uncharacterized", "i"))
          }
        }
      SPARQL
    end

    ### gene - citation
    gene_citation = Thread.new do
      thread = Thread.current
      thread[:result] = query(endpoint, <<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"

        PREFIX idtax: <http://identifiers.org/taxonomy/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX up: <http://purl.uniprot.org/core/>

        SELECT ?gene (COUNT(DISTINCT ?cite) AS ?citation)
        WHERE {
          GRAPH <http://togogenome.org/graph/tgup>  {
            ?gene rdfs:seeAlso idtax:#{tax_id} ;
              skos:exactMatch ?refseq_gene ;
              rdfs:seeAlso/rdfs:seeAlso ?uniprot .
          }
          GRAPH <http://togogenome.org/graph/uniprot> {
            ?uniprot up:citation ?cite .
            ?cite a up:Journal_Citation .
          }
        }
      SPARQL
    end

    ### gene - pathway
    gene_pathway = Thread.new do
      thread = Thread.current
      thread[:result] = query(endpoint, <<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"

        PREFIX idtax: <http://identifiers.org/taxonomy/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX up: <http://purl.uniprot.org/core/>

        SELECT DISTINCT ?gene ?pathway_label
        WHERE {
          {
            SELECT ?uniprot ?gene {
              GRAPH <http://togogenome.org/graph/tgup> {
                ?gene rdfs:seeAlso idtax:#{tax_id} ;
                  skos:exactMatch ?refseq_gene ;
                  rdfs:seeAlso/rdfs:seeAlso ?uniprot .
              }
              GRAPH <http://togogenome.org/graph/uniprot> {
                ?uniprot a up:Protein ;
                  up:reviewed ?reviewed .
              }
            } ORDER BY DESC(?reviewed) LIMIT 1
          } 
          ?uniprot up:annotation ?annotation .
          ?annotation rdf:type up:Pathway_Annotation ;
            rdfs:seeAlso/rdfs:label ?pathway_label .
        }
      SPARQL
    end

    ### gene - protein name, ec
    gene_protein = Thread.new do
      thread = Thread.current
      thread[:result] = query(endpoint, <<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"

        PREFIX idtax: <http://identifiers.org/taxonomy/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX up: <http://purl.uniprot.org/core/>

        SELECT DISTINCT ?gene ?protein_name ?ec_name
        WHERE {
          GRAPH <http://togogenome.org/graph/tgup> {
            ?gene rdfs:seeAlso idtax:#{tax_id} ;
              skos:exactMatch ?refseq_gene ;
              rdfs:seeAlso/rdfs:seeAlso ?uniprot .
          }
          GRAPH <http://togogenome.org/graph/uniprot> {
              {
                  select ?uniprot {
                      ?uniprot a up:Protein ;
                          up:reviewed ?reviewed .
                  } ORDER BY DESC(?reviewed) LIMIT 1
              }
              ?uniprot up:recommendedName ?recommended_name_node .
              ?recommended_name_node up:fullName ?protein_name .
              OPTIONAL { ?recommended_name_node up:ecName ?ec_name . }
          }
        }
      SPARQL
    end

    ### gene - GO
    gene_go = Thread.new do
      thread = Thread.current
      thread[:result] = query(endpoint, <<-SPARQL.strip_heredoc)
        DEFINE sql:select-option "order"

        PREFIX idtax: <http://identifiers.org/taxonomy/>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX up: <http://purl.uniprot.org/core/>
        PREFIX oboInOwl: <http://www.geneontology.org/formats/oboInOwl#>

        SELECT DISTINCT ?gene STR(?go_label) AS ?go_label ?namespace
        WHERE {
          GRAPH <http://togogenome.org/graph/tgup> {
            ?gene rdfs:seeAlso idtax:#{tax_id} ;
              skos:exactMatch ?refseq_gene ;
              rdfs:seeAlso/rdfs:seeAlso ?uniprot .
          }
          GRAPH <http://togogenome.org/graph/uniprot> {
            ?uniprot rdf:type up:Protein ;
               up:classifiedWith ?go  .
            ?go a owl:Class .
          }
          GRAPH <http://togogenome.org/graph/go> {
            ?go rdfs:label ?go_label ;
              oboInOwl:hasOBONamespace ?namespace .
          }
        }
      SPARQL
    end

    result = gene_position.map { |x| [x[:gene], x] }.to_h

    gene_pseudo.join
    result.deep_merge! gene_pseudo[:result].map { |x| [x[:gene], { pseudo: true }] }.to_h

    gene_rna_product.join
    result.deep_merge! gene_rna_product[:result].map { |x| [x[:gene], x] }.to_h

    gene_citation.join
    result.deep_merge! gene_citation[:result].map { |x| [x[:gene], x] }.to_h

    gene_pathway.join
    result.deep_merge! gene_pathway[:result].map { |x| [x[:gene], x] }.to_h

    gene_protein.join
    result.deep_merge! gene_protein[:result].map { |x| [x[:gene], x] }.to_h

    gene_go.join
    result.deep_merge! gene_go[:result].group_by { |x| [x[:gene], x[:namespace]] }
                                       .map { |x| [x[0][0], [ x[0][1].to_s, x[1].map { |y| y[:go_label] } ] ] }
                                       .group_by { |x| x[0] }
                                       .map { |x| [x[0], x[1].map { |y| y[1] }.to_h ] }.to_h

    result.values.to_json
  end
end

class Hash
  def deep_merge!(other_hash, &block)
    other_hash.each_pair do |k,v|
      tv = self[k]
      if tv.is_a?(Hash) && v.is_a?(Hash)
        self[k] = tv.deep_merge(v, &block)
      else
        self[k] = block && tv ? block.call(k, tv, v) : v
      end
    end
    self
  end

  def deep_merge(other_hash, &block)
    dup.deep_merge!(other_hash, &block)
  end
end
