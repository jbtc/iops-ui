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
ClaimCollection = require('./models/claim_collection')
RoleCollection = require('./models/role_collection')
UserCollection = require('./models/user_collection')

# ----------------------------------
window.App = do()->
  return window.App if window.App?

  App = window.App = new BaselineApp()
  App.AdminLTE_lib = AdminLTE_lib
  
  Object.defineProperty App, 'current_user',
    get: ()->
      if App.session? and App.session.user? then App.session.user else null

  App.on "before:start", (options)->
    @log('Starting')
    Session.restore()
    @layout = new AppLayout()
    @uiutils = UIUtils

    ### 
      TODO: load from server - all known Accounts, claims, Roles
    ###
    App.accounts = new AccountCollection(App.store.get('accounts'))
    if !App.accounts? || App.accounts.models.length == 0
      App.accounts = new AccountCollection [
        id: 1
        name : "Example Corporation, International"
        isActive: true
        sites: [
          id: 1
          name: "The Eastern Iowa Airport"
          abbrev: "CID"
          shortName: "Cedar Rapids"
          opc: 'http://opc.iopsnow.com:58725'
        ,
          id: 2
          name: 'Open Automation Systems'
          abbrev: "OAS"
          shortName: "OPCSystems.NET"
          opc: 'http://www.opcsystems.com:58725'
        ]
      ]
    App.claims = new ClaimCollection(App.store.get('claims'))
    App.roles = new RoleCollection(App.store.get('roles'))
    App.users = new UserCollection(App.store.get('users'))
    ###
      END TODO:
    ###

    # connect OPCManager
    @log('Initializing OPCManager')
    App.opc = OPCManager
    App.opc.init(App)

    # REMOVE WHEN API IS CONNECTED - persist objects locally until db is connected
    App.vent.on "user:update", ()->
      App.store.set("user", App.current_user)
    App.vent.on "app:update", ()->
      accounts = App.accounts.toJSON()
      for acc, idx in accounts
        aacc = App.accounts.models[idx]
        acc.sites = aacc.sites.toJSON()
      App.store.set("accounts", accounts)
      App.store.set("claims", App.claims)
      App.store.set("roles", App.roles)
      nuc = new UserCollection()
      for u in App.users.models
        if u.id? && u.id > 0 then nuc.add(u)
      App.users = nuc
      App.store.set("users", App.users)

    # setup app clock
    @log('Setting system clock')
    dtfn = ()->
      App.time = new Date()
      App.vent.trigger 'app:clock', App.time
      App.time

    App.clock = setInterval(dtfn, 5000)


  App.on 'start', (options)->
    @log('Started')
    if (Backbone.history) 
      @controller = new AppController()
      @router = new Router
        controller: @controller
      @log('Backbone.history starting')
      Backbone.history.start()

    # new up and views and render for base app here...
    @log('Done starting and running!')

  App.flush = ()->
    App.store.remove("user")
    App.store.remove("session")
    App.store.remove("claims")
    App.store.remove("roles")
    App.store.remove("users")
    App.router.navigate('login', {trigger:true})

  App




