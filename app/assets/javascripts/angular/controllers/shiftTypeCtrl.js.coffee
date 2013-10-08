@ShiftTypeCtrl = ($scope, $resource, shiftTypeResource) ->
  shiftTypeList = shiftTypeResource.loadShiftTypes()
  $scope.current_user = gon.current_user
  $scope.current_is_admin = gon.current_is_admin

  $scope.initializeShiftType = ->
    shiftType = {short_name: '', description: '', start_time: '', end_time: '', tasks: ''}
    shiftType

  $scope.$on "shiftTypesLoaded", ->
    $scope.shiftTypeList = shiftTypeResource.getShiftTypes()

  $scope.deleteShiftType = (st) ->
    $scope.shiftType = st
    $scope.shiftType.$delete()

    idx = $scope.shiftTypeList.indexOf(st)
    $scope.shiftTypeList.splice(idx, 1)
    $scope.shiftType = $scope.shiftTypeList[0]

  $scope.showShiftType = (st) ->
    if typeof st == 'object'
      $.each $scope.shiftTypeList, (index, obj) ->
        if obj.id == st.id
          st = obj
    shiftTypeResource.setCurrentShiftType(st)
    isShow = true
    if $scope.current_is_admin
      isShow = false
    shiftTypeResource.setIsShowForm(isShow)
    $scope.toggleModal("edit")

  $scope.toggleModal = (action = "toggle") ->
    angular.element('#editShiftTypeModal').modal(action)

  $scope.newShiftType = () ->
    if $scope.current_is_admin
      shiftTypeResource.setCurrentShiftType($scope.initializeShiftType())
      shiftTypeResource.setIsShowForm(false)
      $scope.toggleModal("edit")
    else
      alert('must be administrator to add new shift type. Sorry!')

  $scope.$on "shiftTypeUpdate", ->
    st = shiftTypeResource.getCurrentShiftType()
    $scope.current_shift_type = st
    if st.id
      st.$update((data) ->
        if $scope.current_shift_type.id == data.id
          $scope.current_shift_type = data
      )
    else
      # handle new shift type
      stR = shiftTypeResource.getNewShiftTypeResource()
      stR.$save(st, (data) ->
        $scope.shiftTypeList.push(data)
      )

@ShiftTypeCtrl.inject = ["$scope", "$resource", "shiftTypeResource"]