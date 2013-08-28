@ShiftModalCtrl = ($scope, $resource, shiftResource) ->
  $scope.shift = shiftResource.getCurrentShift()
  $scope.showForm = true

  $scope.setupShift = () ->
    $scope.shift = shiftResource.getCurrentShift()
    $scope.showForm = shiftResource.getIsShowForm()
    ""

  $scope.dismiss = (flag) ->
    if flag == 'cancel'
      $scope.toggleModal('hide')
    else
      shiftResource.setCurrentShift($scope.shift)
      $scope.$parent.$broadcast "shiftUpdate"
      $scope.toggleModal('hide')