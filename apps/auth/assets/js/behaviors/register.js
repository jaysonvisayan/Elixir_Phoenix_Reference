const locale = $('#locale').val();

onmount('div[name="Register"]', function(){
  let csrf = $('input[name="_csrf_token"]').val();

  const valid_mobile_prefix = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994", "976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  $.fn.form.settings.rules.mobileChecker = function(param) {
    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmaked_value.length == "11") {
      return true
    } else {
      return false
    }
  };

  $.fn.form.settings.rules.mobilePrefixChecker = function(param) {
    return valid_mobile_prefix.indexOf(param.substring(1, 4)) == -1 ? false : true
  };

  $.fn.form.settings.rules.telephoneChecker = function(param) {
    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmaked_value.length == "7") {
      return true
    } else {
      return false
    }
  };

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
        return arrayForMobile.indexOf(param.replace(/-/g, "")) == -1 ? true : false;
      };

      $('.ui.form')
      .form({
        inline: true,
        on: 'blur',
        fields: {
          'user[first_name]': {
            identifier : 'user[first_name]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter First Name'
              },
              {
                type   : 'maxLength[150]',
                prompt : 'Please enter at most {ruleValue} characters'
              },
              {
                type   : 'regExp[/^[A-Za-z .,-]*$/]',
                prompt : 'Only letters and characters (.,-) are allowed'
              }
            ]
          },
          'user[middle_name]': {
            identifier : 'user[middle_name]',
            optional   : 'true',
            rules: [
              {
                type   : 'maxLength[150]',
                prompt : 'Please enter at most {ruleValue} characters'
              },
              {
                type   : 'regExp[/^[A-Za-z .,-]*$/]',
                prompt : 'Only letters and characters (.,-) are allowed'
              }
            ]
          },
          'user[last_name]': {
            identifier : 'user[last_name]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Last Name'
              },
              {
                type   : 'maxLength[150]',
                prompt : 'Please enter at most {ruleValue} characters'
              },
              {
                type   : 'regExp[/^[A-Za-z .,-]*$/]',
                prompt : 'Only letters and characters (.,-) are allowed'
              }
            ]
          },
          'user[ext]': {
            identifier : 'user[ext]',
            optional   : 'true',
            rules: [
              {
                type   : 'maxLength[10]',
                prompt : 'Please enter at most {ruleValue} characters'
              },
              {
                type   : 'regExp[/^[A-Za-z .,-]*$/]',
                prompt : 'Only letters and characters (.,-) are allowed'
              }
            ]
          },
          'user[role]': {
            identifier : 'user[role]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please select Role'
              }
            ]
          },
          'user[username]': {
            identifier : 'user[username]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Username'
              },
              {
                type   : 'checkUsername[param]',
                prompt : 'Username is already taken'
              },
              {
                type   : 'regExp[/^[A-Za-z0-9._-]*$/]',
                prompt : 'Only letters, numbers, and characters (._-) are allowed'
              },
              {
                type   : 'minLength[8]',
                prompt : 'Please enter at least {ruleValue} characters'
              },
              {
                type   : 'maxLength[24]',
                prompt : 'Please enter at most {ruleValue} characters'
              }
            ]
          },
          'user[password]': {
            identifier : 'user[password]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Password'
              },
              {
                type   : 'minLength[8]',
                prompt : 'Please enter at least {ruleValue} characters'
              },
              {
                type   : 'maxLength[24]',
                prompt : 'Please enter at most {ruleValue} characters'
              }
            ]
         },
         'user[confirm_password]': {
           identifier  : 'user[confirm_password]',
           rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Confirm Password'
              },
              {
                type   : 'match[user[password]]',
                prompt : 'Passwords do not match'
              }
           ]
         },
         'user[email]': {
            identifier : 'user[email]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Email Address'
              },
              {
                type   : 'email',
                prompt : 'Email Address is invalid'
              },
              {
                type   : 'checkEmail[param]',
                prompt : 'Email Address is already taken'
              }
           ]
         },
         'user[mobile]': {
            identifier : 'user[mobile]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Mobile Number'
              },
              {
                type   : 'checkMobile[param]',
                prompt : 'Mobile Number is already taken'
              },
              {
                type   : 'mobileChecker[param]',
                prompt : 'Mobile Phone 1 must be 11 digits'
              },
              {
                type   : 'mobilePrefixChecker[param]',
                prompt : 'Invalid Mobile Phone 1 prefix'
              }
            ]
          },
          'user[tel_no]': {
            identifier : 'user[tel_no]',
            optional   : true,
            rules: [
              {
                type   : 'telephoneChecker[param]',
                prompt : 'Telephone must be 7 digits'
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
