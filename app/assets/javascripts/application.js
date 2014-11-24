// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this angular, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs

//= require angular
//= require ng-rails-csrf
//= require angular-resource

//= require_tree ./angular/controllers/.
//= require ./angular/services/shifttypeResource
//= require ./angular/services/shiftResource

//= require ./angular/services/services
// require_tree ./angular/services/.
// require_tree ./angular/directives/.
//= require_tree ./angular/.
//= require angular/directives/gravatar-directive

//= require /md5-service
//= require tinymce-jquery
//= require bootstrap
//= require bootstrap-datepicker
//= require bootstrap/load-image.min
//= require bootstrap/image-gallery.min

//= require angular-strap

//= require_tree .

$(document).ready(function() {
    $('text_area').tinymce({
        theme: 'advanced'

    });
});

$(function() {
    $('.flash_notice').delay(3000).fadeIn('normal', function() {
        $(this).delay(4000).fadeOut();
    });
});

$(function() {
    $('.alert-error').delay(3000).fadeIn('normal', function() {
        $(this).delay(4000).fadeOut();
    });
});






