getToday = ->
  current_date = new Date()
  day = current_date.getDate()
  month = current_date.getMonth() + 1
  year = current_date.getFullYear()
  "#{year}-#{month}-#{day}"

@SurveyCtrl = ($scope, $resource, $http) ->
  $scope.current_date = getToday()

  _users = $resource('/get_survey_users/:id', {id: '@id'}, {update: {method: 'put'} })

  # declare resource for host list
  $scope.host_list = _users.query()




@SurveyCtrl.$inject = ["$scope", "$resource", "$http"]