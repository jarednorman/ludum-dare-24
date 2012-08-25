
# constants because I am a C programmer with bad habits
WORLD_WIDTH = 33
WORLD_HEIGHT = 19

class LevelTile

  constructor: ->
    @contents = []
    @is_wall = true;

  getChar: ->
    if @is_wall
      '#'
    else
      '.'

  makeWall: ->
    @is_wall = true

  removeWall: ->
    @is_wall = false

  isWall: ->
    @is_wall

  isEmpty: ->
    @contents.length == 0

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

  generateSpaces: ->
    room_count = 2 + @difficulty
    room_scale = (@difficulty + 1) / (@difficulty + 2)

    # design rooms
    rooms = []

    for i in [0..room_count - 1]
      room =
        x: 1 + Math.floor Math.random() * (WORLD_WIDTH - @minimumRoomSize - 1)
        y: 1 + Math.floor Math.random() * (WORLD_HEIGHT - @minimumRoomSize - 1)

      max_width = WORLD_WIDTH - room.x - 1
      max_height = WORLD_HEIGHT - room.y - 1

      room.w = @minimumRoomSize + Math.floor Math.random() * (max_width - @minimumRoomSize - 1) * room_scale
      room.h = @minimumRoomSize + Math.floor Math.random() * (max_height - @minimumRoomSize - 1) * room_scale

      rooms[i] = room

    # clear rooms
    for room in rooms
      for y in [room.y..(room.y + room.h - 1)]
        for x in [room.x..(room.x + room.w - 1)]
          @map[y][x].removeWall()

    console.log rooms

    # connect rooms

  getChar: (y, x) ->
    @map[y][x].getChar()


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

  initializeHelp: ->
    @help_button.click =>
      @help_overlay.css { display: 'block' }
    @help_overlay.click =>
      @help_overlay.css { display: 'none' }

  render: ->


$ ->
  game = new LDView
