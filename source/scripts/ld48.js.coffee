
# constants because I am a C programmer with bad habits
WORLD_WIDTH = 47
WORLD_HEIGHT = 27

class Thing

  char: '?'

  description: "This is a thing."

  constructor: (@level) ->
    @randomlyPlace()
    @event_function = null
    @event_arg = null

  moveToLevel: (level) ->
    @level = level
    @randomlyPlace()

  randomlyPlace: ->
    while true
      x = Math.floor Math.random() * WORLD_WIDTH
      y = Math.floor Math.random() * WORLD_HEIGHT
      if @level.isEmpty(y, x)
        @place(y, x)
        break

  place: (y, x) ->
    @tile = @level.map[y][x]
    @tile.contents.push this

  getChar: ->
    @char

  update: ->
    @doEvent()
  
  doEvent: ->
    if @event_function?
      @event_function @event_arg
      @event_function = null
      @event_arg = null

  setEvent: (f, arg) ->
    @event_function = f
    @event_arg = arg

  getActions: ->
    []

class LevelEnd extends Thing

  char: '&'

  description: 'This is a teledeporter that takes you to the next level.'

  constructor: (@level) ->
    super(@level)

  getActions: ->
    actions = []
    if @level.distanceFromPlayer(@tile.y, @tile.x) == 1
      actions.push
        description: "Go to next level."
        f: =>
          @level.is_complete = true
          log.print "You've moved to the next level."
        args: {}
    actions

class LivingThing extends Thing
    
  char: 'o'
  
  maxHealth: 1

  constructor: (@level) ->
    super(@level)
    @health = @maxHealth

  notDead: ->
    @health > 0

  hurt: (damage) ->
    @health = Math.max @health - damage, 0
    @destroy() if not @notDead()

  destroy: ->
    @tile.contents = []

  move: (dir) ->
    x = dir.x
    y = dir.y
    destination = @tile.getRelativeTile(y, x)
    if destination? and destination.isEmpty()
      @tile.contents = []
      @place(destination.y, destination.x)

class Enemy extends LivingThing

  attackText: "The enemy uses its laser eyes to hurt you."
  attackDamage: 1
  attackRange: 1

  attack: (arg) =>
    target = arg.what
    log.print @attackText
    target.hurt @attackDamage

  update: ->
    r = Math.random()
    if r < 0.25
      @setEvent @move, { x:  0, y: -1 }
    else if r < 0.5
      @setEvent @move, { x: -1, y:  0 }
    else if r < 0.75
      @setEvent @move, { x:  0, y:  1 }
    else
      @setEvent @move, { x:  1, y:  0 }
    if @tile.level.distanceFromPlayer(@tile.y, @tile.x) <= @attackRange
      @setEvent @attack, { what: @tile.level.player }

    super()

  getActions: ->
    actions = []
    # code possible player attacks abilities into here
    # sweet design, jared, you suck
    actions.push
      description: "Shoot it with a fireball."
      f: @tile.level.player.fireball
      arg: { what: this }
    actions


class GiantPotato extends Enemy

  char: 'P'

  description: 'This is a giant monster potato with red glowing eyes and a shark-like mouth full of sharp teeth.'

  attackText: "The giant potato shoots tiny flaming chairs at you."
  attackRange: 2

  maxHealth: 1

  update: ->
    super()

class Player extends LivingThing

  char: '@'

  description: "This is you, the player."

  maxHealth: 25

  constructor: (@level) ->
    super(@level)

  hurt: (damage) ->
    super(damage)
    log.print "You take #{damage} damage. You have #{@health} health left."

  getActions: ->
    actions = []
    actions.push
      description: 'Commit suicide.'
      f: =>
        @health = 0
        log.print "You have died."
      args: {}
    actions

  fireball: (arg) ->
    log.print "You shoot a fireball the #{arg.what.name}."
    arg.what.hurt(1)
    

class LevelTile

  constructor: (@y, @x, @level) ->
    @contents = []
    @is_wall = true;

  getChar: ->
    if @isWall()
      '#'
    else if @contents.length > 0
      @contents[0].getChar()
    else
      '.'

  getRelativeTile: (y, x) ->
    x = @x + x
    y = @y + y
    if y < 0 or y > WORLD_HEIGHT - 1 or x < 0 or x > WORLD_WIDTH - 1
      return null
    else
      return @level.map[y][x]

  getActions: ->
    if @isEmpty() or @isWall()
      noop =
        description: "do nothing"
        f: ->
          log.print "You did nothing."
        arg: {}
      [noop]
    else
      return @contents[0].getActions()
      

  makeWall: ->
    @is_wall = true

  removeWall: ->
    @is_wall = false

  isWall: ->
    @is_wall

  isEmpty: ->
    @contents.length == 0 and (not @isWall())

  getDescription: ->
    if @contents.length > 0
      @contents[0].description
    else if @isWall()
      "This is a wall."
    else
      "This is an empty tile."

class ActionsView extends Backbone.View

  el: ($ '#buttons')

  initialize: ->
    @actions = []

  render: ->
    @$el.empty()
    for action in @actions
      @addButton action


  addButton: (action) ->
    description = action.description
    f = action.f
    arg = action.arg
    button = ($ '<div class="button">').text(description)
    @$el.append button
    
  setActions: (actions) ->
    @actions = actions
    @render()

  doAction: (text) ->
    for action in @actions
      if action.description == text
        action.f action.arg
        break

class Level

  minimumRoomSize: 5

  constructor: (@difficulty) ->
    @isComplete = false
    @map = do =>
      map = []
      for y in [0..WORLD_HEIGHT - 1]
        row = []
        for x in [0..WORLD_WIDTH - 1]
          row[x] = new LevelTile y, x, this
        map[y] = row
      map

    @generateSpaces()

    exit = new LevelEnd this

    @addEnemies()

  addEnemies: ->
    for n in [0..@difficulty*@difficulty]
      new GiantPotato this

  update: ->
    for row in @map
      for cell in row
        thing.update() for thing in cell.contents

  distanceFromPlayer: (y, x) ->
    dx = Math.abs x - @player.tile.x
    dy = Math.abs y - @player.tile.y
    dx + dy

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
    @$el.empty()
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

class LogView extends Backbone.View

  el: ($ '#log')

  initialize: ->
    @$el.empty()

  print: (message) ->
    p = ($ '<p>').text message
    @$el.append p
    while @$el.children().length > 12
      @$el.children().first().remove()

log = new LogView

class LDView extends Backbone.View

  el: ($ '#page-wrap')

  nextLevel: =>
    @difficulty = @difficulty + 1
    @current_level = new Level @difficulty
    @current_level.player = @player
    @mapView = new MapView @current_level
    @player.moveToLevel @current_level
    @mapView.render()

  initialize: ->
    @difficulty = 0
    @current_level = new Level @difficulty

    @mapView = new MapView @current_level
    @player = new Player @current_level
    @current_level.player = @player
    @mapView.render()

    @actionsView = new ActionsView

    # setup controls

    $(document.body).on
      keypress: (event) =>
        key = String.fromCharCode event.charCode
        switch key
          when 'w'
            @player.setEvent @player.move, { x:  0, y: -1 }
            @update()
          when 'a'
            @player.setEvent @player.move, { x: -1, y:  0 }
            @update()
          when 's'
            @player.setEvent @player.move, { x:  0, y:  1 }
            @update()
          when 'd'
            @player.setEvent @player.move, { x:  1, y:  0 }
            @update()

        @mapView.render()

      click: (event) =>
        target = ($ event.target)
        if target.is 'p span'
          @select(target) 
        if target.is '.button'
          @actionsView.doAction target.text()
          @update()
        else if target.is '#help-button'
          ($ '#help').css { display: 'block' }
        else if target.is '#help'
          target.css { display: 'none' }

  select: (target) =>
    x = target.attr('id')
    y = target.parent().attr('id')
    ($ '#game-area span').removeClass 'active'
    target.addClass 'active'
    @actionsView.setActions @current_level.map[y][x].getActions()
    log.print @current_level.map[y][x].getDescription()

  unselect: ->
    ($ '#game-area span').removeClass 'active'
    @actionsView.setActions []

  render: ->

  update: ->
    @unselect()
    if @current_level.is_complete
      @nextLevel()
    else
      @current_level.update()
    @mapView.render()

$ ->
  game = new LDView
