@LKT =
  Router: {}
  Views: {}
  Utils: {}
  Models: {}
  Collections: {}
  Templates: {}
  Players: []
  Config:
    enviroment: 'production'
    templates_path: 'templates/'
    templates_type: 'html'
    socketio_server:
      local: 'localhost:1347'
      production: 'fear-the-dice-socket.herokuapp.com'
    api_server:
      local: 'localhost:3000'
      production: 'keepiteasy.net:3000'

$ ((app) ->
  # utils
  app.Utils.guid = () ->
    # http://stackoverflow.com/a/105074
    s4 = () ->
      Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)

    s4() + s4() + '-' + s4() + '-' + s4() + '-' +
      s4() + '-' + s4() + s4() + s4()

  # Define array of all template files
  templates = new Array "player", "monster", "base", "dm", "player_dm", "monster_dm",
    "player_sidebar", "monster_sidebar"

  # Load all template files into LKT.Templates
  _.each templates, (template) ->
    url = app.Config.templates_path + template + "." + app.Config.templates_type

    $.ajax
      url: url
      async: false
      dataType: "text"
      success: (data) ->
        app.Templates[template] = data
        this

  # Connect to our socket.io server
  app.socket = io "http://" + app.Config.socketio_server[app.Config.enviroment]
  this

)(window.LKT)

$ ((app) ->
  app.Models.Monster = Backbone.Model.extend
    defaults:
      monster: "Bandit"
      turn: false
      initiative: 12
      ac: 12
      hp: 11
      speed: 30
      health: 11
      damage: 0
      xp: 25
      manual: 343
      thumb: "//www.fillmurray.com/g/200/140"
      playling: false

    initialize: (args) ->
      if typeof(args) == 'undefined'
        this.set "id", app.Utils.guid()

      return this
    this

  this
)(window.LKT)

$ ((app) ->
  app.Models.Player = Backbone.Model.extend
    defaults:
      name: "John"
      character: "Sir Stabington"
      turn: false
      initiative: 1
      ac: 12
      speed: 30
      hp: 10
      health: 10
      damage: 0
      thumb: "//placekitten.com.s3.amazonaws.com/homepage-samples/200/140.jpg"
      playling: false

    initialize: (args) ->
      if typeof(args) == 'undefined'
        this.set "id", app.Utils.guid()

      return this
    this

  this
)(window.LKT)

$ ((app) ->
  app.Collections.Game = Backbone.Collection.extend
    comparator: (model) ->
      parseInt -model.get("initiative")

  this
)(window.LKT)

$ ((app) ->
  app.Collections.Monster = Backbone.Collection.extend
    model: app.Models.Monster
    url: 'http://' + app.Config.api_server[app.Config.enviroment] + '/monsters'
    comparator: (model) ->
      parseInt -model.get("initiative")

  this
)(window.LKT)

$ ((app) ->
  app.Collections.Player = Backbone.Collection.extend
    model: app.Models.Player
    url: 'http://' + app.Config.api_server[app.Config.enviroment] + '/players'
    comparator: (model) ->
      parseInt -model.get("initiative")

  this
)(window.LKT)

$ ((app) ->
  app.Views.Base = Backbone.View.extend
    tagName: "div"
    className: "container-fluid"

    events:
      "click .turn__next_btn": "nextTurn"

    pubsub_init: ->
      PubSub.subscribe "GameCollection.sort", $.proxy(this.reRender, this)
      PubSub.subscribe "ActivePlayer", $.proxy(this.activePlayer, this)

    socket_init: ->
      # turn socket listeners
      app.socket.on "EndTurn", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        model.view.endTurn()
        model
      , this)

      app.socket.on "StartTurn", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        model.view.startTurn()
        model
      , this)

      # player socket listeners
      app.socket.on "NewPlayer", $.proxy((data) ->
        model = new this.playerModel JSON.parse(data)
        app.Collections.Game.push model
        new this.playerView model
        model
      , this)

      app.socket.on "ExistingPlayers", $.proxy((data) ->
        _.each JSON.parse(data), $.proxy((model) ->
          model = new this.playerModel model
          exists = _.find app.Collections.Player.models, (player) ->
            player.get("id") == model.get("id")
          app.Collections.Player.add model if exists == -1
          app.Collections.Game.add(model) if model.get("playing") == true
          new this.playerView model
          model
        , this)
      , this)

      app.socket.on "PlayerUpdate", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        model.set data
        model
      , this)

      app.socket.on "PlayerRemoved", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        app.Collections.Game.remove model
        model
      , this)

      # monster socket listeners
      app.socket.on "NewMonster", $.proxy((data) ->
        model = new this.monsterModel JSON.parse(data)
        app.Collections.Game.push model
        new this.monsterView model
        model
      ,this)

      app.socket.on "ExistingMonsters", $.proxy((data) ->
        _.each JSON.parse(data), $.proxy((model) ->
          model = new this.monsterModel model
          exists = _.find app.Collections.Monster.models, (monster) ->
            monster.get("id") == model.get("id")
          app.Collections.Monster.add model if exists == -1
          app.Collections.Game.add(model) if model.get("playing") == true
          new this.monsterView model
          model
        , this)
      , this)

      app.socket.on "MonsterUpdate", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        model.set data
        model
      , this)

      app.socket.on "MonsterRemoved", $.proxy((data) ->
        data = JSON.parse data
        model = app.Collections.Game.get data.id
        app.Collections.Monster.remove model
        model
      , this)

    initialize: ->
      this.template = app.Templates.base
      this.render()

      this.playerModel = app.Models.Player
      this.playerView = app.Views.Player
      this.monsterModel = app.Models.Monster
      this.monsterView = app.Views.Monster
      this.turn = 0

      this.pubsub_init()
      this.socket_init()

      this

    render: ->
      this.$el.html Mustache.render this.template
      this.$el

    reRender: ->
      this.$el.find(".game").html ""

      _.each app.Collections.Game.models, $.proxy((member) ->
        view = member.view
        this.$el.find(".game").append view.$el
        view.postRender()
      , this)

    activePlayer: (msg, data) ->
      this.$el.addClass "active-player"
      activePlayer = app.Collections.Game.get data
      new app.Views.PlayerDM activePlayer
      activePlayer.view.$el.addClass "active-player"
      this.reRender()

    nextTurn: (e) ->
      if typeof(this.currentPlayer) != 'undefined'
        this.currentPlayer.view.endTurn()
        app.socket.emit "EndTurn", JSON.stringify this.currentPlayer.toJSON()

      this.currentPlayer = app.Collections.Game.at this.turn
      app.socket.emit "StartTurn", JSON.stringify this.currentPlayer.toJSON()

      this.currentPlayer.view.startTurn()
      this.turn = if (this.turn < (app.Collections.Game.length - 1)) then (this.turn + 1) else 0
      this.currentPlayer

  this
)(window.LKT)

$ ((app) ->
  app.Views.Dm = app.Views.Base.extend
    events:
      "click .players__add_btn": "addPlayer"
      "click .monster__add_btn": "addMonster"
      "click .turn__next_btn": "nextTurn"

    initialize: ->
      this.template = app.Templates.dm
      this.render()

      this.playerModel = app.Models.Player
      this.playerView = app.Views.PlayerDM
      this.monsterModel = app.Models.Monster
      this.monsterView = app.Views.MonsterDM
      this.turn = 0

      this.pubsub_init()
      this.socket_init()

      this.loadPlayers()
      this.loadMonsters()

    pubsub_init: ->
      PubSub.subscribe "GameCollection.sort", $.proxy(this.reRender, this)
      PubSub.subscribe "PlayerCollection.add", $.proxy(this.addSidebarPlayer, this)
      PubSub.subscribe "MonsterCollection.add", $.proxy(this.addSidebarMonster, this)

    addSidebarMonster: ->
      this.$el.find(".monsters").html ""

      _.each app.Collections.Monster.models, $.proxy((member) ->
        view = new app.Views.MonsterSidebar member
        this.$el.find(".monsters").append view.$el
      , this)

    addSidebarPlayer: ->
      this.$el.find(".players").html ""

      _.each app.Collections.Player.models, $.proxy((member) ->
        view = new app.Views.PlayerSidebar member
        this.$el.find(".players").append view.$el
      , this)

    loadMonsters: ->
      app.Collections.Monster.fetch()

    loadPlayers: ->
      app.Collections.Player.fetch()

    addPlayer: (e) ->
      model = new app.Models.Player()
      model.set "playing", true
      new this.playerView model
      app.socket.emit "NewPlayer", JSON.stringify model.toJSON()
      app.Collections.Game.push model
      model

    addMonster: (e) ->
      model = new app.Models.Monster()
      model.set "playing", true
      new this.monsterView model
      app.socket.emit "NewMonster", JSON.stringify model.toJSON()
      app.Collections.Game.push model
      model

  this
)(window.LKT)

$ ((app) ->
  app.Views.Monster = Backbone.View.extend
    tagName: "div"
    className: "row"
    events:
      "click .monster__hit": "hit"
      "click .monster__hit--edit .glyphicon-check": "saveDamage"

    initialize: (model) ->
      this.template = app.Templates.monster
      this.model = model
      this.model.view = this
      this.model.set "id", this.model.id
      this.open = false

      _.bindAll this, "render"
      this.model.bind "change", $.proxy(this.change, this)
      this.render()

      this

    change: ->
      health = this.model.get("hp") - this.model.get("damage")
      this.model.set "health", health

      PubSub.publish "MonsterUpdate", JSON.stringify this.model.toJSON()
      app.socket.emit "MonsterUpdate", JSON.stringify this.model.toJSON()
      this.render()

    render: ->
      this.$el.html Mustache.render this.template, this.model.toJSON()
      this.$el.addClass "monster"
      this.$el

    startTurn: ->
      this.model.set "turn", true
      this.$el.addClass "turn"
      this.$el

    endTurn: ->
      this.model.set "turn", false
      this.$el.removeClass "turn"
      this.$el

    postRender: () ->
      this.reRender()

      if this.open is false
        this.$el.slideDown()
        this.open = true

      this.delegateEvents()
      this.$el

    reRender: ->
      if this.model.get("health") <= 0
        this.$el.find(".monster__hit").hide()
        this.$el.addClass "dead"
      else
        this.$el.removeClass "dead"

      this.$el

    hit: (e) ->
      this.$el.find(".monster__hit").hide()
      this.$el.find(".monster__hit--edit").show()

    saveDamage: (e) ->
      value = parseInt this.$el.find(".monster__hit--edit input").val()

      this.$el.find(".monster__hit--edit").hide()
      this.$el.find(".monster__hit--edit").val 0
      this.$el.find(".monster__hit").show()

      stats =
        damage: this.model.get("damage") + value
        health: this.model.get("health") - value

      this.model.set stats

      this.reRender()

  this
)(window.LKT)

$ ((app) ->
  app.Views.MonsterDM = app.Views.Monster.extend
    events:
      "click .monster__stat": "editStat"
      "click .monster__stat--value": "editStat"
      "click .monster__stat--edit .glyphicon-check": "saveStat"

      "click .monster__name": "editName"
      "click .monster__name--edit .glyphicon-check": "saveName"

      "click .monster__hit": "hit"
      "click .monster__hit--edit .glyphicon-check": "saveDamage"

      "click .monster__heal": "heal"
      "click .monster__heal--edit .glyphicon-check": "saveHealing"

      "click .monster__delete": "deleteMonster"

    initialize: (model) ->
      this.template = app.Templates.monster_dm
      this.model = model
      this.model.view = this
      this.model.set "id", this.model.id
      this.open = false

      _.bindAll this, "render"
      this.model.bind "change", $.proxy(this.change, this)
      this.render()

      this

    editName: (e) ->
      $stat = $(e.currentTarget).parent()

      $stat.find(".monster__name").hide()
      $stat.find(".monster__name--edit input").val this.model.get "monster"
      $stat.find(".monster__name--edit").show()

    saveName: (e) ->
      $stat = $(e.currentTarget).parent().parent()

      value = $stat.find(".monster__name--edit input").val()

      this.model.set "monster", value
      $stat.find(".monster__name--edit").hide()
      $stat.find(".monster__name").show()

    editStat: (e) ->
      $stat = $(e.currentTarget).parent()
      stat = $stat.find(".monster__stat").attr "stat"

      $stat.find(".monster__stat--value").hide()
      $stat.find(".monster__stat--edit input").val this.model.get stat
      $stat.find(".monster__stat--edit").show()

    saveStat: (e) ->
      $stat = $(e.currentTarget).parent().parent()
      stat = $stat.find(".monster__stat").attr "stat"

      value = parseInt $stat.find(".monster__stat--edit input").val()

      this.model.set stat, value
      $stat.find(".monster__stat--edit").hide()
      $stat.find(".monster__stat--value").show()

      if stat == "initiative"
        PubSub.publish "PlayerOrderChange"

      this.reRender()

    heal: (e) ->
      this.$el.find(".monster__heal").hide()
      this.$el.find(".monster__heal--edit").show()

    saveHealing: (e) ->
      value = parseInt this.$el.find(".monster__heal--edit input").val()

      this.$el.find(".monster__heal--edit").hide()
      this.$el.find(".monster__heal--edit").val 0
      this.$el.find(".monster__heal").show()

      stats =
        damage: this.model.get("damage") - value
        health: this.model.get("health") + value

      stats.damage = if (stats.damage < 0) then 0 else stats.damage

      this.model.set stats

      this.reRender()

    deleteMonster: (e) ->
      app.socket.emit "MonsterRemoved", JSON.stringify this.model.toJSON()
      app.Collections.Game.remove this.model
      this.$el.remove()

  this
)(window.LKT)

$ ((app) ->
  app.Views.MonsterSidebar = Backbone.View.extend
    tagName: "div"
    className: "sidebar__monster"

    events:
      "click i": "addMonster"

    initialize: (model) ->
      this.template = app.Templates.monster_sidebar
      this.model = model
      this.render()
      this

    render: ->
      this.$el.html Mustache.render this.template, this.model.toJSON()
      this.$el.addClass "text-center row"
      this.$el

    addMonster: ->
      model = new app.Models.Monster()
      console.log model
      console.log JSON.stringify model.toJSON()
      model.set "playing", true
      app.socket.emit "NewMonster", JSON.stringify model.toJSON()
      new app.Views.MonsterDM model
      app.Collections.Game.add model

  this
)(window.LKT)

$ ((app) ->
  app.Views.Player = Backbone.View.extend
    tagName: "div"
    className: "row"
    events:
      "click .player__hit": "hitPlayer"
      "click .player__control": "takeControl"
      "click .player__hit--edit .glyphicon-check": "saveDamage"

    initialize: (model) ->
      this.template = app.Templates.player
      this.model = model
      this.model.view = this
      this.model.set "id", this.model.id
      this.open = false

      _.bindAll this, "render"
      this.model.bind "change", $.proxy(this.change, this)
      this.render()

      this

    change: ->
      PubSub.publish "PlayerUpdate", JSON.stringify this.model.toJSON()
      app.socket.emit "PlayerUpdate", JSON.stringify this.model.toJSON()
      this.render()

    render: ->
      this.$el.html Mustache.render this.template, this.model.toJSON()
      this.$el.addClass "player"
      this.$el

    startTurn: ->
      this.turn = true
      this.$el.addClass "turn"
      this.$el

    endTurn: ->
      this.turn = false
      this.$el.removeClass "turn"
      this.$el

    postRender: () ->
      this.reRender()

      if this.open == false
        this.$el.slideDown()
        this.open = true

      this.delegateEvents()
      this.$el

    reRender: ->
      if this.model.get("damage") >= this.model.get("hp")
        this.$el.find(".player__hit").hide()
        this.$el.addClass "dead"
      else
        this.$el.removeClass "dead"

      this.$el

    hitPlayer: (e) ->
      this.$el.find(".player__hit").hide()
      this.$el.find(".player__hit--edit").show()

    saveDamage: (e) ->
      value = parseInt this.$el.find(".player__hit--edit input").val()

      this.$el.find(".player__hit--edit").hide()
      this.$el.find(".player__hit--edit").val 0
      this.$el.find(".player__hit").show()

      stats =
        damage: this.model.get("damage") + value
        health: this.model.get("health") - value

      this.model.set stats

      this.reRender()

    takeControl: (e) ->
      this.$el.addClass "active-player"
      PubSub.publish "ActivePlayer", this.model.id

  this
)(window.LKT)

$ ((app) ->
  app.Views.PlayerDM = app.Views.Player.extend
    events:
      "click .player__stat": "editStat"
      "click .player__stat--value": "editStat"
      "click .player__stat--edit .glyphicon-check": "saveStat"

      "click .character__name": "editCharacter"
      "click .character__name--edit .glyphicon-check": "saveCharacter"

      "click .player__name": "editName"
      "click .player__name--edit .glyphicon-check": "saveName"

      "click .player__hit": "hitPlayer"
      "click .player__hit--edit .glyphicon-check": "saveDamage"

      "click .player__heal": "healPlayer"
      "click .player__heal--edit .glyphicon-check": "saveHealing"

      "click .player__delete": "deletePlayer"

    initialize: (model) ->
      this.template = app.Templates.player_dm
      this.model = model
      this.model.view = this
      this.model.set "id", this.model.id
      this.open = false

      _.bindAll this, "render"
      this.model.bind "change", $.proxy(this.change, this)
      this.render()

      this

    change: ->
      health = this.model.get("hp") - this.model.get("damage")
      this.model.set "health", health

      PubSub.publish "PlayerUpdate", JSON.stringify this.model.toJSON()
      app.socket.emit "PlayerUpdate", JSON.stringify this.model.toJSON()
      this.render()

    editName: (e) ->
      $stat = $(e.currentTarget).parent()

      $stat.find(".player__name").hide()
      $stat.find(".player__name--edit input").val this.model.get "name"
      $stat.find(".player__name--edit").show()

    saveName: (e) ->
      $stat = $(e.currentTarget).parent().parent()

      value = $stat.find(".player__name--edit input").val()

      this.model.set "name", value
      $stat.find(".player__name--edit").hide()
      $stat.find(".player__name").show()

    editCharacter: (e) ->
      $stat = $(e.currentTarget).parent()

      $stat.find(".character__name").hide()
      $stat.find(".character__name--edit input").val this.model.get "character"
      $stat.find(".character__name--edit").show()

    saveCharacter: (e) ->
      $stat = $(e.currentTarget).parent().parent()

      value = $stat.find(".character__name--edit input").val()

      this.model.set "character", value
      $stat.find(".character__name--edit").hide()
      $stat.find(".character__name").show()

    editStat: (e) ->
      $stat = $(e.currentTarget).parent()
      stat = $stat.find(".player__stat").attr "stat"

      $stat.find(".player__stat--value").hide()
      $stat.find(".player__stat--edit input").val this.model.get stat
      $stat.find(".player__stat--edit").show()

    saveStat: (e) ->
      $stat = $(e.currentTarget).parent().parent()
      console.log $stat
      stat = $stat.find(".player__stat").attr "stat"

      value = parseInt $stat.find(".player__stat--edit input").val()

      this.model.set stat, value
      $stat.find(".player__stat--edit").hide()
      $stat.find(".player__stat--value").show()

      if stat == "initiative"
        PubSub.publish "PlayerOrderChange"

      this.reRender()

    healPlayer: (e) ->
      this.$el.find(".player__heal").hide()
      this.$el.find(".player__heal--edit").show()

    saveHealing: (e) ->
      value = parseInt this.$el.find(".player__heal--edit input").val()

      this.$el.find(".player__heal--edit").hide()
      this.$el.find(".player__heal--edit").val 0
      this.$el.find(".player__heal").show()

      stats = 
        damage: this.model.get("damage") - value
        health: this.model.get("health") + value

      stats.damage = if (stats.damage < 0) then 0 else stats.damage

      this.model.set stats 

      this.reRender()

    deletePlayer: (e) ->
      app.socket.emit "PlayerRemoved", JSON.stringify this.model.toJSON()
      app.Collections.Game.remove this.model
      this.$el.remove()

  this
)(window.LKT)

$ ((app) ->
  app.Views.PlayerSidebar = Backbone.View.extend
    tagName: "div"
    className: "sidebar__player"

    events:
      "click i": "addPlayer"

    initialize: (model) ->
      this.template = app.Templates.player_sidebar
      this.model = model
      this.render()
      this

    render: ->
      this.$el.html Mustache.render this.template, this.model.toJSON()
      this.$el.addClass "text-center row"
      this.$el

    addPlayer: ->
      this.model.set "playing", true
      app.socket.emit "NewPlayer", JSON.stringify this.model.toJSON()
      new app.Views.PlayerDM this.model
      app.Collections.Game.add this.model

  this
)(window.LKT)

$ ((app) ->
  # Configure router
  AppRouter = Backbone.Router.extend
    routes:
      "": "home"
      "dm": "dm"

    home: ->
      view = new app.Views.Base()
      $("body .base").html view.$el

    dm: ->
      view = new app.Views.Dm()
      $("body .base").html view.$el

    pubsub_init: ->
      PubSub.subscribe "PlayerCollection.change", $.proxy(() -> 
        app.Collections.Player.sort()
      , this)

      PubSub.subscribe "MonsterCollection.change", $.proxy(() -> 
        app.Collections.Monster.sort()
      , this)

    initialize: ->
      app.Collections.Player = new app.Collections.Player()
      app.Collections.Monster = new app.Collections.Monster()
      app.Collections.Game = new app.Collections.Game()

      this.pubsub_init()

      # Player collection bindings
      app.Collections.Player.bind "add", (model) ->
        PubSub.publish "PlayerCollection.add"

      app.Collections.Player.bind "change", () ->
        PubSub.publish "PlayerCollection.change"

      # Monster collection bindings
      app.Collections.Monster.bind "add", (model) ->
        PubSub.publish "MonsterCollection.add"

      app.Collections.Monster.bind "change", () ->
        PubSub.publish "MonsterCollection.change"

      # Game collection bindings
      app.Collections.Game.bind "add", () ->
        app.Collections.Game.sort()
        PubSub.publish "GameCollection.add"

      app.Collections.Game.bind "change", () ->
        app.Collections.Game.sort()
        PubSub.publish "GameCollection.change"

      app.Collections.Game.bind "sort", () ->
        PubSub.publish "GameCollection.sort"

  # Light the fuse!
  new AppRouter()
  Backbone.history.start()
  this

)(window.LKT)
