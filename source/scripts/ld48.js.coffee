
# constants because I am a C programmer with bad habits
WORLD_WIDTH = 33
WORLD_HEIGHT = 19

class Level

  constructor: ->

class MapView extends Backbone.View

  el: ($ '#game-area')

  initialize: (@level) ->
    for y in [0..WORLD_HEIGHT-1]
      row = ($ '<p>').attr('id', y.toString())
      for x in [0..WORLD_WIDTH-1]
        cell = ($ '<span>')
        if x == 0 or x == WORLD_WIDTH - 1 or y == 0 or y == WORLD_HEIGHT - 1
          cell.text '#'
        else
          cell.text '.'
        row.append(cell)
      @$el.append(row)

  render: ->

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
