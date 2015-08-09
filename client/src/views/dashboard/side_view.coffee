Marionette = require('marionette')

# ----------------------------------

class DashboardSideView extends Marionette.ItemView
  template: "dashboard/side"
  tagName: "aside"
  className: "main-sidebar"
  ui:
  	avatar: '#avatar'
  	fullname: '#fullname'
  	dashboard_list: '#dashboard-list'

  events:
  	'click #dashboard-list' : 'show_dash'

  show_dash: (e)->
  	tgt = $(e.target)
  	dlink = tgt.closest('.dashboard-link')
  	return null if !dlink? or dlink.length == 0
  	for d in @collection.models
  		if dlink.hasClass("d_#{d.id}")
  			$('li',@ui.dashboard_list).removeClass('active')
  			dlink.addClass('active')
  			App.controller.dashboard(d)
  			break
  	@

  onDomRefresh: ()->
  	if App.current_user? && App.current_user.avatar? 
  		@ui.avatar.attr('src', App.current_user.avatar)

  	$('li.dashboard-link', @ui.dashboard_list).remove()
  	for d in @collection.models
  		dl = $("<li class='dashboard-link d_#{d.id}'><a href='#'><i class='fa fa-th-large'></i> <span>#{d.get('title')}</span></a></li>")
  		@ui.dashboard_list.append(dl)

# ----------------------------------

module.exports = DashboardSideView

