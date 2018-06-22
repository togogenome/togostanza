var opt;
var tooltips
var base;
var data;
var has_range_data;

 //temporary data for transition
var new_scale;
var new_item;

 //status
var current_x_scale;
var current_y_scale;
var current_x_item;
var current_y_item;
var current_pfam;
var current_color;
var current_category;
var current_category_highlight;

//temporary data for mapping the sparql results
var data_tax;
var data_habitat;
var data_phenotype;

var fontsize = 10; //same value with css
/*
Create page
*/
function create_page(sparql_result,option,type) {
  opt = option;
  base = sparql_result;
  d3.select("#scatter_plot").append("div").attr("id","title_label").attr("class","title_label").append("img").attr("id","label_image");
  if (base) {
    if (type == 'pfam') {
      if (opt.pfam_list) {
        d3.select(".title_update")
          .selectAll("button")
          .data(opt.pfam_list)
          .enter()
          .append("button")
          .attr("type", "button")
          .attr("id", function (d) {
            return "button-id-" + d.key + "-pfam";
          })
          .attr("class", "btn")
          .text(function (d) {
            return d.value
          })
          .attr("onclick", function (d) {
            current_pfam = d.key;
            return "selected_item_title('" + d.key + "','" + d.value + "');redraw_render_scatterplot();"
          });
        current_pfam = opt.pfam_list[0].key;
        data = base[opt.pfam_list[0].key];
        selected_item_title(opt.pfam_list[0].key,opt.pfam_list[0].value);
        var title_element_id = "button-id-" + opt.pfam_list[0].key + "-pfam";
        change_button_status("pfam",opt.pfam_list[0].key,title_element_id);
      }
    } else {
      data = base;
    }
    data = set_category_nodata(data);
    render_scatterplot(opt.point_item,opt.point_item_ex, opt.init_x_axis_items, opt.init_y_axis_items);
    if (opt.selected_tax_id) {
      highlight_selected_id(opt.selected_tax_id);
    }
    create_menu();
  } else {
    d3.select(".category_area").remove();
    d3.select("#scatter_plot").append("text").text("No items found");
  }
  fade();
}

/*
Sets value if category value is null
*/
function set_category_nodata(data) {
  //console.log(JSON.stringify(data,null," "));
  var category_items = d3.entries(opt.category_items);
  for (var i = 0; i < data.length; i++) {
    for (var item = 0; item < category_items.length; item++) {
      if(category_items[item].key != opt.no_categorize) {
        if (!data[i][category_items[item].key]) data[i][category_items[item].key] = opt.no_data_label;
      }
    }
  }
  return data;
}
/*
Renders scatter plot
*/
function render_scatterplot(point_label, point_label_ex, x_axis_item, y_axis_item) {

  //set status
  current_x_item = x_axis_item;
  current_y_item = y_axis_item;
  current_color = null;
  current_category = opt.no_categorize;

  //calculate chart range and domain
  var x_scale = get_axis_scale(x_axis_item, "x");
  current_x_scale = x_scale;
  var max_x = d3.max(data,function(d){return d[current_x_item];});
  var x_axis = d3.svg.axis()
    .scale(x_scale);
  if (max_x < 10) {
    x_axis = d3.svg.axis()
      .scale(x_scale)
      .ticks(max_x);
  }

  var y_scale = get_axis_scale(y_axis_item, "y");
  current_y_scale = y_scale;
  var max_y = d3.max(data,function(d){return d[current_y_item];});
  var y_axis = d3.svg.axis()
    .scale(y_scale)
    .orient("left");
  if (max_y < 10) {
    y_axis = d3.svg.axis()
      .scale(y_scale)
      .orient("left")
      .ticks(max_y);
  }

  //add svg
  d3.select("#scatter_plot")
    .append("svg")
    .attr("id", "plot-svg")
    .attr("width", opt.width)
    .attr("height", opt.height);

  //add points
  d3.select("svg")
    .selectAll("circle")
    .data(data)
    .enter()
    .append("circle")
    .attr("class", "point")
    .attr("id", function (d) {
      return opt.elem_id_prefix + trim_tax_prefix(d[point_label])
    })
    .attr("cx", function (d) {
      return x_scale(d[x_axis_item])
    })
    .attr("cy", function (d) {
      return y_scale(d[y_axis_item])
    })
    .attr("r", opt.point_size)
    .attr("fill", opt.init_point_color)
    .style("opacity", opt.point_opacity);

  d3.select("svg")


  //display tooltips on mouseover
  add_tooltips_event();

  var scatter_plot = d3.select("#scatter_plot");
  var menu = d3.select("#menu");
  //axis
  var title_update = d3.select(".title_update");
  var x_axis_update = d3.select(".x_axis_update");
  d3.select("svg")
    .append("g")
    .attr("class", "x axis")
    .attr("transform",
    "translate(0," + (opt.height - opt.margin ) + ")")
    .call(x_axis);

  var y_axis_update = d3.select(".y_axis_update");
  d3.select("svg")
    .append("g")
    .attr("class", "y axis")
    .attr("transform", "translate(" + opt.margin + ", 0 )")
    .call(y_axis);

  d3.select(".x.axis")
    .append("text")
    .attr("class", "x axis-label")
    .on("mouseover", function (d) {
        title_update
          .style("visibility","hidden");
        x_axis_update.transition()
          .duration(200)
          .style("visibility","visible");
        y_axis_update
          .style("visibility","hidden");
        menu
          .style("visibility","visible")
          .style("pointer-events","fill");
        scatter_plot
          .style("pointer-events","none");
    })
    .text(opt.x_axis_items[x_axis_item].axis_label)
    .attr("x", function () {
      return (opt.width / 2) - (fontsize * opt.x_axis_items[x_axis_item].axis_label.length / 2);
    })
    .attr("y", ((opt.margin) / 1.5) - 15);


  d3.select(".x.axis")
    .append("image")
    .attr("class","x axis-image")
    .attr("xlink:href","/stanza/assets/protein_pfam_plot/image/menu_button.png")
    .attr("width","13px")
    .attr("height","13px")
    .on("mouseover", function (d) {
        title_update
          .style("visibility","hidden");
        x_axis_update.transition()
          .duration(200)
          .style("visibility","visible");
        y_axis_update
          .style("visibility","hidden");
        menu
          .style("visibility","visible")
          .style("pointer-events","fill");
        scatter_plot
          .style("pointer-events","none");
    })
    .attr("x", function () {
      return (opt.width / 2) + (fontsize * opt.x_axis_items[x_axis_item].axis_label.length / 2 + 5);
    })
    .attr("y", ((opt.margin) / 1.5) - 25);

  d3.select(".y.axis")
    .append("text")
    .attr("class", "y axis-label")
    .on("mouseover", function (d) {
      title_update
        .style("visibility","hidden");
      y_axis_update.transition()
        .duration(200)
        .style("visibility","visible");
      x_axis_update
        .style("visibility","hidden");
      menu
        .style("visibility","visible")
        .style("pointer-events","fill");
      scatter_plot
        .style("pointer-events","none");
    })
    .text(opt.y_axis_items[y_axis_item].axis_label);

  menu
    .on("click", function (d) {
      title_update
        .style("visibility","hidden");
      x_axis_update.transition()
        .duration(200)
        .style("visibility", "hidden");
      y_axis_update.transition()
        .duration(200)
        .style("visibility", "hidden");
      scatter_plot
        .style("pointer-events","fill");
      menu
        .style("visibility","hidden")
        .style("pointer-events","none");
    });

  var horizontal = (opt.margin - fontsize - 15) * -1;
  var vertical = ((opt.height / 2) + (fontsize * opt.y_axis_items[y_axis_item].axis_label.length / 2)) * -1;
  d3.select(".y.axis-label")
    .attr("transform", "rotate (-90) translate(" + vertical + "," + horizontal + ")");

  var horizontal = (opt.margin - fontsize - 5) * -1;
  var vertical = ((opt.height / 2) - (fontsize * opt.y_axis_items[y_axis_item].axis_label.length / 2 + 5)) * -1;
  d3.select(".y.axis")
    .append("image")
    .attr("class","y axis-image")
    .attr("xlink:href","/stanza/assets/protein_pfam_plot/image/menu_button.png")
    .attr("width","13px")
    .attr("height","13px")
    .on("mouseover", function (d) {
      title_update
        .style("visibility","hidden");
      y_axis_update.transition()
        .duration(200)
        .style("visibility","visible");
      x_axis_update
        .style("visibility","hidden");
      menu
        .style("visibility","visible")
        .style("pointer-events","fill");
      scatter_plot
        .style("pointer-events","none");
    })
    .attr("transform", "rotate (-90) translate(" + vertical + "," + horizontal + ")");

  optimize_axis_unit(".x.axis g text", x_axis_item);
  optimize_axis_unit(".y.axis g text", y_axis_item);
}


/*
Renders scatter plot
*/
function redraw_render_scatterplot() {

  if (opt.range_items[current_x_item]) {
    //console.log('remove-line-x');
    d3.selectAll(".range-line.x")
      .remove();
    d3.selectAll(".min-point.x")
      .remove();
  }

  if (opt.range_items[current_y_item]) {
    //console.log('remove-line-y');
    d3.selectAll(".range-line.y")
      .remove();
    d3.selectAll(".min-point.y")
      .remove();
  }

  //calculate chart range and domain
  var x_scale = get_axis_scale(current_x_item, "x");
  current_x_scale = x_scale;
  var max_x = d3.max(data,function(d){return d[current_x_item];});
  var x_axis = d3.svg.axis()
    .scale(x_scale);
  if (max_x < 10) {
    x_axis = d3.svg.axis()
      .scale(x_scale)
      .ticks(max_x);
  }

  var y_scale = get_axis_scale(current_y_item, "y");
  current_y_scale = y_scale;
  var max_y = d3.max(data,function(d){return d[current_y_item];});
  var y_axis = d3.svg.axis()
    .scale(y_scale)
    .orient("left");
  if (max_y < 10) {
    y_axis = d3.svg.axis()
      .scale(y_scale)
      .orient("left")
      .ticks(max_y);
  }
  //alert(current_x_item);
  //alert(current_y_item);
  if (current_x_item == 'num_pfam' || current_x_item == 'num_pfam_protein'
   || current_y_item == 'num_pfam' || current_y_item == 'num_pfam_protein') {
    //alert("through");
    //update points
    d3.select("svg")
      .selectAll("circle")
      .data(data)
      .attr("class", "point")
      .attr("id", function (d) {
        return opt.elem_id_prefix + trim_tax_prefix(d.tax)
      })
      .attr("fill", opt.init_point_color)
      .transition()
      .duration(1000)
      .attr("cx", function(d){
          if (opt.range_items[current_x_item]) {
            if (d[opt.range_items[current_x_item].max]) {
              return x_scale(d[opt.range_items[current_x_item].max]);
            } else if (d[opt.range_items[current_x_item].opt]) {
              return x_scale(d[opt.range_items[current_x_item].opt]);
            } else {
              return "-500px";
            }
          } else if (d[current_x_item]) {
            return x_scale(d[current_x_item]);
          } else {
            return "-500px";
          }
      })
      .attr("cy", function(d){
          if (opt.range_items[current_y_item]) {
            if (d[opt.range_items[current_y_item].max]) {
              return y_scale(d[opt.range_items[current_y_item].max]);
            } else if (d[opt.range_items[current_y_item].opt]) {
              return y_scale(d[opt.range_items[current_y_item].opt]);
            } else {
              return "-500px";
            }
          } else if (d[current_y_item]) {
            return y_scale(d[current_y_item]);
          } else {
            return "-500px";
          }
      });
  } else {
    //update points
    d3.select("svg")
      .selectAll("circle")
      .data(data)
      .attr("class", "point")
      .attr("id", function (d) {
        return opt.elem_id_prefix + trim_tax_prefix(d.tax)
      })
      .attr("fill", opt.init_point_color)
      .attr("cx", function(d){
          if (opt.range_items[current_x_item]) {
            if (d[opt.range_items[current_x_item].max]) {
              return x_scale(d[opt.range_items[current_x_item].max]);
            } else if (d[opt.range_items[current_x_item].opt]) {
              return x_scale(d[opt.range_items[current_x_item].opt]);
            } else {
              return "-500px";
            }
          } else if (d[current_x_item]) {
            return x_scale(d[current_x_item]);
          } else {
            return "-500px";
          }
      })
      .attr("cy", function(d){
          if (opt.range_items[current_y_item]) {
            if (d[opt.range_items[current_y_item].max]) {
              return y_scale(d[opt.range_items[current_y_item].max]);
            } else if (d[opt.range_items[current_y_item].opt]) {
              return y_scale(d[opt.range_items[current_y_item].opt]);
            } else {
              return "-500px";
            }
          } else if (d[current_y_item]) {
            return y_scale(d[current_y_item]);
          } else {
            return "-500px";
          }
      });
  }
  if (opt.range_items[current_x_item]) {
    add_min_circle(current_x_item, "x");
    add_range_line(current_x_item, "x");
  }
  if (opt.range_items[current_y_item]) {
    add_min_circle(current_y_item, "y");
    add_range_line(current_y_item, "y");
  }
  //update axis
  d3.select(".x.axis")
    .transition()
    .duration(1000)
    .call(x_axis);
  d3.select(".x.axis-label")
    .transition()
    .delay(500)
    .text(opt.x_axis_items[current_x_item].axis_label)
    .attr("x", function () {
      return (opt.width / 2) - (fontsize * opt.x_axis_items[current_x_item].axis_label.length / 2);
    })
    .attr("y", ((opt.margin) / 1.5) - 15);
  optimize_axis_unit(".x.axis g text", current_x_item);

  d3.select(".x.axis-image")
    .transition()
    .delay(500)
    .attr("xlink:href","/stanza/assets/protein_pfam_plot/image/menu_button.png")
    .attr("width","13px")
    .attr("height","13px")
    .attr("x", function () {
      return (opt.width / 2) + (fontsize * opt.x_axis_items[current_x_item].axis_label.length / 2 + 5);
    })
    .attr("y", ((opt.margin) / 1.5) - 25);

  // update axis
  var horizontal = (opt.margin - fontsize - 15) * -1;
  var vertical = ((opt.height / 2) + (fontsize * opt.y_axis_items[current_y_item].axis_label.length / 2)) * -1;
  d3.select(".y.axis")
    .transition()
    .duration(1000)
    .call(y_axis);
  d3.select(".y.axis-label")
    .transition()
    .delay(500)
    .text(
  opt.y_axis_items[current_y_item].axis_label)
    .attr("transform", "rotate (-90) translate(" + vertical + "," + horizontal + ")");
  optimize_axis_unit(".y.axis g text", current_y_item);

  var horizontal = (opt.margin - fontsize - 5) * -1;
  var vertical = ((opt.height / 2) - (fontsize * opt.y_axis_items[current_y_item].axis_label.length / 2 + 5)) * -1;
  d3.select(".y.axis-image")
    .transition()
    .delay(500)
    .attr("xlink:href","/stanza/assets/protein_pfam_plot/image/menu_button.png")
    .attr("width","13px")
    .attr("height","13px")
    .attr("transform", "rotate (-90) translate(" + vertical + "," + horizontal + ")");


  d3.select("svg")
  if (opt.selected_tax_id) {
    highlight_selected_id(opt.selected_tax_id);
  }
}

/*
Optimizes the tick unit
*/
function optimize_axis_unit(elem_selector, item) {
  if (opt.opt_axis_unit_items.indexOf(item) >= 0) { //taget item to optimization
    var max_size = d3.max(data, function (d) {
      return Number(d[item])
    });
    if (max_size > 1000000) {
      d3.selectAll(elem_selector)
        .text(function (d) {
        return (d / 1000000) + "M"
      });
    } else if (max_size > 1000) {
      d3.selectAll(elem_selector)
        .text(function (d) {
        return (d / 1000) + "K"
      });
    } else {
      d3.selectAll(elem_selector)
        .text(function (d) {
        return d
      });
    }
  }
}

/*
Adds event on each point for display tooltips
*/
function add_tooltips_event() {
  tooltips = d3.select(".tooltip");
  if (tooltips) {
    tooltips = d3.select("#scatter_plot")
      .append("table")
      .attr("class",
      "tooltip");
  }
  d3.selectAll(".point")
    .on("mousemove", function (d) {
      tooltips.transition()
        .duration(200)
        .style("opacity", 1.0);
      var pos = d3.mouse(document.getElementById('scatter_plot'));
      tooltips
        .html(function () {
          var tooltipstext = "";
          for (var i = 0; i < opt.tooltips_items.length; i++) {
            var item = opt.tooltips_items[i];
            if (opt.range_items[item]) { //range items
              if (d[opt.range_items[item].opt]) { //has optimal value
                tooltipstext += ("<tr><td>" + opt.x_axis_items[item].button_label + ": " + d[opt.range_items[item].opt] + "</td></tr>");
              } else if (d[opt.range_items[item].min] && d[opt.range_items[item].max]) {//has min - max value
                tooltipstext += ("<tr><td>" + opt.x_axis_items[item].button_label + ": " + d[opt.range_items[item].min] + " - " + d[opt.range_items[item].max] + "</td></tr>");
              }
            } else if (d[item]) {
              if (opt.x_axis_items[item]) { //is axis item
                tooltipstext += ("<tr><td>" + opt.x_axis_items[item].button_label + ": " + d[item] + "</td></tr>");
              } else {
                tooltipstext += ("<tr><td>" + replace_tax_prefix(d[item]) + "</td></tr>");
              }
            }
          }
          return tooltipstext;
        })
        .style("max-width","300px")
        .style("left", ((600 - (pos[0] + 200) >= 0)?(pos[0] + 30) + "px":(pos[0] - 330) + "px"))
        .style("top", (pos[1] - 50) + "px")
        .style("visibility", "visible");
    })
    .on("mouseout", function (d) {
      tooltips.transition()
        .duration(200)
        .style("visibility", "hidden");
    });
}

/*
//TODO specified by opt
Returns taxonomy id from url
*/
function trim_tax_prefix(taxid) {
  taxid = taxid.replace("http://identifiers.org/taxonomy/", "");
  taxid = taxid.replace("http://www.ncbi.nlm.nih.gov/taxonomy/", "");
  return taxid;
}

/*
//TODO specified by opt
Returns taxonomy id from url
*/
function replace_tax_prefix(taxid) {
  taxid = taxid.replace("http://identifiers.org/taxonomy/", "NCBI Taxonomy: ");
  taxid = taxid.replace("http://www.ncbi.nlm.nih.gov/taxonomy/", "NCBI Taxonomy: ");
  return taxid;
}

/*
Highlights a point to indicate current selected item_id.
taxonomy id is specified by request parameter.(?taxid=NNNNN)
*/
function highlight_selected_id(selected_id) {
  var id = opt.elem_id_prefix + selected_id;
  move_in_front(id);
  $("circle[id='" + id + "']")
      .attr("fill", opt.init_selected_point_color);
}

/*
Layers element (specified by id) in front.
Because svg element is not supported z-index style.
*/
function move_in_front(id) {
  $("circle[id='" + id + "']").appendTo("#plot-svg");
}
/*

 */
function selected_item_title(key,value) {

  var scatter_plot = d3.select("#scatter_plot");
  var title_update = d3.select(".title_update");
  var x_axis_update = d3.select(".x_axis_update");
  var y_axis_update = d3.select(".y_axis_update");
  var menu = d3.select("#menu");
  d3.select("#title_label")
    .text(value + " (" + key + ")")
    .style("position", "absolute")
    .style("font-weight", "bold")
    .style("top", opt.margin / 2 + "px")
      .append("img")
      .attr("id","label_image")
      .attr("class", "title-image")
      .attr("src","/stanza/assets/protein_pfam_plot/image/menu_button.png")
      .attr("width","13px")
      .attr("height","13px")
      .attr("alt","")
      .style("margin-left","10px")
      .on("mouseover", function (d) {
        title_update.transition()
          .duration(200)
          .style("visibility","visible");
        x_axis_update
          .style("visibility","hidden");
        y_axis_update
          .style("visibility","hidden");
        menu
          .style("visibility","visible")
          .style("pointer-events","fill");
        scatter_plot
          .style("pointer-events","none");
      });
  title_update.style("left",((fontsize * (key.length + value.length + 2)) - 25) + "px")
  var title_element_id = "button-id-" + key + "-pfam";
  change_button_status("pfam",key,title_element_id);

  data = base[key];
}

/*
Creates menu
*/
function create_menu() {
  //X-Axis
  d3.select(".x_axis_update")
    .selectAll("button")
    .data(d3.entries(opt.x_axis_items))
    .enter()
    .append("button")
    .attr("type", "button")
    .attr("id", function (d) {
      return "button-id-" + d.key + "-x"
    })
    .attr("class", "btn axis-btn")
    .attr("onclick", function (d) {
      return "update_x(this,'" + d.key + "')"
    })
    .text(function (d) {
      return d.value.button_label
    });
  //Y-Axis
  d3.select(".y_axis_update")
    .selectAll("button")
    .data(d3.entries(opt.y_axis_items))
    .enter()
    .append("button")
    .attr("type", "button")
    .attr("id", function (d) {
      return "button-id-" + d.key + "-y"
    })
    .attr("class", "btn axis-btn")
    .attr("onclick", function (d) {
      return "update_y(this,'" + d.key + "')"
    })

    .text(function (d) {
      return d.value.button_label
    });

  //set button status
  var x_element_id = "button-id-" + opt.init_x_axis_items + "-x";
  change_button_status("x", opt.init_x_axis_items, x_element_id);
  var y_element_id = "button-id-" + opt.init_y_axis_items + "-y";
  change_button_status("y", opt.init_y_axis_items, y_element_id);

  d3.select("#vis").selectAll(".btn")
    .each(function () {
      var t = document.createElement("br");
      this.parentNode.insertBefore(t, this.nextSibling);
    });

  //category select list
  d3.select(".dropdown-menu")
    .selectAll("category-list")
    .data(d3.entries(opt.category_items))
    .enter()
    .append("li")
    .append("a")
    .attr("onclick", function (d) {
      return "update_category('" + d.key + "', this)";
    })
    .text(function (d) { return d.value.label });

  d3.select(".menu")
    .style("visibility", "hidden")
    .style("pointer-events","none");
}

/*
Changes button status (enable/disable and current selected )
*/
function change_button_status(axis_type, current_selected_item, element_id) {
  if (axis_type == "x") {
    //button focus
    d3.selectAll(".x_axis_update .btn")
      .classed("btn-primary", false); //reset
    d3.select("#" + element_id)
      .classed("btn-primary", true);

    d3.selectAll(".y_axis_update .btn")
      .attr("disabled", null); //reset
    if (opt.range_items[current_selected_item]) { //can't select range item both X and Y
      for (var key in opt.range_items) {
        d3.select("#button-id-" + key + "-y")
          .attr("disabled", "disabled");
      }
    } else { //can't select same item both X and Y
      d3.select("#button-id-" + current_selected_item + "-y")
        .attr("disabled", "disabled");
    }
  } else if (axis_type == "y") {
    //button focus
    d3.selectAll(".y_axis_update .btn")
      .classed("btn-primary", false); //reset
    d3.select("#" + element_id)
      .classed("btn-primary", true);

    d3.selectAll(".x_axis_update .btn")
      .attr("disabled", null); //reset
    if (opt.range_items[current_selected_item]) { //can't select range item both X and Y
      for (var key in opt.range_items) {
        d3.select("#button-id-" + key + "-x")
          .attr("disabled", "disabled");
      }
    } else { //can't select same item both X and Y
      d3.select("#button-id-" + current_selected_item + "-x")
        .attr("disabled", "disabled");
    }
  } else if (axis_type == "pfam") {
    //button focus
    d3.selectAll(".title_update .btn")
      .classed("btn-primary", false); //reset
    d3.select("#" + element_id)
      .classed("btn-primary", true);

    d3.selectAll(".title_update .btn")
      .attr("disabled", null); //reset
    if (opt.range_items[current_selected_item]) { //can't select range item both X and Y
      for (var key in opt.range_items) {
        d3.select("#button-id-" + key + "-pfam")
          .attr("disabled", "disabled");
      }
    } else { //can't select same item both X and Y
      d3.select("#button-id-" + current_selected_item + "-pfam")
        .attr("disabled", "disabled");
    }
  }
}

/**** update axis ****/
/*
Adds min points for item has range value
*/
function add_min_circle(item, axis_type) {
  var min_item = opt.range_items[item].min;
  //console.log('min_item=' + min_item);
  var has_range_data = data.filter(function (d) {
    return d[min_item];
  });

  var draw_fin_cnt = 0;
  hogehoge = d3
    .select("svg")
    .selectAll("min-circle-" + axis_type)
    .data(has_range_data)
    .enter()
    .append("circle")
    .attr("class", function (d) {
      return opt.elem_id_prefix + trim_tax_prefix(d[opt.point_item]) + " point min-point " + axis_type
    })
    //.attr("id", function (d) {
    //  return opt.elem_id_prefix + trim_tax_prefix(d[opt.point_item])
    //})
    .attr("cx", function (d) {
      if (axis_type == "x") {
        //console.log('d=' + d[current_y_item]);
        if (d[current_y_item]) {
          //console.log('x_scale=' + current_x_scale(d[min_item]));
          return current_x_scale(d[min_item]);
        }
      } else if (axis_type == "y") {
        if (d[current_x_item]) {
          if (opt.range_items[current_x_item]) {
            return current_x_scale(d[opt.range_items[current_x_item].min]);
          } else {
            return current_x_scale(d[current_x_item]);
          }
        }
      }
    })
    .attr("cy", function (d) {
      if (axis_type == "x") {
        if (d[current_y_item]) {
          if (opt.range_items[current_y_item]) {
            return current_y_scale(d[opt.range_items[current_y_item].min]);
          } else {
            return current_y_scale(d[current_y_item]);
          }
        }
      } else if (axis_type == "y") {
        if (d[current_x_item]) {
          return current_y_scale(d[min_item]);
        }
      }
    })
    .transition()
    .delay(500)
    .each("end", function (d) { //when it has completed adding, change order and opacity for category highlight
      draw_fin_cnt++;
      if (has_range_data.length == draw_fin_cnt) {
        if (current_category_highlight) category_highlight(current_category_highlight);
      }
    })
    .attr("r", opt.point_size)
    .attr("fill", function (d) {
      if (current_color) {//TODO test with offline data
        if (d[current_category] != opt.no_data_label) {
          return current_color(d[current_category]);
        } else {
          return opt.no_data_category_color;
        }
      } else {
        return opt.init_point_color;
      }
    })
    .style("opacity", opt.point_opacity);

  add_tooltips_event();
}

/*
Adds lines (min point to max point) for item has range value
*/
function add_range_line(item, axis_type) {
  var min_item = opt.range_items[item].min;
  var max_item = opt.range_items[item].max;
  var has_range_data = data.filter(function (d) {
    return d[min_item] && d[max_item]
  });

  var draw_fin_cnt = 0;
  d3.select("svg")
    .selectAll("range-line-" + axis_type)
    .data(has_range_data)
    .enter()
    .insert("line", "circle")
    .attr("class", "range-line " + axis_type)
    .attr("x1", function (d) {
      if (axis_type == "x") {
        return current_x_scale(d[min_item]);
      } else if (axis_type == "y") {
        return current_x_scale(d[current_x_item]);
      }
    })
    .attr("y1", function (d) {
      if (axis_type == "x") {
        return current_y_scale(d[current_y_item]);
      } else if (axis_type == "y") {
        return current_y_scale(d[min_item]);
      }
    })
    .attr("x2", function (d) {
      if (axis_type == "x") {
        return current_x_scale(d[max_item]);
      } else if (axis_type == "y") {
        return current_x_scale(d[current_x_item]);
      }
    })
    .attr("y2", function (d) {
      if (axis_type == "x") {
        return current_y_scale(d[current_y_item]);
      } else if (axis_type == "y") {
        return current_y_scale(d[max_item]);
      }
    })
    .transition()
    .delay(500)
    .each("end", function (d) { //when it has completed adding, change order and opacity for category highlight
      draw_fin_cnt++;
      if (has_range_data.length == draw_fin_cnt) {
        if (current_category_highlight) category_highlight(current_category_highlight);
      }
    })
    .attr("stroke-width", 2)
    .attr("stroke", function (d) {
      if (current_color) {//TODO test with offline data
        if (d[current_category] != opt.no_data_label) {
          return current_color(d[current_category]);
        } else {
          return opt.no_data_category_color;
        }
      } else {
        return opt.init_point_color;
      }
    })
    .style("opacity", opt.point_opacity);
}

/*
Returns optimal axis scale of specified item and axis(x or y)
*/
function get_axis_scale(item, axis) {
  var scale;
  if (opt.range_items[item]) {
    //max
    var max;
    var max_value = d3.max(data, function (d) {
      if (d[opt.range_items[item].max])
        return Number(d[opt.range_items[item].max])
    });
    var opt_max_value = d3.max(data, function (d) {
      if (d[opt.range_items[item].opt])
        return Number(d[opt.range_items[item].opt])
    });
    if (max_value && opt_max_value) {
      max = Math.max(max_value, opt_max_value);
    } else if (max_value) {
      max = max_value;
    } else if (opt_max_value) {
      max = opt_max_value;
    }

    //min
    var min = 0;
    if (axis == "x") {
      scale = d3.scale.linear()
        .range([opt.margin, opt.width - opt.margin])
        .domain([min, max]);
    } else if (axis == "y") {
      scale = d3.scale.linear()
        .range([opt.height - opt.margin, opt.margin])
        .domain([min, max]);
    }
  } else {
    var max_value = d3.max(data, function (d) {
      return Number(d[item])
    });
    if (axis == "x") {
      scale = d3.scale.linear()
        .range([opt.margin, opt.width - opt.margin])
        .domain([0, max_value]);
    } else if (axis == "y") {
      scale = d3.scale.linear()
        .range([opt.height - opt.margin, opt.margin])
        .domain([0, max_value]);
    }
  }
  return scale;
}

/*
Updates x axis
*/
function update_x(element, item) {
  //control status
  old_item = current_x_item;
  new_item = item;
  current_x_item = new_item;

  //buttun focus
  change_button_status("x", item, element.id);

  if (opt.range_items[old_item]) {
    d3.selectAll(".range-line.x")
      .remove();
    d3.selectAll(".min-point.x")
      .remove();
  }

  new_scale = get_axis_scale(item, "x");
  current_x_scale = new_scale;
  var max_x = d3.max(data,function(d){return d[current_x_item];});
  var x_axis_new = d3.svg.axis()
    .scale(new_scale);
  if (max_x < 10) {
    x_axis_new = d3.svg.axis()
      .scale(new_scale)
      .ticks(max_x);
  }

  //move points
  d3.selectAll("circle")
    .transition()
    .duration(1000)
    .attr("cx", function(d){
        if (opt.range_items[item]) {
          if (d[opt.range_items[item].max]) {
            return current_x_scale(d[opt.range_items[item].max]);
          } else if (d[opt.range_items[item].opt]) {
            return current_x_scale(d[opt.range_items[item].opt]);
          } else {
            return "-500px";
          }
        } else if (d[item]) {
          return current_x_scale(d[item]);
        } else {
          return "-500px";
        }
    });
  //if item has range value is selected, add min value points and lines (min - max)
  if (opt.range_items[item]) {
    add_min_circle(item, "x");
    add_range_line(item, "x");
  }

  //update axis
  d3.select(".x.axis")
    .transition()
    .duration(1000)
    .call(x_axis_new);
  d3.select(".x.axis-label")
    .transition()
    .delay(500)
    .text(opt.x_axis_items[item].axis_label)
    .attr("x", function () {
      return (opt.width / 2) - (fontsize * opt.x_axis_items[item].axis_label.length / 2);
    })
    .attr("y", ((opt.margin) / 1.5) - 15);
  optimize_axis_unit(".x.axis g text", item);

  d3.select(".x.axis-image")
    .transition()
    .delay(500)
    .attr("xlink:href","/stanza/assets/protein_pfam_plot/image/menu_button.png")
    .attr("width","13px")
    .attr("height","13px")
    .attr("x", function () {
      return (opt.width / 2) + (fontsize * opt.x_axis_items[item].axis_label.length / 2 + 5);
    })
    .attr("y", ((opt.margin) / 1.5) - 25);

  // if other axis is range item, move line object
  if (opt.range_items[current_y_item]) {
    d3.selectAll(".range-line.y")
      .transition()
      .duration(1000)
      .attrTween("x1", line_tween)
      .attrTween("x2", line_tween);
  }
}

/*
Updates y axis
*/
function update_y(element, item) {
  //control status
  old_item = current_y_item;
  new_item = item;
  current_y_item = new_item;

  //buttun stasus
  change_button_status("y", item, element.id);

  if (opt.range_items[old_item]) {
    d3.selectAll(".range-line.y")
      .remove();
    d3.selectAll(".min-point.y")
      .remove();
  }

  new_scale = get_axis_scale(item, "y");
  current_y_scale = new_scale;
  var max_y = d3.max(data,function(d){return d[current_y_item];});
  var y_axis_new = d3.svg.axis()
    .scale(new_scale)
    .orient("left");
  if (max_y < 10) {
    y_axis_new = d3.svg.axis()
      .scale(new_scale)
      .orient("left")
      .ticks(max_y);
  }

  //move points
  d3.selectAll("circle")
    .transition()
    .duration(1000)
    .attr("cy", function(d){
        if (opt.range_items[item]) {
          if (d[opt.range_items[item].max]) {
            return current_y_scale(d[opt.range_items[item].max]);
          } else if (d[opt.range_items[item].opt]) {
            return current_y_scale(d[opt.range_items[item].opt]);
          } else {
            return "-500px";
          }
        } else if (d[item]) {
          return current_y_scale(d[item]);
        } else {
          return "-500px";
        }
    });
  //if item has range value is selected, add min value points and lines (min - max)
  if (opt.range_items[item]) {
    add_min_circle(item, "y");
    add_range_line(item, "y");
  }

  // update axis
  var horizontal = (opt.margin - fontsize - 15) * -1;
  var vertical = ((opt.height / 2) + (fontsize * opt.y_axis_items[item].axis_label.length / 2)) * -1;
  d3.select(".y.axis")
    .transition()
    .duration(1000)
    .call(y_axis_new);
  d3.select(".y.axis-label")
    .transition()
    .delay(500)
    .text(
  opt.y_axis_items[item].axis_label)
    .attr("transform", "rotate (-90) translate(" + vertical + "," + horizontal + ")");
  optimize_axis_unit(".y.axis g text", item);

  var horizontal = (opt.margin - fontsize - 5) * -1;
  var vertical = ((opt.height / 2) - (fontsize * opt.y_axis_items[item].axis_label.length / 2 + 5)) * -1;
  d3.select(".y.axis-image")
    .transition()
    .delay(500)
    .attr("xlink:href","/stanza/assets/protein_pfam_plot/image/menu_button.png")
    .attr("width","13px")
    .attr("height","13px")
    .attr("transform", "rotate (-90) translate(" + vertical + "," + horizontal + ")");

  // if other axis is range item, move line object
  if (opt.range_items[current_x_item]) {
    d3.selectAll(".range-line.x")
      .transition()
      .duration(1000)
      .attrTween("y1", line_tween)
      .attrTween("y2", line_tween);
  }
}

/*
Transition between start point and end point
*/
function point_tween(d, i, a) {
  var i;
  //console.log("data=" + new_scale(d[opt.range_items[new_item].max]) + "/" + new_scale(d[opt.range_items[new_item].opt]) + "/" + new_scale(d[new_item]));
  if (opt.range_items[new_item]) {
    if (d[opt.range_items[new_item].max]) {
      i = d3.interpolate(a,
      new_scale(d[opt.range_items[new_item].max]));
    } else if (d[opt.range_items[new_item].opt]) {
      i = d3.interpolate(a,
      new_scale(d[opt.range_items[new_item].opt]));
    } else {
      i = d3.interpolate(a, -500); //out of plot range
    }
  } else if (d[new_item])  {
    i = d3.interpolate(a, new_scale(d[new_item]));
  } else {
    i = d3.interpolate(a, -500); //out of plot range
  }
  return function (t) {
    return i(t);
  };
}

/*
Transition between start point and end point
*/
function line_tween(d, i, a) {
  var i;
  if (new_item == "temperature") {
    if (d["min_temp"]) {
      i = d3.interpolate(a, new_scale(d["min_temp"]));
      return function (t) {
        return i(t);
      };
    }
  } else if (new_item == "ph") {
    if (d["min_ph"]) {
      i = d3.interpolate(a, new_scale(d["min_ph"]));
      return function (t) {
        return i(t);
      };
    }
  } else {
    i = d3.interpolate(a, new_scale(d[new_item]));
    return function (t) {
      return i(t);
    };
  }
}
/*
Updates category
*/
function update_category(category, event) {

  d3.select(".legend-svg")
    .remove();
  reset_category_highlight();
  current_category = category;

  if (category == opt.no_categorize) { //Clear
    current_color = null;
    d3.selectAll(".point")
      .attr("fill", opt.init_point_color);
    d3.selectAll(".range-line")
      .attr("stroke", opt.init_point_color);
    d3.selectAll(".min-point")
      .attr("fill", opt.init_point_color);

    if (opt.selected_tax_id) {
      highlight_selected_id(opt.selected_tax_id);
    }

    d3.select("#appendedDropdownButton")
      .attr("value", "");
  } else {
    var color = d3.scale.ordinal()
      .range(["#1f77b4", "#aec7e8", "#ff7f0e", "#ffbb78", "#2ca02c", "#98df8a", "#d62728", "#ff9896", "#9467bd", "#c5b0d5", "#8c564b", "#c49c94", "#e377c2", "#f7b6d2", "#bcbd22", "#dbdb8d", "#17becf", "#9edae5"]);

    current_color = color;
    d3.selectAll(".point")
      .attr("fill", function (d) {
    	if (d[category] != opt.no_data_label) {
    		return color(d[category]);
    	} else {
    		return opt.no_data_category_color;
    	}
      });
    // if min point and line are exist , color
    d3.selectAll(".range-line")
      .attr("stroke", function (d) {
      	if (d[category] != opt.no_data_label) {
    		return color(d[category]);
    	} else {
    		return opt.no_data_category_color;
    	}
      });
    d3.selectAll(".min-point")
      .attr("fill", function (d) {
      	if (d[category] != opt.no_data_label) {
    		return color(d[category]);
    	} else {
    		return opt.no_data_category_color;
    	}
      });

    var height = ( color.domain().length + 1 ) * 20; // +1 is no data
    var led = d3.select("#legend")
      .append("svg")
      .attr("class", "legend-svg")
      .attr("width", opt.legend_width)
      .attr("height", height);

    //"no data" is always displayed at end of list
    var legendsort = function (a, b) {
      if (a == opt.no_data_label)
        return 1;
      if (b == opt.no_data_label)
        return -1;
      if (a < b)
        return -1;
      if (a > b)
        return 1;
      return 0;
    }

    color.domain().push(opt.no_data_label);
    var legend = led.selectAll(".legend-svg")
      .data(color.domain().sort(legendsort))
      .enter()
      .append("g")
      .attr("class", "legend")
      .attr("id", function (d, i) {
    	if (d != opt.no_data_label) {
      		return color(d);
      	} else {
      		return opt.no_data_category_color;
      	}
      })
      .attr("transform", function (d, i) {
        x_pos = i%2 * 450;
        y_pos = parseInt(i/2) * 20;
        return "translate(" + x_pos + "," + y_pos + ")";
      });

    legend.append("rect")
      .attr("x", 0)
      .attr("width", opt.legend_rect_size)
      .attr("height", opt.legend_rect_size)
      .attr("fill", function (d, i) {
        if (d != opt.no_data_label) {
          return color(d);
        } else {
          return opt.no_data_category_color;
        }
      });

    legend.append("text")
      .attr("x", opt.legend_rect_size + 3)
      .attr("y", 6)
      .attr("dy", ".35em")
      .text(function (d) {
        return d;
      });
    if (opt.selected_tax_id) {
      d3.selectAll(".selected")
        .attr("stroke", "black")
        .attr("stroke-width", "1px");
    }
    d3.selectAll(".legend")
      .on("mouseover", function (d, i) {
        category_highlight(d3.select(this)
          .attr("id"));
        category_text_highlight(this);
      });

    d3.select("#appendedDropdownButton")
      .attr("value", event.text);
  }
}
/*
Resets category highlight . All points and lines are drew with default opacity value.
*/
function reset_category_highlight() {
  $(".range-line")
    .prependTo("#plot-svg"); //draws line backward
  d3.selectAll(".range-line")
    .style("opacity", opt.point_opacity);
  d3.selectAll(".point")
    .style("opacity", opt.point_opacity);
}
/*
Highlights category item. category. Brings to forward and fully opaque the objects drawn with specified color .
*/
function category_highlight(color_id) {
  current_category_highlight = color_id;
  reset_category_highlight();
  //fully opaque on selected item
  d3.selectAll("line[stroke='" + color_id + "']")
    .style("opacity", 1.0);
  d3.selectAll("circle[fill='" + color_id + "']")
    .style("opacity", 1.0);
  //move to forground
  $("line[strok='" + color_id + "']")
    .appendTo("#plot-svg");
  $("circle[fill='" + color_id + "']")
    .appendTo("#plot-svg");
}
/*
Highlights category text.
*/
function category_text_highlight(element) {
  d3.selectAll(".category-hightlight")
    .remove();
  d3.select(element)
    .insert("rect", ".legend rect")
    .attr("class", "category-hightlight")
    .attr("x", "0")
    .attr("y", "-2")
    .attr("width", opt.legend_hightlight_width)
    .attr("height", "16")
    .attr("fill", "#BBBBBB")
    .style("opacity", 0.3);
}
