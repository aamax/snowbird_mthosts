$(document).ready ->
  pad = (number, length) ->
    str = "" + number
    str = "0" + str  while str.length < length
    str

  $("#set_training_date_btn").datepicker().on "changeDate", (ev) ->
    date_str = ev.date.getFullYear() + "-" + pad((ev.date.getMonth() + 1), 2) + "-" + pad(ev.date.getDate(), 2)
    $("input#training_shift_date").val date_str
    $(this).datepicker "hide"
