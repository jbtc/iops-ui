###
#
# AdminLTE initialization code modularized so it can be executed
# whenever the top-level dashboard is re-drawn.
#
# Usage:
# View.onShow: ()-> App.AdminLTE_lib.reset()
#
###

# ----------------------------------

class AdminLTE_lib extends Object

  @init: ()->
    $.AdminLTE = {}

    ### --------------------
    # - AdminLTE Options -
    # --------------------
    # Modify these options to suit your implementation
    ###

    $.AdminLTE.options =
      navbarMenuSlimscroll: true
      navbarMenuSlimscrollWidth: '3px'
      navbarMenuHeight: '200px'
      sidebarToggleSelector: '[data-toggle=\'offcanvas\']'
      sidebarPushMenu: true
      sidebarSlimScroll: true
      sidebarExpandOnHover: false
      enableBoxRefresh: true
      enableBSToppltip: true
      BSTooltipSelector: '[data-toggle=\'tooltip\']'
      enableFastclick: true
      enableControlSidebar: true
      controlSidebarOptions:
        toggleBtnSelector: '[data-toggle=\'control-sidebar\']'
        selector: '.control-sidebar'
        slide: true
      enableBoxWidget: true
      boxWidgetOptions:
        boxWidgetIcons:
          collapse: 'fa-minus'
          open: 'fa-plus'
          remove: 'fa-times'
        boxWidgetSelectors:
          remove: '[data-widget="remove"]'
          collapse: '[data-widget="collapse"]'
      directChat:
        enable: true
        contactToggleSelector: '[data-widget="chat-pane-toggle"]'
      colors:
        lightBlue: '#3c8dbc'
        red: '#f56954'
        green: '#00a65a'
        aqua: '#00c0ef'
        yellow: '#f39c12'
        blue: '#0073b7'
        navy: '#001F3F'
        teal: '#39CCCC'
        olive: '#3D9970'
        lime: '#01FF70'
        orange: '#FF851B'
        fuchsia: '#F012BE'
        purple: '#8E24AA'
        maroon: '#D81B60'
        black: '#222222'
        gray: '#d2d6de'
      screenSizes:
        xs: 480
        sm: 768
        md: 992
        lg: 1200

    $.AdminLTE.layout =
      activate: ->
        $.AdminLTE.layout.fix()
        $.AdminLTE.layout.fixSidebar()
        $(window, '.wrapper').resize ->
          $.AdminLTE.layout.fix()
          $.AdminLTE.layout.fixSidebar()
          
      fix: ->
        #Get window height and the wrapper height
        neg = $('.main-header').outerHeight() + $('.main-footer').outerHeight()
        window_height = $(window).height()
        sidebar_height = $('.sidebar').height()
        #Set the min-height of the content and sidebar based on the
        #the height of the document.
        if $('body').hasClass('fixed')
          $('.content-wrapper, .right-side').css 'min-height', window_height - $('.main-footer').outerHeight()
        else
          postSetWidth = undefined
          if window_height >= sidebar_height
            $('.content-wrapper, .right-side').css 'min-height', window_height - neg
            postSetWidth = window_height - neg
          else
            $('.content-wrapper, .right-side').css 'min-height', sidebar_height
            postSetWidth = sidebar_height
          #Fix for the control sidebar height
          # controlSidebar = $($.AdminLTE.options.controlSidebarOptions.selector)
          # controlSidebar.css('min-height', $(".main-sidebar").height())
          # if typeof controlSidebar != 'undefined'
          #   if controlSidebar.height() > postSetWidth
          #     $('.content-wrapper, .right-side').css 'min-height', controlSidebar.height()
      
      fixSidebar: ->
        #Make sure the body tag has the .fixed class
        if !$('body').hasClass('fixed')
          if typeof $.fn.slimScroll != 'undefined'
            $('.sidebar').slimScroll(destroy: true).height 'auto'
          return
        else if typeof $.fn.slimScroll == 'undefined' and console
          console.error 'Error: the fixed layout requires the slimscroll plugin!'
        #Enable slimscroll for fixed layout
        if $.AdminLTE.options.sidebarSlimScroll
          if typeof $.fn.slimScroll != 'undefined'
            #Destroy if it exists
            $('.sidebar').slimScroll(destroy: true).height 'auto'
            #Add slimscroll
            $('.sidebar').slimscroll
              height: $(window).height() - $('.main-header').height() + 'px'
              color: 'rgba(0,0,0,0.2)'
              size: '3px'
        
    $.AdminLTE.pushMenu =
      activate: (toggleBtn) ->
        #Get the screen sizes
        screenSizes = $.AdminLTE.options.screenSizes
        #Enable sidebar toggle
        $(toggleBtn).on 'click', (e) ->
          e.preventDefault()
          #Enable sidebar push menu
          if $(window).width() > screenSizes.sm - 1
            $('body').toggleClass 'sidebar-collapse'
          else
            if $('body').hasClass('sidebar-open')
              $('body').removeClass 'sidebar-open'
              $('body').removeClass 'sidebar-collapse'
            else
              $('body').addClass 'sidebar-open'
        
        $('.content-wrapper').click ->
          #Enable hide menu when clicking on the content-wrapper on small screens
          if $(window).width() <= screenSizes.sm - 1 and $('body').hasClass('sidebar-open')
            $('body').removeClass 'sidebar-open'
          return
        #Enable expand on hover for sidebar mini
        if $.AdminLTE.options.sidebarExpandOnHover or $('body').hasClass('fixed') and $('body').hasClass('sidebar-mini')
          @expandOnHover()
      
      expandOnHover: ->
        _this = this
        screenWidth = $.AdminLTE.options.screenSizes.sm - 1
        #Expand sidebar on hover
        $('.main-sidebar').hover (->
          if $('body').hasClass('sidebar-mini') and $('body').hasClass('sidebar-collapse') and $(window).width() > screenWidth
            _this.expand()
          return
        ), ->
          if $('body').hasClass('sidebar-mini') and $('body').hasClass('sidebar-expanded-on-hover') and $(window).width() > screenWidth
            _this.collapse()
          return
      
      expand: ->
        $('body').removeClass('sidebar-collapse').addClass 'sidebar-expanded-on-hover'
      
      collapse: ->
        if $('body').hasClass('sidebar-expanded-on-hover')
          $('body').removeClass('sidebar-expanded-on-hover').addClass 'sidebar-collapse'
      
    $.AdminLTE.tree = (menu) ->
      _this = this
      $('li a', $(menu)).on 'click', (e) ->
        #Get the clicked link and the next element
        $this = $(this)
        checkElement = $this.next()
        #Check if the next element is a menu and is visible
        if checkElement.is('.treeview-menu') and checkElement.is(':visible')
          #Close the menu
          checkElement.slideUp 'normal', ->
            checkElement.removeClass 'menu-open'
            #Fix the layout in case the sidebar stretches over the height of the window
            #_this.layout.fix()
            return
          checkElement.parent('li').removeClass 'active'
        else if checkElement.is('.treeview-menu') and !checkElement.is(':visible')
          #Get the parent menu
          parent = $this.parents('ul').first()
          #Close all open menus within the parent
          ul = parent.find('ul:visible').slideUp('normal')
          #Remove the menu-open class from the parent
          ul.removeClass 'menu-open'
          #Get the parent li
          parent_li = $this.parent('li')
          #Open the target menu and add the menu-open class
          checkElement.slideDown 'normal', ->
            #Add the class active to the parent li
            checkElement.addClass 'menu-open'
            parent.find('li.active').removeClass 'active'
            parent_li.addClass 'active'
            #Fix the layout in case the sidebar stretches over the height of the window
            _this.layout.fix()
            return
        #if this isn't a link, prevent the page from being redirected
        if checkElement.is('.treeview-menu')
          e.preventDefault()
    
    $.AdminLTE.controlSidebar =
      activate: ->
        #Get the object
        _this = this
        #Update options
        o = $.AdminLTE.options.controlSidebarOptions
        #Get the sidebar
        sidebar = $(o.selector)
        #The toggle button
        btn = $(o.toggleBtnSelector)
        #Listen to the click event
        btn.on 'click', (e) ->
          e.preventDefault()
          #If the sidebar is not open
          if !sidebar.hasClass('control-sidebar-open') and !$('body').hasClass('control-sidebar-open')
            #Open the sidebar
            _this.open sidebar, o.slide
          else
            _this.close sidebar, o.slide
          return
        #If the body has a boxed layout, fix the sidebar bg position
        bg = $('.control-sidebar-bg')
        _this._fix bg
        #If the body has a fixed layout, make the control sidebar fixed      
        if $('body').hasClass('fixed')
          _this._fixForFixed sidebar
        else
          #If the content height is less than the sidebar's height, force max height
          if $('.content-wrapper, .right-side').height() < sidebar.height()
            _this._fixForContent sidebar
      
      open: (sidebar, slide) ->
        _this = this
        #Slide over content
        if slide
          sidebar.addClass 'control-sidebar-open'
        else
          #Push the content by adding the open class to the body instead 
          #of the sidebar itself
          $('body').addClass 'control-sidebar-open'
      
      close: (sidebar, slide) ->
        if slide
          sidebar.removeClass 'control-sidebar-open'
        else
          $('body').removeClass 'control-sidebar-open'
      
      _fix: (sidebar) ->
        _this = this
        if $('body').hasClass('layout-boxed')
          sidebar.css 'position', 'absolute'
          sidebar.height $('.wrapper').height()
          $(window).resize ->
            _this._fix sidebar
            return
        else
          sidebar.css
            'position': 'fixed'
            'height': 'auto'
      
      _fixForFixed: (sidebar) ->
        sidebar.css
          'position': 'fixed'
          'max-height': '100%'
          'overflow': 'auto'
          'padding-bottom': '50px'
      
      _fixForContent: (sidebar) ->
        $('.content-wrapper, .right-side').css 'min-height', sidebar.height()
      
    $.AdminLTE.boxWidget =
      selectors: $.AdminLTE.options.boxWidgetOptions.boxWidgetSelectors
      icons: $.AdminLTE.options.boxWidgetOptions.boxWidgetIcons
      activate: ->
        _this = this
        #Listen for collapse event triggers
        $(_this.selectors.collapse).on 'click', (e) ->
          e.preventDefault()
          _this.collapse $(this)
          return
        #Listen for remove event triggers
        $(_this.selectors.remove).on 'click', (e) ->
          e.preventDefault()
          _this.remove $(this)
          return
      
      collapse: (element) ->
        _this = this
        #Find the box parent
        box = element.parents('.box').first()
        #Find the body and the footer
        box_content = box.find('.box-body, .box-footer')
        if !box.hasClass('collapsed-box')
          #Convert minus into plus
          element.children(':first').removeClass(_this.icons.collapse).addClass _this.icons.open
          #Hide the content
          box_content.slideUp 300, ->
            box.addClass 'collapsed-box'
            return
        else
          #Convert plus into minus
          element.children(':first').removeClass(_this.icons.open).addClass _this.icons.collapse
          #Show the content
          box_content.slideDown 300, ->
            box.removeClass 'collapsed-box'
            return
      
      remove: (element) ->
        #Find the box parent
        box = element.parents('.box').first()
        box.slideUp()


    # $ extension
    $.fn.boxRefresh = (options) ->
      # Render options
      settings = $.extend({
        trigger: '.refresh-btn'
        source: ''
        onLoadStart: (box) ->
        onLoadDone: (box) ->

      }, options)
      #The overlay
      overlay = $('<div class="overlay"><div class="fa fa-refresh fa-spin"></div></div>')

      start = (box) ->
        #Add overlay and loading img
        box.append overlay
        settings.onLoadStart.call box
        return

      done = (box) ->
        #Remove overlay and loading img
        box.find(overlay).remove()
        settings.onLoadDone.call box
        return

      @each ->
        #if a source is specified
        if settings.source == ''
          if console
            console.log 'Please specify a source first - boxRefresh()'
          return
        #the box
        box = $(this)
        #the button
        rBtn = box.find(settings.trigger).first()
        #On trigger click
        rBtn.on 'click', (e) ->
          e.preventDefault()
          #Add loading overlay
          start box
          #Perform ajax call
          box.find('.box-body').load settings.source, ->
            done box
 
    $.fn.todolist = (options) ->
      # Render options
      settings = $.extend({
        onCheck: (ele) ->
        onUncheck: (ele) ->

      }, options)
      @each ->
        if typeof $.fn.iCheck != 'undefined'
          $('input', this).on 'ifChecked', (event) ->
            ele = $(this).parents('li').first()
            ele.toggleClass 'done'
            settings.onCheck.call ele
            return
          $('input', this).on 'ifUnchecked', (event) ->
            ele = $(this).parents('li').first()
            ele.toggleClass 'done'
            settings.onUncheck.call ele
            return
        else
          $('input', this).on 'change', (event) ->
            ele = $(this).parents('li').first()
            ele.toggleClass 'done'
            settings.onCheck.call ele
            return
        return

  @reset = ()->
    @init()
    
    #Extend options if external options exist
    if typeof AdminLTEOptions != 'undefined'
      $.extend true, $.AdminLTE.options, AdminLTEOptions
    #Easy access to options
    o = $.AdminLTE.options
    #Set up the object
    #Activate the layout maker
    $.AdminLTE.layout.activate()
    #Enable sidebar tree view controls
    $.AdminLTE.tree '.sidebar'
    #Enable control sidebar
    if o.enableControlSidebar
      $.AdminLTE.controlSidebar.activate()
    #Add slimscroll to navbar dropdown
    if o.navbarMenuSlimscroll and typeof $.fn.slimscroll != 'undefined'
      $('.navbar .menu').slimscroll(
        height: o.navbarMenuHeight
        alwaysVisible: false
        size: o.navbarMenuSlimscrollWidth).css 'width', '100%'
    #Activate sidebar push menu
    if o.sidebarPushMenu
      $.AdminLTE.pushMenu.activate o.sidebarToggleSelector
    #Activate Bootstrap tooltip
    if o.enableBSToppltip
      $('body').tooltip selector: o.BSTooltipSelector
    #Activate box widget
    if o.enableBoxWidget
      $.AdminLTE.boxWidget.activate()
    #Activate fast click
    if o.enableFastclick and typeof FastClick != 'undefined'
      FastClick.attach document.body
    #Activate direct chat widget
    if o.directChat.enable
      $(o.directChat.contactToggleSelector).on 'click', ->
        box = $(this).parents('.direct-chat').first()
        box.toggleClass 'direct-chat-contacts-open'
        return

    $('.btn-group[data-toggle="btn-toggle"]').each ->
      group = $(this)
      $(this).find('.btn').on 'click', (e) ->
        group.find('.btn.active').removeClass 'active'
        $(this).addClass 'active'
        e.preventDefault()

# ----------------------------------

module.exports = AdminLTE_lib
