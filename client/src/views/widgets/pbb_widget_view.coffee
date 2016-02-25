Marionette = require('marionette')
IOPSWidgetView = require('./iops_widget_view')

# ----------------------------------
class PbbWidgetView extends IOPSWidgetView
  template:   "widgets/pbb_widget"
  className: 'widget-outer box box-primary gate_widget'
  ui:
    wtitle:         'h3.box-title'
    display:        '.display'
    content:        '.content'
    docked:         'i#docked'
    alarms:         'i#alarms'
    warnings:       'i#warnings'
    site:           'select#site'

  @layout:
    sx: 5
    sy: 7

  tags:
    #Grid Tags
    pbb_status :        'PBB.AIRCRAFTDOCKEDCALCULATION'
    pbb_aircraft :      'PBB.AIRCRAFTSTATUS'
    pbb_autolevel :     'PBB.AUTOLEVELMODEFLAG'
    pbb_canopy:         'PBB.Warning.CANOPYDOWN'
    pbb_acffloor:       'PBB.ACFFLOOR'
    pbb_cablehoist:     'PBB.HZ400CABLEDEPLOYED'
    pbb_estop:          'PBB.Alarm.E_STOP'
    pbb_limits:         'PBB.400HZ Pit'
    pbb_docktime:       'PBB.DOCKTIME'
    pbb_undocktime:     'PBB.UNDOCKTIME'
    
    #Processing Tags
    pbb_autolevelfail:  'PBB.AUTOLEVEL_FAIL_FLAG'
    pbb_has_warnings :  'Warning._HasWarnings'
    pbb_has_alarms :    'Alarm._HasAlarms'
    
  update: ()->
    @update_settings
      prefix: 'Airport.#{@site_code}.Term#{s.terminal}.Zone#{s.zone}.Gate#{s.gate}.'
      cloud_prefix: 'RemoteSCADAHosting.Airport-#{@site_code}.'
    if !@site_code? then return null

    s = @model.get("settings")
   
    if s? && !!s.site      
      tags = []
      for tg of @tags
        t = @tags[tg]
        tags.push "#{@prefix}#{t}.Value"
      App.opc.add_tags @site_code, tags

      lbl = "Gate #{s.gate}"
      @ui.wtitle.html(lbl)
      @$('#display_label #txt').html(lbl)

      @opc =  App.opc.connections[@site_code]
      # listen for updates
      @watch_updates(@site_code)
      @set_descriptions(true)

  # process data and update the view
  data_update: (data)=>
    @vals = {}
    for tg of @tags
      @vals[tg] = @get_value(@tags[tg])
    
    # PBB AIRCRAFT
    @render_row("pbb_status", "", "", "ok")
    aircraftstatus = @vals['pbb_aircraft']
    @$('#pbb_status').html(aircraftstatus)
    # @render_row("gpu_gpuoutputvolts", "", "", "ok")
    # gpuoutputvoltsstatus = @vals['gpu_gpuoutputvolts']
    # @$('#gpu_gpuoutputvolts').html(gpuoutputvoltsstatus)

    @$("#pbb_status_lbl").html('PBB Status')
    @$("#pbb_canopy_lbl").html('Canopy')
    @$("#pbb_estop_lbl").html('E-Stop')
    # @$("#pbb_smokedetectord_lbl").html('Smoke Detector')

    # PBB STATUS
    v = @get_bool(@vals.pbb_status)
    a = @get_bool(@vals.pbb_autolevel)
    c = @get_bool(@vals.pbb_canopy)
    f = @get_bool(@vals.pbb_acffloor)
    h = @get_bool(@vals.pbb_cablehoist)
    e = @get_bool(@vals.pbb_estop)
    l = @get_bool(@vals.pbb_limits)

    #DOCK-UNDOCK
    txt = if v then "Docked" else "Undocked"
    @$("#pbb_docked_lbl").html('PBB Status')
    el = @$("#pbb_docked").html(txt).toggleClass('ok', v)  
    
    #CANOPY-AUTOLEVEL
    txta = if a then "On " else "Off"
    @$("#pbb_autolevelon_lbl").html('Auto Level')
    el = @$("#pbb_autolevelon").html(txta).toggleClass('ok', a)   
    txta1 = if c then "Down " else "Up "
    @$("#pbb_canopydown_lbl").html('Canopy')
    el = @$("#pbb_canopydown").html(txta1).toggleClass('ok', c)  

    #ACF FLOOR
    txtf = if f then "On" else "Off"
    @$("#pbb_acffloored_lbl").html('ACF Floor')
    el = @$("#pbb_acfflooron").html(txtf).toggleClass('ok', f)   
    

    # #CABLE HOIST
    # txth = if h then "Active" else "Off"
    # @$("#pbb_cablehoist_lbl").html('Cable Hoist Int.')
    # el = @$("#pbb_cablehoist").html(txth).toggleClass('ok', h)   


    #E-STOP
    txte = if e then "Off" else "On"
    @$("#pbb_estoped_lbl").html('E-Stop')
    el = @$("#pbb_estopoff").html(txte).toggleClass('ok', e) 

    #LIMITS
    txtl = if l then "Ok" else "Active"
    @$("#pbb_limited_lbl").html('Limits')
    el = @$("#pbb_limitok").html(txtl).toggleClass('ok', l)   

    # Auto Level
    @render_row("pbb_autolevel", "On", "Off", "ok")

    # CANOPY
    @render_row("pbb_canopy", "Down", "Up", "ok")
    
    # SMOKEDETECTOR
    # @render_row("pbb_smokedetector","Activated","Ready/OK","err")

    # E-STOP
    @render_row("pbb_estop", "Activated", "Ready/OK", "err")
  
    # CABLE HOIST
    @render_row("pbb_cablehoist", "Deployed", "Retracted", "ok")

        # ALARMS
    aq = @data_q(@tags.pbb_has_alarms)
    @ui.alarms.toggle(@get_bool(@vals.pbb_has_alarms)==true && aq)
    # WARNINGS
    wq = @data_q(@tags.pbb_has_warnings)
    @ui.warnings.toggle(@get_bool(@vals.pbb_has_warnings)==true && wq)
    # DOCKED
    dq = @data_q(@tags.pbb_status)
    @ui.docked.toggle(@get_bool(@vals.pbb_status)==true && dq)
    
    # AUTOLEVELFAIL
    fq = @data_q(@tags.pbb_autolevelfail)
    show_alarms = (@get_bool(@vals.pbb_autolevelfail)==true && fq)
    @ui.alarms.toggle(show_alarms).toggleClass("blink",show_alarms)

    # DOCKTIME
    @$("#pbb_dockedtime_lbl").html('Dock Time')
    docktime = if @vals.pbb_docktime? && @vals.pbb_docktime != '' then parseFloat(@vals.pbb_docktime).toFixed(2) else ' -- ' 
    el = @$('#pbb_docktime').html("#{docktime} mins")
    @mark_bad_data @tags.pbb_docktime, el

    @$("#pbb_undockedtime_lbl").html('Un-Dock Time')
    undocktime = if @vals.pbb_undocktime? && @vals.pbb_undocktime != '' then parseFloat(@vals.pbb_undocktime).toFixed(2) else ' -- '      
    el = @$('#pbb_undocktime').html("#{undocktime} mins")
    @mark_bad_data @tags.pbb_undocktime, el


    @set_descriptions()

  set_model: ()=>
    s = _.clone(@model.get("settings"))
    s.site = @$('#site').val()
    s.terminal = @$('#terminal').val()
    s.zone = @$('#zone').val()
    s.gate = @$('#gate').val()
    @model.set("settings", s)

  toggle_settings: (e)->
    super(e)
    @ui.display.toggle(!@settings_visible)
    if @settings_visible then @ui.site.chosen()

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

    @site_code = OPCManager.get_site_code(settings.site)
    if @site_code? then @watch_updates(@site_code)


  start: ()->
    @update()

  onDestroy: (arg1, arg2) ->
    # be sure to remove listener
    @kill_updates(@site_code)
    
# ----------------------------------

window.PbbWidgetView = PbbWidgetView
module.exports = PbbWidgetView
