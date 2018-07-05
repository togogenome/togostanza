require 'bio-svgenes'

class GenomeGenomicContextStanza < TogoStanza::Stanza::Base
  property :svg do |tax_id, gene_id|
    results = query("http://dev.togogenome.org/sparql-app", <<-SPARQL.strip_heredoc)
      DEFINE sql:select-option "order"
      PREFIX rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs:   <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX obo:    <http://purl.obolibrary.org/obo/>
      PREFIX faldo:  <http://biohackathon.org/resource/faldo#>
      PREFIX insdc:  <http://ddbj.nig.ac.jp/ontologies/sequence#>

      SELECT ?gene ?gene_type ?seq ?seq_type ?gene_loc ?gene_begin ?gene_end ?ncbi_taxid ?obj ?b ?e ?strand ?obj_label ?label ?obj_name ?pb ?pe
      FROM <http://togogenome.org/graph/refseq/>
      FROM <http://togogenome.org/graph/so/>
      FROM <http://togogenome.org/graph/faldo/>
      WHERE
      {
        {
          SELECT ?gene ?gene_type ?seq ?seq_type ?gene_loc ?gene_begin ?gene_end ?ncbi_taxid ?obj ?b ?e ?strand ?obj_label
          WHERE
          {
            VALUES ?locus_tag { "#{ gene_id }" }
            VALUES ?seq_type  { obo:SO_0000340 obo:SO_0000155 } # chromosome, plasmid
            VALUES ?gene_type { obo:SO_0000316 obo:SO_0000252 obo:SO_0000253 } # CDS, rRNA, tRNA
            VALUES ?faldo_type { faldo:ForwardStrandPosition faldo:ReverseStrandPosition }
            VALUES ?offset { 2000 }

            # gene
            ?gene insdc:locus_tag ?locus_tag.
            ?gene a ?gene_type.

            # seq
            ?gene obo:so_part_of+ ?seq.
            ?seq a ?seq_type.

            # faldo
            ?gene faldo:location ?gene_loc.
            ?gene_loc faldo:begin/faldo:position ?gene_begin.
            ?gene_loc faldo:end/faldo:position ?gene_end.

            # taxonomy ncbi
            ?seq rdfs:seeAlso ?taxonomy .
            ?taxonomy a <http://identifiers.org/taxonomy/> .
            ?taxonomy rdfs:label ?ncbi_taxid .

            # objects around the gene
            ?obj obo:so_part_of+ ?seq .

            ?obj faldo:location ?faldo .
            ?faldo faldo:begin/rdf:type ?faldo_type .
            ?faldo_type rdfs:label ?strand .
            ?faldo faldo:begin/faldo:position ?b .
            ?faldo faldo:end/faldo:position ?e .
            FILTER (!(?b > ?gene_end + ?offset || ?e < ?gene_begin - ?offset))

            ?obj rdf:type ?obj_type .
            ?obj_type rdfs:label ?obj_label .
            FILTER (?obj_type != obo:SO_0000704)  # gene
          }
        }
        OPTIONAL { ?obj insdc:locus_tag ?label . }
        OPTIONAL { ?obj insdc:product ?obj_name . }
        OPTIONAL
        {
          ?obj obo:so_has_part/rdf:rest*/rdf:first ?part .
          ?part faldo:begin/faldo:position ?pb .
          ?part faldo:end/faldo:position ?pe .
        }
      } ORDER BY ?b
    SPARQL
    objs = results.group_by {|h| h[:obj]}

    page = Bio::Graphics::Page.new(
      width: 800,
      height: 200,
      number_of_intervals: 3
    )

    gene_track = nil
    rrna_track = nil
    trna_track = nil
    other_track = nil

    objs.each do |k, gene|
      exons = []
      param = {}

      gene.each do |exon|
        param[:id] = exon[:label]
        param[:type] = exon[:obj_label]
        param[:start] = exon[:b].to_i
        param[:end] = exon[:e].to_i

        case exon[:strand]
        when 'Positive strand'
          param[:strand] = '+'
        else
          param[:strand] = '-'
        end

        if exon[:pb] and exon[:pe]
          exons << [exon[:pb].to_i, exon[:pe].to_i]
        else
          exons << [exon[:b].to_i, exon[:e].to_i]
        end
      end

      obj = Bio::Graphics::MiniFeature.new(
        id: param[:id],
        start: param[:start],
        end: param[:end],
        strand: param[:strand],
        exons: exons.sort_by{|x| x.first}.flatten
      )

      case param[:type]
      when "CDS"
        unless gene_track
          gene_track = page.add_track(
            glyph: :transcript,
            name: 'protein coding gene',
            feature_height: 15,
            exon_fill_color: :blue_white_h,
            utr_fill_color: :red_white_h,
            gap_marker: 'angled'
          )
        end

        gene_track.add(obj)
      when "rRNA"
        unless rrna_track
          rrna_track = page.add_track(
            glyph: :transcript,
            name: 'rRNA gene',
            feature_height: 15,
            exon_fill_color: :yellow_white_h,
            utr_fill_color: :red_white_h,
            gap_marker: 'angled'
          )
        end

        rrna_track.add(obj)
      when "tRNA"
        unless trna_track
          trna_track = page.add_track(
            glyph: :transcript,
            name: 'tRNA gene',
            feature_height: 15,
            exon_fill_color: :green_white_h,
            utr_fill_color: :red_white_h,
            gap_marker: 'angled'
          )
        end

        trna_track.add(obj)
      else
        unless other_track
          other_track = page.add_track(
            glyph: :transcript,
            name: 'other',
            feature_height: 15,
            exon_fill_color: :red_white_h,
            utr_fill_color: :red_white_h,
            gap_marker: 'angled'
          )
        end

        other_track.add(obj)
      end
    end

    # reserve diagram width
    range = page.add_track(
      glyph: :generic,
      label: false,
      feature_height: 2,
      stroke_width: 1,
      stroke: 'white',
      fill_color: 'white',
      line_color: 'white'
    )

    h_tmp = results.first
    f = h_tmp[:gene_begin].to_i - h_tmp[:offset].to_i
    t = h_tmp[:gene_end].to_i + h_tmp[:offset].to_i

    #rf = (f - offset) / 1000
    #rt = (t + offset) / 1000

    feature = Bio::Graphics::MiniFeature.new(
      start: f, # rf * 1000,
      end: t, # rt * 1000,
      strand: '+'
    )

    range.add(feature)

    svg = page.get_markup
  end
end
