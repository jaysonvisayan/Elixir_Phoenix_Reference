onmount('div[id="change_password_div"]', function () {
  $('#strengthMeter').progress({
    total: '99',
    showActivity: false
  });

  $('#strengthMeterLabel').hide();
  $('#strengthMeter').hide();
  $('#strengthMeter').progress('reset');

  $('#password_validate').on('keyup',function(){
console.log(1231231)
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


      $('#change_password')
      .form({
        on: blur,
        inline: true,
        fields: {
          'user[password]': {
            identifier: 'user[password]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter a new password'
              },
              {
                type: 'regExp[/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,20}$/]',
                prompt: 'Password must be 8 to 20 characters long and should include at least 1 numeric character, special character and uppercase letter.'
              }]
          },
          'user[old_password]': {
            identifier: 'user[old_password]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter current password'
              }
            ]
          },
          'user[password_confirmation]': {
            identifier: 'user[password_confirmation]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter password confirmation'
              }
            ]
          }
        }
      });

})
