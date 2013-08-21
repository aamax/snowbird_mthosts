angular.module("mthosts", ["ngResource",
                        "ng-rails-csrf",
                        "UserServices",
                        'md5',
                        'ui-gravatar'])

angular.module("UserServices", []).factory "userResource", ($resource, $rootScope, $http, md5) ->
  _loadedHosts    = []
  _currUser = undefined
  _isShowForm = true
  _hosts = $resource('/users/:id', {id: '@id'}, {update: {method: 'put'}})

  loadUsers: ->
    _loadedHosts = _hosts.query( ->
      $rootScope.$broadcast "usersLoaded"
    )

  getUsers: ->
    _loadedHosts.slice()

  gravatar_path: (user, size, rating, defaultUrl) ->
    user = {email: 'foo@example.com'} if user == undefined
    'http://www.gravatar.com/avatar/' + md5.createHash(user.email.toLowerCase()) +  "?s=" + size + "&r=" + rating + "&d=" + defaultUrl  if user.email

  getCurrentUser: ->
    _currUser

  setCurrentUser: (user) ->
    _currUser = user

  getIsShowForm: ->
    _isShowForm

  setIsShowForm: (value) ->
    _isShowForm = value

  saveNewUser: (usr) ->
    u = _hosts.save(usr, ->
      _loadedHosts.push(u)
    )
    u

  getUserResource: ->
    _hosts