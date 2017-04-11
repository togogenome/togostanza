class ProteinNamesStanza < TogoStanza::Stanza::Base
  property :protein_names do |tax_id, gene_id|
    # genes
    gene_names = query("http://togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX up: <http://purl.uniprot.org/core/>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

      SELECT DISTINCT ?gene_name ?synonyms_name ?locus_name ?orf_name
      FROM <http://togogenome.org/graph/uniprot>
      FROM <http://togogenome.org/graph/tgup>
      WHERE {
        {
          SELECT ?gene
          {
            <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene .
          } ORDER BY ?gene LIMIT 1
        }
        <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
          rdfs:seeAlso ?id_upid .
        ?id_upid rdfs:seeAlso ?protein .
        ?protein a up:Protein .

        # Gene names
        ?protein up:encodedBy ?gene_hash .

        ## Name:
        OPTIONAL { ?gene_hash skos:prefLabel ?gene_name . }

        ## Synonyms:
        OPTIONAL { ?gene_hash skos:altLabel ?synonyms_name . }

        ## Ordered Locus Names:
        OPTIONAL { ?gene_hash up:locusName ?locus_name . }

        ## ORF Names:
        OPTIONAL { ?gene_hash up:orfName ?orf_name . }
      }
    SPARQL
    genes = {}
    unless gene_names.nil? || gene_names.size.zero?
      genes = gene_names.flat_map(&:to_a).group_by(&:first).each_with_object({}) {|(k, vs), hash|
        hash[k] = vs.map(&:last).uniq
      }
    end

    # summary
    protein_summary = query("http://togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX up: <http://purl.uniprot.org/core/>

      SELECT DISTINCT ?recommended_name ?ec_name ?alternative_names
      FROM <http://togogenome.org/graph/taxonomy>
      FROM <http://togogenome.org/graph/uniprot>
      FROM <http://togogenome.org/graph/tgup>
      WHERE {
        {
          SELECT ?gene
          {
            <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene .
          } ORDER BY ?gene LIMIT 1
        }
        <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
          rdfs:seeAlso ?id_upid .
        ?id_upid rdfs:seeAlso ?protein .
        ?protein a up:Protein .

        # Protein names
        ## Recommended name:
        OPTIONAL {
          ?protein up:recommendedName ?recommended_name_node .
          ?recommended_name_node up:fullName ?recommended_name .
        }

        ### EC=
        OPTIONAL { ?recommended_name_node up:ecName ?ec_name . }

        OPTIONAL {
          ?protein up:alternativeName ?alternative_names_node .
          ?alternative_names_node up:fullName ?alternative_names .
        }
      }
    SPARQL

    summary = {}
    unless protein_summary.nil? || protein_summary.size.zero?
      # alternative_names, parent_taxonomy_names のみ複数取りうる
      summary = protein_summary.flat_map(&:to_a).group_by(&:first).each_with_object({}) {|(k, vs), hash|
        v = vs.map(&:last).uniq
        hash[k] = [:alternative_names, :parent_taxonomy_names].include?(k) ? v : v.first
      }

      summary[:parent_taxonomy_names].reverse! if summary[:parent_taxonomy_names]
    end
    protein_names = genes.merge(summary)

    organism = query("http://togogenome.org/sparql", <<-SPARQL.strip_heredoc)
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX taxo: <http://ddbj.nig.ac.jp/ontologies/taxonomy/>
      PREFIX taxid: <http://identifiers.org/taxonomy/>

      SELECT DISTINCT ?tax ?tax_label
      FROM <http://togogenome.org/graph/taxonomy>
      FROM <http://togogenome.org/graph/tgup>
      WHERE
      {
        <http://togogenome.org/gene/#{tax_id}:#{gene_id}> skos:exactMatch ?gene ;
          rdfs:seeAlso ?id_taxid.
        ?id_taxid rdfs:seeAlso ?search_tax .
        ?search_tax a taxo:Taxon .
        ?search_tax rdfs:subClassOf ?tax OPTION (transitive, t_direction 1, t_min(0), t_step("step_no") as ?step) .
        ?tax rdfs:label ?tax_label .
        FILTER(?tax != taxid:1)
      } ORDER BY DESC(?step)
    SPARQL
    if organism.size != 0
      protein_names[:taxonomy_id] = organism.last[:tax].split('/').last
      protein_names[:organism_name] = organism.last[:tax_label]
      protein_names[:parent_taxonomy_names] = organism[0..-2].map {|row| row[:tax_label]}
    end

    if protein_names.keys.size == 0
      nil
      next
    end

    protein_names
  end
end
