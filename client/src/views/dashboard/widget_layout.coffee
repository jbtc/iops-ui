Marionette = require('marionette')
Widget = require('../../models/widget')
WidgetView = require('../widgets/widget_view')
GateWidgetView = require('../widgets/gate_widget_view')
UrlWidgetView = require('../widgets/url_widget_view')
WidgetModalView = require('./widget_modal')

# ----------------------------------

class WidgetLayout extends Marionette.LayoutView
  template:		"dashboard/widget_layout"
  ui:
    wgrid : "ul.gridster"
  events:
    "click #add_widget" : "add_widget"

  insert_widget: (type)->
    id = @model.widgets.length+1
    @model.widgets.add
      id: id
      type: type
      settings:
        layout:
          r:          1
          c:          1
          sx:         1
          sy:         1
      config:     true
    @draw_widgets()

  add_widget: (e)->
    e.preventDefault()
    m = new Backbone.Model()
    m.view = @
    @wmv = new WidgetModalView
      model:m
    App.layout.modal_region.show(@wmv)

  adjust_widgets: (e, ui)=>
    wid = $(e.target).closest('li.widget').data('id')
    for wm, idx in @model.widgets.models
      @$('ul.gridster li').each ()->
        id = $(@).data('id')
        if (id == wm.id)
          s = wm.get("settings")
          layout = 
            r : $(@).attr('data-row')
            c : $(@).attr('data-col')
            sx : $(@).attr('data-sizex')
            sy : $(@).attr('data-sizey')
          s.layout = layout
          wm.set("settings", s)
    App.vent.trigger("user:update")
 
  set_gridster: ()->
    #return if @grid?
    @grid = $(@ui.wgrid).gridster
      resize:
        enabled: true
        stop: @adjust_widgets
      autogrow_cols: true
      draggable:
        handle: '.box-header'
        stop: @adjust_widgets
    @grid = @grid.data('gridster')
    @

  draw_widgets: ()->
    #if !@grid? then @set_gridster()
    @set_gridster()
    for w, idx in @model.widgets.models
      region = "widget_#{w.id}"
      r = @getRegion(region)
      continue if r? && r.currentView?

      wli = $("<li id='#{region}' class='widget'></li>")
      s = w.get('settings')
      lo = if s? && s.layout? then s.layout else null
      wli.attr
        'data-id' : w.id
        'data-row' : s.layout.r
        'data-column' : s.layout.c
        'data-sizex' : s.layout.sx
        'data-sizey' : s.layout.sy
      $(@ui.wgrid).append(wli)
      
      tpe = if w.get('type')? then w.get('type') else 'default'
      
      switch tpe
        when 'gate' then wv = new GateWidgetView({model:w})
        when 'url' then wv = new UrlWidgetView({model:w})
        else wv = new WidgetView({model: w})
      
      # create the region if it's a new widget
      new_region = @addRegion(region, "li##{region}")
      new_region.on "show", ()=>
        # add it to gridster
        @grid.add_widget(wli, lo.sx, lo.sy, lo.c, lo.r)
      
      # show the widget view
      new_region.show(wv);
    @set_gridster()
      
  onRender: ()->
    @draw_widgets()
    @model.widgets.on "remove", (w, b)=>
      cid = @.cid
      rg = "widget_#{w.id}"
      App.currentView.grid.remove_widget($("li##{rg}"))
    App.currentView = @
      
  	#App.AdminLTE_lib.reset()
  	
# ----------------------------------

module.exports = WidgetLayout
