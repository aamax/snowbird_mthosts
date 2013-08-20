@UserCtrl = ($scope, $resource, userResource, md5) ->
  userResource.loadUsers() if userResource.getUsers().length == 0
  $scope.current_user = gon.current_user

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


  $scope.gravatar_path = (user, size, rating, defaultUrl) ->
    userResource.gravatar_path(user,size,rating,defaultUrl)

  $scope.showUser = (user) ->
    if typeof user == 'object'
      $.each $scope.hostList, (index, obj) ->
        if obj.id == user.id
          user = obj

    userResource.setCurrentUser(user)
    isShow = true
    if $scope.current_is_admin || ($scope.current_user.id == user.id)
      isShow = false
    userResource.setIsShowForm(isShow)
    $scope.toggleModal("show")

  $scope.newUser = () ->
    if $scope.current_is_admin()
      userResource.setCurrentUser({})
      userResource.setIsShowForm(false)
      $scope.toggleModal("show")
    else
      alert('must be administrator to add new users. Sorry!')

  $scope.toggleModal = (action = "toggle") ->
    angular.element('#editUserModal').modal(action)

  $scope.$on "userUpdate", ->
    u = userResource.getCurrentUser()
    if u.id
      u.$update((data) ->
        if $scope.current_user.id == data.id
          $scope.current_user = data
      )
    else
      u.$save()   # TODO need to create new resource object ???

  $scope.updateLocalUser = (id, userData) ->
    $.each $scope.hostList, (index, obj) ->
      if obj.id == id
        obj = userData

#    user_resource = undefined
#    $.each $scope.hostList, (index, obj) ->
#      if obj.id == $scope.user.id
#        user_resource = obj
#        false
#
#    if user_resource != undefined
#      user_resource.$update()
#    else
#      # TODO need to create new resource to save with user values
#      $scope.user.$save()

#  $scope.updateDataset = (ds) ->
#    ds.$update(->
#      dimResource.changeDataset($scope.ds.id)
#    , (data) ->
#      alert("Error caught while updating dataset:\n" + data.status + " - " + data.data.errors.name[0])
#      $scope.toggleModal($scope.ds, 'show')
#    )


  $scope.deleteUser = (user) ->
    $scope.user = user
    $scope.user.$delete()
    $scope.hostList.splice(user, 1)

  $scope.isCurrent = (user) ->
    $scope.current_user.id == user.id

#  $scope.admin_or_self = ->
#    $scope.user.is_current_user

#  $scope.gravatar_path = (value, size, rating, default_value) ->
#    if (value isnt null) and (value isnt `undefined`) and (value isnt "") and (null isnt value.match(/.*@.*\..{2}/))
#
#      # convert the value to lower case and then to a md5 hash
#      hash = md5.createHash($scope.email.toLowerCase())
#
#      # parse the size attribute
#      size = attrs.size
#
#      # default to 40 pixels if not set
#      size = 40  if (size is null) or (size is `undefined`) or (size is "")
#
#      # parse the ratings attribute
#      rating = attrs.rating
#
#      # default to pg if not set
#      rating = "pg"  if (rating is null) or (rating is `undefined`) or (rating is "")
#
#      # parse the default image url
#      defaultUrl = attrs.default_value;
#      defaultUrl = "404"  if (defaultUrl is null) or (defaultUrl is `undefined`) or (defaultUrl is "")
#
#      # construct the tag to insert into the element
#      tag = "http://www.gravatar.com/avatar/" + hash + "?s=" + size + "&r=" + rating + "&d=" + defaultUrl + "\" >"
#
#      tag


