angular.module("UserServices", []).factory "userResource", ($resource, $rootScope, $http, md5) ->
  _loadedHosts    = []
  _currUser = undefined
  _isShowForm = true
  _hosts = $resource('/users/:id', {id: '@id'}, {update: {method: 'put'}})

  loadUsers: ->
    _loadedHosts = _hosts.query( ->
      $rootScope.$broadcast "usersLoaded"
    )

  getUsers: ->
    _loadedHosts.slice()

  gravatar_path: (user, size, rating, defaultUrl) ->
    user = {email: 'foo@example.com'}
    if user == undefined
      'http://www.gravatar.com/avatar/' + md5.createHash(user.email.toLowerCase()) +  "?s=" + size + "&r=" + rating + "&d=" + defaultUrl  if user.email

  getCurrentUser: ->
    _currUser

  setCurrentUser: (user) ->
    _currUser = user

  getIsShowForm: ->
    _isShowForm

  setIsShowForm: (value) ->
    _isShowForm = value

  saveNewUser: (usr) ->
    u = _hosts.save(usr, ->
      _loadedHosts.push(u)
    )
    u

  getUserResource: ->
    _hosts

angular.module("ShiftTypeServices", []).factory "shiftTypeResource", ($resource, $rootScope) ->
  _loadedShiftTypes    = []
  _currShiftType = undefined
  _isShowForm = true
  _shiftTypes = $resource('/shift_types/:id', {id: '@id'}, {update: {method: 'put'}})

  loadShiftTypes: ->
    _loadedShiftTypes = _shiftTypes.query( ->
      $rootScope.$broadcast "shiftTypesLoaded"
    )

  getShiftTypes: ->
    _loadedShiftTypes.slice()

  getIsShowForm: ->
    _isShowForm

  setIsShowForm: (value) ->
    _isShowForm = value

  getCurrentShiftType: ->
    _currShiftType

  setCurrentShiftType: (st) ->
    _currShiftType = st

  getNewShiftTypeResource: ->
    str = new _shiftTypes()
    str

angular.module("ShiftServices", []).factory "shiftResource", ($resource, $rootScope) ->
  _loadedShifts    = []
  _currShift = undefined
  _isShowForm = true
  _shifts = $resource('/shifts/:id', {id: '@id'}, {update: {method: 'put'} })

  loadShifts: ->
    _loadedShifts = _shifts.query( ->
      $rootScope.$broadcast "shiftsLoaded"
    )

  getShifts: ->
    _loadedShifts.slice()

  getIsShowForm: ->
    _isShowForm

  setIsShowForm: (value) ->
    _isShowForm = value

  getCurrentShift: ->
    _currShift

  setCurrentShift: (s) ->
    _currShift = s

  getNewShiftResource: ->
    sr = new _shifts()
    sr

angular.module("mthosts", ["ngResource",
                        "ng-rails-csrf",
                        "UserServices",
                        'md5',
                        'ui-gravatar',
                        "ShiftTypeServices",
                        'ShiftServices'])

.controller("ShiftTypeCtrl", ["$scope", "$resource", "shiftTypeResource", ShiftTypeCtrl])
.controller("ShiftTypeModalCtrl", ["$scope", "$resource", "shiftTypeResource", ShiftTypeModalCtrl])
.controller("SurveyCtrl", ["$scope", "$resource", "$http", SurveyCtrl])
.controller("ShiftBuilderCtrl", ["$scope", ShiftBuilderCtrl])

ShiftTypeCtrl.$inject = ["$scope", "$resource", "shiftTypeResource"]
ShiftTypeModalCtrl.$inject = ["$scope", "$resource", "shiftTypeResource"]
SurveyCtrl.$inject = ["$scope", "$resource", "$http"]
ShiftBuilderCtrl.$inject = ["$scope"]


