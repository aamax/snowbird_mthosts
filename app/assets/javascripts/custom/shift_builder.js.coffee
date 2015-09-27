# move selected shifts to confirm page

# move selected shifts to confirm page

# move shifts to select box

# move shifts from select box

# clear shifts from select box

# hide multi date elements

# hide single date elements
setupShiftBuilderDatePicker = ->

  # date picker code
  $ ->
    $(".cal_icon_start").datepicker().on "changeDate", (ev) ->
      date_str = convert_date_to_str(ev.date)
      if $("#type_Multiple_Dates").attr("checked") is "checked"
        unless $("input#end_date").val() is ""
          if date_str > $(".cal_icon_end").datepicker().data().date
            alert "Cannot set the start date after the end date"
            return
      $("input#start_date").val date_str
      $(this).datepicker "hide"


  $ ->
    $(".cal_icon_end").datepicker().on "changeDate", (ev) ->
      date_str = convert_date_to_str(ev.date)
      if $("#type_Multiple_Dates").attr("checked") is "checked"
        unless $("input#start_date").val() is ""
          if date_str < $(".cal_icon_start").datepicker().data().date
            alert "Cannot set the end date before the start date"
            return
      $("input#end_date").val date_str
      $(this).datepicker "hide"


update_display = ->
  page = $("#current_page").val()
  hide_all_pages()

  # show current page
  $("#" + page).show()

  # if no date radio selected, select single date
  $("#type_Single_Date").attr "checked", "checked"  if ($("#type_Multiple_Dates").attr("checked") is `undefined`) and ($("#type_Single_Date").attr("checked") is `undefined`)
  if $("#day_selected_shifts option").length > 0
    $("#shifts_next").show()
  else
    $("#shifts_next").hide()

  # if single, hide multi stuff, else show multi stuff
  if $("#type_Single_Date").attr("checked")
    $(".multi_date").hide()
    $(".single_date").show()
  else
    $(".multi_date").show()
    $(".single_date").hide()
  if $("#selected_dates option").length > 0
    $("#dates_next").show()
  else
    $("#dates_next").hide()

  # set options in confirm page
  if $("#option_0").attr("checked")
    $("#confirm_option").text "WARNING:  You have elected to delete existing shifts. This will not destroy any shifts you've already set up."
    $("#confirm_option").addClass "red_warning"
  else
    $("#confirm_option").text "You have elected to add shifts to existing shifts. This is a safe way of populating shifts and will not destroy any shifts you've already set up."
    $("#confirm_option").removeClass "red_warning"
  if ready_to_post()
    $("#finish").attr "readonly", `undefined`
  else
    $("#finish").attr "readonly", "readonly"
ready_to_post = ->
  true
hide_all_pages = ->
  $("#introduction").hide()
  $("#select_shifts").hide()
  $("#select_dates").hide()
  $("#set_options").hide()
  $("#confirmation").hide()

clear_date_selections = ->
  $("#selected_dates option").remove()

process_date_selections = ->
  # if no date in single, alert error...
  if $("#start_date").val() is ""
    alert "ERROR: Start Date Must Be Set."
    return
  if $("#type_Single_Date").attr("checked")

    # add date to select box
    key_str = $("#start_date").val()
    label_str = $("#start_date").val()
    $("#selected_dates").append "<option value=\"" + key_str + "\">" + label_str + "</option>"
  else

    # if no date in end, alert error...
    if $("#end_date").val() is ""
      alert "ERROR: End Date Must Be Set."
      return

    # if no day of week selected, alert error...
    if $("#days_of_the_week option:selected").length is 0
      alert "ERROR: You must select a Day of the Week."
      return

    # move all dates to selection list
    curr_date_str = $("#start_date").val()
    curr_date = convert_to_date(curr_date_str)
    end_date_str = $("#end_date").val()
    end_date = convert_to_date(end_date_str)
    valid_days = new Array()
    $("#days_of_the_week option:selected").each (index) ->
      valid_days[valid_days.length] = parseInt($(this).val())

    while curr_date <= end_date

      # make sure it's a valid day of the week
      day = curr_date.getDay()
      unless $.inArray(day, valid_days) is -1

        # add day to list
        key_str = convert_date_to_str(curr_date)
        label_str = convert_date_to_str(curr_date)
        $("#selected_dates").append "<option value=\"" + key_str + "\">" + label_str + "</option>"

      # set curr_date to next day
      curr_date = increment_date_by_a_day(curr_date)
  update_display()
convert_to_date = (dt_str) ->
  dateParts = dt_str.split("-")
  y = parseInt(dateParts[0], 10)
  m = parseInt(dateParts[1], 10)
  d = parseInt(dateParts[2], 10)
  retval = new Date(y, m - 1, d)
  retval
convert_date_to_str = (dt) ->
  date_str = dt.getFullYear() + "-" + pad((dt.getMonth() + 1), 2) + "-" + pad(dt.getDate(), 2)
  date_str
increment_date_by_a_day = (dt) ->
  y = dt.getFullYear()
  m = dt.getMonth()
  d = dt.getDate()
  new Date(y, m, d + 1)
$(document).ready ->
  $("#intro_next").click (e) ->
    $("#current_page").val "select_shifts"
    update_display()

  $("#shifts_next").click (e) ->
    $("#current_page").val "select_dates"
    $("#confirm_selected_shifts option").remove()
    $("#day_selected_shifts option").each (i) ->
      key_str = $(this).val()
      label_str = $(this).text()
      $("#confirm_selected_shifts").append "<option value=\"" + key_str + "\">" + label_str + "</option>"
      $(this).attr "selected", "selected"

    update_display()

  $("#shifts_back").click (e) ->
    $("#current_page").val "introduction"
    update_display()

  $("#dates_next").click (e) ->
    $("#current_page").val "set_options"
    update_display()
    $("#confirm_selected_dates option").remove()
    $("#selected_dates option").each (i) ->
      key_str = $(this).val()
      label_str = $(this).text()
      $("#confirm_selected_dates").append "<option value=\"" + key_str + "\">" + label_str + "</option>"
      $(this).attr "selected", "selected"


  $("#dates_back").click (e) ->
    $("#current_page").val "select_shifts"
    update_display()

  $("#confirm_next").click (e) ->
    $("#current_page").val "confirmation"
    update_display()

  $("#confirm_back").click (e) ->
    $("#current_page").val "select_dates"
    update_display()

  $("#finish_back").click (e) ->
    $("#current_page").val "set_options"
    update_display()

  $("#shift_select_btn").click (ev) ->
    selected_items = $("#day_available_shifts option:selected")
    iCnt = 0
    while iCnt < selected_items.length
      key_str = selected_items[iCnt].value
      label_str = selected_items[iCnt].text
      $("#day_selected_shifts").append "<option value=\"" + key_str + "\">" + label_str + "</option>"
      iCnt++
    ev.preventDefault()
    update_display()

  $("#shift_unselect_btn").click (ev) ->
    $("#day_selected_shifts option:selected").remove()
    ev.preventDefault()
    update_display()

  $("#clear_shifts_btn").click (ev) ->
    $("#day_selected_shifts option").remove()
    update_display()

  $("#type_Single_Date").click (ev) ->
    update_display()

  $("#type_Multiple_Dates").click (ev) ->
    update_display()

  $("#update_dates").click (ev) ->
    process_date_selections()

  $("#clear_dates").click (ev) ->
    clear_date_selections()

  setupShiftBuilderDatePicker()
  update_display()

pad = (number, length) ->
  str = "" + number
  str = "0" + str  while str.length < length
  str