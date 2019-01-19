class OrganismMicrobialCellShapeNanoStanza < TogoStanza::Stanza::Base
  property :cell_shapes do |tax_id|
    result = query("http://togogenome.org/sparql-app", <<-SPARQL.strip_heredoc).first
      DEFINE sql:select-option "order"
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mpo: <http://purl.jp/bio/01/mpo#>
      PREFIX tax: <http://identifiers.org/taxonomy/>

      SELECT DISTINCT ?label ?file_name
      FROM <http://togogenome.org/graph/gold>
      FROM <http://togogenome.org/graph/mpo>
      WHERE {
        tax:#{tax_id} mpo:MPO_10019 ?morphology .
        ?morphology rdfs:label ?label FILTER (lang(?label) = "en")
        BIND (CONCAT(REPLACE(LCASE(?label)," ", "_"),".svg") AS ?file_name)
      }
    SPARQL

    if result
      file_path = File.expand_path("../assets/organism_microbial_cell_shape_nano/images/#{result[:file_name]}", __FILE__)
      if File.exist?(file_path)
        result[:image_url] = "/stanza/assets/organism_microbial_cell_shape_nano/images/#{result[:file_name]}"
      else
        result[:image_url] = "/stanza/assets/organism_microbial_cell_shape_nano/images/no_image.svg"
      end
      result
    else
      nil
    end
  end
end
