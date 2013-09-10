@UserCtrl = ($scope, $resource, $window, userResource) ->
  userResource.loadUsers() if userResource.getUsers().length == 0
  $scope.current_user = gon.current_user

  $scope.initializeUser = ->
    user = {name: '', nickname: '', street: '', city: '', zip: '', id: undefined, home_phone: '',
    cell_phone: '', email: '', alt_email: '', active_user: '', confirmed: '', notes: '', start_year: '',
    password: '', password_confirmation: ''}
    user

  $scope.current_is_admin = ->
    return false if $scope.hostList == undefined
    arr = []
    $.each $scope.hostList, (index, obj) ->
      if obj.id == $scope.current_user.id
        arr = [obj]
        false
    arr[0].is_admin if arr.length > 0

  $scope.$on "usersLoaded", ->
    $scope.hostList = userResource.getUsers()
    $scope.hostIndexList = []
    $.each $scope.hostList, (index, obj) ->
      if obj.id != $scope.current_user.id
        $scope.hostIndexList.push obj

  $scope.$on "userUpdate", ->
    u = userResource.getCurrentUser()
    if u.id
      u.$update((data) ->
        if $scope.current_user.id == data.id
          $scope.current_user = data
      )
    else
      u_res = $resource('/users/save_new')
      #u_res = $resource('/users/:id', {id: '@id'}, {update: {method: 'put'}})
      usr = new u_res(u)
      usr.$save((data) ->
        res = userResource.getUserResource()
        u = res.get({id: usr.id}, ->
          $scope.hostList.push(u)
          $scope.hostIndexList.push(u)
        )
      , (data) ->
        err_str = JSON.stringify(data.data.errors)
        alert("Error " + data.status + " - " + err_str)
      )

  $scope.gravatar_path = (user, size, rating, defaultUrl) ->
    userResource.gravatar_path(user,size,rating,defaultUrl)

  $scope.showUser = (user) ->
    if typeof user == 'object'
      $.each $scope.hostList, (index, obj) ->
        if obj.id == user.id
          user = obj
#    userResource.setCurrentUser(user)
#    isShow = true
#    if $scope.current_is_admin() || ($scope.current_user.id == user.id)
#      isShow = false
#    userResource.setIsShowForm(isShow)
#    $scope.toggleModal("show")
    $window.location = "/users/#{user.id}"

  $scope.newUser = () ->
    if $scope.current_is_admin()
      userResource.setCurrentUser($scope.initializeUser())
      userResource.setIsShowForm(false)
      $scope.toggleModal("show")
    else
      alert('must be administrator to add new users. Sorry!')

  $scope.toggleModal = (action = "toggle") ->
    angular.element('#editUserModal').modal(action)

  $scope.updateLocalUser = (id, userData) ->
    $.each $scope.hostList, (index, obj) ->
      if obj.id == id
        obj = userData

  $scope.deleteUser = (user) ->
    $scope.user = user
    $scope.user.$delete()
    $scope.hostList.splice(user, 1)
    $scope.hostIndexList.splice(user, 1)
    $scope.user = $scope.hostList[0]

  $scope.isCurrent = (user) ->
    $scope.current_user.id == user.id


