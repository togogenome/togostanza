class EnvironmentTopLevelSymbolicImageNanoStanza < TogoStanza::Stanza::Base
  property :top_level_category do |meo_id|
    result = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc).first
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX owl: <http://www.w3.org/2002/07/owl#>
      PREFIX meo: <http://purl.jp/bio/11/meo/>

      SELECT DISTINCT ?ancestor
      FROM <http://togogenome.org/graph/meo>
      WHERE {
        ?ancestor rdf:type owl:Class
        FILTER (?ancestor IN (meo:MEO_0000001, meo:MEO_0000002, meo:MEO_0000003, meo:MEO_0000004, meo:MEO_0000005) ).
        meo:#{meo_id} rdfs:subClassOf* ?ancestor .
      }
    SPARQL
    if result
      name = name_by_ancestor(result[:ancestor])

      result.merge(
        name: name.capitalize,
        image_url: "/stanza/assets/environment_top_level_symbolic_image_nano/meo_#{name}.svg"
      )
    else
      nil
    end
  end

  private

  def name_by_ancestor(ancestor)
    case ancestor
    when /MEO_0000001/
      'atmosphere'
    when /MEO_0000002/
      'geosphere'
    when /MEO_0000003/
      'anthrosphere'
    when /MEO_0000004/
      'hydrosphere'
    when /MEO_0000005/
      'organism_association'
    end
  end
end
