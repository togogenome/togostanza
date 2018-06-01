class OrganismGenomeSizeNanoStanza < TogoStanza::Stanza::Base
  property :genome_size do |tax_id|
   result = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
     PREFIX taxid: <http://identifiers.org/taxonomy/>
     PREFIX stats: <http://togogenome.org/stats/>

     SELECT ?genome_size
     FROM <http://togogenome.org/graph/stats>
     WHERE
     {
       taxid:#{tax_id} stats:sequence_length ?genome_size .
     }
   SPARQL

   if result.nil? || result.size.zero?
     result = nil
     next
   end

   genome_size = result.first[:genome_size].to_f

   if genome_size >= 10**9
     mantissa = (genome_size / (10**9).to_f).round(1)
     unit = "Gb"
   elsif genome_size >= 10**6
     mantissa = (genome_size / (10**6).to_f).round(1)
     unit = "Mb"
   elsif genome_size >= 10**3
     mantissa = (genome_size / (10**3).to_f).round(1)
     unit = "Kb"
   else
     mantissa = genome_size
     unit = "b"
   end

   ret = { :genome_size => genome_size, :mantissa => mantissa, :unit => unit }
   ret
  end
end
