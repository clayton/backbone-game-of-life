module 'Zee Router'
  setup: ->
    @router = new GameOfLife.Router()
    @worldMock = {}
    @landscapeMock = {cataclysm: -> true}
    @worldStub = sinon.stub(window.GameOfLife, "World").returns(@worldMock)
    @landscapeStub = sinon.stub(window.GameOfLife, "Landscape").returns(@landscapeMock)
  teardown: ->
    @worldStub.restore()
    @landscapeStub.restore()

test 'the router has a default route', ->
  equals @router.routes[""], "home"

test 'the default route creates a world', ->
  @router.home()
  equals @worldStub.callCount, 1

test 'the router creates a landscape', ->
  @router.home()
  equals @landscapeStub.callCount, 1

test 'the router creates landscape using the world', ->
  @router.home()
  ok @landscapeStub.calledWith({model:@worldMock})

module 'The Landscape - experiencing a cataclysmic event'
  setup: ->
    @worldMock = sinon.mock({evolve: -> true})
    @worldMock.expects("evolve").once()
    @landscape = new GameOfLife.Landscape({model: @worldMock.object})
  teardown: ->

test 'it should evolve the world', ->
  @landscape.cataclysm()
  ok @worldMock.verify()

module 'The World'
  setup: ->
    @sectorSpy = sinon.spy(window.GameOfLife, "Sector")
    @world = new GameOfLife.World
  teardown: ->
    @sectorSpy.restore()

test 'the world should populate its sectors', ->
  equals(@sectorSpy.callCount, 1024, "expected 1024 sectors")

test 'the world should assign the sector a location in the world', ->
  ok @sectorSpy.calledWith({world: @world, x: 1, y: 1})
  ok @sectorSpy.calledWith({world: @world, x: 32, y: 32})

module 'The World - Finding Neighbors with no borders'
  setup: ->
    @world = new GameOfLife.World
    neighbors = @world.findNeighbors({x: 5, y: 5})
    @results = _.map(neighbors, (neighbor)-> {x: neighbor.get("x"), y: neighbor.get("y")})
    null
  teardown: ->

test 'should only find neighbors surrounding the defined coordinates', ->
  ok _.find(@results, (result)-> result.x == 4 && result.y == 4)
  ok _.find(@results, (result)-> result.x == 5 && result.y == 4)
  ok _.find(@results, (result)-> result.x == 6 && result.y == 4)
  ok _.find(@results, (result)-> result.x == 4 && result.y == 5)
  ok _.find(@results, (result)-> result.x == 4 && result.y == 6)
  ok _.find(@results, (result)-> result.x == 5 && result.y == 6)
  ok _.find(@results, (result)-> result.x == 6 && result.y == 6)

module 'The World - Finding Neighbors with borders'
  setup: ->
    @world = new GameOfLife.World
    neighbors = @world.findNeighbors({x: 1, y: 1})
    @results = _.map(neighbors, (neighbor)-> {x: neighbor.get("x"), y: neighbor.get("y")})
    null
  teardown: ->

test 'it should ignore border regions', ->
  ok _.find(@results, (result)-> result.x == 2 && result.y == 1)
  ok _.find(@results, (result)-> result.x == 1 && result.y == 2)
  ok _.find(@results, (result)-> result.x == 2 && result.y == 2)


module 'The World - Evolving'
  setup: ->
    @world = new GameOfLife.World
    @mockSector = sinon.mock({
      evolve: ->
        true
      determineFate: ->
        true
      trigger: ->
        true})
    @mockSector.expects("determineFate").once()
    @mockSector.expects("evolve").once()
    @world.models = [@mockSector.object]
    null
  teardown: ->

test 'should tell all of the sectors determine their fate', ->
  @world.evolve()
  ok @mockSector.verify()

test 'should tell all of the sectors to evolve', ->
  @world.evolve()
  ok @mockSector.verify()

module 'God'
  setup: ->
    @god = new GameOfLife.God
    @mathStub = sinon.stub(Math, "random")
  teardown: ->
    @mathStub.restore()

test 'blessings should be random', ->
  @god.blessedOrCursed()
  equals @mathStub.callCount, 1

module 'A Sector'
  setup: ->
    @god = new GameOfLife.God
    @godSpy = sinon.stub(@god, "blessedOrCursed").returns(true)
    @godStub = sinon.stub(window.GameOfLife, "God").returns(@god)
    @sectorLandscapeSpy = sinon.spy(window.GameOfLife, "SectorLandscape")
    @sector = new GameOfLife.Sector
  teardown: ->
    @godSpy.restore()
    @godStub.restore()
    @sectorLandscapeSpy.restore()

test 'should ask if its blessed or cursed', ->
  equals @godSpy.callCount, 1

test 'should set its state based on blessing', ->
  equals @sector.get("alive"), true

test 'should create a view for itself', ->
  ok @sectorLandscapeSpy.calledOnce

module 'A living Sector with fewer than two live neighbors'
  setup: ->
    @sutSector = new GameOfLife.Sector
    @sutSector.set({alive:true})
    @liveNeighborsStub = sinon.stub(@sutSector, "liveNeighbors").returns([{}])
  teardown: ->
    @liveNeighborsStub.restore()

test 'should die, as if caused by under-population', ->
  equals @sutSector.willBeAlive(), false

module 'A living Sector with two live neighbors'
  setup: ->
    @sutSector = new GameOfLife.Sector
    @sutSector.set({alive:true})
    @liveNeighborsStub = sinon.stub(@sutSector, "liveNeighbors").returns([{}, {}])
  teardown: ->
    @liveNeighborsStub.restore()

test 'should keep living', ->
  equals @sutSector.willBeAlive(), true

module 'A living Sector with three live neighbors'
  setup: ->
    @sutSector = new GameOfLife.Sector
    @sutSector.set({alive:true})
    @liveNeighborsStub = sinon.stub(@sutSector, "liveNeighbors").returns([{}, {}, {}])
  teardown: ->
    @liveNeighborsStub.restore()

test 'should keep living', ->
  equals @sutSector.willBeAlive(), true

module 'A living Sector with more than three live neighbors'
  setup: ->
    @sutSector = new GameOfLife.Sector
    @sutSector.set({alive:true})
    @liveNeighborsStub = sinon.stub(@sutSector, "liveNeighbors").returns([{}, {}, {}, {}])
  teardown: ->
    @liveNeighborsStub.restore()

test 'should die, as if by over crowding', ->
  equals @sutSector.willBeAlive(), false


module 'A dead Sector with exactly three live neighbors'
  setup: ->
    @sutSector = new GameOfLife.Sector
    @sutSector.set({alive:false})
    @liveNeighborsStub = sinon.stub(@sutSector, "liveNeighbors").returns([{}, {}, {}])
  teardown: ->
    @liveNeighborsStub.restore()

test 'becomes a live cell, as if by reproduction', ->
  equals @sutSector.willBeAlive(), true

module 'A Sector with 4 living neighbors and 4 dead neighbors'
  setup: ->
    @sutSector = new GameOfLife.Sector
    @sutSector.set({alive:true})
    fakeNeighbors = [
      {get:(alive) -> false},
      {get:(alive) -> false},
      {get:(alive) -> false},
      {get:(alive) -> false},
      {get:(alive) -> true},
      {get:(alive) -> true},
      {get:(alive) -> true},
      {get:(alive) -> true}
    ]
    @neighborsStub = sinon.stub(@sutSector, "neighbors").returns(fakeNeighbors)
  teardown: ->
    @neighborsStub.restore()

test 'should know that it has 4 living neighbors', ->
  equals @sutSector.liveNeighbors().length, 4

module 'Finding neighbors of a Sector'
  setup: ->
    @sutSector = new GameOfLife.Sector({x: 1, y: 1})
    @mockWorld = sinon.mock({findNeighbors:({}) -> []})
    @mockWorld.expects("findNeighbors").withArgs({x: 1, y: 1})
    @worldStub = sinon.stub(@sutSector, "myWorld").returns(@mockWorld.object)
  teardown: ->
    @worldStub.restore()

test 'the sector should ask the world who its neighbors are', ->
  @sutSector.neighbors()
  ok @mockWorld.verify()

module 'A Sector, when evolving'
  setup: ->
    @sutSector = new GameOfLife.Sector()
    @fateStub = sinon.stub(@sutSector, "get")
    @fateStub.withArgs("fate").returns(true)
    @setSpy = sinon.spy(@sutSector, "set")
    @setSpy.withArgs({alive: true}, {silent:true})
    null
  teardown: ->
    @fateStub.restore()
    @setSpy.restore()

test 'should set its alive state based on the evolution', ->
  @sutSector.evolve()
  ok @setSpy.calledOnce

module 'A Sector, when determining its fate'
  setup: ->
    @sutSector = new GameOfLife.Sector()
    @willBeAliveStub = sinon.stub(@sutSector, "willBeAlive").returns(true)
    null
  teardown: ->
    @willBeAliveStub.restore()

test 'should know if it will be alive after the evolution', ->
  @sutSector.determineFate()
  equals @sutSector.get("fate"), true
