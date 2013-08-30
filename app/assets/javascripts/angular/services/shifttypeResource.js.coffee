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