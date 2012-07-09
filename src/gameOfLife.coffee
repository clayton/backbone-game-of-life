GameOfLife = {}

GameOfLife.Router = Backbone.Router.extend({
  routes: {
    "" : "home"
  }

  home: ->
    world = new GameOfLife.World
    landscape = new GameOfLife.Landscape({model:world})
    landscape.cataclysm()
})

GameOfLife.World = Backbone.Collection.extend({
  model: GameOfLife.Sector
  initialize: ->
    @.populateSectors()
    null

  populateSectors: ->
    x = 1
    while x <= 32
      y = 1
      while y <= 32
        @.add(new GameOfLife.Sector({world: @, x: x, y: y}), {silent: true})
        y++
      x++
    null
  findNeighbors:(coordinates) ->
    x = coordinates.x
    y = coordinates.y

    neighbors = @.filter (sector) ->
      (sector.get("x") == x-1 and sector.get("y") == y - 1) or
      (sector.get("x") == x and sector.get("y") == y - 1)   or
      (sector.get("x") == x+1 && sector.get("y") == y - 1)  or
      (sector.get("x") == x-1 && sector.get("y") == y)      or
      (sector.get("x") == x+1 && sector.get("y") == y)      or
      (sector.get("x") == x-1 && sector.get("y") == y + 1)  or
      (sector.get("x") == x   && sector.get("y") == y + 1)  or
      (sector.get("x") == x+1 && sector.get("y") == y + 1)

    _.reject(neighbors, (neighbor)-> neighbor == undefined)
  evolve: ->
    for model in @.models
      model.determineFate()
    for model in @.models
      model.evolve()
    for model in @.models
      model.trigger("change")
})

GameOfLife.Landscape = Backbone.View.extend({
  initialize: ->
    @.evolutions = 0
  cataclysm: ->
    @.evolutions += 1
    $("#evolutions").html("evolution: " + @.evolutions)
    $("#world").html("")
    @.model.evolve()
    null
    self = @
    setTimeout (->
      self.cataclysm()
    ), 10
})

GameOfLife.Sector = Backbone.Model.extend({
  initialize: ->
    state = new GameOfLife.God().blessedOrCursed()
    @.set({alive: state})
    new GameOfLife.SectorLandscape({model: @})
  myWorld: ->
    @.get("world")
  neighbors: ->
    @.myWorld().findNeighbors({x: this.get("x"), y: this.get("y")})
  liveNeighbors: ->
    _.filter @.neighbors(), (neighbor)->
      neighbor.get("alive") == true
  determineFate: ->
    @.set({fate: @.willBeAlive()}, {silent: true})
    null
  willBeAlive: ->
    liveNeighbors = @liveNeighbors()
    if @.get("alive")
      return true  if liveNeighbors.length == 2 or liveNeighbors.length == 3
      return false if liveNeighbors.length < 2
      return false if liveNeighbors.length > 3
    else
      return true  if liveNeighbors.length == 3
  evolve: ->
    @.set({alive: @.get("fate")}, {silent:true})
})

GameOfLife.SectorLandscape = Backbone.View.extend({
  initialize: ->
    _.bindAll(this, 'render');
    @.model.bind("change", @.render)
    @.render()
  events: {

  }
  render: ->
    template = '<span id="{{cid}}" class="sector-landscape {{alive}}"></span>'
    $("#world").append(Mustache.to_html(template, {cid: @model.cid, alive: @.model.get("alive")}))
})

class GameOfLife.God
  blessedOrCursed: ->
    true if Math.random() > 0.50
