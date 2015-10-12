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

  $(".phone_edit").mask("(999) 999-9999")

  validate_pword = () ->
    pword = $("#user_password").val()
    pconf = $("#user_password_confirmation").val()

    if (pword.length == 0) && ((pconf.length == 0) || (pconf == undefined))
      $("#user_password")[0].style.backgroundColor = "white"
      $("#user_password_confirmation")[0].style.backgroundColor = "white"
    else
      if (pword.length < 8)
        $("#user_password")[0].style.backgroundColor = "red"
        $("#user_password_confirmation")[0].style.backgroundColor = "red"
      else
        $("#user_password")[0].style.backgroundColor = "white"

        if (pword != pconf)
          $("#user_password_confirmation")[0].style.backgroundColor = "yellow"
        else
          $("#user_password_confirmation")[0].style.backgroundColor = "white"

  $('.set_active').change(->
    # make ajax call to set active value for this user
    chkboxValue = this.checked
    arr = this.name.split('_')
    userID = arr[arr.length - 1]

    $.ajax
      type: "POST" # GET in place of POST
      contentType: "application/json; charset=utf-8"
      url: "/set_user_active/#{userID},#{chkboxValue}"
      dataType: "json"
      success: (result) ->
        #do somthing here
        alert "User Active Setting updated for: #{result.user.name}"
      error: ->
       alert "Error Setting Active Value."
  )
)
