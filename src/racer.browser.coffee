require 'es5-shim'

# NOTE: All racer modules for the browser should be included in racer.coffee

# Static isReady and model variables are used, so that the ready function
# can be called anonymously. This assumes that only one instace of Racer
# is running, which should be the case in the browser.
isReady = model = null

module.exports = (racer) ->
  racer.util.mergeAll racer,

    # socket argument makes it easier to test - see test/util/model
    init: ([clientId, memory, count, onLoad, startId, ioUri], socket) ->
      model = new racer.Model
      model._clientId = clientId
      model._startId = startId
      model._memory.init memory
      model._count = count

      for item in onLoad
        method = item.shift()
        model[method] item...

      racer.emit 'init', model

      model._setSocket socket || io.connect ioUri,
        'reconnection delay': 100
        'max reconnection attempts': 20

      isReady = true
      racer.emit 'ready', model
      return racer

    ready: (onready) -> ->
      racer.on 'ready', onready
      if isReady
        connected = model.socket.socket.connected
        onready model
        # Republish the Socket.IO connect event after the onready callback
        # executes in case any client code wants to use it
        model.socket.socket.publish 'connect' if connected
