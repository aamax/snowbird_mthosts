# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$(document).ready ->
  $('#reset_shifts_index_form').click ->
    $("input#filter_date").val ''
    $("#filter_dayofweek").val ''
    options = $("#filter_shifttype option")
    len = options.length
    i = 0
    while i < len
      options[i].selected = false
      i++
    options = $("#filter_host option")
    len = options.length
    i = 0
    while i < len
      options[i].selected = false
      i++
    $("#filter_shifts_i_can_pick").checked = false
    $("#filter_start_from_today").checked = true

  $(".cal_icon").datepicker().on "changeDate", (ev) ->
    date_str = ev.date.getFullYear() + "-" + pad((ev.date.getMonth() + 1), 2) + "-" + pad(ev.date.getDate(), 2)
    $("input#filter_date").val date_str
    $(this).datepicker "hide"

  pad = (number, length) ->
    str = "" + number
    str = "0" + str  while str.length < length
    str

  $("#clear_date").click ->
    $("input#filter_date").val ''

  window.onbeforeunload = (e) ->
    $('#show_page a').each ->
      this.style.display = 'none'
    $('#shift_listing a').each ->
      this.style.display = 'none'
    undefined

  $('.select_btn').click ->
    $('.select_btn').remove()

  $('.toggle_disabled').change(->
    # make ajax call to toggle disabled flag for shift
    chkboxValue = this.checked

    arr = this.name.split('_')
    shiftID = arr[arr.length - 1]

    $.ajax
      type: "POST" # GET in place of POST
      contentType: "application/json; charset=utf-8"
      url: "/toggle_shift_disabled/#{shiftID},#{chkboxValue}"
      dataType: "json"
      success: (result) ->
      #do somthing here
        alert "Shift Disabled Flag Toggled: #{result.shift.short_name} on #{result.shift.shift_date}"
      error: ->
        alert "Error Toggling Shift Disabled Flag Value."
  )
