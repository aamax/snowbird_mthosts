getToday = ->
  getDateStr(new Date())

getDateStr = (aDate) ->
  if aDate
    curr_date = aDate.getDate()
    curr_month = aDate.getMonth() + 1;
    curr_year = aDate.getFullYear();
    return "#{curr_year}-#{curr_month}-#{curr_date}"
  else
    '---'

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
    last = undefined
    for rec in $scope.survey_data_list
      if rec.user_id == host_id
        t1 += rec.type1
        t2 += rec.type2
        last = new Date(rec.date)
    # TODO calculate needed value from totals
    {type1: padstr(t1,5), type2: padstr(t2, 5), needed: 38 - t1, last_entered: last}

  $(".survey_cal_icon").datepicker().on "changeDate", (ev) ->
    date_str = ev.date.getFullYear() + "-" + pad((ev.date.getMonth() + 1), 2) + "-" + pad(ev.date.getDate(), 2)
    $scope.current_date = date_str
    $(this).datepicker "hide"

  $scope.calculate_survey_list = () ->
    $scope.name_list.length = 0
    for host in $scope.user_list
      totals = $scope.getSurveyTotals(host.id)
      $scope.name_list.push {
        name: host.name,
        id: host.id,
        type1_total: totals.type1,
        type2_total: totals.type2,
        needed: totals.needed,
        last_entered: getDateStr(totals.last_entered)
      }

  # declare resource for host list
  $scope.survey_data_list = _surveys.query()

  $scope.refreshGrid = () ->
    $scope.calculate_survey_list()

  $scope.tmp_list = _users.query(->
    $scope.user_list = [] unless $scope.user_list
    $scope.user_list.length = 0
    for item in $scope.tmp_list
      $scope.user_list.push item
    $scope.calculate_survey_list()
    $scope.addCurrentEntries()
  )

  $scope.addCurrentEntries = () ->
    number_changes = 0
    $scope.user_list = [] unless $scope.user_list
    for host in $scope.name_list
      if host.new_value
        number_changes += 1
        new_record = {
          user_id: host.id,
          date: getToday(),
          type1: host.new_value,
        }
        new_res = _surveys.save(new_record)
        $scope.survey_data_list.push new_res
        host.new_value = undefined
    $scope.user_list.length = 0
    $scope.tmp_list = _users.query(->
      for item in $scope.tmp_list
        $scope.user_list.push item
      $scope.calculate_survey_list()
      $scope.addCurrentEntries() if number_changes > 0
    )

  $scope.surveyHeader =  () ->
    arr = []
    for survey in $scope.survey_data_list
      if arr.indexOf(survey.date.substr(0,10)) == -1
        arr.push survey.date.substr(0,10)
    arr

  $scope.surveyRecords = (host_id) ->
    hdr = $scope.surveyHeader()
    arr = []
    for i in hdr
      arr.push 0
    for survey in $scope.survey_data_list
      if survey.user_id == host_id
        idx = hdr.indexOf(survey.date.substr(0,10))
        arr[idx] += survey.type1
    arr

  $scope.openModalForUser = (host) ->
    $scope.current_host = host
    $scope.modal_hidden = false



@SurveyCtrl.$inject = ["$scope", "$resource", "$http"]

