onmount('div[name="Register"]', function(){
  const locale = $('#locale').val();
  const p_num = $('#principal_number').val()
  let csrf = $('input[name="_csrf_token"]').val();
  let validMobileNos = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994","976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  $.ajax({
    url:`/${locale}/register/user/validate`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let data = JSON.parse(response);
      let arrayForUsername = $.map(data, function(value, index) {
        return [value.username];
      });

      let arrayForEmail = $.map(data, function(value, index) {
        return [value.email];
      });

      let arrayForMobile = $.map(data, function(value, index) {
        return [value.mobile];
      });

      $.fn.form.settings.rules.checkUsername= function(param) {
        return arrayForUsername.indexOf(param) == -1 ? true : false;
      };

      $.fn.form.settings.rules.checkEmail = function(param) {
        return arrayForEmail.indexOf(param) == -1 ? true : false;
      };

      $.fn.form.settings.rules.checkMobile = function(param) {
        let result = arrayForMobile.indexOf(param.replace(/-/g, "")) == -1 ? true : false;
        if(result == false){
          if(p_num != "not_dependent"){
               if(param == p_num) {
                     return true
               } else {
                   return false
               }
           } else {
             return result
           }
         }else{
          return result
         }
      };
      $.fn.form.settings.rules.checkMobilePrefix = function(param) {
        return validMobileNos.indexOf(param.substring(1,4)) == -1 ? false : true;
      }
      $.fn.form.settings.rules.validateMobile = function(param) {

        if (param == '') {
          return true;
        } else {
          param = param.replace(/-/g, '');
          return /^0[0-9]{10}$/.test(param);
        }
      }

      $('.ui.form')
      .form({
        inline: true,
        on: 'blur',
        fields: {
          'user[username]': {
            identifier  : 'user[username]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Username'
              },
              {
                type  : 'checkUsername[param]',
                prompt: 'Username is already taken'
              },
              {
                type   : 'minLength[5]',
                prompt : 'Please enter at least {ruleValue} characters'
              }
            ]
          },
          'user[password]': {
            identifier  : 'user[password]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Password'
              },
              {
                type: 'regExp[/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,20}$/]',
                prompt: 'Password must be 8 to 20 characters long and should include at least 1 numeric character, special character and uppercase letter.'
              }
            ]
          },
          'user[password_confirmation]': {
            identifier  : 'user[password_confirmation]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Confirm Password'
              },
              {
                type   : 'match[user[password]]',
                prompt : 'Password doesn’t match'
              }
            ]
          },
          'user[email]': {
            identifier  : 'user[email]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Email Address'
              },
              {
                type: 'regExp[/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/]',
                prompt: 'The email you have entered is invalid'
              },
              {
                type  : 'checkEmail[param]',
                prompt: 'Email Address is already taken'
              }
            ]
          },
          'user[email_confirmation]': {
            identifier  : 'user[email_confirmation]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Confirm Email Address'
              },
              {
                type : 'match[user[email]]',
                prompt: 'Email address doesn’t match'
              }
           ]
         },
         'user[mobile]': {
            identifier  : 'user[mobile]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Mobile Number'
              },
              {
                type  : 'checkMobile[param]',
                prompt: 'Mobile Number is already taken'
              },
              {
                type  : 'checkMobilePrefix[param]',
                prompt: 'The mobile number you have entered is invalid'
              },
              {
                type   : 'validateMobile[param]',
                prompt: 'The Mobile number you have entered is invalid'
              }
            ]
          },
         'user[mobile_confirmation]': {
           identifier  : 'user[mobile_confirmation]',
           rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Confirm Mobile Number'
              },
              {
                type : 'match[user[mobile]]',
                prompt: 'Mobile number doesn’t match'
              }
           ]
         }
        }
      });
    }
  });

  $('div[role="success"]', function(){
    $('#modal_success')
      .modal('setting', 'closable', false)
      .modal('show')
  });
});
