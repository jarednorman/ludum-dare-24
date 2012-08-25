
# constants because I am a C programmer with bad habits
WORLD_WIDTH = 47
WORLD_HEIGHT = 27

class Thing

  char: '?'

  constructor: (@level) ->
    @randomlyPlace()

  randomlyPlace: ->
    while true
      x = Math.floor Math.random() * WORLD_WIDTH
      y = Math.floor Math.random() * WORLD_HEIGHT
      if @level.isEmpty(y, x)
        console.log y, x
        @place(y, x)
        break

  place: (y, x) ->
    @tile = @level.map[y][x]
    @tile.contents.push this

  getChar: ->
    @char

class LivingThing extends Thing
    
  char: 'o'
  
  maxHealth: 1

  constructor: (@level) ->
    super(@level)
    @health = @maxHealth

  notDead: ->
    @health > 0

class Player extends LivingThing

  char: '@'

  maxHealth: 5

  constructor: (@level) ->
    super(@level)

class LevelTile

  constructor: ->
    @contents = []
    @is_wall = true;

  getChar: ->
    if @isWall()
      '#'
    else if @contents.length > 0
      @contents[0].getChar()
    else
      '.'

  makeWall: ->
    @is_wall = true

  removeWall: ->
    @is_wall = false

  isWall: ->
    @is_wall

  isEmpty: ->
    @contents.length == 0 or (not @isWall())

class Level

  minimumRoomSize: 5

  constructor: (@difficulty) ->
    @map = do ->
      map = []
      for y in [0..WORLD_HEIGHT - 1]
        row = []
        for x in [0..WORLD_WIDTH - 1]
          row[x] = new LevelTile
        map[y] = row
      map

    @generateSpaces()

  @updateEverything: ->
    for row in @map
      for cell in row
        thing.update for thing in cell.contents

  generateSpaces: ->
    room_count = 1 + @difficulty
    room_scale = Math.max (-1/40)*@difficulty + 1, 0

    # design rooms
    rooms = []

    for i in [0..room_count - 1]
      room =
        x: 1 + Math.floor Math.random() * (WORLD_WIDTH - @minimumRoomSize - 1)
        y: 1 + Math.floor Math.random() * (WORLD_HEIGHT - @minimumRoomSize - 1)

      max_width = WORLD_WIDTH - room.x
      max_height = WORLD_HEIGHT - room.y 

      room.w = @minimumRoomSize + Math.floor Math.random() * (max_width - @minimumRoomSize - 1) * room_scale
      room.h = @minimumRoomSize + Math.floor Math.random() * (max_height - @minimumRoomSize - 1) * room_scale

      rooms[i] = room

    # clear rooms
    for room in rooms
      for y in [room.y..(room.y + room.h - 1)]
        for x in [room.x..(room.x + room.w - 1)]
          @map[y][x].removeWall()

    # connect rooms
    connected = []
    for source in rooms
      for destination in rooms
        already_connected = false
        for path in connected
          already_connected = true if (path[0] == source) and (path[1] == destination)
          already_connected = true if (path[1] == source) and (path[0] == destination)
        if not ((source == destination) or already_connected)
          source_x = Math.floor source.x + source.w/2
          source_y = Math.floor source.y + source.h/2

          target_x = Math.floor destination.x + destination.w/2
          target_y = Math.floor destination.y + destination.h/2

          current_x = source_x
          current_y = source_y

          while current_x != target_x or current_y != target_y
            x = if current_x < target_x then 1 else -1
            y = if current_y < target_y then 1 else -1
            dx = Math.abs(current_x - target_x)
            dy = Math.abs(current_y - target_y)
            if Math.random() < dx / (dx + dy)
              current_x = current_x + x
            else
              current_y = current_y + y
            if current_y > 1 and current_y < WORLD_HEIGHT - 2 and current_x > 1 and current_x < WORLD_WIDTH - 2
              @map[current_y][current_x].removeWall() 

          connected.push [source, destination]


  getChar: (y, x) ->
    @map[y][x].getChar()

  isEmpty: (y, x) ->
    @map[y][x].isEmpty()


class MapView extends Backbone.View

  el: ($ '#game-area')

  initialize: (@level) ->
    for y in [0..WORLD_HEIGHT - 1]
      row = ($ '<p>').attr('id', y.toString())
      for x in [0..WORLD_WIDTH - 1]
        cell = ($ '<span>')
        cell.attr('id', x.toString())
        cell.text ' '
        row.append(cell)
      @$el.append(row)

    @screen = do =>
      screen = []
      (@$ 'p').each (p_index, p) ->
        row = []
        ($ p).children().each (span_index, span) ->
          row[span_index] = ($ span)
        screen[p_index] = row
      screen

    @render()

  render: ->
    for row, y in @screen
      for cell, x in row
        char = @level.getChar(y, x)
        cell.text(char) if cell.text() != char


class LDView extends Backbone.View

  el: ($ '#page-wrap')

  initialize: ->
    @help_button = (@$ '#help-button')
    @help_overlay = (@$ '#help')
    @initializeHelp()

    @difficulty = 0
    @current_level = new Level @difficulty

    @mapView = new MapView @current_level
    @player = new Player @current_level
    @mapView.render()

  initializeHelp: ->
    @help_button.click =>
      @help_overlay.css { display: 'block' }
    @help_overlay.click =>
      @help_overlay.css { display: 'none' }

  render: ->


$ ->
  game = new LDView
