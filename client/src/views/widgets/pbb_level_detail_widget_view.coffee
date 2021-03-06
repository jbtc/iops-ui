Marionette = require('marionette')
IOPSWidgetView = require('./iops_widget_view')

# ----------------------------------
class PbbleveldetailWidgetView extends IOPSWidgetView
  template:   "widgets/pbb_level_detail_widget"
  classID: 'pbb_level_detail_widget'
  className: 'widget-outer box box-primary pbb_level_detail_widget'
  ui:
    terminal:       'input#terminal'
    zone:           'input#zone'
    display_prefix: 'input#display_prefix'
    gate:           'input#gate'
    site:           'select#site'
    wtitle:         'h3.box-title'
    display:        '.display'
    content:        '.content'
    docked:         'i#docked'
    alarms:         'i#alarms'
    warnings:       'i#warnings'

  @layout:
    sx: 13
    sy: 16

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
      lbl = "#{@site_code}: PBB #{s.gate} - Details"
      @ui.wtitle.html(lbl)

      # stop listening for updates
      #@kill_updates(@site_code)

      tags = []
      @tagData = []
      @tagConfig = []
      @tagConfig = @create_dynamic_elements(@el.parentNode.id, @classID, null, null, @site_code, s)
      @tagData = @tagConfig.TagData

      $(".data td").toggleClass("transparent",true)

      for tag, tagData of @tagData
        tags.push "#{@prefix}#{tagData.Tag}.Value"

      for tg of @tags
        t = @tags[tg]
        tags.push "#{@prefix}#{t}.Value"

      #App.opc.add_tags @site_code, tags
      #App.vent.on "opc:data:#{@site_code}", @data_update

      #@opc =  App.opc.connections[@site_code]

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


  # process data and update the view
  data_update: (data)=>
    @refresh_values()
    @beat_time = new Date().getTime() + @site_refresh

    for tag, tagData of @tagData
      switch tagData.DataType.toLowerCase()
        when 'boolean'
          @render_row("dynamic_#{tag}", tagData.Parameters.Parm001, tagData.Parameters.Parm002, tagData.Parameters.Parm003, tagData.Parameters.Parm004, tagData.Parameters.Parm005)
        when 'float'
          @render_value_row("dynamic_#{tag}", tagData.Parameters.Parm001, tagData.Parameters.Parm002, tagData.Parameters.Parm00)
        when 'value'
          @render_value_row("dynamic_#{tag}", tagData.Parameters.Parm001, tagData.Parameters.Parm002, tagData.Parameters.Parm003, tagData.Parameters.Parm004)
        #when 'byte' null
        #when 'int' null
        #when 'string' null
        #when 'double' null
        else null

    v = @get_bool(@vals.pbb_status)
    

    sq = @data_q(@tagData.pbb_status.Tag)
    @$("#aircraft_img").toggleClass('docked', v==true && sq)

    if (@tagData.elvrot_rotunda_position_boolean?)
        e = @get_bool(@vals.elvrot_rotunda_position_boolean)
        eq = @data_q(@tagData.elvrot_rotunda_position_boolean.Tag)
        @$("div.elevating_img").toggleClass('down-position', e==true && eq)
      
    #WHEEL ANGLE DEG
    if @tagData.pbb_wheel_angle_deg?
      wheelangledeg = if @vals.pbb_wheel_angle_deg? && @vals.pbb_wheel_angle_deg != '' then parseFloat(@vals.pbb_wheel_angle_deg).toFixed(2)  else ' -- ' 
      #wa1 = @$('#pbb_wheel_angle_deg').html("Wheel Bogie Angle : #{wheelangledeg}")
      wa1 = @$('#pbb_wheel_angle_deg').text("Wheel Bogie Angle : #{wheelangledeg}")
      @mark_bad_data @tagData.pbb_wheel_angle_deg.Tag, wa1
    else
      @$('#pbb_wheel_angle_deg').html("")
    
    #SLOPE DEG
    if @tagData.pbb_slope_deg?
      slopedeg = if @vals.pbb_slope_deg? && @vals.pbb_slope_deg != '' then parseFloat(@vals.pbb_slope_deg).toFixed(2)  else ' -- ' 
      s2 = @$('#pbb_slope_deg').html("Slope : #{slopedeg}")
      @mark_bad_data @tagData.pbb_slope_deg.Tag, s2
    else
      @$('#pbb_slope_deg').html("")

    # CAB ANGLE DISP
    if @tagData.pbb_cab_angle_disp?
      cabangledisp = if @vals.pbb_cab_angle_disp? && @vals.pbb_cab_angle_disp != '' then parseFloat(@vals.pbb_cab_angle_disp).toFixed(2)  else ' -- ' 
      ca1 = @$('#pbb_cab_angle_disp').html("Cab Angle : #{cabangledisp}")
      @mark_bad_data @tagData.pbb_cab_angle_disp.Tag, ca1
    else
      @$('#pbb_cab_angle_disp').html("")

    # SWING ANGLE DISP
    if @tagData.pbb_swing_angle_disp?
      swingangledisp = if @vals.pbb_swing_angle_disp? && @vals.pbb_swing_angle_disp != '' then parseFloat(@vals.pbb_swing_angle_disp).toFixed(2)  else ' -- ' 
      swa1 = @$('#pbb_swing_angle_disp').html("Bridge Rotation :#{swingangledisp}")
      @mark_bad_data @tagData.pbb_swing_angle_disp.Tag, swa1
    else
      @$('#pbb_swing_angle_disp').html("")

    # HEIGHT TO DISP
    if @tagData.pbb_height_to_disp?
      heighttodisp = if @vals.pbb_height_to_disp? && @vals.pbb_height_to_disp != '' then parseFloat(@vals.pbb_height_to_disp).toFixed(2)  else ' -- ' 
      hd1 = @$('#pbb_height_to_disp').html("Height : #{heighttodisp}")
      @mark_bad_data @tagData.pbb_height_to_disp.Tag, hd1
    else
      @$('#pbb_height_to_disp').html("")

    # TUNNEL LENGTH
    if @tagData.pbb_tunnel_length?
      tunnellength = if @vals.pbb_tunnel_length? && @vals.pbb_tunnel_length != '' then parseFloat(@vals.pbb_tunnel_length).toFixed(2)  else ' -- ' 
      tl = @$('#pbb_tunnel_length').html("Tunnel Length : #{tunnellength}")
      @mark_bad_data @tagData.pbb_tunnel_length.Tag, tl
    else
      @$('#pbb_tunnel_length').html("")

    # ALARMS
    aq = @data_q(@tagData.pbb_has_alarms)
    @ui.alarms.toggle(@get_bool(@vals.pbb_has_alarms)==true && aq)
    # WARNINGS
    wq = @data_q(@tags.pbb_has_warnings)
    @ui.warnings.toggle(@get_bool(@vals.pbb_has_warnings)==true && wq)

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

window.PbbleveldetailWidgetView = PbbleveldetailWidgetView
module.exports = PbbleveldetailWidgetView
