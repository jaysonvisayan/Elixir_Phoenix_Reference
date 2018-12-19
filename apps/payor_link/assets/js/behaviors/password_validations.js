onmount('div[id="resetPassword"]', function(){
  $('#forgotPasswordFormValidate').form({
    on: 'blur',
    inline: true,
    fields: {
      'user[password_confirmation]': {
        identifier: 'user[password_confirmation]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter password confirmation'
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
  $('#matchlabel').hide();

  // $('#user_password_confirmation').on('blur',function(){
  //   if($('#user_password_confirmation').val()){
  //     $('#matchlabel').show();
  //     $('#passwordMatch').show();
  //     $('#passwordMatch').removeClass('');
  //     $('#passwordMatch').addClass('ui right floated sublabel');
  //     let password_match = document.getElementById("passwordMatch");
  //     let result,color = "";


  //     if( $('.ui.resetPasswordForm').form('is valid', 'user[password_confirmation]')) {
  //       result = "Yes";
  //       color = "#21ba45";
  //     }
  //     else {
  //       result = "No";
  //       color = "#db2828";
  //     }
  //     password_match.innerHTML = result;
  //     password_match.style.color = color;
  //   }
  //   else{
  //     $('#matchlabel').hide();
  //   }

  // });

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

onmount('div[id="createPassword"]', function(){

  $('.ui.createPasswordForm').form({
    on: 'blur',
    fields: {
      'user[password_confirmation]': {
        identifier: 'user[password_confirmation]',
        rules: [
          {
            type: 'match[user[password]]',
            prompt: 'Password match: No'
          }
        ]
      }
    }

  });
  $('#createPasswordFormValidate').form({
    on: 'blur',
    inline: true,
    fields: {
      'user[password_confirmation]': {
        identifier: 'user[password_confirmation]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter password confirmation'
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
  $('#matchlabel').hide();

  $('#user_password_confirmation').on('blur',function(){
    if($('#user_password_confirmation').val()){
      $('#matchlabel').show();
      $('#passwordMatch').show();
      $('#passwordMatch').removeClass('');
      $('#passwordMatch').addClass('ui right floated sublabel');
      let password_match = document.getElementById("passwordMatch");
      let result,color = "";


      if( $('.ui.createPasswordForm').form('is valid', 'user[password_confirmation]')) {
        result = "Yes";
        color = "#21ba45";
      }
      else {
        result = "No";
        color = "#db2828";
      }
      password_match.innerHTML = result;
      password_match.style.color = color;
    }
    else{
      $('#matchlabel').hide();
    }

  });

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

onmount('div[name="AccountValidation"]', function(){
  $('#AccountForm').form({
    on: 'blur',
    inline: true,
    fields: {
      'user[current_password]': {
        identifier: 'user[current_password]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter current password'
        }]
      },
      'user[password]': {
        identifier: 'user[password]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter new password'
        },
        {
          type: 'regExp[/.*[0-9].*/]',
          prompt: 'Password should contain alpha-numeric characters'
        },
        {
          type: 'regExp[/.*[A-Z].*/]',
          prompt: 'Password should contain at least 1 capital letter'
        },
        {
          type: 'regExp[/.*[^A-Za-z0-9].*/]',
          prompt: 'Password should contain special character'
        },
        {
          type: 'regExp[/^(.){8,128}$/]',
          prompt: 'Password should be at least 8 characters and at most 128 characters'
        }]
      },
      'user[password_confirmation]': {
        identifier: 'user[password_confirmation]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter confirm new password'
        },
        {
          type: 'match[user[password]]',
          prompt: "Password did not match"
        }]
      },
    },
  });

});
