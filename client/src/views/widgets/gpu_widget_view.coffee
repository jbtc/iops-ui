Marionette = require('marionette')
IOPSWidgetView = require('./iops_widget_view')

# ----------------------------------
class GpuWidgetView extends IOPSWidgetView
  template:   "widgets/gpu_widget"
  classID: 'gpu_widget'
  className: 'widget-outer box box-primary gpu_widget'
  ui:
    terminal:       'select#terminal'
    zone:           'select#zone'
    display_prefix: 'input#display_prefix'
    gate:           'select#gate'
    site:           'select#site'
    wtitle:         'h3.box-title'
    display:        '.display'
    content:        '.content'
    docked:         'i#docked'
    alarms:         'i#alarms'
    warnings:       'i#warnings'

  @layout:
    sx: 5
    sy: 10

  tags = []
  tagData = []
  tagConfig = []
  site_refresh: 50000
  refId: 0

  IsUpdatingSettings: false
  IsPageLoading: true

  update: ()->
    # Ignore all calls except those from startup and Update
    if @IsUpdatingSettings || @IsPageLoading
      return null

    s = @update_settings
      prefix: 'Airport.#{@site_code}.Term#{s.terminal}.Zone#{s.zone}.Gate#{s.gate}.'
      cloud_prefix: 'RemoteSCADAHosting.Airport-#{@site_code}.'

    if !@site_code? then return null

    if s? && !!s.site      
      lbl = "#{@site_code}: Gate #{s.gate} - GPU"
      @ui.wtitle.html(lbl)

      # stop listening for updates
      #@kill_updates(@site_code)

      $("#widgetData").toggleClass("no-show", false)
      $("#widgetData2").toggleClass("no-show", true)

      tags = []
      @tagData = []
      @tagConfig = []
      @tagConfig = @create_dynamic_elements(@el.parentNode.id, @classID, null, null, @site_code, s)
      @tagData = @tagConfig.TagData
      
      for tag, tagData of @tagData
        tags.push "#{@prefix}#{tagData.Tag}.Value"

      for tg of @tags
        t = @tags[tg]
        tags.push "#{@prefix}#{t}.Value"
      
      App.opc.add_tags @site_code, tags

      @opc =  App.opc.connections[@site_code]
      ref = s.layout

      # listen for updates
      #@watch_updates(@site_code)
      #@start_heartbeat()
      if @refId == 0
        @refId = App.opc.add_tags @site_code, tags
        App.vent.on "opc:data:#{@site_code}", @data_update
        @opc =  App.opc.connections[@site_code]
        @start_heartbeat()

      @set_descriptions(true)

      # Handle the second table used for dual unit GPU's
      if @$('.data2').hasClass('no-show')
        @$('.data').css('width', '100%')
        if $('.data thead')? || $('.data thead').length = 0
          $('.data thead').remove()
        if $('.data2 thead')? || $('.data2 thead').length = 0
          $('.data2 thead').remove()
      else
        @$('.data').css('width', '75%')
        if @$('.data thead th:contains(Unit 01)').length == 0
          $('.data').prepend('<thead><tr><th></th><th>Unit 01</th></tr></thead>')
        if @$('.data2 thead th:contains(Unit 02)').length == 0
          $('.data2').prepend('<thead><tr><th></th><th>Unit 02</th></tr></thead>')
    @

  # process data and update the view
  data_update: (data)=>
    @refresh_values()
    @beat_time = new Date().getTime() + @site_refresh
    #@vals = {}
    #for tg of @tags
    #  @vals[tg] = @get_value(@tags[tg])
    
    for tag, tagData of @tagData
      switch tagData.DataType.toLowerCase()
        when 'boolean'
          @render_row("dynamic_#{tag}", tagData.Parameters.Parm001, tagData.Parameters.Parm002, tagData.Parameters.Parm003, tagData.Parameters.Parm004, tagData.Parameters.Parm005)
        when 'float'
          @render_value_row("dynamic_#{tag}", tagData.Parameters.Parm001, tagData.Parameters.Parm002, tagData.Parameters.Parm003, tagData.Parameters.Parm004)
        when 'value'
          @render_value_row("dynamic_#{tag}", tagData.Parameters.Parm001, tagData.Parameters.Parm002, tagData.Parameters.Parm003, tagData.Parameters.Parm004)
        #when 'byte' null
        #when 'int' null
        #when 'string' null
        #when 'double' null
        else null

    # ALARMS
    aq = @data_q(@tags.gpu_has_alarms)
    @ui.alarms.toggle(@get_bool(@vals.gpu_has_alarms)==true && aq)

    # WARNINGS
    wq = @data_q(@tags.gpu_has_warnings)
    @ui.warnings.toggle(@get_bool(@vals.gpu_has_warnings)==true && wq)

    @set_descriptions()

  set_model: ()=>
    if @refId > 0
      @kill_updates(@site_code)
      if @heartbeat_timer? && @heartbeat_timer > 0
        window.clearInterval(@heartbeat_timer)
      @refId = 0

    s = _.clone(@model.get("settings"))
    s.site = @$('#site').val()
    @site_code = OPCManager.get_site_code(s.site)
    s.terminal = @$('#terminal').val()
    s.zone = @$('#zone').val()
    s.gate = @$('#gate').val()
    @model.set("settings", s)

  toggle_settings: (e)->
    super(e)
    @ui.display.toggle(!@settings_visible)
    @IsUpdatingSettings = @settings_visible
    if @settings_visible
      #@kill_updates(@site_code)
      #if @heartbeat_timer? && @heartbeat_timer > 0
      #  window.clearInterval(@heartbeat_timer)
    else
      @IsPageLoading = false
      @update()

  onShow: ()->
    settings = @model.get('settings')
    settings || settings = {}
    @draw_selectors(settings.terminal, settings.zone, settings.gate)

    @$('#site').on 'change', ()=>
      @draw_selectors()
      @set_model()
    
    gate = settings.gate
    if !gate? || gate == ''
      @toggle_settings()
    else
      @IsPageLoading = false

    @site_code = OPCManager.get_site_code(settings.site)
    if @site_code?
      @site_refresh = ((OPCManager.get_site(settings.site).get("refreshRate") * 1000) * 3)
      #@watch_updates(@site_code)

    @check_init_site()


  start: ()->
    #$("#widgetData").removeClass("no-show", false)
    #$("#widgetData2").toggleClass("no-show", true)
    @update()

  start_heartbeat: ()=>
    @beat_time = new Date().getTime() + @site_refresh
    $("##{@el.parentNode.id} .widget-outer").toggleClass("no-heartbeat", false)
    if @heartbeat_timer? && @heartbeat_timer > 0
      window.clearInterval(@heartbeat_timer)
    @heartbeat_timer = window.setInterval((=>
      @check_heartbeat @el.parentNode.id
      return
    ), @site_refresh) 

  check_heartbeat: (widget_id)=>
    @curTime = new Date().getTime()
    $("##{widget_id} .widget-outer").toggleClass("no-heartbeat", (@curTime > @beat_time))

  onDestroy: (arg1, arg2) ->
    # be sure to remove listener
    if @heartbeat_timer? && @heartbeat_timer > 0
      window.clearInterval(@heartbeat_timer)
    @kill_updates(@site_code)

# ----------------------------------

window.GpuWidgetView = GpuWidgetView
module.exports = GpuWidgetView
