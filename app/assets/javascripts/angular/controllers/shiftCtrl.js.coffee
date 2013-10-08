@ShiftCtrl = ($scope, $resource, shiftResource) ->
  $scope.shiftList = shiftResource.loadShifts()
  $scope.current_user = gon.current_user
  $scope.current_is_admin = gon.current_is_admin

  $scope.initializeShift = ->
    # TODO make relevant to Shift model
    shift = {short_name: '', description: '', start_time: '', end_time: '', tasks: ''}
    shift

  $scope.$on "shiftsLoaded", ->
    $scope.shiftList = shiftResource.getShifts()

  $scope.deleteShift = (s) ->
    delete_shift = confirm('Are you sure you want to delete this shift?');
    if (delete_shift)
      $scope.shift = s
      $scope.shift.$delete()

      idx = $scope.shiftList.indexOf(s)
      $scope.shiftList.splice(idx, 1)
      $scope.shift = $scope.shiftList[0]

  $scope.showShift = (s) ->
    if typeof s == 'object'
      $.each $scope.shiftList, (index, obj) ->
        if obj.id == st.id
          s = obj
    shiftResource.setCurrentShift(s)
    isShow = true
    if $scope.current_is_admin
      isShow = false
    shiftResource.setIsShowForm(isShow)
    $scope.toggleModal("edit")

  $scope.toggleModal = (action = "toggle") ->
    angular.element('#editShiftModal').modal(action)

  $scope.newShift = () ->
    if $scope.current_is_admin
      shiftResource.setCurrentShift($scope.initializeShift())
      shiftResource.setIsShowForm(false)
      $scope.toggleModal("edit")
    else
      alert('must be administrator to add new shift. Sorry!')

  $scope.$on "shiftUpdate", ->
    s = shiftResource.getCurrentShift()
    $scope.current_shift = s
    if s.id
      s.$update((data) ->
        if $scope.current_shift.id == data.id
          $scope.current_shift = data
      )
    else
      # handle new shift type
      sR = shiftResource.getNewShiftResource()
      sR.$save(s, (data) ->
        $scope.shiftList.push(data)
      )

  $scope.showDeSelectUser = (shift) ->
    shift.user_name != ''

  $scope.showSelectUser = (shift) ->
    shift.user_name == '' && shift.can_select


@ShiftCtrl.$inject = ["$scope", "$resource", "shiftResource"]