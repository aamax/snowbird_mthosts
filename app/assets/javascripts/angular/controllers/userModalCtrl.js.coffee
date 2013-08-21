@UserModalCtrl = ($scope, $resource, userResource, md5) ->
  $scope.user = userResource.getCurrentUser()
  $scope.showForm = true

  $scope.setupUser = () ->
    $scope.user = userResource.getCurrentUser()
    if $scope.user
      $scope.user.password = ''
      $scope.user.password_confirmation = ''
    $scope.showForm = userResource.getIsShowForm()
    ""

  $scope.gravatar_path = (user, size, rating, defaultUrl) ->
    userResource.gravatar_path($scope.user,size,rating,defaultUrl)

  $scope.isFormDirty = (user) ->
    if user != undefined
      (ds.definition != $scope.ds_backup.definition) || (ds.name != $scope.ds_backup.name) || (ds.id != $scope.ds_backup.id)

  $scope.dismiss = (flag) ->
    if flag == 'cancel'
      $scope.toggleModal('hide')
    else
      if $scope.password != $scope.password_confirmation
        alert('password and confirmation does not match')
      else
        if $scope.password != ''
          $scope.user.password = $scope.password
        userResource.setCurrentUser($scope.user)
        $scope.$parent.$broadcast "userUpdate"
        $scope.toggleModal('hide')