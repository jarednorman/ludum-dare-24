
class MapView extends Backbone.View

  el: ($ '#game-area')

  initialize: (@rows, @columns) ->
    for y in [0..@rows-1]
      row = ($ '<p>').attr('id', y.toString())
      for x in [0..@columns-1]
        cell = ($ '<span>').text(' ')
        row.append(cell)
      @$el.append(row)

  render: ->

class LDView extends Backbone.View

  el: ($ '#page-wrap')

  initialize: ->
    @mapView = new MapView 10, 10

  render: ->


$ ->
  game = new LDView
