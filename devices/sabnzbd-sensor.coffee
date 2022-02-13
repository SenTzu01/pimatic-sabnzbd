module.exports = (env) ->

  Promise = env.require 'bluebird'
  commons = require('pimatic-plugin-commons')(env)
  t = env.require('decl-api').types
  SABnzbd = require('sabnzbd')
  signals = require('../lib/sabnzbd_signals.json')
  class SabnzbdSensor extends env.devices.PresenceSensor

    constructor: (@config, @_plugin, lastState) ->
      @_base = commons.base @, @config.class
      @debug = @_plugin.debug || false
      @id = @config.id
      @name = @config.name
      
      @addAttribute 'status',
        description: "SABNZBd status status",
        type: t.string
        discrete: true
        acronym: "Status"
      
      @_status = lastState?.status?.value || "unknown"
      
      super()
      
      @_pullUpdatesTimeout = null
      @_pullUpdates()
      
    
    getStatus: () => Promise.resolve(@_activity)
    
    
    _pullUpdates: () =>
      @retrieveStatus()
      @_pullUpdatesTimeout = setTimeout(@_pullUpdates, Math.round(@config.interval) * 1000)
    
    retrieveStatus: () =>
      status = "idle"
      @_sabnzbd = new SABnzbd("http://#{@config.address}:#{@config.port}/", @config.key)
      return @_base.rejectWithErrorString(Promise.reject(), error, "Unable to connect to SABNZBd at http://#{@config.address}:#{@config.port}/") if !@_sabnzbd?
      @_sabnzbd.entries().then( (entries) =>
        @_setPresence(true)
        entries.map( (item) =>
          if signals[item.status] is "active"
            status = signals[item.status] 
            @_base.debug("#{item.name} - item.status: #{item.status} -> status: #{status}")
        )
        @_base.debug("SABNZBD STATUS: #{status}")
      
      ).catch( (error) =>
        @_setPresence(false)
        status = "unknown"
        @_base.rejectWithErrorString(Promise.reject(), error, "Unable to retrieve status from SABNZBd API at http://#{@config.address}:#{@config.port}/")
      
      ).finally( () =>
        @_setStatus(status)
        
      )
    
    _setStatus: (status) =>
      return if @_activity is status
      @_base.debug __("status: %s", status)
      @_activity = status
      @emit('status', status)
    
    destroy: () ->
      clearTimeout(@_pullUpdatesTimeout)
      super()