# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$(->
  $('#user_form_submit').click(->
    if ($("#user_password").val() != $("#user_password_confirmation").val())
      return false
  )
)
