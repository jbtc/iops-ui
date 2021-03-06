Marionette = require('marionette')
WidgetView = require('../dashboard/widget_view')

# ----------------------------------
class UrlWidgetView extends WidgetView
  template:   "widgets/url_widget"
  classID: 'url_widget'
  className: 'widget-outer box box-primary url_widget'
  ui:
    iframe: 'iframe#iframe'
    title: 'input#title'
    url: 'input#url'
    wtitle: "h3.box-title"

  @layout:
    sx: 4
    sy: 10

  IsUpdatingSettings: false
  IsPageLoading: true

  update: ()->
    # Ignore all calls except those from startup and Update
    if !@IsUpdatingSettings && !@IsPageLoading
      return null

    @IsPageLoading = false
    @IsUpdatingSettings = false

    s = @model.get("settings")
    @ui.iframe.attr("src", s.url)
    @ui.wtitle.html("#{s.name}")

  set_model: ()=>
    @IsUpdatingSettings = true

    s = _.clone(@model.get("settings"))
    url = @ui.url.val().trim()
    if url.indexOf("http://") == -1 && url.indexOf("https://") == -1
      url = "http://#{url}"
    s.url = url
    s.name = @ui.title.val()
    @model.set("settings", s)

  toggle_settings: (e)->
    super(e)
    @ui.iframe.toggle(!@settings_visible)

  onShow: ()->
    @ui.title.on "change", ()=>@set_model()
    @ui.url.on "change", ()=>@set_model()
    url = @model.get("settings").url
    if !url? || url == ''
      @toggle_settings()

  start:()->
    @update()
    
# ----------------------------------

window.UrlWidgetView = UrlWidgetView
module.exports = UrlWidgetView
