module.exports = (env) ->

  commons = require('pimatic-plugin-commons')(env)
  Promise = env.require 'bluebird'
  M = env.matcher
  _ = env.require('lodash')
  assert = env.require 'cassert'
  
  class SabnzbdActivityPredicateProvider extends env.predicates.PredicateProvider
    constructor: (@framework, @plugin) ->
      @debug = @plugin.config.debug ? false
      @base = commons.base @, "SabnzbdActivityPredicateProvider"

    parsePredicate: (input, context) ->
      signals = require '../lib/sabnzbd_signals.json'
      
      devices = _(@framework.deviceManager.devices).values()
        .filter((device) => device.config.class is 'SabnzbdSensor').value()
      device = null
      match = null
      status = null

      M(input, context)
        .match(['status of '])
        .matchDevice(devices, (next, d) =>   
          next.match([' is ', ' reports ', ' signals '])
            .match(Object.values(signals), (m, s) =>
              if device? and device.id isnt d.id
                context?.addError(""""#{input.trim()}" is ambiguous.""")
                return
              device = d
              status = s.trim()
              match = m.getFullMatch()
            )
      )

      if match?
        assert device?
        assert status?
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          predicateHandler: new SabnzbdActivityPredicateHandler(device, status, @plugin)
        }
      else
        return null

  class SabnzbdActivityPredicateHandler extends env.predicates.PredicateHandler

    constructor: (@device, @status, plugin) ->
      @debug = plugin.config.debug ? false
      @base = commons.base @, "SabnzbdActivityPredicateHandler"
      @dependOnDevice(@device)

    setup: ->
      @statusListener = (status) =>
        @base.debug "Checking if current state #{status} matches #{@status}"
        @emit 'change', true if @status is status

      @device.on 'status', @statusListener
      super()

    getValue: ->
      @device.getUpdatedAttributeValue('status').then( (status) =>
        return status
      )

    destroy: ->
      @device.removeListener 'status', @statusListener
      super()

    getType: -> 'status'
    
  return SabnzbdActivityPredicateProvider