Marionette = require('marionette')

# ----------------------------------

class WidgetView extends Marionette.ItemView
  template:		"widgets/widget"
  className: 'widget-outer box box-primary'

  events:
    "click #show_settings" : "toggle_settings"
    "click #remove" : "remove_widget"

  constructor: (config)->
    super(config)
    @settings_visible = false
    @

  toggle_settings: (e)->
    if e? then e.preventDefault()
    @settings_visible = !@settings_visible
    @$(".settings").toggle(@settings_visible)

  remove_widget: (e)->
    if e?
      e.preventDefault()
      @model.collection.remove(@model)

  start: ()->
    console.log "not implemented"

  	
# ----------------------------------

module.exports = WidgetView
