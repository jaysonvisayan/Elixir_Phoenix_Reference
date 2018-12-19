onmount('div[name="formValidate"]', function () {
  let csrf = $('input[name="_csrf_token"]').val();
  let roleName = $('input[type="text"][name="role[name]"]').val()
  $.ajax({
    url:`/roles/load/role_name`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let data = JSON.parse(response);

      let array = $.map(data, function(value, index) {
        return [value.name];
      });
      $.fn.form.settings.rules.checkRole = function(param) {
        return array.indexOf(param) == -1 ? true : false;
      }
      array.splice($.inArray(roleName, array),1)
      $.fn.form.settings.rules.checkEditRole = function(param) {
        return array.indexOf(param) == -1 ? true : false;
      }

      $('#formBasicRole').form({
        on: blur,
        inline: true,
        fields: {
          'role[name]': {
            identifier: 'role[name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'checkRole[param]',
              prompt : 'Name already exists!'
            }
            ]
          },
          'role[application_ids][]': {
            identifier: 'role[application_ids][]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          }
        }
      });


       // $('#suspend').form({
       //  on: blur,
       //  inline: true,
       //  fields: {
       //    'account[suspend_date]': {
       //      identifier: 'account[suspend_date]',
       //      rules: [{
       //        type  : 'empty',
       //        prompt: 'Please enter suspension date.'
       //      }
       //      ]
       //    },
       //    'account[suspend_reason]': {
       //      identifier: 'account[suspend_reason]',
       //      rules: [{
       //        type  : 'empty',
       //        prompt: 'Please enter suspension reason.'
       //      }
       //      ]
       //    }
       //  }
      // });


      $('#formEditRole').form({
        on: blur,
        inline: true,
        fields: {
          'role[name]': {
            identifier: 'role[name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'checkEditRole[param]',
              prompt : 'Name already exists!'
            }
            ]
          },
          'role[application_ids][]': {
            identifier: 'role[application_ids][]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          }
        }
      });

    }
  });

  let val_username = $('input[name="user[username]"]').attr("user")
  let val_email = $('input[name="user[email]"]').attr("user")
  let val_mobile = $('input[name="user[mobile]"]').attr("user")
  let validMobileNos = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994","976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  $.ajax({
    url:`/users/get/validate`,
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
      //  array.splice($.inArray(test, array),1)
      $.fn.form.settings.rules.checkUsername= function(param) {
        return arrayForUsername.indexOf(param) == -1 ? true : false;
      }
      $.fn.form.settings.rules.checkEmail = function(param) {
        return arrayForEmail.indexOf(param) == -1 ? true : false;
      }
      $.fn.form.settings.rules.checkMobile = function(param) {
        return arrayForMobile.indexOf(param) == -1 ? true : false;
      }
      $.fn.form.settings.rules.checkMobilePrefix = function(param) {
        return validMobileNos.indexOf(param.substring(1,4)) == -1 ? false : true;
      }

      if(val_email != undefined){
        arrayForEmail.splice($.inArray(val_email, arrayForEmail),1)
      }
      if(val_username != undefined){
        console.log(arrayForUsername)
        arrayForUsername.splice($.inArray(val_username, arrayForUsername),1)
      }
      if(val_mobile != undefined){
        arrayForMobile.splice($.inArray(val_mobile, arrayForMobile),1)
      }

      $.fn.form.settings.rules.checkEditUsername= function(param) {
        return arrayForUsername.indexOf(param) == -1 ? true : false;
      }
      $.fn.form.settings.rules.checkEditEmail = function(param){
        return arrayForEmail.indexOf(param) == -1 ? true : false;
      }
      $.fn.form.settings.rules.checkEditMobile = function(param) {
        return arrayForMobile.indexOf(param) == -1 ? true : false;
      }

      $('#formBasicUser').form({
        on: blur,
        inline: true,
        fields: {
          'user[last_name]': {
            identifier: 'user[last_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[2]',
              prompt : 'Your last name must be at least {ruleValue} characters'
            }
            ]

          },
          'user[first_name]': {
            identifier: 'user[first_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[2]',
              prompt : 'Your first name must be at least {ruleValue} characters'
            }
            ]
          },
          'user[email]': {
            identifier: 'user[email]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type  : 'email',
              prompt: 'Should be a valid email address'
            },
            {
              type  : 'checkEmail[param]',
              prompt: 'Email is already being used by another user.'
            },
            {
              type   : 'maxLength[50]',
              prompt : 'Your email address must be less than {ruleValue} characters'
            }
            ]
          },
          'user[mobile]': {
            identifier: 'user[mobile]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type  : 'checkMobile[param]',
              prompt: 'Mobile is already being used by another user.'
            },
            {
              type  : 'checkMobilePrefix[param]',
              prompt: 'Mobile prefix is invalid.'
            },
            {
              type   : 'exactLength[11]',
              prompt : 'Your mobile number must be {ruleValue} characters'
            }
            ]
          },
          'user[username]': {
            identifier: 'user[username]',
            rules: [
              {
                type  : 'empty',
                prompt: 'This is a required field'
              },
              {
                type  : 'checkUsername[param]',
                prompt: 'Username is already being used by another user.'
              },
              {
                type   : 'minLength[5]',
                prompt : 'Your username must be at least {ruleValue} characters'
              }
            ]
          }
        }
      });
      $('#formEditUser').form({
        on: blur,
        inline: true,
        fields: {
          'user[last_name]': {
            identifier: 'user[last_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[2]',
              prompt : 'Your last name must be at least {ruleValue} characters'
            }
            ]
          },
          'user[first_name]': {
            identifier: 'user[first_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[2]',
              prompt : 'Your first name must be at least {ruleValue} characters'
            }
            ]
          },
          'user[email]': {
            identifier: 'user[email]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type  : 'email',
              prompt: 'Should be a valid email address'
            },
            {
              type  : 'checkEditEmail[param]',
              prompt: 'Email is already being used by another user.'
            },
            {
              type   : 'maxLength[50]',
              prompt : 'Your email address must be less than {ruleValue} characters'
            }
            ]
          },
          'user[mobile]': {
            identifier: 'user[mobile]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type  : 'checkEditMobile[param]',
              prompt: 'Mobile is already being used by another user.'
            },
            {
              type  : 'checkMobilePrefix[param]',
              prompt: 'Mobile prefix is invalid.'
            },
            {
              type   : 'exactLength[11]',
              prompt : 'Your mobile number must be {ruleValue} characters'
            }
            ]
          },
          'user[username]': {
            identifier: 'user[username]',
            rules: [
              {
                type  : 'empty',
                prompt: 'This is a required field'

              },
              {
                type  : 'checkEditUsername[param]',
                prompt: 'Username is already being used by another user.'
              }
            ]
          }
        }
      });
      //Practitioner Validations start
      $('#formPractitionerGeneral').form({
        on: blur,
        inline: true,
        fields: {
          'practitioner[first_name]': {
            identifier: 'practitioner[first_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[2]',
              prompt : 'Your first name must be at least {ruleValue} characters'
            }
            ]

          },
          'practitioner[middle_name]': {
            identifier: 'practitioner[middle_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[2]',
              prompt : 'Your middle name must be at least {ruleValue} characters'
            }
            ]

          },
          'practitioner[last_name]': {
            identifier: 'practitioner[last_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[2]',
              prompt : 'Your last name must be at least {ruleValue} characters'
            }
            ]
          },
          'practitioner[birth_date]': {
            identifier: 'practitioner[birth_date]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          },
          'practitioner[gender]': {
            identifier: 'practitioner[gender]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          },
          'practitioner[prc_no]': {
            identifier: 'practitioner[prc_no]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[7]',
              prompt : 'Your PRC No. must be at least {ruleValue} characters'
            }
            ]
          },
          'practitioner[affiliated]': {
            identifier: 'practitioner[affiliated]',
            rules: [
              {
                type  : 'empty',
                prompt: 'This is a required field'
              }
            ]
          },
          'practitioner[effectivity_from]': {
            identifier: 'practitioner[effectivity_from]',
            rules: [
              {
                type  : 'empty',
                prompt: 'This is a required field'
              }
            ]
          },
          'practitioner[effectivity_to]': {
            identifier: 'practitioner[effectivity_to]',
            rules: [
              {
                type  : 'empty',
                prompt: 'This is a required field'
              }
            ]
          },
          'practitioner[specialization_ids][]': {
            identifier: 'practitioner[specialization_ids][]',
            rules: [
              {
                type  : 'empty',
                prompt: 'This is a required field'
              }
            ]
          }
        }
      });
      $('#formPractitionerGeneralEdit').form({
        on: blur,
        inline: true,
        fields: {
          'practitioner[first_name]': {
            identifier: 'practitioner[first_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[2]',
              prompt : 'Your first name must be at least {ruleValue} characters'
            }
            ]

          },
          'practitioner[middle_name]': {
            identifier: 'practitioner[middle_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[2]',
              prompt : 'Your middle name must be at least {ruleValue} characters'
            }
            ]

          },
          'practitioner[last_name]': {
            identifier: 'practitioner[last_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[2]',
              prompt : 'Your last name must be at least {ruleValue} characters'
            }
            ]
          },
          'practitioner[birth_date]': {
            identifier: 'practitioner[birth_date]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          },
          'practitioner[gender]': {
            identifier: 'practitioner[gender]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          },
          'practitioner[prc_no]': {
            identifier: 'practitioner[prc_no]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[7]',
              prompt : 'Your PRC No. must be at least {ruleValue} characters'
            }
            ]
          },
          'practitioner[affiliated]': {
            identifier: 'practitioner[affiliated]',
            rules: [
              {
                type  : 'empty',
                prompt: 'This is a required field'
              }
            ]
          },
          'practitioner[effectivity_from]': {
            identifier: 'practitioner[effectivity_from]',
            rules: [
              {
                type  : 'empty',
                prompt: 'This is a required field'
              }
            ]
          },
          'practitioner[effectivity_to]': {
            identifier: 'practitioner[effectivity_to]',
            rules: [
              {
                type  : 'empty',
                prompt: 'This is a required field'
              }
            ]
          },
          'practitioner[specialization_ids][]': {
            identifier: 'practitioner[specialization_ids][]',
            rules: [
              {
                type  : 'empty',
                prompt: 'This is a required field'
              }
            ]
          }
        }
      });

      $('#prac_modal_contact').form({
        on: blur,
        inline: true,
        fields: {
          'practitioner[mobile][]': {
            identifier: 'practitioner[mobile][]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[11]',
              prompt : 'Must be at least {ruleValue} numbers'
            },
            {
              type  : 'checkMobilePrefix[param]',
              prompt: 'Mobile prefix is invalid.'
            }
            ]
          },
          'practitioner[email]': {
            identifier: 'practitioner[email]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          }
         }
        });

        $('#prac_modal_contact_edit').form({
        on: blur,
        inline: true,
        fields: {
          'practitioner[mobile][]': {
            identifier: 'practitioner[mobile][]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'minLength[11]',
              prompt : 'Must be at least {ruleValue} numbers'
            },
            {
              type  : 'checkMobilePrefix[param]',
              prompt: 'Mobile prefix is invalid.'
            }
            ]
          },
          'practitioner[email]': {
            identifier: 'practitioner[email]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          }
         }
        });

      $('#formPractitionerFinancial').form({
        on: blur,
        inline: true,
        fields: {
          'practitioner[tin]': {
            identifier: 'practitioner[tin]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'exactLength[12]',
              prompt : 'TIN must be {ruleValue} characters'
            }
            ]
          },
          'practitioner[vat_status]': {
            identifier: 'practitioner[vat_status]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          },
          'practitioner[account_name]': {
            identifier: 'practitioner[account_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          },
          'practitioner[account_no]': {
            identifier: 'practitioner[account_no]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          },
          'practitioner[xp_card_no]': {
            identifier: 'practitioner[xp_card_no]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'exactLength[16]',
              prompt : 'Card no. must be {ruleValue} characters'
            }
            ]
          },
          'practitioner[payee_name]': {
            identifier: 'practitioner[payee_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          }

        }
      });
      $('#formPractitionerFinancialEdit').form({
        on: blur,
        inline: true,
        fields: {
          'practitioner[tin]': {
            identifier: 'practitioner[tin]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'exactLength[12]',
              prompt : 'TIN must be {ruleValue} characters'
            }
            ]
          },
          'practitioner[vat_status]': {
            identifier: 'practitioner[vat_status]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          },
          'practitioner[account_name]': {
            identifier: 'practitioner[account_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          },
          'practitioner[account_no]': {
            identifier: 'practitioner[account_no]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          },
          'practitioner[xp_card_no]': {
            identifier: 'practitioner[xp_card_no]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            },
            {
              type   : 'exactLength[16]',
              prompt : 'Card no. must be {ruleValue} characters'
            }
            ]
          },
          'practitioner[payee_name]': {
            identifier: 'practitioner[payee_name]',
            rules: [{
              type  : 'empty',
              prompt: 'This is a required field'
            }
            ]
          }
        }
      });
    }
  });
});
