onmount('div[name="forgotPasswordValidate"]', function(){
  let test = $('input[name="user[verification_code][]"]').val();
  $('input[name="user[verification_code][]"]').each(function(){
    if($(this).val() == ""){
      $('button[type="submit"]').prop('disabled', true);
    }
    else{
      $('button[type="submit"]').prop('disabled', false);
    }
  });
    $('#session_userinfo').on('keyup', function(){
      $('#append_error').remove()
      $('.field').removeClass('error')
    })
    $('input[name="user[verification_code][]"]').on('keyup', function(){
    $('input[name="user[verification_code][]"]').each(function(){
      if($(this).val() == ""){
        $('button[type="submit"]').prop('disabled', true);
      }
      else{
        $('button[type="submit"]').prop('disabled', false);
      }
    });
  });
  let csrf = $('input[name="_csrf_token"]').val();

  // $.ajax({
  //   url:`/sign`,
  //   headers: {"X-CSRF-TOKEN": csrf},
  //   type: 'get',
  //   success: function(response){
  //     let data = JSON.parse(response)
  //     let array = $.map(data, function(value, index) {
  //       return [value.username];
  //     });

  //     $.fn.form.settings.rules.validateUsername = function(param) {
  //       return array.indexOf(param) == -1 ? false : true;
  //     }
  //   }
  // });

  $('#send').on('click', function(){
    $('.ui.large.form')
    .form({
      inline: true,
      on: 'blur',
      fields: {
        'session[userinfo]': {
          identifier : 'session[userinfo]',
          rules : [{
            type : 'empty',
            prompt : "Please enter your phone number or email"
          }
          // {
          //   type : 'validateUsername[param]',
          //   prompt : "Username is invalid"
          // }
          ]
        }
      }
    })
  })
});


onmount('.resetPasswordForm', function(){
      $('#password_validate').on('keyup', function(){
      $('#append_error_new_password').remove()
      $('.field').removeClass('error')
    })

    $("#reset_eye").click(function() {
      var input = $('#password_validate');
      if (input.attr("type") == "password") {
        input.attr("type", "text");
      } else {
        input.attr("type", "password");
      }
    });

    $("#reset_eye_1").click(function() {
      var input = $('#password_confirm');
      if (input.attr("type") == "password") {
        input.attr("type", "text");
      } else {
        input.attr("type", "password");
      }
    });

})

onmount('#verify_form', function(){
    $('#verify_form')
  .form({
    fields: {
        'user[verification_code][]': {
          identifier : 'user[verification_code][]',
          rules : [{
            type : 'empty',
            prompt : "Please enter Verification Code"
          }
          ]
        }
      }
    })
  let count_function = function(){
    if ($('#counter').text() != "0"){
      $('#counter').text(`${parseInt($('#counter').text()) - 1}`)
    }
    if ($('#counter').text() == "0"){
      clearInterval(interval_id)
      $('#counter').attr('style', 'text-align:right; color: #0fd8f1; display: none;')
      $('#resend_id').attr('style', 'text-align:right; color: #0fd8f1; display: block;')
    }
  }
  let interval_id = setInterval(count_function, 1000)
})
