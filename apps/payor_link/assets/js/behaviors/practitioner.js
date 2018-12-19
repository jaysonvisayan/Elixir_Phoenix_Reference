onmount('div[role="add-practitioner-contact"]', function() {
  let validMobileNos = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994", "976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  $.fn.form.settings.rules.checkMobilePrefix = function(param) {
    return validMobileNos.indexOf(param.substring(0, 3)) == -1 ? false : true;
  }

 $('#formPractitionerContact').form({
    inline: true,
    fields: {
      // 'practitioner[telephone][]': {
      //   identifier: 'practitioner[telephone][]',
      //   optional: true,
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter the practitioner account telephone number'
      //   }]
      // },
      'practitioner[mobile][]': {
        identifier: 'practitioner[mobile][]',
        optional: true,
        rules: [
        // {
        //   type: 'exactLength[10]',
        //   prompt: 'Please enter a 10 digit number'
        // },
        {
          type: 'checkMobilePrefix[param]',
          prompt: 'Mobile Prefix is invalid'
        }
        ]
      },
      'practitioner[email][]': {
        identifier: 'practitioner[email][]',
        optional: true,
        rules: [{
          type: 'email',
          prompt: 'Please enter a valid email!'
        }]
      }
    }
  });

 $('#formPractitionerFacilityContact').form({
    inline: true,
    fields: {
      // 'practitioner[telephone][]': {
      //   identifier: 'practitioner[telephone][]',
      //   optional: true,
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter the practitioner account telephone number'
      //   }]
      // },
      'practitioner_facility[mobile][]': {
        identifier: 'practitioner_facility[mobile][]',
        optional: true,
        rules: [
        // {
        //   type: 'exactLength[10]',
        //   prompt: 'Please enter a 10 digit number'
        // },
        {
          type: 'checkMobilePrefix[param]',
          prompt: 'Mobile Prefix is invalid'
        }
        ]
      },
      'practitioner_facility[email][]': {
        identifier: 'practitioner_facility[email][]',
        optional: true,
        rules: [{
          type: 'email',
          prompt: 'Please enter a valid email!'
        }]
      }
    }
  });


  // let i = 1
  // $('.btnAddTelephone').click(function() {

  //   let telephoneHtml = $('div[role="form-telephone"]').html();
  //   let telephone = `<div class="two fields" role="form-telephone" index_tel="${i}" id="append-telephone">${telephoneHtml}</div>`

  //   $('p[role="append-telephone"]').append(telephone);

  //   let input_tel = $('div[index_tel="' + i + '"]').find('div').find('input')
  //   i++;

  //   $('div[id="append-telephone"]').find('a').removeAttr("add");
  //   $('div[id="append-telephone"]').find('a').attr("remove", "telephone");
  //   $('div[id="append-telephone"]').find('a').attr("class", "ui icon basic button");
  //   $('div[id="append-telephone"]').find('a').html(`<i class="trash icon"></i>`);
  //   $('div[id="append-telephone"]').find('label').remove();
  //   $('div[id="append-telephone"]').find('a').addClass('btnTelephoneRemove');
  //   input_tel.val("");

  //   var Inputmask = require('inputmask');
  //   var tele = new Inputmask("999-99-99", { "clearIncomplete": true });
  //   tele.mask($('.phone'));

  //   $('div[role="form-telephone"]').on('click', 'a[remove="telephone"]', function(e) {
  //     $(this).closest('div[id="append-telephone"]').remove();
  //   });
  // });
  // $('div[role="form-telephone"]').on('click', 'a[remove="telephone"]', function(e) {
  //   $(this).closest('div[role="form-telephone"]').remove();
  // });

  // let f = 1

  // $('.btnAddFax').click(function() {
  //   let faxHtml = $('div[role="form-fax"]').html();
  //   let fax = `<div class="two fields" role="form-fax" index_fax="${f}" id="append-fax">${faxHtml}</div>`
  //   $('p[role="append-fax"]').append(fax);
  //   let input_fax = $('div[index_fax="' + f + '"]').find('div').find('input')
  //   f++;

  //   $('div[id="append-fax"]').find('a').removeAttr("add");
  //   $('div[id="append-fax"]').find('a').attr("remove", "fax");
  //   $('div[id="append-fax"]').find('a').attr("class", "ui icon basic button");
  //   $('div[id="append-fax"]').find('a').html(`<i class="trash icon"></i>`);
  //   $('div[id="append-fax"]').find('label').remove();
  //   $('div[id="append-fax"]').find('a').addClass('btnFaxRemove');
  //   input_fax.val("");

  //   var Inputmask = require('inputmask');
  //   var tele = new Inputmask("999-99-99", { "clearIncomplete": true });
  //   tele.mask($('.phone'));

  //   $('div[role="form-fax"]').on('click', 'a[remove="fax"]', function(e) {
  //     $(this).closest('div[id="append-fax"]').remove();
  //   });
  // });
  // $('div[role="form-fax"]').on('click', 'a[remove="fax"]', function(e) {
  //   $(this).closest('div[role="form-fax"]').remove();
  // });

  // let m = 1
  // $('.btnAddMobile').click(function() {
  //   let mobileHtml = $('div[role="form-mobile"]').html();
  //   let mobile = `<div class="two fields" role="form-mobile" index_mobile="${m}" id="append-mobile">${mobileHtml}</div>`
  //   $('p[role="append-mobile"]').append(mobile);
  //   let input_mobile = $('div[index_mobile="' + m + '"]').find('div').find('input')
  //   m++;

  //   $('div[id="append-mobile"]').find('a').removeAttr("add");
  //   $('div[id="append-mobile"]').find('a').attr("remove", "mobile");
  //   $('div[id="append-mobile"]').find('a').attr("class", "ui icon basic button");
  //   $('div[id="append-mobile"]').find('a').html(`<i class="trash icon"></i>`);
  //   $('div[id="append-mobile"]').find('label').remove();
  //   $('div[id="append-mobile"]').find('a').addClass('btnMobileRemove');
  //   input_mobile.val("");

  //   var Inputmask = require('inputmask');
  //   var tele = new Inputmask("0\\999-999-99-99", { "clearIncomplete": true });
  //   tele.mask($('.mobile'));


  //   $('div[role="form-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
  //     $(this).closest('div[id="append-mobile"]').remove();
  //   });
  // });
  // $('div[role="form-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
  //   $(this).closest('div[role="form-mobile"]').remove();
  // });

  // let e = 1
  // $('.btnAddEmail').click(function() {
  //   let emailHtml = $('div[role="form-email"]').html();
  //   let email = `<div class="two fields" role="form-email" index_email="${e}" id="append-email">${emailHtml}</div>`
  //   $('p[role="append-email"]').append(email);
  //   let input_email = $('div[index_email="' + e + '"]').find('div').find('input')
  //   e++;

  //   $('div[id="append-email"]').find('a').removeAttr("add");
  //   $('div[id="append-email"]').find('a').attr("remove", "email");
  //   $('div[id="append-email"]').find('a').attr("class", "ui  icon basic button");
  //   $('div[id="append-email"]').find('a').html(`<i class="trash icon"></i>`);
  //   $('div[id="append-email"]').find('label').remove();
  //   $('div[id="append-email"]').find('a').addClass('btnEmailRemove');
  //   input_email.val("");

  //   $('div[role="form-email"]').on('click', 'a[remove="email"]', function(e) {
  //     $(this).closest('div[id="append-email"]').remove();
  //   });
  // });
  // $('div[role="form-email"]').on('click', 'a[remove="email"]', function(e) {
  //   $(this).closest('div[role="form-email"]').remove();
  // });
});

onmount('div[id="practitioner_new_financial"]', function() {
  if ($('#radio_bank').prop('checked')) {
    $('#bank').attr('disabled', false)
    $('#account_no').attr('disabled', false)
    $('#card').attr('disabled', 'disabled')
    $('#check').attr('disabled', 'disabled')
    $('#payment_bank').removeClass('display-none');
    $('#payment_card').addClass('display-none');
    $('#payment_check').addClass('display-none');
    $('#item-bank').removeClass('bg-gray');
    $('#item-bank').addClass('item');
    $('#item-card').addClass('bg-gray');
    $('#item-check').addClass('bg-gray');
  } else if ($('#radio_card').prop('checked')) {
    $('#bank').attr('disabled', 'disabled')
    $('#account_no').attr('disabled', 'disabled')
    $('#card').attr('disabled', false)
    $('#check').attr('disabled', 'disabled')
    $('#payment_card').removeClass('display-none');
    $('#payment_bank').addClass('display-none');
    $('#payment_check').addClass('display-none');
    $('#item-card').removeClass('bg-gray');
    $('#item-card').addClass('item');
    $('#item-bank').addClass('bg-gray');
    $('#item-check').addClass('bg-gray');
  } else if ($('#radio_check').prop('checked')) {
    $('#bank').attr('disabled', 'disabled')
    $('#account_no').attr('disabled', 'disabled')
    $('#card').attr('disabled', 'disabled')
    $('#check').attr('disabled', false)
    $('#payment_check').removeClass('display-none');
    $('#payment_card').addClass('display-none');
    $('#payment_bank').addClass('display-none');
    $('#item-check').removeClass('bg-gray');
    $('#item-check').addClass('item');
    $('#item-card').addClass('bg-gray');
    $('#item-bank').addClass('bg-gray');
  }
  $('#bank_radio').on('click', function() {
    $('#card').val('')
    $('#check').val('')
    $('#bank').attr("disabled", false)
    $('#account_no').attr("disabled", false)
    $('#card').attr("disabled", "disabled")
    $('#check').attr("disabled", "disabled")
    $('div[id="bank_field"]').find('.ui.dropdown').removeClass('disabled')
    $('div[id="bank_field"]').find('.ui.dropdown').val('')
    $('#payment_bank').removeClass('display-none');
    $('#payment_card').addClass('display-none');
    $('#payment_check').addClass('display-none');
    $('#item-bank').removeClass('bg-gray');
    $('#item-bank').addClass('item');
    $('#item-card').addClass('bg-gray');
    $('#item-check').addClass('bg-gray');
  });
  $('#card_radio').on('click', function() {
    $('#bank').val('')
    $('#account_no').val('')
    $('#check').val('')
    $('#card').attr("disabled", false)
    $('#bank').attr("disabled", "disabled")
    $('#account_no').attr("disabled", "disabled")
    $('#check').attr("disabled", "disabled")
    $('div[id="bank_field"]').find('.ui.dropdown').addClass('disabled')
    $('#payment_card').removeClass('display-none');
    $('#payment_bank').addClass('display-none');
    $('#payment_check').addClass('display-none');
    $('#item-card').removeClass('bg-gray');
    $('#item-card').addClass('item');
    $('#item-check').addClass('bg-gray');
    $('#item-bank').addClass('bg-gray');
  });
  $('#check_radio').on('click', function() {
    $('#bank').val('')
    $('#account_no').val('')
    $('#card').val('')
    $('#check').attr("disabled", false)
    $('#bank').attr("disabled", "disabled")
    $('#account_no').attr("disabled", "disabled")
    $('#card').attr("disabled", "disabled")
    $('div[id="bank_field"]').find('.ui.dropdown').addClass('disabled')
    $('#payment_check').removeClass('display-none');
    $('#payment_bank').addClass('display-none');
    $('#item-check').removeClass('bg-gray');
    $('#item-check').addClass('item');
    $('#item-card').addClass('bg-gray');
    $('#item-bank').addClass('bg-gray');
  });
});

onmount('div[id="practitioner_edit_financial"]', function() {

  if ($('#radio_bank').prop('checked')) {
    $('#bank').attr('disabled', false)
    $('#account_no').attr('disabled', false)
    $('#card').attr('disabled', 'disabled')
    $('#check').attr('disabled', 'disabled')
    $('#payment_bank').removeClass('display-none');
    $('#payment_card').addClass('display-none');
    $('#payment_check').addClass('display-none');
    $('#item-bank').removeClass('bg-gray');
    $('#item-bank').addClass('item');
    $('#item-card').addClass('bg-gray');
    $('#item-check').addClass('bg-gray');
  } else if ($('#radio_card').prop('checked')) {
    $('#bank').attr('disabled', 'disabled')
    $('#account_no').attr('disabled', 'disabled')
    $('#card').attr('disabled', false)
    $('#check').attr('disabled', 'disabled')
    $('#payment_card').removeClass('display-none');
    $('#payment_bank').addClass('display-none');
    $('#payment_check').addClass('display-none');
    $('#item-card').removeClass('bg-gray');
    $('#item-card').addClass('item');
    $('#item-bank').addClass('bg-gray');
    $('#item-check').addClass('bg-gray');
  } else if ($('#radio_check').prop('checked')) {
    $('#bank').attr('disabled', 'disabled')
    $('#account_no').attr('disabled', 'disabled')
    $('#card').attr('disabled', 'disabled')
    $('#check').attr('disabled', false)
    $('#payment_check').removeClass('display-none');
    $('#payment_card').addClass('display-none');
    $('#payment_bank').addClass('display-none');
    $('#item-check').removeClass('bg-gray');
    $('#item-check').addClass('item');
    $('#item-card').addClass('bg-gray');
    $('#item-bank').addClass('bg-gray');
  }
  $('#bank_radio').on('click', function() {
    $('#card').val('')
    $('#check').val('')
    $('#bank').attr("disabled", false)
    $('#account_no').attr("disabled", false)
    $('#card').attr("disabled", "disabled")
    $('#check').attr("disabled", "disabled")
    $('div[id="bank_field"]').find('.ui.dropdown').removeClass('disabled')
    $('div[id="bank_field"]').find('.ui.dropdown').val('')
    $('#payment_bank').removeClass('display-none');
    $('#payment_card').addClass('display-none');
    $('#payment_check').addClass('display-none');
    $('#item-bank').removeClass('bg-gray');
    $('#item-bank').addClass('item');
    $('#item-card').addClass('bg-gray');
    $('#item-check').addClass('bg-gray');
  });
  $('#card_radio').on('click', function() {
    $('#bank').val('')
    $('#account_no').val('')
    $('#check').val('')
    $('#card').attr("disabled", false)
    $('#bank').attr("disabled", "disabled")
    $('#account_no').attr("disabled", "disabled")
    $('#check').attr("disabled", "disabled")
    $('div[id="bank_field"]').find('.ui.dropdown').addClass('disabled')
    $('#payment_card').removeClass('display-none');
    $('#payment_bank').addClass('display-none');
    $('#payment_check').addClass('display-none');
    $('#item-card').removeClass('bg-gray');
    $('#item-card').addClass('item');
    $('#item-check').addClass('bg-gray');
    $('#item-bank').addClass('bg-gray');
  });
  $('#check_radio').on('click', function() {
    $('#bank').val('')
    $('#account_no').val('')
    $('#card').val('')
    $('#check').attr("disabled", false)
    $('#bank').attr("disabled", "disabled")
    $('#account_no').attr("disabled", "disabled")
    $('#card').attr("disabled", "disabled")
    $('div[id="bank_field"]').find('.ui.dropdown').addClass('disabled')
    $('#payment_check').removeClass('display-none');
    $('#payment_bank').addClass('display-none');
    $('#item-check').removeClass('bg-gray');
    $('#item-check').addClass('item');
    $('#item-card').addClass('bg-gray');
    $('#item-bank').addClass('bg-gray');
    ind('.ui.dropdown').addClass('disabled')
  });
});

onmount('div[name="formValidateGeneral"]', function() {

  $.fn.form.settings.rules.validDateFormat = function(param) {
    if (param != '') {
      return moment(param, 'MM-DD-YYYY').isValid();
    } else {
      return true;
    }
  }

  if ($('#practitioner_affiliated_No').prop('checked')) {
    $('#eff_from').val('')
    $('#eff_to').val('')
    $('#eff_from').attr('disabled', 'disabled')
    $('#eff_to').attr('disabled', 'disabled')
  }

  $('#affiliated_no').on('click', function() {
    $('#eff_from').val('')
    $('#eff_to').val('')
    $('#eff_from').attr('disabled', 'disabled')
    $('#eff_to').attr('disabled', 'disabled')
  })

  $('#affiliated_yes').on('click', function() {
    $('#eff_from').attr('disabled', false)
    $('#eff_to').attr('disabled', false)
  })

  //Practitioner Validations start
  $('#formPractitionerGeneral').form({
    on: blur,
    inline: true,
    fields: {
      'practitioner[first_name]': {
        identifier: 'practitioner[first_name]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter first name'
        },
        {
          type: 'minLength[2]',
          prompt: 'Your first name must be at least {ruleValue} characters'
        }
        ]
      },
      'practitioner[last_name]': {
        identifier: 'practitioner[last_name]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter last name'
        },
        {
          type: 'minLength[2]',
          prompt: 'Your last name must be at least {ruleValue} characters'
        }
        ]
      },
      'practitioner[birth_date]': {
        identifier: 'practitioner[birth_date]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter birth date'
        }]
      },
      'practitioner[gender]': {
        identifier: 'practitioner[gender]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter gender'
        }]
      },
      'practitioner[prc_no]': {
        identifier: 'practitioner[prc_no]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter PRC No.'
        },
        {
          type: 'minLength[7]',
          prompt: 'Your PRC No. must be at least {ruleValue} characters'
        }
        ]
      },
      'practitioner[affiliated]': {
        identifier: 'practitioner[affiliated]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter if affiliated'
        }]
      },
      'practitioner[effectivity_from]': {
        identifier: 'practitioner[effectivity_from]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter effectivity date'
        }
        ]
      },
      'practitioner[effectivity_to]': {
        identifier: 'practitioner[effectivity_to]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter expiry date'
        }
        ]
      },
      'practitioner[specialization_ids][]': {
        identifier: 'practitioner[specialization_ids][]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter specialization'
        }]
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
          type: 'empty',
          prompt: 'This is a required field'
        },
        {
          type: 'minLength[2]',
          prompt: 'Your first name must be at least {ruleValue} characters'
        }
        ]
      },
      'practitioner[last_name]': {
        identifier: 'practitioner[last_name]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        },
        {
          type: 'minLength[2]',
          prompt: 'Your last name must be at least {ruleValue} characters'
        }
        ]
      },
      'practitioner[birth_date]': {
        identifier: 'practitioner[birth_date]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        }]
      },
      'practitioner[gender]': {
        identifier: 'practitioner[gender]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        }]
      },
      'practitioner[prc_no]': {
        identifier: 'practitioner[prc_no]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        },
        {
          type: 'minLength[7]',
          prompt: 'Your PRC No. must be at least {ruleValue} characters'
        }
        ]
      },
      'practitioner[affiliated]': {
        identifier: 'practitioner[affiliated]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        }]
      },
      'practitioner[effectivity_from]': {
        identifier: 'practitioner[effectivity_from]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        }]
      },
      'practitioner[effectivity_to]': {
        identifier: 'practitioner[effectivity_to]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        }]
      },
      'practitioner[specialization_ids][]': {
        identifier: 'practitioner[specialization_ids][]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        }]
      }
    }
  });

    $('select[name="practitioner[specialization_ids][]"]').on('change', function(){
      $('select[name="practitioner[sub_specialization_ids][]"]').find('option').remove()
      $('select[name="practitioner[sub_specialization_ids][]"]').dropdown();
      loadSubSpecializationOptions()
    })

    function loadSubSpecializationOptions() {
      let csrf = $('input[name="_csrf_token"]').val();
      let s_id = $('select[name="practitioner[specialization_ids][]"]').val()
      $('select[name="practitioner[sub_specialization_ids][]"]').dropdown('clear')

      $.ajax({
        url:`/practitioners/${s_id}/load_specializations`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'GET',
        success: function(response){
          $('select[name="practitioner[sub_specialization_ids][]"]').find('option').remove()
          $('select[name="practitioner[sub_specialization_ids][]"]').dropdown();
          for (let s of response.specialization) {
            let new_row = `<option value="${s.id}">${s.name}</option>`
            $('select[name="practitioner[sub_specialization_ids][]"]').append(new_row)
          }
          $('select[name="practitioner[sub_specialization_ids][]"]').dropdown();
        }
      });
    }

});

onmount('div[name="formValidateContact"]', function() {
  let validMobileNos = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994", "976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  $.fn.form.settings.rules.checkMobilePrefix = function(param) {
    return validMobileNos.indexOf(param.substring(1, 4)) == -1 ? false : true;
  }

  $('#prac_modal_contact').form({
    on: blur,
    inline: true,
    fields: {
      'practitioner[mobile][]': {
        identifier: 'practitioner[mobile][]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        },
        {
          type: 'minLength[11]',
          prompt: 'Must be at least {ruleValue} numbers'
        },
        {
          type: 'checkMobilePrefix[param]',
          prompt: 'Mobile prefix is invalid.'
        }
        ]
      },
      'practitioner[email][]': {
        identifier: 'practitioner[email][]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        }]
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
          type: 'empty',
          prompt: 'This is a required field'
        },
        {
          type: 'minLength[11]',
          prompt: 'Must be at least {ruleValue} numbers'
        },
        {
          type: 'checkMobilePrefix[param]',
          prompt: 'Mobile prefix is invalid.'
        }
        ]
      },
      'practitioner[email]': {
        identifier: 'practitioner[email]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        }]
      }
    }
  });
});

onmount('div[name="formValidatePractitionerFinancial"]', function() {
  $('#formPractitionerFinancial').form({
    on: blur,
    inline: true,
    fields: {
      'practitioner[tin]': {
        identifier: 'practitioner[tin]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter TIN'
        },
        {
          type: 'exactLength[12]',
          prompt: 'TIN must be {ruleValue} characters'
        }
        ]
      },
      'practitioner[vat_status]': {
        identifier: 'practitioner[vat_status]',
        rules: [{
          type: 'empty',
          prompt: 'Please select VAT Status'
        }]
      },
      'practitioner[bank_id]': {
        identifier: 'practitioner[bank_id]',
        rules: [{
          type: 'empty',
          prompt: 'Please select Bank name'
        }]
      },
      'practitioner[account_no]': {
        identifier: 'practitioner[account_no]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter account number'
        },
        {
          type: 'exactLength[16]',
          prompt: 'Account no. must be {ruleValue} characters'
        }
        ]
      },
      'practitioner[xp_card_no]': {
        identifier: 'practitioner[xp_card_no]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter MediLinkXP Card number'
        },
        {
          type: 'exactLength[16]',
          prompt: 'Card no. must be {ruleValue} characters'
        }
        ]
      },
      'practitioner[payee_name]': {
        identifier: 'practitioner[payee_name]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Payee Name'
        }]
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
          type: 'empty',
          prompt: 'This is a required field'
        },
        {
          type: 'exactLength[12]',
          prompt: 'TIN must be {ruleValue} characters'
        }
        ]
      },
      'practitioner[vat_status]': {
        identifier: 'practitioner[vat_status]',
        rules: [{
          type: 'empty',
          prompt: 'This is a required field'
        }]
      },
      'practitioner[account_name]': {
        identifier: 'practitioner[account_name]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Bank name'
        }]
      },
      'practitioner[account_no]': {
        identifier: 'practitioner[account_no]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter account number'
        },
        {
          type: 'exactLength[16]',
          prompt: 'Account no. must be {ruleValue} characters'
        }
        ]
      },
      'practitioner[xp_card_no]': {
        identifier: 'practitioner[xp_card_no]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter MediLinkXP Card number'
        },
        {
          type: 'exactLength[16]',
          prompt: 'Card no. must be {ruleValue} characters'
        }
        ]
      },
      'practitioner[payee_name]': {
        identifier: 'practitioner[payee_name]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Payee Name'
        }]
      }
    }
  });
});

onmount('div[id="formStep1PractitionerAccount"]', function() {
  let validMobileNos = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994", "976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  $.fn.form.settings.rules.checkMobilePrefix = function(param) {
    return validMobileNos.indexOf(param.substring(1, 4)) == -1 ? false : true;
  }

  $(this).form({
    inline: true,
    fields: {
      'practitioner_account[telephone][]': {
        identifier: 'practitioner_account[telephone][]',
        optional: true,
        rules: [{
          type: 'empty',
          prompt: 'Please enter the practitioner account telephone number'
        }]
      },
      'practitioner_account[mobile][]': {
        identifier: 'practitioner_account[mobile][]',
        optional: true,
        rules: [{
          type: 'empty',
          prompt: 'Please enter the practitioner account mobile number'
        },
        {
          type: 'checkMobilePrefix[params]',
          prompt: 'Mobile prefix is invalid'
        }
        ]
      },
      'practitioner_account[email][]': {
        optional: true,
        identifier: 'practitioner_account[email][]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter the practitioner account email'
        },
        {
          type: 'email',
          prompt: 'Email is invalid'
        }
        ]
      }
    }
  });
  let i = 1
  $('.btnAddTelephone').click(function() {

    let telephoneHtml = $('div[role="form-telephone"]').html();
    let telephone = `<div class="two fields" role="form-telephone" index_tel="${i}" id="append-telephone">${telephoneHtml}</div>`

    $('p[role="append-telephone"]').append(telephone);

    let input_tel = $('div[index_tel="' + i + '"]').find('div').find('input')
    i++;

    $('div[id="append-telephone"]').find('a').removeAttr("add");
    $('div[id="append-telephone"]').find('a').attr("remove", "telephone");
    $('div[id="append-telephone"]').find('a').attr("class", "small ui red button");
    $('div[id="append-telephone"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-telephone"]').find('label').remove();
    $('div[id="append-telephone"]').find('a').addClass('btnTelephoneRemove');
    input_tel.val("");

    var Inputmask = require('inputmask');
    var tele = new Inputmask("999-99-99", { "clearIncomplete": true });
    tele.mask($('.phone'));

    $('div[role="form-telephone"]').on('click', 'a[remove="telephone"]', function(e) {
      $(this).closest('div[id="append-telephone"]').remove();
    });
  });
  $('div[role="form-telephone"]').on('click', 'a[remove="telephone"]', function(e) {
    $(this).closest('div[role="form-telephone"]').remove();
  });

  let f = 1

  $('.btnAddFax').click(function() {
    let faxHtml = $('div[role="form-fax"]').html();
    let fax = `<div class="two fields" role="form-fax" index_fax="${f}" id="append-fax">${faxHtml}</div>`
    $('p[role="append-fax"]').append(fax);
    let input_fax = $('div[index_fax="' + f + '"]').find('div').find('input')
    f++;

    $('div[id="append-fax"]').find('a').removeAttr("add");
    $('div[id="append-fax"]').find('a').attr("remove", "fax");
    $('div[id="append-fax"]').find('a').attr("class", "small ui red button");
    $('div[id="append-fax"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-fax"]').find('label').remove();
    $('div[id="append-fax"]').find('a').addClass('btnFaxRemove');
    input_fax.val("");

    var Inputmask = require('inputmask');
    var tele = new Inputmask("999-99-99", { "clearIncomplete": true });
    tele.mask($('.phone'));

    $('div[role="form-fax"]').on('click', 'a[remove="fax"]', function(e) {
      $(this).closest('div[id="append-fax"]').remove();
    });
  });
  $('div[role="form-fax"]').on('click', 'a[remove="fax"]', function(e) {
    $(this).closest('div[role="form-fax"]').remove();
  });

  let m = 1
  $('.btnAddMobile').click(function() {
    let mobileHtml = $('div[role="form-mobile"]').html();
    let mobile = `<div class="two fields" role="form-mobile" index_mobile="${m}" id="append-mobile">${mobileHtml}</div>`
    $('p[role="append-mobile"]').append(mobile);
    let input_mobile = $('div[index_mobile="' + m + '"]').find('div').find('input')
    m++;

    $('div[id="append-mobile"]').find('a').removeAttr("add");
    $('div[id="append-mobile"]').find('a').attr("remove", "mobile");
    $('div[id="append-mobile"]').find('a').attr("class", "small ui red button");
    $('div[id="append-mobile"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-mobile"]').find('label').remove();
    $('div[id="append-mobile"]').find('a').addClass('btnMobileRemove');
    input_mobile.val("");

    var Inputmask = require('inputmask');
    var tele = new Inputmask("0\\999-999-99-99", { "clearIncomplete": true });
    tele.mask($('.mobile'));


    $('div[role="form-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
      $(this).closest('div[id="append-mobile"]').remove();
    });
  });
  $('div[role="form-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
    $(this).closest('div[role="form-mobile"]').remove();
  });

  let e = 1
  $('.btnAddEmail').click(function() {
    let emailHtml = $('div[role="form-email"]').html();
    let email = `<div class="two fields" role="form-email" index_email="${e}" id="append-email">${emailHtml}</div>`
    $('p[role="append-email"]').append(email);
    let input_email = $('div[index_email="' + e + '"]').find('div').find('input')
    e++;

    $('div[id="append-email"]').find('a').removeAttr("add");
    $('div[id="append-email"]').find('a').attr("remove", "email");
    $('div[id="append-email"]').find('a').attr("class", "small ui red button");
    $('div[id="append-email"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-email"]').find('label').remove();
    $('div[id="append-email"]').find('a').addClass('btnEmailRemove');
    input_email.val("");

    $('div[role="form-email"]').on('click', 'a[remove="email"]', function(e) {
      $(this).closest('div[id="append-email"]').remove();
    });
  });
  $('div[role="form-email"]').on('click', 'a[remove="email"]', function(e) {
    $(this).closest('div[role="form-email"]').remove();
  });
});

onmount('div[id="showPractitioner"]', function() {
  $('#logsModal').modal('attach events', '#logs', 'show')

  $('p[class="log-date"]').each(function() {
    let date = $(this).html();
    $(this).html(moment(date).format("MMM D, YYYY"));
  })

});

onmount('div[id="edit_practitioner"]', function() {
  $(this).find($('input')).on('change', function() {
    $('a[id="edit_cancel_button"]').click(function(e) {
      $('#modal_cancel').modal('show')
      e.preventDefault()
    })
  })

});

onmount('div[role="practitioner-datepicker"]', function() {
  $('#eff_from').val(moment($('input[name="practitioner[hidden_eff]"]').val()).format("MM-DD-YYYY"));
  $('#eff_to').val(moment($('input[name="practitioner[hidden_exp]"]').val()).format("MM-DD-YYYY"));
  $('#prac_eff_from').calendar({
    type: 'date',
    onChange: function(start_date, text, mode) {
      start_date = moment(start_date).add(1, 'year').calendar()
      start_date = moment(start_date).format("MM-DD-YYYY")
      $('input[name="practitioner[effectivity_to]"]').val(start_date)
      $('#prac_eff_to').calendar("set date", start_date);
    },
    formatter: {
      date: function(date, settings) {
        var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
        ];
        var day = date.getDate();
        var monthIndex = date.getMonth();
        var year = date.getFullYear();

        return monthNames[monthIndex] + ' ' + day + ', ' + year;
      }
    }
  });

  $('#prac_eff_to').calendar({
    type: 'date',
    startCalendar: $('#prac_eff_from'),
    formatter: {
      date: function(date, settings) {
        var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
        ];
        var day = date.getDate();
        var monthIndex = date.getMonth();
        var year = date.getFullYear();

        return monthNames[monthIndex] + ' ' + day + ', ' + year;
      }
    }
  });

  $('#practitioner_birth_date').val(moment($('input[name="practitioner[hidden_birth_date]"]').val()).format("MM-DD-YYYY"));
  let today = new Date()
  $('#birthdate1').calendar({
    type: 'date',
    maxDate: new Date(today.getFullYear(), "", ""),
    formatter: {
      date: function(date, settings) {
        var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
        ];
        var day = date.getDate();
        var monthIndex = date.getMonth();
        var year = date.getFullYear();

        return monthNames[monthIndex] + ' ' + day + ', ' + year;
      }
    }
  })
});

onmount('div[id="phic-datepicker-container"]', function() {
  $('#phic-datepicker').val(moment($('input[name="practitioner[hidden_phic_date]"]').val()).format("MM-DD-YYYY"));
  $('.phic_no').on('change', function(){
    $('#phic-datepicker').attr("disabled", true)

    $('#phic-datepicker-container > div.field.error > div.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });
    $('#phic_container').removeClass("error");
  })
  $('.phic_yes').on('change', function(){
    $('#phic-datepicker').attr("disabled", false)
    formPractitionerGeneralWithPHIC()
    formPractitionerGeneralEditWithPHIC()
  })

  let today = new Date()
  $('#prac_phic_date').calendar({
    type: 'date',
    maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
    formatter: {
      date: function(date, settings) {
        var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
        ];
        var day = date.getDate();
        var monthIndex = date.getMonth();
        var year = date.getFullYear();

        return monthNames[monthIndex] + ' ' + day + ', ' + year;
      }
    }
  });

  function formPractitionerGeneralWithPHIC(){
    $('#formPractitionerGeneral').form({
      on: blur,
      inline: true,
      fields: {
        'practitioner[first_name]': {
          identifier: 'practitioner[first_name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter first name'
          },
          {
            type: 'minLength[2]',
            prompt: 'Your first name must be at least {ruleValue} characters'
          }
          ]
        },
        'practitioner[last_name]': {
          identifier: 'practitioner[last_name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter last name'
          },
          {
            type: 'minLength[2]',
            prompt: 'Your last name must be at least {ruleValue} characters'
          }
          ]
        },
        'practitioner[birth_date]': {
          identifier: 'practitioner[birth_date]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter birth date'
          }]
        },
        'practitioner[gender]': {
          identifier: 'practitioner[gender]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter gender'
          }]
        },
        'practitioner[prc_no]': {
          identifier: 'practitioner[prc_no]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter PRC No.'
          },
          {
            type: 'minLength[7]',
            prompt: 'Your PRC No. must be at least {ruleValue} characters'
          }
          ]
        },
        'practitioner[affiliated]': {
          identifier: 'practitioner[affiliated]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter if affiliated'
          }]
        },
        'practitioner[phic_date]': {
          identifier: 'practitioner[phic_date]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter PHIC Accreditation Date'
          }]
        },
        'practitioner[effectivity_from]': {
          identifier: 'practitioner[effectivity_from]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter effectivity date'
          }]
        },
        'practitioner[effectivity_to]': {
          identifier: 'practitioner[effectivity_to]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter expiry date'
          }
          ]
        },
        'practitioner[specialization_ids][]': {
          identifier: 'practitioner[specialization_ids][]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter specialization'
          }]
        }
      }
    });

  }


  function formPractitionerGeneralEditWithPHIC(){
    $('#formPractitionerGeneralEdit').form({
      on: blur,
      inline: true,
      fields: {
        'practitioner[first_name]': {
          identifier: 'practitioner[first_name]',
          rules: [{
            type: 'empty',
            prompt: 'This is a required field'
          },
          {
            type: 'minLength[2]',
            prompt: 'Your first name must be at least {ruleValue} characters'
          }
          ]
        },
        'practitioner[last_name]': {
          identifier: 'practitioner[last_name]',
          rules: [{
            type: 'empty',
            prompt: 'This is a required field'
          },
          {
            type: 'minLength[2]',
            prompt: 'Your last name must be at least {ruleValue} characters'
          }
          ]
        },
        'practitioner[birth_date]': {
          identifier: 'practitioner[birth_date]',
          rules: [{
            type: 'empty',
            prompt: 'This is a required field'
          }]
        },
        'practitioner[gender]': {
          identifier: 'practitioner[gender]',
          rules: [{
            type: 'empty',
            prompt: 'This is a required field'
          }]
        },
        'practitioner[prc_no]': {
          identifier: 'practitioner[prc_no]',
          rules: [{
            type: 'empty',
            prompt: 'This is a required field'
          },
          {
            type: 'minLength[7]',
            prompt: 'Your PRC No. must be at least {ruleValue} characters'
          }
          ]
        },
        'practitioner[affiliated]': {
          identifier: 'practitioner[affiliated]',
          rules: [{
            type: 'empty',
            prompt: 'This is a required field'
          }]
        },
        'practitioner[phic_date]': {
          identifier: 'practitioner[phic_date]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter PHIC Accreditation Date'
          }]
        },
        'practitioner[effectivity_from]': {
          identifier: 'practitioner[effectivity_from]',
          rules: [{
            type: 'empty',
            prompt: 'This is a required field'
          }]
        },
        'practitioner[effectivity_to]': {
          identifier: 'practitioner[effectivity_to]',
          rules: [{
            type: 'empty',
            prompt: 'This is a required field'
          }
          ]
        },
        'practitioner[specialization_ids][]': {
          identifier: 'practitioner[specialization_ids][]',
          rules: [{
            type: 'empty',
            prompt: 'This is a required field'
          }]
        }
      }
    });
  }

});


onmount('div[role="print_practitioner"]', function() {
  $('div[role="print_practitioner').click(function() {
    let prac_id = $(this).attr('pracID')
    window.open(`/practitioners/${prac_id}/print_summary`, '_blank')
  });
});
