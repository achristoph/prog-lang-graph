draw = (links)->
  nodes = {}

  links = _.filter(links, (l)-> l.count > 20  )
  console.log(links)

  links.forEach (link)->
    link.source = nodes[link.source] || (nodes[link.source] = {name: link.source})
    link.target = nodes[link.target] || (nodes[link.target] = {name: link.target})


  width = 1200
  height = 800

  tick = () ->
    path.attr("d", linkArc)
    circle.attr("transform", transform)
    text.attr("transform", transform)

  force = d3.layout.force()
  .nodes(d3.values(nodes))
  .links(links)
  .size([width, height])
  .linkDistance(60)
  .charge(-300)
  .on("tick", tick)
  .start()

  svg = d3.select("svg")
  .attr("width", width)
  .attr("height", height)

  svg.append("defs").selectAll("marker")
  .data(["suit"])
  .enter().append("marker")
  .attr("id", (d)-> return d )
  .attr("viewBox", "0 -5 10 10")
  .attr("refX", 15)
  .attr("refY", -1.5)
  .attr("markerWidth", 6)
  .attr("markerHeight", 6)
  .attr("orient", "auto")
  .append("path")
  .attr("d", "M0,-5L10,0L0,5")

  path = svg.append("g").selectAll("path")
  .data(force.links())
  .enter().append("path")
  .attr("class", (d)->
#    console.log(d.type)
    return "link " + d.type
  )
  .attr("marker-end", (d) -> return "url(#" + d.type + ")")

  circle = svg.append("g").selectAll("circle")
  .data(force.nodes())
  .enter().append("circle")
  .attr("r", 6)
  .call(force.drag)

  text = svg.append("g").selectAll("text")
  .data(force.nodes())
  .enter().append("text")
  .attr("x", 8)
  .attr("y", ".31em")
  .text((d)-> return d.name)

  linkArc = (d) ->
    dx = d.target.x - d.source.x
    dy = d.target.y - d.source.y
    dr = Math.sqrt(dx * dx + dy * dy)
    return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " + d.target.x + "," + d.target.y

  transform = (d) ->
    return "translate(" + d.x + "," + d.y + ")"

#$ ->
#  $("#search").click ()->
#    $.getJSON "/assets/data_source.json", (data) ->
#      $("svg").empty()
#      draw(data)
