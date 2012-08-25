
class MapView extends Backbone.View

  el: ($ '#game-area')

  initialize: (@rows, @columns) ->
    for y in [0..@rows-1]
      row = ($ '<p>').attr('id', y.toString())
      for x in [0..@columns-1]
        cell = ($ '<span>')
        if x == 0 or x == @columns - 1 or y == 0 or y == @rows - 1
          cell.text '#'
        else
          cell.text '.'
        row.append(cell)
      @$el.append(row)

  render: ->

class LDView extends Backbone.View

  el: ($ '#page-wrap')

  initialize: ->
    @mapView = new MapView 19, 33

  render: ->


$ ->
  game = new LDView
