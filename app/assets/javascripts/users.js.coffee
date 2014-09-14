# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$(->
  $('#user_form_submit').click(->
    if ($("#user_password").val() != $("#user_password_confirmation").val())
      return false
  )

  $('#user_search_box').keyup(->
    str_val = $(this).val().toLowerCase()
    # iterate through all users shown and hide any that don't have this substring in the name
    user_recs = $('.user_entry')
    for rec in user_recs
      if (rec.children[0].children[0].value.toLowerCase().indexOf(str_val) == -1)
        # hide the entry
        rec.style.display = 'none'
      else
        # show the entry
        rec.style.display = ''

  )

  $('#user_password').keyup(->
    validate_pword()
  )

  $('#user_password_confirmation').keyup(->
    validate_pword()
  )

  validate_pword = () ->
    pword = $("#user_password").val()
    pconf = $("#user_password_confirmation").val()

    if (pword.length < 8)
      $("#user_password_confirmation")[0].style.backgroundColor = "red"
    else
      if (pword != pconf)
        $("#user_password_confirmation")[0].style.backgroundColor = "yellow"
      else
        $("#user_password_confirmation")[0].style.backgroundColor = "white"

)
