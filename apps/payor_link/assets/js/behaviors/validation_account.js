// General
onmount('#account_name', function(){
  const csrf = $('input[name="_csrf_token"]').val();
  const account_name = $('input[name="account[name]"]').attr("dummy-val")

  $.ajax({
    url:`/get_all_account_name`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      const data = JSON.parse(response)
      const array = $.map(data, function(value, index) {
        return [value.name]
      });

      if(account_name != undefined){
        array.splice($.inArray(account_name, array),1)
      }

      $.fn.form.settings.rules.checkAccountName = function(param) {
        return array.indexOf(param) == -1 ? true : false
      }

      $.fn.form.settings.rules.checkEndDate = function(param) {
        let start = $('input[name="account[start_date]"]').val()
        let end = $('input[name="account[end_date]"]').val()
        start  = moment(start).format("YYYY-MM-DD")
        end = moment(end).format("YYYY-MM-DD")
        if(start >= end){
          return false
        }else{
          return true
        }
      }

      $.fn.form.settings.rules.checkStartDate = function(param) {
        let start = $('input[name="account[start_date]"]').val()
        start = moment(start).format("YYYY-MM-DD")
        let today = moment().format("YYYY-MM-DD")
        if(start <= today){
          return false
        }else{
          return true
        }
      }

      $.fn.form.settings.rules.validateCoveragePeriod = function(param) {
        let cur_end_date = $('input[id="account_cur_end_date"]').val();
        if (cur_end_date == ""){
          return true
        } else {
          if(param <= cur_end_date){
            return false
          }else{
            return true
          }
        }
      }

      $.fn.form.settings.rules.beyondCancelDate = function(param) {
        let cancellation_date = $('input[id="account_cancellation_date"]').val();
        if (cancellation_date == "") {
          return true
        } else {
          if(param > cancellation_date){
            return false
          }else{
            return true
          }
        }
      }

      $('#general').form({
        on: blur,
        inline: true,
        fields: {
          'account[name]': {
            identifier: 'account[name]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Account name'
            },
            {
              type   : 'minLength[5]',
              prompt : 'Account name must be at least {ruleValue} characters'
            },
            {
              type   : 'checkAccountName[param]',
              prompt: 'Account name is already exist!'
            }]
          },
          'account_group[start_date]':{
            identifier: 'account[start_date]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Effectivity date'
            },
            {
              type: 'checkStartDate[param]',
              prompt: 'It must be future dated'
            },
            {
              type: 'validateCoveragePeriod[param]',
              prompt: 'Effective Date shall not be within the coverage period of the current Active version of the Account'
            },
            {
              type: 'beyondCancelDate[param]',
              prompt: 'Effective Date shall not be equal or go beyond the Cancellation Date.'
            }
            ]
          },
          'account[end_date]':{
            identifier: 'account[end_date]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Expiry date'
            },
            {
              type: 'checkEndDate[param]',
              prompt: 'It must be future dated'
            }]
          }
        }
      })
    },
    error: function(){}
  })

})

// Address
onmount('div[name="AccountAddressValidation"]', function () {

  $('input[name="account[is_check]"]').on('change', function(){
    account_address_validation()
  });

  const account_address_validation = () => {

     if($(this).is(':checked')){
      $('#AccountAddress')
      .form({
        on: blur,
        inline: true,
        fields: {
          'account[line_1]': {
            identifier: 'account[line_1]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Address 1'
            }
            ]
          },
          'account[line_2]': {
            identifier: 'account[line_2]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Adress 2'
            }
            ]
          },
          'account[street]': {
            identifier: 'account[street]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Street'
            }
            ]
          },
          'account[city]': {
            identifier: 'account[city]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter City/Municipality'
            }
            ]
          },
          'account[province]': {
            identifier: 'account[province]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Province'
            }
            ]
          },
          'account[region]': {
            identifier: 'account[region]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Region'
            }
            ]
          },
          'account[postal_code]': {
            identifier: 'account[postal_code]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Postal code'
            }
            ]
          },
          'account[country]': {
            identifier: 'account[country]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Country'
            }
            ]
          }
        }
      });
    }else{
      $('#AccountAddress')
      .form({
        on: blur,
        inline: true,
        fields: {
          'account[line_1]': {
            identifier: 'account[line_1]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Address 1'
            }
            ]
          },
          'account[line_2]': {
            identifier: 'account[line_2]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Address 2'
            }
            ]
          },
          'account[street]': {
            identifier: 'account[street]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Street'
            }
            ]
          },
          'account[city]': {
            identifier: 'account[city]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter City/Municipality'
            }
            ]
          },
          'account[province]': {
            identifier: 'account[province]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Province'
            }
            ]
          },
          'account[region]': {
            identifier: 'account[region]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Region'
            }
            ]
          },
          'account[postal_code]': {
            identifier: 'account[postal_code]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Postal code'
            }
            ]
          },
          'account[country]': {
            identifier: 'account[country]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Country'
            }
            ]
          },
          'account[line_1_v2]': {
            identifier: 'account[line_1_v2]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Address 1'
            }
            ]
          },
          'account[line_2_v2]': {
            identifier: 'account[line_2_v2]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Address 2'
            }
            ]
          },
          'account[street_v2]': {
            identifier: 'account[street_v2]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Street'
            }
            ]
          },
          'account[city_v2]': {
            identifier: 'account[city_v2]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter City/Municipality'
            }
            ]
          },
          'account[province_v2]': {
            identifier: 'account[province_v2]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Province'
            }
            ]
          },
          'account[region_v2]': {
            identifier: 'account[region_v2]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Region'
            }
            ]
          },
          'account[postal_code_v2]': {
            identifier: 'account[postal_code_v2]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Postal code'
            }
            ]
          },
          'account[country_v2]': {
            identifier: 'account[country_v2]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter Country'
            }
            ]
          }
        }
      });
    }
  }

  account_address_validation()
});

// Contact
onmount('div[role="contact"]', function(){
  $('button[name="add_modal_contact"]').on('click', function(e){
    let type = $('select[name="account[type]"]').find(":selected").text().slice(10, 50);
    $('.ui.error.message').empty();

    if(type == "" || type == "Contact Person" || type == "Corp Signatory"){
      $('#AddContact').form({
        on: blur,
        inline: true,
        fields: {
          'account[type]': {
            identifier: 'account[type]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Contact type'
            },
            ]
          },
          'account[last_name]': {
            identifier: 'account[last_name]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Name'
            },
            ]
          },
          'account[mobile][]': {
            identifier: 'account[mobile][]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Mobile number'
            },
            ]
          },
          'account[email]': {
            identifier: 'account[email]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Email'
            },
            {
              type  : 'email',
              prompt: '{name} must be a valid e-mail'
            },
            {
              type: 'regExp',
              value: '^[-,_:a-zA-Z0-9()@.]+$',
              prompt: 'Please enter alphanumeric character'
             }
            ]
          }
        }
      })
    } else {
      $('div[role="form-mobile"]').find('div[role="mobile"]').removeClass("error")
      $('div[role="form-email"]').removeClass("error")
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()

      $('#AddContact').form({
        on: blur,
        inline: true,
        fields: {
          'account[type]': {
            identifier: 'account[type]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Contact type'
            },
            ]
          },
          'account[last_name]': {
            identifier: 'account[last_name]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Name'
            },
            ]
          },
          'account[email]': {
            identifier: 'account[email]',
            rules: [{
              type  : 'email',
              prompt: '{name} must be a valid e-mail'
            },
            {
              type: 'regExp',
              value: '^[-,_:a-zA-Z0-9()@.]+$',
              prompt: 'Please enter alphanumeric character'
             }
            ]
          }
        }
      })
    }
  })

  $('button[id="UpdateContact"]').on('click', function(){
    let type = $('select[name="account[type]"]').find(":selected").text().slice(10, 50);
    $('.ui.error.message').empty();

    if(type == "Select One" || type == "Contact Person" || type == "Corp Signatory"){
      $('#EditContact').form({
        on: blur,
        inline: true,
        fields: {
          'account[type]': {
            identifier: 'account[type]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Contact type'
            },
            ]
          },
          'account[last_name]': {
            identifier: 'account[last_name]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Name'
            },
            ]
          },
          'account[mobile][]': {
            identifier: 'account[mobile][]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Mobile number'
            },
            ]
          },
          'account[email]': {
            identifier: 'account[email]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Email'
            },
            {
              type  : 'email',
              prompt: '{name} must be a valid e-mail'
            },
            {
              type: 'regExp',
              value: '^[-,_:a-zA-Z0-9()@.]+$',
              prompt: 'Please enter alphanumeric character'
             }
            ]
          }
        }
      })
    } else {
      $('div[role="edit-mobile"]').find('div[role="mobile"]').removeClass("error")
      $('div[role="form-email"]').removeClass("error")
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()

      $('#EditContact').form({
        on: blur,
        inline: true,
        fields: {
          'account[type]': {
            identifier: 'account[type]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Contact type'
            },
            ]
          },
          'account[last_name]': {
            identifier: 'account[last_name]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Name'
            },
            ]
          },
          'account[email]': {
            identifier: 'account[email]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Email'
            },
            {
              type  : 'email',
              prompt: '{name} must be a valid e-mail'
            },
            {
              type: 'regExp',
              value: '^[-,_:a-zA-Z0-9()@.]+$',
              prompt: 'Please enter alphanumeric character'
             }
            ]
          }
        }
      })

    }
  })
})

//Financial
onmount('div[role="financial"]', function(){
  const csrf = $('input[name="_csrf_token"]').val();
  const account_tin = $('input[name="account[account_tin]"]').attr("dummy-val")

  $.ajax({
    url:`/get_all_account_tin`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      const data = JSON.parse(response)
      const array = $.map(data, function(value, index) {
        return [value.account_tin]
      });

      if(account_tin != undefined){
        array.splice($.inArray(account_tin, array),1)
      }

      $.fn.form.settings.rules.checkAccountTin= function(param) {
        return array.indexOf(param) == -1 ? true : false
      }

      $('#financial').form({
        on: blur,
        inline: true,
        fields: {
          'account[account_tin]': {
            identifier: 'account[account_tin]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Account Tin'
            },
            {
              type   : 'checkAccountTin[param]',
              prompt: 'Account TIN is already exist!'
            }
            ]
          },
          'account[mode_of_payment]': {
            identifier: 'account[mode_of_payment]',
            rules: [{
              type  : 'empty',
              prompt: 'Please choose a Mode of payment'
            },
            ]
          },
          'account[p_sched_of_payment]': {
            identifier: 'account[p_sched_of_payment]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Principal Schedule of Payment'
            },
            ]
          },
          'account[d_sched_of_payment]': {
            identifier: 'account[d_sched_of_payment]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Dependent Schedule of Payment'
            },
            ]
          },
          'account[threshold]': {
            identifier: 'account[threshold]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Replenish Threshold'
            },
            ]
          },
          'account[vat_status]': {
            identifier: 'account[vat_status]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter VAT status'
            }]
          },
          'account[payee_name]': {
            identifier: 'account[payee_name]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Payee name'
            }]
          },
          'account[approval_payee_name]': {
            identifier: 'approval_payee_name',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Payee name'
            },
            {
              type  : 'checkPayeeName[param]',
              prompt: 'Same payee name is required'
            }
            ]
          }
        }
      })
    },
    error: function(){}
  })

  $.fn.form.settings.rules.checkBankAccount= function(param) {
    let mode = $('#account_mode_of_payment').val()
    return mode == "Electronic Debit" && param == "" ? true : true
  }

  $.fn.form.settings.rules.checkPayeeName = function(param) {
    let payee_name = $('#account_payee_name').val()
    return payee_name === param ? true : false
  }

  $('#modal_financial').form({
    on: blur,
    inline: true,
    fields: {
      'account[approval_email]': {
        identifier: 'account[approval_email]',
        rules: [{
          type  : 'empty',
          prompt: 'Please enter Email'
        },
        {
          type  : 'email',
          prompt: '{name} must be a valid e-mail'
        }
       ]
      },
      'account[approval_name]': {
        identifier: 'account[approval_name]',
        rules: [{
          type  : 'empty',
          prompt: 'Please enter Name'
        }]
      },
      'account[approval_department]': {
        identifier: 'account[approval_department]',
        rules: [{
          type  : 'empty',
          prompt: 'Please enter Department'
        }]
      },
      'account[approval_mobile]': {
        identifier: 'account[approval_mobile]',
        rules: [{
          type  : 'empty',
          prompt: 'Please enter Mobile'
        }]
      },
    }
  })

})

