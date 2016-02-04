Marionette = require('marionette')
BaselineApp = require('./common/baseline_app')
Extensions = require('./common/extensions')
AppController = require('./app_controller')
Router = require('./router')
AppLayout = require('./views/app_layout')
Session = require('./models/session')
AdminLTE_lib = require('./common/adminlte_lib')
UIUtils = require('./common/uiutils')
OPCManager = require('./opcmanager')
AccountCollection = require('./models/account_collection')
SiteCollection = require('./models/site_collection')
ClaimCollection = require('./models/claim_collection')
RoleCollection = require('./models/role_collection')
UserCollection = require('./models/user_collection')
AppConfig = require('./common/appconfig')
# forces inclusion of core widget classes
require('./views/widgets/alarm_widget_view')
require('./views/widgets/pbb_widget_view')
require('./views/widgets/pca_widget_view')
require('./views/widgets/url_widget_view')
require('./views/widgets/weather_widget_view')

# ----------------------------------
window.App = do()->
  return window.App if window.App?

  App = window.App = new BaselineApp()
  App.AdminLTE_lib = AdminLTE_lib
  
  Object.defineProperty App, 'current_user',
    get: ()->
      if App.session? then App.session else null

  App.config = AppConfig

  App.on "before:start", (options)->
    @log('Starting')
    $('#loading_cover').fadeTo(0,0.8)
    Session.restore()
    @layout = new AppLayout()
    @uiutils = UIUtils

    ### 
      TODO: load from server - all known Accounts, claims, Roles
    ###
    #App.accounts = new AccountCollection(App.store.get('accounts'))

    App.refresh_accounts()

    #App.claims = new ClaimCollection(App.store.get('claims'))

    #App.roles = new RoleCollection(App.store.get('roles'))
    
    #App.users = new UserCollection(App.store.get('users'))
    ###
      END TODO:
    ###

    App.vent.on "user:update", ()->
      Session.save_session()

    App.vent.on "app:update", ()->
      return null if !App.accounts?
      accounts = App.accounts.toJSON()
      for acc, idx in accounts
        aacc = App.accounts.models[idx]
        acc.sites = aacc.sites.toJSON()
      
    # setup app clock
    @log('Setting system clock')
    dtfn = ()->
      App.time = new Date()
      App.vent.trigger 'app:clock', App.time
      App.vent.trigger 'check:timeout'
      App.time

    App.clock = setInterval(dtfn, 5000)

    # check user session timestamp for auto purging sessions
    App.check_session = ()->
      sto = App.config.session_timeout
      return true if !App.session? || !sto? || sto <= 0
      timeout = false
      ts = App.store.get('user_ts')
      if !ts? 
        ts = new Date()
        App.store.set('user_ts', ts)
      else
        ts = new Date(ts)
      tsn = new Date()
      if ((tsn - ts)/1000) > (sto * 60)
        App.controller.logout()
        return false
      true

    # check session_timeout to kick user
    App.vent.on 'check:timeout', App.check_session

  App.on 'start', (options)->
    @log('Started')
    if (Backbone.history) 
      App.vent.on "app:resources_loaded", ()=>
        # ensure this only fires once
        App.vent.off "app:resources_loaded"
        # connect OPC
        @log('Initializing OPCManager')
        App.opc = OPCManager
        App.opc.init(App)
        # make app available to UI
        $('#loading_cover').fadeOut(100, ()-> $(@).hide())
        # set up routing and controller
        @controller = new AppController()
        @router = new Router
          controller: @controller
        @log('Backbone.history starting')
        Backbone.history.start()

    # new up and views and render for base app here...
    @log('Done starting and running!')

  App.refresh_accounts = (cb)->
    App.accounts = new AccountCollection()    
    App.accounts.fetch
      success:((cb) =>
        (data, xhr)=>
          cnt = App.accounts.models.length
          completed = 0
          for acct in App.accounts.models
            acct.sites.fetch
              success:((cb, cnt, completed) =>
                (data, xhr)=>
                  completed++
                  if completed == cnt
                    App.vent.trigger "app:resources_loaded"
                    App.vent.trigger "app:update"
                    if cb? then cb()
                )(cb, cnt, completed)
        )(cb)


  App.refresh_claims = (cb)->
    App.refresh_accounts ()->
      # pull global claims
      # iterate thru sites and pull claims


  App.save_user = ()->
    App.vent.trigger("user:update")
    
  App.flush = ()->
    App.store.remove("user_ts")
    App.store.remove("session")
    App.session = null
    App.accounts = null
    #App.store.remove("claims")
    #App.store.remove("roles")
    #App.store.remove("users")
    App.router.navigate('login', {trigger:true})

  App




