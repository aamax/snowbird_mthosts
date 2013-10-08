@ShiftTypeModalCtrl = ($scope, $resource, shiftTypeResource) ->
  $scope.shiftType = shiftTypeResource.getCurrentShiftType()
  $scope.showForm = true

  $scope.setupShiftType = () ->
    $scope.shiftType = shiftTypeResource.getCurrentShiftType()
    $scope.showForm = shiftTypeResource.getIsShowForm()
    ""

  $scope.dismiss = (flag) ->
    if flag == 'cancel'
      $scope.toggleModal('hide')
    else
      shiftTypeResource.setCurrentShiftType($scope.shiftType)
      $scope.$parent.$broadcast "shiftTypeUpdate"
      $scope.toggleModal('hide')

@ShiftTypeModalCtrl.inject = ["$scope", "$resource", "shiftTypeResource"]