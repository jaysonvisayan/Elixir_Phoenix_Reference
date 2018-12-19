onmount('div[role="facility-onchange"]', function () {
  if ($('input[name="facility[status]"]:checked').val() == "Pending") {
    $('#facility_affiliation_date').prop('disabled', true);
  } else {
    $('#facility_affiliation_date').prop('disabled', false);
  }

  $('input[name="facility[status]"]').on('change', function(){
    $('div[id="formStep1Facility"]').find('.error').removeClass('error').find('.prompt').remove();

    if ($('input[name="facility[status]"]:checked').val() == "Pending") {
      $('#facility_affiliation_date').prop('disabled', true);
      $('#facility_disaffiliation_date').prop('disabled', true);
      $('#facility_affiliation_date').val("");
      $('#facility_disaffiliation_date').val("");
    } else {
      $('#facility_affiliation_date').prop('disabled', false);
      $('#facility_disaffiliation_date').prop('disabled', false);
    }
  });

  $('select[name="facility[payment_mode_id]"]').on('change', function(){
    let selected_text = $('#facility_payment_mode_id option:selected').text()
    if (selected_text == 'Check') {
      $('input[name="facility[authority_to_credit]"]').prop('disabled', true)
      $('#addFile').prop('disabled', true)
      $("#facility_authority_to_credit_true").prop('checked', true)
      $('input[name="facility[payee_name]"]').prop('disabled', false)
      $('input[name="facility[bank_account_no]"]').val('')
      $('input[name="facility[bank_account_no]"]').prop('disabled', true)
    } else if (selected_text == 'Auto-Credit') {
      $('input[name="facility[authority_to_credit]"]').prop('disabled', false)
      $('#addFile').prop('disabled', false)
      $('input[name="facility[payee_name]"]').val('')
      $('input[name="facility[payee_name]"]').prop('disabled', true)
      $('input[name="facility[bank_account_no]"]').prop('disabled', false)
    } else if (selected_text == 'Bank') {
      $('input[name="facility[authority_to_credit]"]').prop('disabled', true)
      $('#addFile').prop('disabled', true)
      $("#facility_authority_to_credit_true").prop('checked', true)
      $('input[name="facility[payee_name]"]').val('')
      $('input[name="facility[payee_name]"]').prop('disabled', true)
      $('input[name="facility[bank_account_no]"]').prop('disabled', false)
    }
  })

  if ($('#facility_payment_mode_id option:selected').text() == 'Check') {
    $('input[name="facility[authority_to_credit]"]').prop('disabled', true)
    $('#addFile').prop('disabled', true)
    $('input[name="facility[payee_name]"]').prop('disabled', false)
    $('input[name="facility[bank_account_no]"]').val('')
    $('input[name="facility[bank_account_no]"]').prop('disabled', true)
  } else if ($('#facility_payment_mode_id option:selected').text() == 'Auto-Credit') {
    $('input[name="facility[authority_to_credit]"]').prop('disabled', false)
    $('#addFile').prop('disabled', false)
    $('input[name="facility[payee_name]"]').val('')
    $('input[name="facility[payee_name]"]').prop('disabled', true)
    $('input[name="facility[bank_account_no]"]').prop('disabled', false)
  } else if ($('#facility_payment_mode_id option:selected').text() == 'Bank') {
    $('input[name="facility[authority_to_credit]"]').prop('disabled', true)
    $('#addFile').prop('disabled', true)
    $('input[name="facility[payee_name]"]').val('')
    $('input[name="facility[payee_name]"]').prop('disabled', true)
    $('input[name="facility[bank_account_no]"]').prop('disabled', false)
  }

  if ($('#facility_payment_mode_id option:selected').text() == 'Auto-Credit') {
    if ($('input[name="facility[authority_to_credit]"]:checked').val() == false) {
      $('#addFile').prop('disabled', true)
    } else {
      $('#addFile').prop('disabled', false)
    }
  }

  $('input[name="facility[authority_to_credit]"]').on('change', function(){
    $('div[id="formStep1Facility"]').find('.error').removeClass('error').find('.prompt').remove();
    if ($(this).val() == "false") {
      $('#addFile').prop('disabled', true)
    } else {
      $('#addFile').prop('disabled', false)
    }
  });

});

onmount('div[role="facility-numeric"]', function () {
  var facility_tin = document.getElementById("facility_tin");
  var facility_phic_no = document.getElementById("facility_phic_accreditation_no");
  var facility_postal = document.getElementById("facility_postal_code");

  if (facility_tin != null) {
    facility_tin.addEventListener("keydown", function(e) {
    // prevent: "e", "=", ",", "-", "."
      if ([69, 187, 188, 189, 190].includes(e.keyCode)) {
        e.preventDefault();
      }
    });
  }

  if (facility_phic_no != null) {
    facility_phic_no.addEventListener("keydown", function(e) {
    // prevent: "e", "=", ",", "-", "."
      if ([69, 187, 188, 189, 190].includes(e.keyCode)) {
        e.preventDefault();
      }
    });
  }

  if (facility_postal != null) {
    facility_postal.addEventListener("keydown", function(e) {
    // prevent: "e", "=", ",", "-", "."
      if ([69, 187, 188, 189, 190].includes(e.keyCode)) {
        e.preventDefault();
      }
    });
  }
});

onmount('div[name="facility-formValidate"]', function () {
  $.fn.form.settings.rules.validEmail = function(param) {
    var pattern = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/;

    if (param == '') {
      return true;
    } else {
      return pattern.test($.trim(param));
    }
  }

  $.fn.form.settings.rules.validWebsite = function(param) {
    var pattern = /^((https?|ftp|smtp):\/\/)?(www.)?[a-z0-9]+\.[a-z]+(\/[a-zA-Z0-9#]+\/?)*$/;

    if (param == '') {
      return true;
    } else {
      return pattern.test($.trim(param));
    }
  }

  let validMobileNos = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994","976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  $.fn.form.settings.rules.checkMobilePrefix = function(param) {
    return validMobileNos.indexOf(param.substring(0,3)) == -1 ? false : true;
  }

  let facility_code = $('#facility_code').val()

  $.fn.form.settings.rules.existsFacilityCode = function(param) {
    if ($('#facility_codes').val() == "" || $('#facility_codes').val() == null){
      return true;
    } else {
      var facility_codes = JSON.parse($('#facility_codes').val());
      if (facility_code != '') {
        var index = facility_codes.indexOf(facility_code)
        facility_codes.splice( index, 1 )
      }
      if (jQuery.inArray(param, facility_codes) < 0) {
        return true;
      } else {
        return false;
      }
    }
  }

  $.fn.form.settings.rules.addressLineChecker = function(param) {
    let line_1 = $('input[name="facility[line_1]"]').val()
    let line_2 = $('input[name="facility[line_2]"]').val()

    if (line_1 == '' && line_2 == '') {
      return false
    } else {
      return true
    }
  }

  $.fn.form.settings.rules.customLength = function(param) {

    if (param == '') {
      return true
    } else {
      if(param.length == 12) {
        return true
      } else{
        return false
      }
    }
  }

  $('#formStep1Facility').form({
    on: 'blur',
    inline: true,
    fields: {
      'facility[code]': {
        identifier: 'facility[code]',
        rules:
        [
          {
            type   : 'empty',
            prompt : 'Please enter facility code'
          },
          {
            type   : 'existsFacilityCode[param]',
            prompt : 'Facility code already exists'
          },
        ]
      },
      'facility[name]': {
        identifier: 'facility[name]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter facility name'
        }]
      },
      'facility[ftype_id]': {
        identifier: 'facility[ftype_id]',
        rules: [{
          type   : 'empty',
          prompt : 'Please select facility type'
        }]
      },
      'facility[fcategory_id]': {
        identifier: 'facility[fcategory_id]',
        rules: [{
          type   : 'empty',
          prompt : 'Please select facility category'
        }]
      },
      'facility[phic_accreditation_no]': {
        identifier: 'facility[phic_accreditation_no]',
        rules: [
          {
            type   : 'number',
            prompt : 'Philhealth accreditation number must be numeric'
          }
        ]
      },
      'facility[affiliation_date]': {
        identifier: 'facility[affiliation_date]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter the facility affiliation date'
        }]
      },
      'facility[disaffiliation_date]': {
        identifier: 'facility[disaffiliation_date]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter the facility disaffiliation date'
        }]
      },
      'facility[email_address]': {
        identifier: 'facility[email_address]',
        rules: [{
          type   : 'validEmail[param]',
          prompt : 'Please enter valid email'
        }]
      },
      'facility[website]': {
        identifier: 'facility[website]',
        rules: [{
          type   : 'validWebsite[param]',
          prompt : 'Please enter valid website'
        }]
      },
      'facility[phic_accreditation_no]': {
        identifier: 'facility[phic_accreditation_no]',
        rules: [{
          type   : 'customLength[param]',
          prompt : 'Philhealth Accreditation Number must be 12 digits'
        }]
      },
    }
  });

  $('#cutoff_timer').calendar({
    ampm: false,
    type: 'time'
  });

  if ($('input#facility_location_group').length > 0){

    if ($('input#facility_location_group').val() == ""){
      $('select#facility_location_group_ids').dropdown('set selected', []);
    } else {
      let flg = JSON.parse($('input#facility_location_group').val());
      let flg_ids = [];

      for(let i=0; i < flg.length; i++){
        if(flg[i].location_group != null) {
          flg_ids.push(flg[i].location_group.id);
        }
      }

      $('select#facility_location_group_ids').dropdown('set selected', flg_ids);
    }

  }

      $('#formStep2Facility').form({
        inline: true,
        fields: {
          'facility[line_1]': {
            identifier: 'facility[line_1]',
            rules: [{
              type   : 'addressLineChecker[param]',
              prompt : 'Please enter the facility address line 1'
            }]
          },
          'facility[line_2]': {
            identifier: 'facility[line_2]',
            rules: [{
              type   : 'addressLineChecker[param]',
              prompt : 'Please enter the facility address line 2'
            }]
          },
          'facility[city]': {
            identifier: 'facility[city]',
            rules: [{
              type   : 'empty',
              prompt : 'Please enter the facility city / municipal'
            }]
          },
          'facility[province]': {
            identifier: 'facility[province]',
            rules: [{
              type   : 'empty',
              prompt : 'Please enter the facility province'
            }]
          },
          'facility[region]': {
            identifier: 'facility[region]',
            rules: [{
              type   : 'empty',
              prompt : 'Please enter the facility region'
            }]
          },
          'facility[country]': {
            identifier: 'facility[country]',
            rules: [{
              type   : 'empty',
              prompt : 'Please enter the facility country'
            }]
          },
          'facility[postal_code]': {
            identifier: 'facility[postal_code]',
            rules:
            [
              {
                type   : 'empty',
                prompt : 'Please enter the facility postal'
              },
              {
                type   : 'number',
                prompt : 'Postal must be numeric'
              }

            ]
          },
          'facility[longitude]': {
            identifier: 'facility[longitude]',
            rules:
            [
              {
                type   : 'empty',
                prompt : 'Please enter longitude'
              }

            ]
          },
          'facility[latitude]': {
            identifier: 'facility[latitude]',
            rules:
            [
              {
                type   : 'empty',
                prompt : 'Please enter latitude'
              }

            ]
          },
          'facility[location_group_ids][]': {
            identifier: 'facility[location_group_ids][]',
            rules:
            [
              {
                type   : 'minCount[1]',
                prompt : 'Please select location group'
              }

            ]
          }
        }
      });

    $('#formUpdateStep3Facility').form({
        inline: true,
        on: 'blur',
        fields: {
          'facility[last_name]': {
            identifier: 'facility[last_name]',
            rules: [{
              type   : 'empty',
              prompt : "Please enter the facility contact person's last name"
            }]
          },
          'facility[first_name]': {
            identifier: 'facility[first_name]',
            rules: [{
              type   : 'empty',
              prompt : "Please enter the facility contact person's first name"
            }]
          },
          'facility[suffix]': {
            identifier: 'facility[suffix]',
            optional: 'true',
            rules: [{
              type   : 'maxLength[4]',
              prompt : "Please enter at most {ruleValue} characters"
            },
            {
              type   : 'regExp[/^[A-Za-z .-]*$/]',
              prompt : 'Only letters and characters (.-) are allowed'
            }]
          },
          'facility[mobile][]': {
            identifier: 'facility[mobile][]',
            rules:
            [
              {
                type   : 'empty',
                prompt : "Please enter the facility contact person's mobile"
              },
              // {
              //   type   : 'exactLength[13]',
              //   prompt : 'Please enter a 10 digit number'
              // }
              {
                type  : 'checkMobilePrefix[param]',
                prompt: 'Mobile prefix is invalid.'
              }
            ]
          },
          'facility[email]': {
            identifier: 'facility[email]',
            rules:
            [
              {
                type   : 'empty',
                prompt : "Please enter the facility contact person's email"
              },
              {
                type   : 'email',
                prompt : 'Please enter a valid e-mail'
              }
            ]
          },
          // 'facility[tel_area_code][]': {
          //   identifier: 'facility[tel_area_code][]',
          //   rules:
          //   [
          //     {
          //       type   : 'empty',
          //       prompt : "Please include your Area Code"
          //     }
          //   ]
          // },
        }
      });

      $('#formStep3Facility').form({
        inline: true,
        on: 'blur',
        fields: {
          'facility[last_name]': {
            identifier: 'facility[last_name]',
            rules: [{
              type   : 'empty',
              prompt : "Please enter the facility contact person's last name"
            }]
          },
          'facility[first_name]': {
            identifier: 'facility[first_name]',
            rules: [{
              type   : 'empty',
              prompt : "Please enter the facility contact person's first name"
            }]
          },
          'facility[suffix]': {
            identifier: 'facility[suffix]',
            optional: 'true',
            rules: [{
              type   : 'maxLength[4]',
              prompt : "Please enter at most {ruleValue} characters"
            },
            {
              type   : 'regExp[/^[A-Za-z .-]*$/]',
              prompt : 'Only letters and characters (.-) are allowed'
            }]
          },
          'facility[mobile][]': {
            identifier: 'facility[mobile][]',
            rules:
            [
              {
                type   : 'empty',
                prompt : "Please enter the facility contact person's mobile"
              },
              // {
              //   type   : 'exactLength[13]',
              //   prompt : 'Please enter a 10 digit number'
              // }
              {
                type  : 'checkMobilePrefix[param]',
                prompt: 'Mobile prefix is invalid.'
              }
            ]
          },
          'facility[email]': {
            identifier: 'facility[email]',
            rules:
            [
              {
                type   : 'empty',
                prompt : "Please enter the facility contact person's email"
              },
              {
                type   : 'email',
                prompt : 'Please enter a valid e-mail'
              }
            ]
          },
        }
      });

      $('#formStep4Facility').form({
        inline: true,
        fields: {
          'facility[tin]': {
            identifier: 'facility[tin]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter TIN'
              },
              {
                type   : 'exactLength[12]',
                prompt : 'TIN must be 12 digits'
              }
            ]
          },
          'facility[vat_status_id]': {
            identifier: 'facility[vat_status_id]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please select VAT Status'
              }
            ]
          },
          'facility[prescription_term]': {
            identifier: 'facility[prescription_term]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Prescription Term'
              }
            ]
          },
          'facility[prescription_clause_id]': {
            identifier: 'facility[prescription_clause_id]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please select Prescription Clause'
              }
            ]
          },
          'facility[credit_term]': {
            identifier: 'facility[credit_term]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Credit Term'
              }
            ]
          },
          'facility[credit_limit]': {
            identifier: 'facility[credit_limit]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Credit Limit'
              }
            ]
          },
          'facility[payment_mode_id]': {
            identifier: 'facility[payment_mode_id]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please select Mode of Payment'
              }
            ]
          },
          'facility[releasing_mode_id]': {
            identifier: 'facility[releasing_mode_id]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please select Mode of Releasing'
              }
            ]
          },
          'facility[bank_account_no]': {
            identifier: 'facility[bank_account_no]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Bank Account No.'
              }
            ]
          },
          'facility[payee_name]': {
            identifier: 'facility[payee_name]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Payee Name'
              }
            ]
          },
          'facility[withholding_tax]': {
            identifier: 'facility[withholding_tax]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Withholding Tax'
              }
            ]
          },
          'facility[withholding_tax]': {
            identifier: 'facility[withholding_tax]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter Withholding Tax'
              }
            ]
          },
        }
      });

      var elem = $("#prescription_term");
      var elem2 = $("#credit_term");
      var elem3 = $("#credit_limit");
      var elem4 = $("#withholding_tax");
      var elem5 = $("#no_of_beds");
      var elem6 = $("#bond");
      if (elem) {
        elem.keydown(function() {
            if (elem.val().length > 9)
                elem.val(elem.val().substr(0, 9));
        });
      }
      if (elem2) {
        elem2.keydown(function() {
            if (elem2.val().length > 9)
                elem2.val(elem2.val().substr(0, 9));
        });
      }
      if (elem3) {
        elem3.keydown(function() {
            if (elem3.val().length > 9)
                elem3.val(elem3.val().substr(0, 9));
        });
      }
      if (elem4) {
        elem4.keydown(function() {
            if (elem4.val().length > 9)
                elem4.val(elem4.val().substr(0, 9));
        });
      }
      if (elem5) {
        elem5.keydown(function() {
            if (elem5.val().length > 9)
                elem5.val(elem5.val().substr(0, 9));
        });
      }
      if (elem6) {
        elem6.keydown(function() {
            if (elem6.val().length > 9)
                elem6.val(elem6.val().substr(0, 9));
        });
      }
  })

onmount('div[role="facility-datepicker"]', function(){
  const tomorrow = new Date()
  tomorrow.setDate(tomorrow.getDate()+1)

  $('#phic_accreditation_from').calendar({
    type: 'date',
    endCalendar: $('#phic_accreditation_to'),
    onChange: function (start_date, text, mode) {
      start_date = moment(start_date).add(1, 'year').calendar()
      start_date = moment(start_date).format("MM-DD-YYYY")
      $('input[name="facility[phic_accreditation_to]"]').val(start_date)
      $('#phic_accreditation_to').calendar("set date", start_date);
    },
    formatter: {
        date: function (date, settings) {
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

  $('#phic_accreditation_to').calendar({
	  type: 'date',
    startCalendar: $('#phic_accreditation_from'),
    formatter: {
      date: function (date, settings) {
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

  $('#affiliation_date').calendar({
    type: 'date',
    minDate: new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate()),
    endCalendar: $('#disaffiliation_date'),
    onChange: function (start_date, text, mode) {
      start_date = moment(start_date).add(1, 'year').calendar()
      start_date = moment(start_date).format("MM-DD-YYYY")
      $('input[name="facility[disaffiliation_date]"]').val(start_date)
      $('#disaffiliation_date').calendar("set date", start_date);
    },
    formatter: {
        date: function (date, settings) {
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

  $('#disaffiliation_date').calendar({
	  type: 'date',
    startCalendar: $('#affiliation_date'),
    formatter: {
      date: function (date, settings) {
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
});

onmount('div[role="facility-modal"]', function(){
  $(".number").keydown(function (e) {
      // Allow: backspace, delete, tab, escape, enter and .
      if ($.inArray(e.keyCode, [46, 8, 9, 27, 13, 110, 190]) !== -1 ||
           // Allow: Ctrl+A, Command+A
          (e.keyCode === 65 && (e.ctrlKey === true || e.metaKey === true)) ||
           // Allow: home, end, left, right, down, up
          (e.keyCode >= 35 && e.keyCode <= 40)) {
               // let it happen, don't do anything
               return;
      }
      // Ensure that it is a number and stop the keypress
      if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) && (e.keyCode < 96 || e.keyCode > 105)) {
          e.preventDefault();
      }
  });

  // TODO ADD FACILITY SERVICE FEE MODAL
  $('button[name="modal_service_charge"]').on('click', function(){
    $('div[role="add-service-fee"]').modal({onShow: function(){$('.form').form('reset')},autofocus: false, observeChanges: true}).modal('show')
  })

  $('button[name="edit_modal_contact"]').on('click', function(){
    $('div[role="edit-contact"]').form('reset');
    $('div[role="edit-contact"]').modal('show');
    $('p[role="append-telephone"]').empty();
    $('p[role="append-fmobile"]').empty();
    $('p[role="append-fax"]').empty();

    let facility_id = $(this).attr('facilityID');
    let contact_id = $(this).attr('contactID');
    let csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url: `/facilities/${contact_id}/get_contact`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let selector = 'div[role="edit-contact"]';

        $('input[indexT="0"]').val('');
        $('input[indexM="0"]').val('');
        $('input[indexF="0"]').val('');

        for(let i=0; i < response.phones.length; i++){
          if(response.phones[i].type == "telephone"){
            if($('input[indexT="0"]').val() == "") {
              $('input[indexT="0"]').val(response.phones[i].number)
              $('input[indexTCC="0"]').val(response.phones[i].country_code)
              $('input[indexTAC="0"]').val(response.phones[i].area_code)
              $('input[indexTL="0"]').val(response.phones[i].local)
            } else {
              let telHtml = $('div[role="edit-form-telephone"]').html();
              let tel = `<div class="fields" role="form-telephone" id="append-tel">${telHtml}</div>`
              $('p[role="append-telephone"]').append(tel);

              $('div[id="append-tel"]').find('a').removeAttr("add");
              $('div[id="append-tel"]').find('a').attr("remove", "tel");
              $('div[id="append-tel"]').find('#edit_facility_telephone').attr("indexT", i);
              $('div[id="append-tel"]').find('#edit_facility_telephone_cc').attr("indexTCC", i);
              $('div[id="append-tel"]').find('#edit_facility_telephone_ac').attr("indexTAC", i);
              $('div[id="append-tel"]').find('#edit_facility_telephone_l').attr("indexTL", i);
              $('div[id="append-tel"]').find('a').attr("class", "ui icon red button");
              $('div[id="append-tel"]').find('a').html(`<i class="icon trash"></i>`);
              $('div[id="append-tel"]').find('label').remove();


              $('div[role="form-telephone"]').on('click', 'a[remove="tel"]', function(e) {
                  $(this).closest('div[role="form-telephone"]').remove();
              });

              var Inputmask = require('inputmask');
              var phone = new Inputmask("999-99-99", { "clearIncomplete": true})
              phone.mask($('.phone'));
              $('input[indexT="'+ i +'"]').val(response.phones[i].number)
              $('input[indexTCC="'+ i +'"]').val(response.phones[i].country_code)
              $('input[indexTAC="'+ i +'"]').val(response.phones[i].area_code)
              $('input[indexTL="'+ i +'"]').val(response.phones[i].local)
            }
          } else if(response.phones[i].type == "mobile"){
            if($('input[indexM="0"]').val() == "") {
              $('input[indexM="0"]').val(response.phones[i].number)
              $('input[indexMCC="0"]').val(response.phones[i].country_code)
            } else {
              let mobc = parseInt($('p[role="append-fmobile"]').attr('mobc')) + 1
              let append_mob = "append_mob" + mobc

              let mobHtml = $('div[role="edit-form-mobile"]').html();
              let mob = `<div class="fields" role="form-mobile" id="${append_mob}">${mobHtml}</div>`

              $('p[role="append-fmobile"]').append(mob);
              $('p[role="append-fmobile"]').attr("mobc", mobc);
              $(`div[id="${append_mob}"]`).find('a').removeAttr("add");
              $(`div[id="${append_mob}"]`).find('a').attr("remove", "mobile");
              $(`div[id="${append_mob}"]`).find('#edit_facility_mobile').attr("indexM", i);
              $(`div[id="${append_mob}"]`).find('#edit_facility_mobile_cc').attr("indexMCC", i);
              $(`div[id="${append_mob}"]`).find('a').attr("class", "ui icon red button");
              $(`div[id="${append_mob}"]`).find('a').html(`<i class="icon trash"></i>`);
              $(`div[id="${append_mob}"]`).find('label').remove();

              $('div[role="form-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
                  $(this).closest('div[role="form-mobile"]').remove();
              });

              var Inputmask = require('inputmask');
              var im = new Inputmask("\\999-999-99-99", { "clearIncomplete": true});
              im.mask($(`div[id="${append_mob}"]`).find('.mobile'));

              $('input[indexM="'+ i +'"]').val(response.phones[i].number)
              $('input[indexMCC="'+ i +'"]').val(response.phones[i].country_code)
            }
          } if(response.phones[i].type == "fax"){
            if($('input[indexF="0"]').val() == "") {
              $('input[indexF="0"]').val(response.phones[i].number)
              $('input[indexFCC="0"]').val(response.phones[i].country_code)
              $('input[indexFAC="0"]').val(response.phones[i].area_code)
              $('input[indexFL="0"]').val(response.phones[i].local)
            } else {
              let faxHtml = $('div[role="edit-form-fax"]').html();
              let fax = `<div class="fields" role="form-fax" id="append-fax">${faxHtml}</div>`
              $('p[role="append-fax"]').append(fax);

              $('div[id="append-fax"]').find('a').removeAttr("add");
              $('div[id="append-fax"]').find('a').attr("remove", "fax");
              $('div[id="append-fax"]').find('#edit_facility_fax').attr("indexF", i);
              $('div[id="append-fax"]').find('#edit_facility_fax_cc').attr("indexFCC", i);
              $('div[id="append-fax"]').find('#edit_facility_fax_ac').attr("indexFAC", i);
              $('div[id="append-fax"]').find('#edit_facility_fax_l').attr("indexFL", i);
              $('div[id="append-fax"]').find('a').attr("class", "ui icon red button");
              $('div[id="append-fax"]').find('a').html(`<i class="icon trash"></i>`);
              $('div[id="append-fax"]').find('label').remove();


              $('div[role="form-fax"]').on('click', 'a[remove="fax"]', function(e) {
                  $(this).closest('div[role="form-fax"]').remove();
              });

              var Inputmask = require('inputmask');
              var phone = new Inputmask("999-99-99", { "clearIncomplete": true})
              phone.mask($('.phone'));
              $('input[indexF="'+ i +'"]').val(response.phones[i].number)
              $('input[indexFCC="'+ i +'"]').val(response.phones[i].country_code)
              $('input[indexFAC="'+ i +'"]').val(response.phones[i].area_code)
              $('input[indexFL="'+ i +'"]').val(response.phones[i].local)
            }
          }
        }

        $(selector).find('#facility_contact_id').val(contact_id);
        $(selector).find('#facility_last_name').val(response.last_name)
        $(selector).find('#facility_first_name').val(response.first_name);
        $(selector).find('#facility_department').val(response.department);
        $(selector).find('#facility_designation').val(response.designation);
        $(selector).find('#facility_email').val(response.emails[0].address);
        $(selector).find('#facility_suffix').val(response.suffix);
      }
    });
  });
});

onmount('div[role="delete-facility"]', function () {
  $('div[role="delete-facility"]').on('click', function(){
    swal({
      title: 'Delete Facility Draft?',
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Facility Draft',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Facility Draft',
      confirmButtonClass: 'ui positive button',
      cancelButtonClass: 'ui negative button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false

    }).then(function() {
      let facility_id = $('div[role="delete-facility"]').attr('facilityId')
      window.location = '/facilities/' + facility_id + '/delete';
    }).catch(swal.noop)
  });
});

onmount('div[role="multipleFileUpload"]', function () {
  let counter = 1
  let delete_array = []

  $('#addFile').on('click', function(){
    let file_id = '#file_' + counter
    $('#filePreviewContainer').append(`<input type="file" class="display-none" id="file_${counter}" name="facility[files][]">`)
    $(file_id).on('change', function(){
      let icon = ''
      let file_type = $(file_id)[0].files[0].type
      if (file_type.includes('ms-excel')) {
        icon = 'file excel outline'
      } else if (file_type.includes('pdf')) {
        icon = 'file pdf outline'
      } else {
        icon = 'file outline'
      }
      if ($(this).val() != '') {
        let file_name = $(file_id)[0].files[0].name
        let new_row =
          `\
          <div class="item file-item">\
            <div class="right floated content">\
              <button class="ui button remove-file" fileID="${file_id}" type="button">Remove</button>\
            </div>\
            <i class="big ${icon} icon"></i>\
            <div class="content">\
              ${file_name}\
            </div>\
          </div>\
          `
        $('#filePreviewContainer').append(new_row)
      }
    })
    $(file_id).click()
    counter++
  })

  $('body').on('click', '.remove-file', function() {
    let file_id = $(this).attr('fileID')
    $(file_id).remove()
    $(this).closest('.item').remove()
  });

  $('body').on('click', '.remove-uploaded', function() {
    let file_id = $(this).attr('fileID')
    $(this).closest('.item').remove()
    if (delete_array.includes(file_id) == false) {
      delete_array.push(file_id)
    }
    $('#deleteIDs').val(delete_array)
  });

});

onmount('div[role="add-service-fee"]', function () {

  let mask_decimal =
    new Inputmask('decimal', {
      radixPoint: '.',
      groupSeparator: ',',
      digits: 2,
      autoGroup: true,
      rightAlign: false,
      oncleared: function () { self.Value('') }
    });

  let mask_percentage =
    new Inputmask('numeric', {
        min: 1,
        max: 100,
        rightAlign: false
      });

  // mask input on page load
  mask_decimal.mask($('#serviceFeeRate'))


  $('select[name="facility[service_type_id]"]').on('change', function(){
    let service_fee_type = $('select[name="facility[service_type_id]"] option:selected').text()

    if (service_fee_type == "MDR" || service_fee_type == "Discount Rate") {
      $('input[name="facility[rate]"]').prop('disabled', false)
      $('#serviceFeeRateIcon').html('%')
      mask_percentage.mask($('#serviceFeeRate'))
    } else if(service_fee_type == "Fixed Fee") {
      $('input[name="facility[rate]"]').prop('disabled', false)
      $('#serviceFeeRateIcon').html('PHP')
      mask_decimal.mask($('#serviceFeeRate'));
    } else {
      $('input[name="facility[rate]"]').prop('disabled', true)
    }
  });

  $('#formStep5Facility').form({
    inline: true,
    fields: {
      'facility[coverage_id]': {
        identifier: 'facility[coverage_id]',
        rules: [{
          type: 'empty',
          prompt: "Please select Coverage"
        }]
      },
      'facility[service_type_id]': {
        identifier: 'facility[service_type_id]',
        rules: [{
          type: 'empty',
          prompt: "Please select Service Fee"
        }]
      },
      'facility[rate]': {
        identifier: 'facility[rate]',
        rules: [{
            type: 'empty',
            prompt: "Please enter Rate"
          }]
      }
    },
    // unmasking the comma separator before form submission
    onSuccess: function(event, fields){
      let input = document.getElementById('serviceFeeRate');
      let unmasked_value = input.inputmask.unmaskedvalue()
      input.inputmask.remove()
      let test = $('#serviceFeeRate').val(unmasked_value)
    }
  });

});
