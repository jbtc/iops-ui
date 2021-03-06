Marionette = require('marionette')
DashboardHeaderView = require('./header_view')
DashboardSideView = require('./side_view')
DashboardToolView = require('./tool_view')
DashboardFooterView = require('./footer_view')
DashboardContentView = require('./content_view')
WidgetLayout = require('./widget_layout')

# ----------------------------------

class DashboardLayout extends Marionette.LayoutView
  template: "dashboard/dashboard_layout"
  regions:
    header: "#header-region"
    side: "#side-region"
    tool: "#tool-region"
    footer: "#footer-region"
    content: "#content-region"

  show_content: ({title, subtitle, view, icon})->
    App.currentView = view
    contentview = new DashboardContentView()
    contentview.title = title
    contentview.subtitle = subtitle
    contentview.center_view = view
    contentview.icon = icon
    @content.show(contentview)
    #App.AdminLTE_lib.reset()
    @

  show_widgets: (dash)->
    v = new WidgetLayout
      model: dash
    @show_content
      title: dash.get('name')
      subtitle: ''
      view: v

  empty: ()->
    @content.empty()

  onShow: () ->
    @headerview = new DashboardHeaderView
      model: App.session
    @header.show(@headerview)

    @sideview = new DashboardSideView
      collection: App.dashboards
    @side.show(@sideview)

    global_admin = App.session.is_global_admin()
    site_admin = false
    for s in App.accounts.models[0].sites.models
      site_admin = site_admin || App.session.is_site_admin(s.id)

    if site_admin || global_admin
      @toolview = new DashboardToolView()
      @tool.show(@toolview)
      @toolview.set_options(global_admin)
    else
      $("#toolsmenu").hide()

    @footerview = new DashboardFooterView()
    @footer.show(@footerview)

    App.AdminLTE_lib.reset()

    App.vent.on 'dashboard:update', ()=>
      App.vent.trigger "show:dashboard"

# ----------------------------------

module.exports = DashboardLayout
    