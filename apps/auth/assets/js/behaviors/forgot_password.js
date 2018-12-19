const locale = $('#locale').val();

onmount('div[name="ForgotPassword"]', function () {
  let csrf = $('input[name="_csrf_token"]').val();

  $.ajax({
    url:`/${locale}/sign`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let data = JSON.parse(response)
      let array = $.map(data, function(value, index) {
        return [value.username];
      });

      $.fn.form.settings.rules.validateUsername = function(param) {
        return array.indexOf(param) == -1 ? false : true;
      }
    }
  });

  $('#send').on('click', function() {
    let channelPrompt = ""
    let validatePrompt = ""

    if ($('#channelEmail').is(':checked')) {
      channelPrompt = "Please enter Registered Email Address"
    }
    if ($('#channelSMS').is(':checked')) {
      channelPrompt = "Please enter Registered Mobile Number"
    }

    $('.ui.form')
    .form({
      inline: true,
      on: 'blur',
      fields: {
        'session[username]': {
          identifier : 'session[username]',
          rules : [{
            type : 'empty',
            prompt : "Please enter Username"
          },
          {
            type : 'validateUsername[param]',
            prompt : "Username is invalid"
          }]
        },
        'session[text]': {
          identifier : 'session[text]',
          rules : [{
            type : 'empty',
            prompt : channelPrompt
          }]
        }
      }
    })
  });

  $('input[name="session[channel]"]').change(function() {
    $('.ui.form').find('.error').removeClass('error');
    $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()

    if ($('#channelEmail').is(':checked')) {
      $('input[name="session[text]"]').attr('placeholder', 'Registered Email Address')
    }
    if ($('#channelSMS').is(':checked')) {
      $('input[name="session[text]"]').attr('placeholder', 'Registered Mobile Number')
    }
  });
});

onmount('div[name="VerifyCode"]', function(){
  let test = $('input[name="user[verification_code][]"]').val();

  $('input[name="user[verification_code][]"]').each(function(){
    if($(this).val() == ""){
      $('button[type="submit"]').prop('disabled', true);
    }
    else{
      $('button[type="submit"]').prop('disabled', false);
    }
  });

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
});

onmount('div[name="ResetPassword"]', function(){
  $('.ui.form').form({
    on: 'blur',
    inline: true,
    fields: {
      'user[password_confirmation]': {
        identifier: 'user[password_confirmation]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter password confirmation'
          },
          {
            type: 'match[user[password]]',
            prompt: 'Password match: No'
          }

        ]
      },
      'user[password]': {
        identifier: 'user[password]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter a new password'
          }
        ]
      }
    }
  });

//   $('#matchlabel').hide();

//   $('#user_password_confirmation').on('blur',function(){
//     if($('#user_password_confirmation').val()){
//       $('#matchlabel').show();
//       $('#passwordMatch').show();
//       $('#passwordMatch').removeClass('');
//       $('#passwordMatch').addClass('ui right floated sublabel');
//       let password_match = document.getElementById("passwordMatch");
//       let result,color = "";


//       if( $('.ui.resetPasswordForm').form('is valid', 'user[password_confirmation]')) {
//         result = "Yes";
//         color = "#21ba45";
//       }
//       else {
//         result = "No";
//         color = "#db2828";
//       }
//       password_match.innerHTML = result;
//       password_match.style.color = color;
//     }
//     else{
//       $('#matchlabel').hide();
//     }

//   });

  $('#strengthMeter').progress({
    total: '99',
    showActivity: false
  });

  $('#strengthMeterLabel').hide();
  $('#strengthMeter').hide();
  $('#strengthMeter').progress('reset');

  $('#password_validate').on('keyup',function(){
    if($('#password_validate').val()){
      $('#strengthMeterLabel').show();
      $('#strengthMeter').show();
      let password_validate = $(this).val();
      let password_strength = document.getElementById("passwordStrength");

      let regex = new Array();
      regex.push("[A-Z]"); //Uppercase Alphabet.
      regex.push("[a-z]"); //Lowercase Alphabet.
      regex.push("[0-9]"); //Digit.
      regex.push("[$@$!%*#?&]"); //Special Character.

      let passed = 0;

      //Validate for each Regular Expression.
      for (let i = 0; i < regex.length; i++) {
        if (new RegExp(regex[i]).test(password_validate)) {
          passed++;
        }
      }

      //Validate for length of Password.
      if (passed > 2 && password_validate.length > 8) {
        passed++;
      }

      //Display status.
      let color,value,strength = "";
      switch (passed) {
        case 0:
          case 1:
          strength = "Weak";
        color = "#db2828";
        value = 33;
        break;
        case 2:
          strength = "Weak";
        color = "#db2828";
        value = 33;;
        break;
        case 3:
          case 4:
          strength = "Medium";
        color = "#f2c037";
        value = 66;
        break;
        case 5:
          strength = "Strong";
        color = "#21ba45";
        value = 99;
        break;
      }

      password_strength.innerHTML = strength;
      password_strength.style.color = color;
      $('#strengthMeter').progress('set progress', value);
      $('.bar').css('background-color', color);
    }
    else {
      $('#strengthMeterLabel').hide();
      $('#strengthMeter').hide();
    }
  });
});

