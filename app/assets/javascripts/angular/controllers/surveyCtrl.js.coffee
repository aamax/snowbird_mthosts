getToday = ->
  current_date = new Date()
  day = current_date.getDate()
  month = current_date.getMonth() + 1
  year = current_date.getFullYear()
  "#{year}-#{month}-#{day}"

item_in_array = (test_item, test_array) ->
  for item in test_array
    return true if test_item.id == item.id
  false

pad = (number, length) ->
  str = "" + number
  str = "0" + str  while str.length < length
  str

padstr = (value, length) ->
  str = "" + value
  str = " " + str  while str.length < length
  str



@SurveyCtrl = ($scope, $resource, $http) ->
  $scope.current_date = getToday()
  $scope.survey_data_list = []
  $scope.name_list = []
  $scope.current_host = undefined
  $scope.modal_hidden = true

  _users = $resource('/get_survey_users/:id', {id: '@id'}, {update: {method: 'put'} })
  _surveys = $resource('/surveys/:id', {id: '@id'}, {update: {method: 'put'} })

  $scope.getSurveyTotals = (host_id) ->
    t1 = 0
    t2 = 0
    for rec in $scope.survey_data_list
      if rec.user_id == host_id
        t1 += rec.type1
        t2 += rec.type2
    # TODO calculate needed value from totals
    {type1: padstr(t1,5), type2: padstr(t2, 5), needed: "smiles"}

  $(".survey_cal_icon").datepicker().on "changeDate", (ev) ->
    date_str = ev.date.getFullYear() + "-" + pad((ev.date.getMonth() + 1), 2) + "-" + pad(ev.date.getDate(), 2)
    $scope.current_date = date_str
    $(this).datepicker "hide"

  $scope.calculate_survey_list = () ->
    $scope.name_list = []
    for host in $scope.user_list
      totals = $scope.getSurveyTotals(host.id)
      $scope.name_list.push {name: host.name, id: host.id, type1_total: totals.type1, type2_total: totals.type2, needed: totals.needed}

  # declare resource for host list
  $scope.survey_data_list = _surveys.query()

  $scope.user_list = _users.query(->
    $scope.calculate_survey_list()
  )

  $scope.addSurveyRecord = () ->
    new_record = {user_id: $scope.current_host.id, date: $scope.current_date, type1: $scope.type_1_value, type2: $scope.type_2_value}
    new_res = _surveys.save(new_record)
    $scope.survey_data_list.push new_res
    $scope.user_list = _users.query(->
      $scope.calculate_survey_list()
    )

  $scope.openModalForUser = (host) ->
    $scope.current_host = host
    $scope.modal_hidden = false



@SurveyCtrl.$inject = ["$scope", "$resource", "$http"]