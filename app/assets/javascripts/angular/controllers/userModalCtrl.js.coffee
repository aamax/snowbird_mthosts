@UserModalCtrl = ($scope, $resource, userResource, md5) ->
  $scope.user = userResource.getCurrentUser()
  if (($scope.user == undefined) && (window.location.pathname != '/users'))
    userResource.setCurrentUser(gon.user_to_show)
    angular.element('#editUserModal').modal('edit')
    $scope.is_direct_access = true
    userResource.setIsShowForm(false)
  else
    $scope.is_direct_access = false

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

#  $scope.toggleModal = (action = "toggle") ->
#    angular.element('#editUserModal').modal(action)
#    if ($scope.is_direct_access == true)
#      if (document.referrer.replace(document.location.origin, '') == '/users')
#        self.location = '/users.html'
#      else
#      history.go(-1)

@UserModalCtrl.inject = ["$scope", "$resource", "userResource", "md5"]
