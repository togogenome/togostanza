class TaxonomyOrthologProfileStanza < TogoStanza::Stanza::Base
  property :title do |tax_id|
    "Orthologs of tax: #{tax_id}, number of members"
  end

  property :param_tax_id do |tax_id|
    tax_id
  end

  resource :taxonomy_ortholog_profile do |tax_id|
    ortholog_uris = query("http://bias5-db.nibb.ac.jp:8047/sparql/", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX mbgd: <http://purl.jp/bio/11/mbgd#>
      PREFIX orth: <http://purl.jp/bio/11/orth#>
      PREFIX dct: <http://purl.org/dc/terms/>
      PREFIX taxon: <http://purl.uniprot.org/taxonomy/>
      PREFIX mbgdr: <http://mbgd.genome.ad.jp/rdf/resource/>

      SELECT ?group ?comment (COUNT(?member) AS ?count)
      WHERE {
        ?tax rdfs:subClassOf* taxon:#{tax_id} .
        ?organism orth:taxon ?tax .
        ?member orth:organism ?organism .
        ?group orth:member ?member ;
          dct:description ?comment ;
          a orth:OrthologGroup ;
          orth:inDataset mbgdr:default .
      } ORDER BY DESC (?count) limit 10
    SPARQL
  end
end
