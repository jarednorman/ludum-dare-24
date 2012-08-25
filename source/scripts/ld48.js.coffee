
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

  constructor: (difficulty) ->
    console.log "making a level with difficulty: #{difficulty}"
    @map = do ->
      map = []
      for y in [0..WORLD_HEIGHT - 1]
        row = []
        for x in [0..WORLD_WIDTH - 1]
          row[x] = new LevelTile
        map[y] = row
      map

  generateSpaces: ->

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
