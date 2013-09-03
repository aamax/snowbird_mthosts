angular.module("ShiftServices", []).factory "shiftResource", ($resource, $rootScope) ->
  _loadedShifts    = []
  _currShift = undefined
  _isShowForm = true
  _shifts = $resource('/shifts/:id:format', {id: '@id'}, {update: {method: 'put'}, destroy: {method: 'post'}}, format: 'json')

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