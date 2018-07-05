class GenomeCrossReferencesStanza < TogoStanza::Stanza::Base
  property :xrefs do |tax_id|
    results = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX obo: <http://purl.obolibrary.org/obo/>
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX insdc: <http://ddbj.nig.ac.jp/ontologies/nucleotide/>
      PREFIX idtax: <http://identifiers.org/taxonomy/>
      PREFIX ass: <http://ddbj.nig.ac.jp/ontologies/assembly/>

      SELECT ?assembly_name ?rs ?desc ?xref ?xref_type ?label
      WHERE
      {
        VALUES ?tax_id { idtax:#{tax_id} }
        GRAPH  <http://togogenome.org/graph/refseq>
        {
          ?sequence obo:RO_0002162 ?tax_id .
          ?refseq insdc:sequence ?sequence .
          ?refseq a insdc:Entry ;
            insdc:definition ?desc ;
            insdc:sequence_version ?rs .

          #link data
          { #BioProject
            ?refseq insdc:dblink ?xref .
            ?xref rdfs:label ?label ;
              rdf:type ?xref_type .
          }
          UNION
          { # RefSeq separated other xref, because refseq uri's rdf:label returns also description.
            ?refseq rdfs:seeAlso ?xref .
            ?xref insdc:sequence_version ?label ;
              rdf:type ?xref_type .
            FILTER (?xref_type IN (insdc:RefSeq))
          }
          UNION
          { # Other
            ?refseq rdfs:seeAlso ?xref .
            ?xref rdfs:label ?label ;
              rdf:type ?xref_type .
            FILTER (! ?xref_type IN (insdc:Entry, insdc:RefSeq))
          }
        }
        GRAPH <http://togogenome.org/graph/stats>
        {
          ?refseq rdfs:seeAlso ?ass_id .
        }
        GRAPH <http://togogenome.org/graph/assembly_report>
        {
          ?ass rdfs:seeAlso ?ass_id ;
            ass:assembly_id ?assembly_id ;
            ass:asm_name ?assembly_name .
        }
      } ORDER BY ?assembly_name ?refseq
    SPARQL

    results.group_by {|h| h[:assembly_name] }.map do |assembly, values|
      data = values.group_by {|h| h[:rs] }.map {|rs, v|
        {rs: rs, desc: v.first[:desc], xref: xref(v)}
      }
      assembly = 'Assembly:' + assembly
      {assembly: assembly, data: data}
    end
  end

  def xref(values)
    values.map {|hash|
      xref_db = hash[:xref_type].split('/').last
      xref_id = hash[:label]
      hash.merge(xref_db: xref_db, xref_id: xref_id)
    }.sort_by {|h| h[:xref_db] }
  end
end
