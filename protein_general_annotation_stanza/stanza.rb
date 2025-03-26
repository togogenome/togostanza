class ProteinGeneralAnnotationStanza < TogoStanza::Stanza::Base
  property :general_annotations do |tax_id, gene_id|

    result = query("https://dev.togogenome.org/sparql", <<-SPARQL.strip_heredoc)
    DEFINE sql:select-option "order"
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX up: <http://purl.uniprot.org/core/>

    SELECT DISTINCT ?name ?message
    FROM <http://togogenome.org/graph/uniprot>
    FROM <http://togogenome.org/graph/tgup>
    WHERE {
      {
        SELECT DISTINCT ?protein ?annotation
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
          ?protein up:annotation ?annotation .
        }
      }

      {
          # type がup:Annotation のアノテーション
          ?annotation a up:Annotation .
          # name, message の取得
          BIND(STR('Miscellaneous') AS ?name) .
          ?annotation rdfs:comment ?message .
      }UNION{
          # subClassOf Annotation で type が up:Subcellular_Location_Annotation のアノテーション
          ?annotation a up:Subcellular_Location_Annotation .
          # name, message の取得
          up:Subcellular_Location_Annotation rdfs:label ?name .
          ?annotation up:locatedIn ?located_in .
          ?located_in up:cellularComponent ?location .
          ?location up:alias ?message .
      }UNION{
          # type が up:Subcellular_Location_Annotation 以外の subClassOf Annotation のアノテーション
          ?annotation a ?type .
          ?type rdfs:subClassOf up:Annotation .
          FILTER (?type != up:Subcellular_Location_Annotation)
          # name, message の取得
          ?type rdfs:label ?name .
          ?annotation rdfs:comment ?message .
      }
    }
    SPARQL

    # [{name: 'xxx', message: 'aaa'}, {name: 'xxx', message: 'bbb'}, {name: 'yyy', message: 'ccc'}]
    # => [{name: 'xxx', messages: ['aaa', 'bbb']}, {name: 'yyy', messages: ['ccc']}]
    result.group_by {|a| a[:name] }.map {|k, vs|
      {
        name:     k,
        messages: vs.map {|v| v[:message] }
      }
    }.reverse
  end
end
