const locale = $('#locale').val();

onmount('.peme', function () {
  $('.active-peme').addClass('active')
});

onmount('#member-details-show', function(){
});

onmount('.evoucher-pdf', function () {
  let pmID = $(this).attr('pmID')
  $.ajax({
    url:`/en/peme/${pmID}/render`,
    type: 'get',
    success: function(response){
      $('.evoucher-pdf').html(response.html)
    }
  })
  let qrcode = $('#evoucherQR').val()
  $('#qrContainer').qrcode({
        width: 180,
        height: 180,
        text: qrcode
  })
  let canvas = $('#qrContainer').find('canvas')[0].toDataURL()
  $('#qrBase').val(canvas)
});

onmount('#peme_generate_evoucher', function () {
  $('.single_member').on('click', function(){
    $('#member_count').attr('style', 'display: none;')
  });

  $('.batch_member').on('click', function(){
    $('#member_count').attr('style', '')
  });

  let today = new Date();
  let expiry_date = new Date($('#account_expiry_date').val());
  let effective_date = new Date($('#account_effective_date').val());
  let date = new Date();

  Date.prototype.addDays = function(days) {
    this.setDate(this.getDate() + parseInt(days));
    return this;
  };

  Date.prototype.minusDays = function(days) {
    this.setDate(this.getDate() - parseInt(days));
    return this;
  };

  today.addDays(1);
  expiry_date.minusDays(1);

  $('.peme_date_from').val(new Date())

  $('#date_to').calendar({
    type: 'date',
    minDate: new Date($('#peme_input_date_from').val()),
    maxDate: new Date($('#account_expiry_date').val()),
    startCalendar: $('#date_from'),
    formatter: {
      date: function (date, settings) {
        if (!date) return '';
        var day = date.getDate() + '';
        if (day.length < 2) {
          day = '0' + day;
        }
        var month = (date.getMonth() + 1) + '';
        if (month.length < 2) {
          month = '0' + month;
        }
        var year = date.getFullYear();
        return year + '-' + month + '-' + day;
      }
    },
    onChange: function (date, text, mode) {
      $('#date_from').calendar({
        type: 'date',
        minDate: new Date,
        maxDate: date,
        endCalendar: $('#date_to'),
        formatter: {
          date: function (date, settings) {
            if (!date) return '';
            var day = date.getDate() + '';
            if (day.length < 2) {
              day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
              month = '0' + month;
            }
            var year = date.getFullYear();
            return year + '-' + month + '-' + day;
          }
        }
      })
    }
  });

  $('#date_from').calendar({
    type: 'date',
    minDate: new Date(),
    maxDate: expiry_date,
    endCalendar: $('#date_to'),
    formatter: {
      date: function (date, settings) {
        if (!date) return '';
        var day = date.getDate() + '';
        if (day.length < 2) {
          day = '0' + day;
        }
        var month = (date.getMonth() + 1) + '';
        if (month.length < 2) {
          month = '0' + month;
        }
        var year = date.getFullYear();
        return year + '-' + month + '-' + day;
      }
    }
  });

  let Inputmask = require('inputmask');

  let peme_date_to = new Inputmask("9999-99-99", {
    placeholder: "YYYY-MM-DD",
    allowMinus: false,
    rightAlign: false,
  });

  let peme_date_from = new Inputmask("9999-99-99", {
    placeholder: "YYYY-MM-DD",
    allowMinus: false,
    rightAlign: false,
  });

  let peme_mobile_mask = new Inputmask("\\9999999999", {
    placeholder: "",
    allowMinus: false,
    rightAlign: false
  });

  peme_date_to.mask($('.peme_date_to'))
  peme_date_from.mask($('.peme_date_from'))
  peme_mobile_mask.mask($('.mobile_peme'))

 $('.email_peme').on('keypress', function (evt) {
     let theEvent = evt || window.event;
     let key = theEvent.keyCode || theEvent.which;
     key = String.fromCharCode(key);
     let regex = /[``~<>^'{}()[\]\\;,'"/?!#$%&*+=|:]/;

     if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
       return false;
     } else {
       $(this).on('focusout', function (evt) {
         $(this).val($(this).val().charAt(0) + $(this).val().slice(1))
       })
     }
   });

  $('#peme_name').on('keypress', function(evt) {
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode(key);
    let regex = /[a-zA-Z,. -]/;

    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key) == false) {
      return false;
    } else {
      $(this).on('focusout', function(evt) {
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  });

  $('#peme_mname').on('keypress', function(evt) {
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode(key);
    let regex = /[a-zA-Z,. -]/;

    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key) == false) {
      return false;
    } else {
      $(this).on('focusout', function(evt) {
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  });

  $('#peme_lastname').on('keypress', function(evt) {
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode(key);
    let regex = /[a-zA-Z,. -]/;

    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key) == false) {
      return false;
    } else {
      $(this).on('focusout', function(evt) {
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  });

  $('#peme_suffix').on('keypress', function(evt) {
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode(key);
    let regex = /[a-zA-Z,. -]/;

    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key) == false) {
      return false;
    } else {
      $(this).on('focusout', function(evt) {
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  });

  $('body').on('change', '.package_class', function() {
    $('.facility_class').dropdown('clear')
  })

  $('#PemeForm')
  .form({
    on: blur,
    inline: true,
    fields: {
      'peme[package_id]': {
        identifier: 'peme[package_id]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Select Package'
          }
        ]
      },
      'peme[date_from]': {
        identifier: 'peme[date_from]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Medical Examination (PEME) Date From'
          }
        ]
      },
      'peme[date_to]': {
        identifier: 'peme[date_to]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Medical Examination (PEME) Date To'
          }
        ]
      }
    }
  });

  $('#packageID').change(function(){
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/api/v1/peme/package/with_facility_and_procedures/${$(this).val()}/${$('#account_id').val()}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        $('#procedure_list_message').attr('style', '')
        $('#procedure_list_message').find('.header').remove()
        $('#procedure_list_message').find('.list').remove()
        $('#facilityID').find('.option').remove()
        let procedures = ``
        if(response.facilities.length > 0){
        for (let i=0;i<response.facilities.length;i++){
          $('#facilityID').append(`<option class="option" value="${response.facilities[i].id}">${response.facilities[i].name}</option>`)
        }
        }
        for (let i=0;i<response.procedures.length;i++){
          procedures = procedures + `<li>${response.procedures[i].description}</li>`
        }
        $('#procedure_list_message').append(`
          <div class="header">
            Procedures included for ${response.name}
          </div>
          <ul class="list">
            ${procedures}
          </ul>`
        )
      }
    })
  });

  $('#submit_generate_evoucher').click(() => {
    let result = $('#PemeForm').form('validate form')
    if (result) {
      let date_from = $('#peme_input_date_from').val()
      let date_to = $('#peme_input_date_to').val()
      let package_id = $('#packageID :selected').val()
      let member_count = $('#peme_member_countID :selected').val()
      let facility_id = $('#facilityID :selected').val()

      $('#package_ID').val(package_id)
      $('#peme_date_from').val(date_from)
      $('#peme_date_to').val(date_to)
      $('#peme_member_count').val(member_count)
      $('#facility_ID').val(facility_id)

      $('#send_evoucher_modal')
      .modal({ autofocus: false, closable: false, observeChanges: true })
      .modal("show");

      const valid_mobile_prefix = ["905", "906", "907", "908",
                                   "909", "910", "912", "915",
                                   "916", "917", "918", "919",
                                   "920", "921", "922", "923",
                                   "926", "927", "928", "929",
                                   "930", "932", "933", "935",
                                   "936", "937", "938", "939",
                                   "942", "943", "947", "948",
                                   "949", "973", "974", "979",
                                   "989", "996", "997", "999",
                                   "977", "978", "945", "955",
                                   "956", "994", "976", "975",
                                   "995", "940", "946", "950",
                                   "992", "911", "913", "914",
                                   "981", "998", "951", "970",
                                   "934", "941", "944", "925",
                                   "924", "931"];

      let max_fields = member_count; //maximum input boxes allowed
      let fields = 1

      $('body').unbind('click').on("click", '.add-row', function() {

        if(fields < max_fields) {
            fields += 1
            let field_cloned = $(`
               <div class= "ui form cloned_fields" id="form_fields">
                <div class="three fields remove-row whole-row" id="remove_row">
                  <div class="fourteen wide field">
                    <div class = "field field-email">
                      <br>
                      <input type="text" name="peme[email_address][]" id="email_peme_evoucher" class= "appended prompt email-array email_peme${fields} field-secondary${fields}" attr="" placeholder= "(e.g. myemail@gmail.com)" >
                      <div class="error-msg"></div>
                    </div>
                  </div>
                  <div class="sixteen wide field">
                    <div class="two fields">
                      <div class="three wide field disabled">
                          <br>
                          <input type="text" name="peme[mobile_code][]" id="mobile_code" class="mobile-code " placeholder= "+63" value="63">
                      </div>

                    <div class="twelve wide field field-mobile">
                    <br>
                    <input type="text" name="peme[mobile_number][]" id="mobile_peme_evoucher" class="appended prompt mobile-array mobile_peme${fields} field-secondary${fields}" placeholder= "(e.g. 09123456789)" maxlength= "11">
                      <div class="error-msg"></div>
                    </div>
                  </div>
                 </div>
                  <div class="four wide field" id="button_container">
                    <div class="field remove-body" id="remove_button">
                      <br>
                      <a class="circular ui icon button remove-field-row" id="Remove_Email_and_Mobile_Field">
                        <i class="icon minus"></i>
                      </a>
                    </div>
                   </div>
                  </div>
                </div>
          `)

          $('#email_mobile_form').first().append(field_cloned)

          let Inputmask = require('inputmask');
          let mobile_phone = new Inputmask("\\9999999999")
          mobile_phone.mask($('.mobile-array'))

          $('.email-array').on('keypress', function (evt) {
            let theEvent = evt || window.event;
            let key = theEvent.keyCode || theEvent.which;
                key = String.fromCharCode(key);
            let regex = /[``~<>^'{}()[\]\\;,'"/?!#$%&*+=|:]/;

            if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
              return false;
              } else {
                $(this).on('focusout', function (evt) {
                  $(this).val($(this).val().charAt(0) + $(this).val().slice(1))
              })
             }
          });
        }
      });

      $('body').on("click", '.remove-field-row', function() {
        fields -= 1
        $(this).closest('.cloned_fields').remove();
      });

      $('body').on("click", '.close_button', function() {
          $('#modal_evoucher_form').form('clear');
          $('.cloned_fields').each(function(index, obj){
             fields -= 1
             $(this).remove();
          })
          $('#send_evoucher_modal').modal("hide");
       });

      //Validation For Main Row
      const main_row = _ => {
        let em_pe = $('input[name="peme[email_address][]"]').val()?true:false
        let mn_pe = $('input[name="peme[mobile_number][]"]').val()?true:false

        // Checks either Email or Mobile Fields are true
        if((em_pe || mn_pe) == true) {
          $(".main-field-email")
          .removeClass('error')
          .find('.ui.basic.red.pointing.prompt.label.transition.visible')
          .remove()

          $(".main-field-mobile")
          .removeClass('error')
          .find('.ui.basic.red.pointing.prompt.label.transition.visible')
          .remove()

          } else {
          $(".main-field-email")
          .addClass('error')
          .find('.error-msg')
          .html(
            `<div class="ui basic red pointing prompt label transition visible">Please enter either email address or mobile number</div>`
           )
          .fadeIn('fast')

          $(".main-field-mobile")
          .addClass('error')
          .find('.error-msg')
          .html(
            `<div class="ui basic red pointing prompt label transition visible">Please enter either email address or mobile number</div>`
           )
          .fadeIn('fast')
        }

        //Checks Mobile Number for Valid Prefix
        if(mn_pe == true) {
          let mn_value = $('input[name="peme[mobile_number][]"]').val()
          let mobile_prefix_checker = valid_mobile_prefix.indexOf(mn_value.substring(0, 3)) == -1 ? false : true
          if (mobile_prefix_checker == true) {
                //Checks Mobile Number length
                let unmarked_value = mn_value.replace(/-/g, '').replace(/_/g, '')
                if (unmarked_value.length == "10") {
                  $(".main-field-mobile")
                  .removeClass('error')
                  .find('.ui.basic.red.pointing.prompt.label.transition.visible')
                  .remove()
                } else {
                  $(".main-field-mobile")
                  .addClass('error')
                  .find('.error-msg')
                  .html(
                  `<div class="ui basic red pointing prompt label transition visible">You have entered an invalid Mobile number </div>`
                  )
                  .fadeIn('fast')
                }
          } else {
          $(".main-field-mobile")
          .addClass('error')
          .find('.error-msg')
          .html(
            `<div class="ui basic red pointing prompt label transition visible">You have entered an invalid Mobile number </div>`
           )
          .fadeIn('fast')
          }
        }

        //Checks Email Address if format is correct
        if(em_pe == true) {
          let em_value = $('input[name="peme[email_address][]"]').val()
          let regex_match = new RegExp(/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/)

          if (regex_match.test(em_value)){
            $(".main-field-email")
            .removeClass('error')
            .find('.ui.basic.red.pointing.prompt.label.transition.visible')
            .remove()
          } else {
            $(".main-field-email")
            .addClass('error')
            .find('.error-msg')
            .html(
              `<div class="ui basic red pointing prompt label transition visible">You have entered an invalid Email address</div>`
            )
            .fadeIn('fast')
          }
        }
      }

      //Validation For Clone Fields
      const row_validation = _ => {
       $(`.whole-row`).each(function(index, value){
          var temp = index + parseInt(2)
          $(this).find(".field-secondary" + (temp)).each(function(){

          let email_value = $(".email_peme" + (temp)).val()?true:false
          let mobile_value = $(".mobile_peme" + (temp)).val()?true:false

            // Checks either Email or Mobile Fields are true
            if ((email_value || mobile_value) == true){
              $(this)
              .closest('.field')
              .removeClass('error')
              .find('.ui.basic.red.pointing.prompt.label.transition.visible')
              .remove()
            } else{
              $(this)
              .closest('.field')
              .addClass('error')
              .find('.error-msg')
              .html(
                `<div class="ui basic red pointing prompt label transition visible">Please enter either email address or mobile number</div>`
              )
              .fadeIn('fast')
            }

            //Checks Mobile Number for Valid Prefix
            if(mobile_value == true){
              let mobile_number = $(".mobile_peme" + (temp)).val()
              let mobile_prefix_checker = valid_mobile_prefix.indexOf(mobile_number.substring(0, 3)) == -1 ? false : true

              if (mobile_prefix_checker == true) {

                //Checks Mobile Number length
                let unmarked_value = mobile_number.replace(/-/g, '').replace(/_/g, '')
                if (unmarked_value.length == "10") {

                  $(this)
                  .closest('.field-mobile')
                  .removeClass('error')
                  .find('.ui.basic.red.pointing.prompt.label.transition.visible')
                  .remove()
                } else {
                  $(this)
                  .closest('.field-mobile')
                  .addClass('error')
                  .find('.error-msg')
                  .html(
                   `<div class="ui basic red pointing prompt label transition visible">You have entered an invalid Mobile number</div>`
                  )
                  .fadeIn('fast')
                }
              } else {
                $(this)
                .closest('.field-mobile')
                .addClass('error')
                .find('.error-msg')
                .html(
                  `<div class="ui basic red pointing prompt label transition visible">You have entered an invalid Mobile number</div>`
                )
                .fadeIn('fast')
              }
            }

          //Checks Email Address if format is correct
          if(email_value == true) {
            let email_address = $(".email_peme" + (temp)).val()
            let regex_match = new RegExp(/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/)

             if (regex_match.test(email_address)){
                $(this)
                .closest('.field-email')
                .removeClass('error')
                .find('.ui.basic.red.pointing.prompt.label.transition.visible')
                .remove()
             } else {
                $(this)
                .closest('.field-email')
                .addClass('error')
                .find('.error-msg')
                .html(
                  `<div class="ui basic red pointing prompt label transition visible">You have entered an invalid Email address </div>`
                )
                .fadeIn('fast')
             }
          }
          })
        })
      }

      $('#skip_evoucher').click(() => {
        $('#PemeForm').submit()
      })

      $('#modal_evoucher_form').submit( _ => {
        main_row()
        row_validation()
        return $('.ui.red.pointing.label.transition').length == 0 ? true : false
       })

    }
  });
});

onmount('#cancel_confirm', function () {
  $('#cancel_confirm_no').on('click', function (){
     $('#cancel_confirm').modal("hide")
  });

  $('#reason_text_area').css('display', 'none')
    $('#reason_dropdown').change(function(){
      if($(this).val() == "Others") {
        $('#reason_text_area').css('display', 'block')
      } else {
        $('#reason_text_area').css('display', 'none')
      }
  });
});

onmount('#show_swall', function () {
  swal({
    title: 'E-Voucher Successfully Generated',
    text: 'Fill out the Pre-Employment Medical Examination Application Form or processed to the selected principal',
    type: 'success',
    allowOutsideClick: false,
    confirmButtonText: '<i class="check icon"></i> Ok',
    confirmButtonClass: 'ui button primary',
    buttonsStyling: false
  }).then(function () {
  }).catch(swal.noop)
});

// onmount('#show_swall_cancel', function () {
//   let date_to = $('#evoucher_date_to').val()
//   let date_from = $('#evoucher_date_from').val()
//   let evoucher_no = $('#evoucher').val()
//  swal({
//       title: 'E-Voucher Cancellation Successful',
//       // text: 'Fill out the Pre-Employment Medical Examination Application Form or processed to the selected principal',
//       html:'<div class="ui one column centered grid">' +
//         '<div class="column">' +
//           '<b>E-voucher Number</b>'+
//           '<br>' +
//            evoucher_no +
//         '</div>' +
//         '<div class="column">' +
//           '<b>PEME Date From</b>'+
//           '<br>' +
//            date_from +
//         '</div>' +
//         '<div class="column">' +
//           '<b>PEME Date To</b>'+
//           '<br>' +
//           date_to +
//         '</div>' +
//       '</div>' +
//       '<br>' +
//       '<br>',
//       type: 'success',
//       allowOutsideClick: false,
//       confirmButtonText: '<i class="check icon"></i> Okay',
//       confirmButtonClass: 'ui button primary',
//       buttonsStyling: false
//     }).then(function () {
//       window.location.replace(`/${locale}/peme`)
//     }).catch(swal.noop)
// })

// onmount('#show_swall_cancel_failed', function () {
//   swal({
//       title: 'This e-voucher cannot be cancelled',
//       type: 'error',
//       allowOutsideClick: false,
//       confirmButtonText: '<i class="check icon"></i> Ok',
//       confirmButtonClass: 'ui button primary',
//       buttonsStyling: false
//     }).then(function () {
//     }).catch(swal.noop)
// })

onmount('#print_evoucher_modal', function() {
  let peme_ids = []

  $('.print_evoucher').click(function() {
    let pmID = $(this).attr("pmID")
    $('#pmID').val(pmID)
    $('#print_button').attr('href', `/${locale}/print_preview/evoucher/${pmID}`);
    let csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/${locale}/render/evoucher/${pmID}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        $('#for_pdf').html(response.html)
      }
    });

    $('#print_evoucher_modal').modal({autofocus: false}).modal('show')
  })

  let peme_type = $('div[id="member-details-show"]').attr("role")

  if (peme_type == "Single") {
    $('#export_evoucher').click(function(){
       let value = $('tbody').find('tr').attr("peme_id")
       window.open(`/${locale}/print/evoucher/${value}`)
    })
  } else {
    $('#member_table').find('tbody').find('tr').find('input[type="checkbox"]').click(function(){
      let value = $(this).val()
      let check = $(this).attr("checked")
      if(check == "checked"){
        // $(this).removeAttr('style')
        $(this).removeAttr("checked")

        let index = peme_ids.indexOf(value);
        if (index >= 0) {
           peme_ids.splice( index, 1)
        }
      } else {
        peme_ids.push(value)
        // $(this).css('background-color', '#b2ccf4')
        $(this).attr("checked", "checked")
      }
    })

    $('#export_evoucher').click(function(){
      if(peme_ids.length > 0){
        $('input[name="peme[peme_ids]"]').val(peme_ids)
        $('#form-export').submit()
      } else {
        alertify.error('<i class="close icon"></i>Please select which member’s e-voucher to be exported')
      }
    })
  }
});

onmount('div[id="accountlink_signin"]', function () {
  sessionStorage.clear();
  localStorage.clear();
});

onmount('div[id="peme_index"]', function () {

  $('#select_all').on('click', function(){ //set all ids to local storage here!!!!!!!!!!!!!
    var $boxes = $("#checkbox-container :checkbox");

    if(this.checked) {
      var flag = true;
      $boxes.each(function(){
        if (flag == false)
        {
          $(this).prop('checked', true)
        } else {
        } flag = false
      });
    }
    else {
      var flag = true;
      $boxes.each(function(){
        if (flag == false)
        {
          $(this).prop('checked', false)
        } else {
        } flag = false
      });
    }
  });

  const csrf = $('input[name="_csrf_token"]').val();
  $('#peme_table').dataTable( {
    aoColumns: [
      { className: "peme_qrcode", "bSortable": false },
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null
    ],
    "ajax": {
      "url": "/en/peme/index/data",
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "processing": true,
    "serverSide": true,
    "deferRender": true,
    "stateSave": true,
    "order": [[ 3, "desc" ]],
    stateSaveCallback: function(settings,data) {
      localStorage.setItem( 'DataTables_' + settings.sInstance, JSON.stringify(data) )
    },
    stateLoadCallback: function(settings) {
      return JSON.parse( localStorage.getItem( 'DataTables_' + settings.sInstance ) )
    },

    "drawCallback": function (){

  $('#select_all').prop('checked', false)
  let table = $('#peme_table').DataTable();
  let rows = table.rows({ 'search': 'applied' }).nodes();
  let date_to = $('#peme_date_to').val();
  let date_from = $('#peme_date_from').val();
  let evoucher_no = $('#evoucher_no').val();

  // $('#member_table').find('tbody').find('td').find('#cancel_evoucher').on('click', function() {

    $('.cancel_evoucher', rows).click(function() {
    if ($(this).attr('peme_status') == "Availed" || $(this).attr('peme_status') == "Cancelled" || $(this).attr('peme_status') == "Stale") {
          swal({
            title: 'This e-voucher cannot be cancelled',
            type: 'error',
            allowOutsideClick: false,
            confirmButtonText: '<i class="check icon"></i> Ok',
            confirmButtonClass: 'ui button primary',
            buttonsStyling: false
          }).then(function () {
          }).catch(swal.noop)
    }else{
      let evoucher_number = $(this).attr('evoucher')
      let date_from = $(this).attr('date_from')
      let date_to = $(this).attr('date_to')
      let member_id = $(this).attr('member_id')
      let pemeID = $(this).attr('peme_id')
      $('#reason_dropdown').dropdown('clear');
      $('#cancel_confirm').modal({autofocus: false}).modal("show")
      $('#evoucher_num_modal').text(evoucher_number)
      $('#evoucher_date_from').text(date_from)
      $('#evoucher_date_to').text(date_to)
      $('input[name="member[member_id]"]').val(member_id)
      $('input[name="member[peme_id]"]').val(pemeID)
      $('#cancel_peme_evoucher').attr('href', '/${locale}/peme/${member_id}/cancel_evoucher')
    }
  });

  $('.cancel_evoucher_button').click(function(){
    let csrf = $('input[name="_csrf_token"]').val();
    let param = {
      member: {
        member_id: $('input[name="member[member_id]"]').val(),
        peme_id: $('input[name="member[peme_id]"]').val(),
        cancel_reason: $('#reason_dropdown').val(),
        cancel_others: $('#reason_text_area').val()
      },
      locale: locale
    }
    $('#cancel_confirm').modal("hide")
    let evoucher_no = $('#evoucher_num_modal').text()
    let date_from = $('#evoucher_date_from').text()
    let date_to = $('#evoucher_date_to').text()
    $.ajax({
      url:`/${locale}/peme/cancel_evoucher`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'post',
      data: param,
      success: function(response){
        if (response == "true"){
          swal({
            title: 'E-Voucher Cancellation Successful',
            html:'<div class="ui one column centered grid">' +
              '<div class="column">' +
              '<b>E-voucher Number</b>'+
              '<br>' +
              evoucher_no +
              '</div>' +
              '<div class="column">' +
              '<b>PEME Date From</b>'+
              '<br>' +
              date_from +
              '</div>' +
              '<div class="column">' +
              '<b>PEME Date To</b>'+
              '<br>' +
              date_to +
              '</div>' +
              '</div>' +
              '<br>' +
              '<br>',
            type: 'success',
            allowOutsideClick: false,
            confirmButtonText: '<i class="check icon"></i> Okay',
            confirmButtonClass: 'ui button primary',
            buttonsStyling: false
          }).then(function () {
              window.location.replace(`/${locale}/peme`)
          }).catch(swal.noop)
        }else{
          swal({
            title: 'This e-voucher cannot be cancelled',
            type: 'error',
            allowOutsideClick: false,
            confirmButtonText: '<i class="check icon"></i> Ok',
            confirmButtonClass: 'ui button primary',
            buttonsStyling: false
          }).then(function () {
          }).catch(swal.noop)
        }
      }
    })
  })

  var $checkboxes = $("#checkbox-container :checkbox");
  var array = {};

  var getbox = JSON.parse(sessionStorage.getItem("check_state"));
  var first_flag = true;
  let checked_count = 0
  $checkboxes.each(function(){
    if (first_flag == false)
    {
      var idid = $(this).val()
      if (getbox){$(this).prop('checked', getbox[idid]);}
    } else {
      if ("") {
        $(this).prop('checked', false);
      }
    } first_flag = false
    if (this.checked == true){
      checked_count += 1
    }
  });
  if ((checked_count == $checkboxes.length - 1) && ($checkboxes.length - 1 != 0)){
      $('#select_all').prop('checked', true)
    }else{
      $('#select_all').prop('checked', false)
    }

  $checkboxes.on("click", function(){
    let ids_to_export = []
    let export_ids = JSON.parse(sessionStorage.getItem("export_storage"));

    if (export_ids) {
      $.each(export_ids, function(index, old_value){
       ids_to_export.push(old_value);
      });
    }

    let memory = JSON.parse(sessionStorage.getItem("check_state"));
    if (memory) {
      $.each(memory, function(index, value){
        array[index] = value;
      });
    }

    var first_flag = true
    let checked_count = 0
    $checkboxes.each(function(){
      if (first_flag == false)
      {
        var value = $(this).val()
        var name = value.substr(0, 36)
        array[name] = this.checked

        if(this.checked) {
          var a_index = ids_to_export.indexOf(value);
          if (a_index >= 0) {
          } else {
            ids_to_export.push(value);
          }
          checked_count += 1
        }
        else {
          var a_index = ids_to_export.indexOf(value);
          if (a_index >= 0) {
            ids_to_export.splice( a_index, 1)
          }
        }
      } first_flag = false
    });
    if (checked_count == ($checkboxes.length - 1) && ($checkboxes.length - 1) != 0){
      $('#select_all').prop('checked', true)
    }else{
      $('#select_all').prop('checked', false)
    }
    sessionStorage.setItem("check_state", JSON.stringify(array));
    sessionStorage.setItem("export_storage", JSON.stringify(ids_to_export));
  });


  $('.export_evoucher_button').click(function(){
    let export_ids = JSON.parse(sessionStorage.getItem("export_storage"));
    if (!export_ids || export_ids == [] || export_ids == "") {
      $('.ajs-message.ajs-error.ajs-visible').remove()
      alertify.error('<i class="close icon"></i><p>Please select which e-voucher <br>to be exported</p>')
    } else {
      $('#peme_ids').val(export_ids)
      $('#peme_export_evoucher_form').submit()
    }
  });

  $('.peme_qrcode', rows).each(function() {
    let qrcode = $(this).find('#member_qrcode').val()
    $(this).find('#print_qrcode_evoucher').qrcode({
      width: 180,
      height: 180,
      text: qrcode
    })
    let value = $(this).find('input[name="peme[id][]"]').val()
    let canvas = $(this).find('#print_qrcode_evoucher').find('canvas')[0].toDataURL();
    canvas = canvas.replace('data:image/png;', '')
    canvas = canvas.replace('base64,', '')
    $(this).find('input[name="peme[id][]"]').val(`${value}_${canvas}`)
  })

    }
  });
})

onmount('.show_peme_summary', function(){
  let pmID = $('.print_evoucher_modal').attr("pmID")
  $('#pmID').val(pmID)
  let csrf = $('input[name="_csrf_token"]').val();

  $.ajax({
    url:`/${locale}/render/evoucher/${pmID}`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      $('.ajax_pdf').html(response.html)
    }
  });

  $('.print_evoucher_modal').click(function(){
    let pmID = $(this).attr("pmID")
    $('#pmID').val(pmID)
    $('#print_evoucher_modal').modal({autofocus: false}).modal('show')
      let qrcode = $('#member_qrcode').val()
      $('#print_qrcode_evoucher').qrcode({
        width: 180,
        height: 180,
        text: qrcode
      })
      let canvas = $('#print_qrcode_evoucher').find('canvas')[0].toDataURL();
    $('#input_print_qrcode_evoucher').val(canvas)
  });
});

/*
onmount('#peme_tab', function () {
  $('.step').click(function(){
    let link = $(this).attr('link')
    if($(this).hasClass('link')) {
      window.location.replace(link)
    }
  })
})

onmount('div[id="request_loa"]', function () {
  let csrf = $('input[name="_csrf_token"]').val();
  $.ajax({
    url:`/${locale}/peme/single/load_packages`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let obj = JSON.parse(response);
      for (let pckg of obj) {
        let new_row = `<option value="${pckg.id}">${pckg.display}</option>`
        $('#package_dd').append(new_row)
      }
      $('.dropdown.selection').dropdown('refresh');
    }
  });

  $('#pemedate').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
    formatter: {
      date: function (date, settings) {
        if (!date) return '';
        var day = date.getDate() + '';
        if (day.length < 2) {
          day = '0' + day;
        }
        var month = (date.getMonth() + 1) + '';
        if (month.length < 2) {
          month = '0' + month;
        }
        var year = date.getFullYear();
        return year + '-' + month + '-' + day;
      }
    }
  })

  $('#package_dd').change(function(){
    let val = $('.ui.fluid.dropdown.selection').dropdown('get value')
    if(val != null) {
      let csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/peme/single/${val}/load_package`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        success: function(response){
          $('#facility_name').text(response.package_facility)
          $('#package_name').text(response.name)
          $('#procedure_record').text(response.package_payor_procedure)
          $('.package-list').css('display', 'block')
          $('.peme-general-info').css('display', 'block')
        }
      })
    }
  })

  $('#singlePemeForm')
  .form({
    inline : true,
    on     : 'blur',
    fields: {
      'peme_loa[peme_date]': {
        identifier: 'peme_loa[peme_date]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please select a PEME Date.'
          }
        ]
      },
      'peme_loa[package_id]': {
        identifier: 'peme_loa[package_id]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please select a package.'
          }
        ]
      }
    }
  })

})

onmount('div[id="general"]', function () {

  $('#birthdate').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
    formatter: {
        date: function (date, settings) {
            if (!date) return '';
            var day = date.getDate() + '';
            if (day.length < 2) {
                day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
                month = '0' + month;
            }
            var year = date.getFullYear();
            return year + '-' + month + '-' + day;
        }
    }
  })

  $('#effectivitydate').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
    formatter: {
        date: function (date, settings) {
            if (!date) return '';
            var day = date.getDate() + '';
            if (day.length < 2) {
                day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
                month = '0' + month;
            }
            var year = date.getFullYear();
            return year + '-' + month + '-' + day;
        }
    }
  })

  $('#expirydate').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
    formatter: {
        date: function (date, settings) {
            if (!date) return '';
            var day = date.getDate() + '';
            if (day.length < 2) {
                day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
                month = '0' + month;
            }
            var year = date.getFullYear();
            return year + '-' + month + '-' + day;
        }
    }
  })

  $('#singlePemeForm')
  .form({
    inline : true,
    on     : 'blur',
    fields: {
      'member[first_name]': {
        identifier: 'member[first_name]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a first name.'
          }
        ]
      },
      'member[middle_name]': {
        identifier: 'member[middle_name]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a middle name.'
          }
        ]
      },
      'member[last_name]': {
        identifier: 'member[last_name]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a last name.'
          }
        ]
      },
      'member[birthdate]': {
        identifier: 'member[birthdate]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a birthdate.'
          }
        ]
      },
      'member[gender]': {
        identifier: 'member[gender]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a gender.'
          }
        ]
      },
      'member[gender]': {
        identifier: 'member[gender]',
        rules: [
          {
            type   : 'checked',
            prompt : 'Please enter a gender.'
          }
        ]
      },
      'member[civil_status]': {
        identifier: 'member[civil_status]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a civil status.'
          }
        ]
      },
      'member[effectivity_date]': {
        identifier: 'member[effectivity_date]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a effectivity date.'
          }
        ]
      },
      'member[expiry_date]': {
        identifier: 'member[expiry_date]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a expiry date.'
          }
        ]
      }
    }
  })

})

onmount('div[id="contact"]', function () {
  $('#singlePemeForm')
  .form({
    inline : true,
    on     : 'blur',
    fields: {
      'member[email]': {
        identifier: 'member[email]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter an email.'
          }
        ]
      },
      'member[mobile]': {
        identifier: 'member[mobile]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a mobile.'
          }
        ]
      }
    }
  })
})
*/

onmount('div[id="evoucherSelectFacility"]', function () {
  var script = document.createElement("script")
  script.type = "text/javascript"
  script.src = "https://maps.googleapis.com/maps/api/js?key=AIzaSyB-FlYg_DB4v-UcHCH2XxX6MWy0qSF-9C4&callback=initMap"
  script.setAttribute = ("async", "async")
  script.setAttribute = ("defer", "defer")
  var facilities = JSON.parse($('input[id="facilities"]').val());
  var map, marker
  document.body.appendChild(script)

  window.initMap = function() {
    map = new google.maps.Map(document.getElementById('map'), {
      center: {lat: 14.599512, lng: 120.984222},
      zoom: 20,
      size: new google.maps.Size(200, 200)
    });
  }

  $('.ui.search').search({
    source: facilities,
    showNoResults: true,
    maxResults: 10,
    searchFields: ['title'],
    onSelect: function(result, response) {
      $('input[name="peme[facility_id]"]').val(result.id)
      $(`#${result.id}`).closest('.card').find('.content').find('.description').css('color', '#0086CA')

      map = new google.maps.Map(document.getElementById('map'), {
        center: {lat: 14.599512, lng: 120.984222},
        zoom: 15,
        size: new google.maps.Size(200, 200)
      })

      var bounds = new google.maps.LatLngBounds()

      if (result != null){
        var position = new google.maps.LatLng(parseFloat(result.latitude), parseFloat(result.longitude))
        bounds.extend(position)

        marker = new google.maps.Marker({
          position: position,
          map: map,
          clickable: true,
          title: result.code
        })

        map.fitBounds(bounds);

        var address = result.line_1 + ' ' +
                      result.line_2 + ' ' +
                      result.city + ' ' +
                      result.province + ' ' +
                      result.region + ' ' +
                      result.country + ','  +
                      result.postal_code

        $('#facility_code').html(result.code);
        $('#facility_name').html(result.name);
        $('#facility_type').html(result.type);
        $('#facility_category').html(result.category);
        $('#facility_address').html(address);
        $('#facility_contact_number').html(result.phone_no);
        $('input[name="authorization[facility_id]"]').val(result.id);
        $('input[name="authorization[facility_code]"]').val(result.code);
      }
    },
    minCharacters: 0
  });

  $('.facility-card').on('click', function(){
    $('.description').removeAttr('style')
    $(this).closest('.card').find('.content').find('.description').css('color', '#0086CA')

    let long = $(this).attr('long')
    let lat = $(this).attr('lat')
    let code = $(this).attr('code')
    let id = $(this).attr('facilityID')
    let name = $(this).attr('facility_name')
    let line_1 = $(this).attr('facility_line1')
    let line_2 = $(this).attr('facility_line2')

    $('input[name="peme[facility_id]"]').val(id)

    map = new google.maps.Map(document.getElementById('map'), {
      center: {lat: 14.599512, lng: 120.984222},
      zoom: 20,
      size: new google.maps.Size(200, 200)
    })

    var bounds = new google.maps.LatLngBounds()

    var position = new google.maps.LatLng(parseFloat(lat), parseFloat(long))
    bounds.extend(position)

    marker = new google.maps.Marker({
      position: position,
      map: map,
      clickable: true,
      title: code
    })

    map.fitBounds(bounds)

    let facility_name = name + " | " + line_1 + " " + line_2
    $('#peme_code').val(facility_name)
  });

  $('#selectFacilityForm').submit(function(e) {
    if ($('input[name="peme[facility_id]"]').val() == "") {
      e.preventDefault()
      $('.ajs-message.ajs-error.ajs-visible').remove()
      alertify.error('<i class="close icon"></i>Please select a facility')
    } else {
      return true
    }
  });
});

onmount('.evoucher-container' ,function(){
  const today = new Date();
  $('#evouch_dob').calendar({
    type: 'date',
    monthFirst: true,
    maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
    formatter: {
      date: function(date, settings) {
        if (!date) return '';
        var day = date.getDate() + '';
        if (day.length < 2) {
          day = '0' + day;
        }
        var month = (date.getMonth() + 1) + '';
        if (month.length < 2) {
          month = '0' + month;
        }
        var year = date.getFullYear();
        return month + '/' + day + '/' + year;
      }
    }
  });

  $.fn.form.settings.rules.mobileChecker2 = function(param) {
    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmaked_value.length == "10") {
      return true
    } else {
      return false
    }
  };

  const valid_mobile_prefix = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994", "976", "975", "995", "940", "946", "950", "992", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  $.fn.form.settings.rules.mobilePrefixChecker2 = function(param) {

    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    return valid_mobile_prefix.indexOf(unmaked_value.substring(0, 3)) == -1 ? false : true

  };

  $('#upload_secondary').click(function() {
    $('#secondary_id').click()
  });

  $('#upload_primary').click(function() {
    $('#primary_id').click()
  });

  $('#primary_id').change(function(){
    let file = event.target.files[0];
    var fileName = file.name;

    if (file.size < 5000000)
    {
      var ispic = checkfiletype(fileName);
      if (ispic)
      {
        $('#capture_primary').hide()
        $('.upload_txt_primary').text(file.name + " ")
        $('#remove_primary').show();
      }
      else if (!ispic)
      {
        $(this).val('')
        $('.upload_txt_primary').text('Upload Primary ID ')
        alertify.error('<i id="notification_error" class="close icon"></i><p>Acceptable file types are jpg, jpeg and png only</p>');
      }
    }
    else
    {
      $(this).val('')
      $('.upload_txt_primary').text('Upload Primary ID ')
      alertify.error('<i id="notification_error" class="close icon"></i><p>Maximum file size is 5 MB</p>');
    }
  });

  $('#remove_primary').click(function(){
    $('#primary_id').val(null);
    $('.upload_txt_primary').text('Upload Primary ID ')
    $('#capture_primary').show()
    $(this).hide();
    $('#delete-primary-id').submit()
  });

  $('#remove_secondary').click(function(){
    $('#secondary_id').val(null);
    $('.upload_txt_secondary').text('Upload Secondary ID ')
    $('#capture_secondary').show()
    $(this).hide();
    $('#delete-secondary-id').submit()
  });

  $('#secondary_id').change(function(){
    let file = event.target.files[0];
    var fileName = file.name;

    if (file.size < 5000000)
    {
      var ispic = checkfiletype(fileName);
      if (ispic)
      {
        $('#capture_secondary').hide()
        $('.upload_txt_secondary').text(file.name + " ")
        $('#remove_secondary').show();
      }
      else if (!ispic)
      {
        $(this).val('')
        $('.upload_txt').text('Upload Secondary ID ')
        alertify.error('<i id="notification_error" class="close icon"></i><p>Acceptable file types are jpg, jpeg and png only</p>');
      }
    }
    else
    {
      $(this).val('')
      $('.upload_txt').text('Upload Secondary ID ')
      alertify.error('<i id="notification_error" class="close icon"></i><p>Maximum file size is 5 MB</p>');
    }
  });

  $.fn.form.settings.rules.checkAge = function(param) {
      let age_from = $('#evoucher_age_from').val()
      let age_to = $('#evoucher_age_to').val()
      let age = calculateAge(param)
      if ( age >= age_from && age <= age_to )
      {
        return true
      }
      else
      {
        return false
      }
  };

  $('#evoucher_gender_Male').change(function(){
    let male = $('#evoucher_male').val()
    if ( male == "false" )
     {
       alertify.error('<i id="notification_error" class="close icon"></i><p>You are not allowed to avail the package in the e-voucher reason: Gender is not eligible</p>');
       $('#evoucher_gender_Male').attr('checked',false);
     }
  });

  $('#evoucher_gender_Female').change(function(){
    let female = $('#evoucher_female').val()
    if ( female == "false" )
    {
       alertify.error('<i id="notification_error" class="close icon"></i><p>You are not allowed to avail the package in the e-voucher reason: Gender is not eligible</p>');
       $('#evoucher_gender_Female').attr('checked',false);
    }
  });

  function checkfiletype (fileName)
  {
    var ext = "";
    var i = fileName.lastIndexOf('.');
    if (i > 0) {
        ext = fileName.substring(i+1);
    }
    switch (ext.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    return true;
    }
  };

  function calculateAge(birthdate) {
    var today = new Date();
    var birthDate = new Date(birthdate);
    var age = today.getFullYear() - birthDate.getFullYear();
    var m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
        age--;
    }
    return age;
  }

  let regex_address = /[a-z0-9A-Z@._-]/;
  $('#peme_address').keyup(function(){
      let array = $('#peme_address').val().split("")
      if (regex_address.test(array.slice(-1)[0]) == false){
      let peme_address = array.slice(0, -1).join("")
      $('#peme_address').val(peme_address)
    }
  });

  $('.person.name').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[a-zA-Z\s,.-]/;

    if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key) == false){
      return false;
    }else{
      $(this).on('focusout', function(evt){
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  });

  // let mobiles = [];
  // $.each( JSON.parse($('input[id="mobiles"]').val()), function(index, value) {
  //   mobiles.push( value.replace(/-/g, '').replace(/_/g, '') )
  // });
  // $.fn.form.settings.rules.checkMobile = function(param) {
  //   let unmasked_value = param.replace(/-/g, '').replace(/_/g, '')
  //   return ( !mobiles.includes(unmasked_value) )
  // };

  let peme_mobile = $('#evoucher_mobile').val()
  peme_mobile = peme_mobile.replace(/-/g, '').replace(/_/g, '')
  let account_code = $('#account_code').val()
  let csrf2 = $('input[name="_csrf_token"]').val();
  $.ajax({
    url:`/${locale}/peme/${account_code}/member`,
    headers: {"X-CSRF-TOKEN": csrf2},
    type: 'get',
    success: function(response){
      let data = JSON.parse(response);

      let array = $.map(data, function(value, index) {
        return [value];
      });

      $.fn.form.settings.rules.checkMobile = function(param) {
        param = param.replace(/-/g, '').replace(/_/g, '')
        return array.indexOf(param) == -1 ? true : false;
      }
      array.splice($.inArray(peme_mobile, array),1)
      $.fn.form.settings.rules.checkEditMobile = function(param) {
        param = param.replace(/-/g, '').replace(/_/g, '')
        // let hiddenRole = $('.hidden-role-name').val().toLowerCase()
        return $.inArray(param, array) == -1 ? true : false;
      }

      // $.fn.form.settings.rules.checkLimitAmount = function(param) {
      //   return param != "" ? true : false
      // }
      $('#validateEvoucher')
        .form({
          inline: true,
          on: 'blur',
          fields: {
            'evoucher[first_name]': {
              identifier: 'evoucher[first_name]',
              rules: [{
              type: 'empty',
                prompt: 'Please enter First Name'
              },
        {
          type   : 'maxLength[150]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/[a-zA-Z\s,.-]/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'evoucher[middle_name]': {
        identifier  : 'evoucher[middle_name]',
        optional    : 'true',
        rules: [{
          type   : 'maxLength[150]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/[a-zA-Z\s,.-]/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'evoucher[last_name]': {
        identifier: 'evoucher[last_name]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Last Name'
        },
        {
          type   : 'maxLength[150]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/[a-zA-Z\s,.-]/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'evoucher[suffix]': {
        identifier  : 'evoucher[suffix]',
        optional    : 'true',
        rules: [{
          type   : 'maxLength[10]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/[a-zA-Z\s,.-]/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'evoucher[birthdate]': {
        identifier: 'evoucher[birthdate]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Birthdate'
        },
        {
          type   : 'checkAge[param]',
          prompt : 'You are not allowed to avail the package in the e-voucher reason: Age is not eligible'
        }]
      },
      'evoucher[civil_status]': {
        identifier: 'evoucher[civil_status]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Civil Status'
        }]
      },
      'evoucher[mobile]': {
        identifier: 'evoucher[mobile]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Mobile Number'
        },
        {
          type   : 'checkMobile[param]',
          prompt : 'Mobile Number already exists'
        },
        {
          type   : 'mobileChecker2[param]',
          prompt : 'Please enter a valid mobile number'
        },
        {
          type   : 'mobilePrefixChecker2[param]',
          prompt : 'Invalid Mobile Number prefix'
        }
        ]
      },
      'evoucher[email]': {
        identifier: 'evoucher[email]',
        optional: 'true',
        rules: [
        {
          type   : 'regExp[/^[0-9A-Za-z@._-]*$/]',
          prompt : 'Only alphanumeric characters and special characters (@._-) are allowed'
        },
        {
          type   : 'email',
          prompt : 'Please enter a valid email'
        }]
      },
      'evoucher[gender]': {
        identifier: 'evoucher[gender]',
        rules: [
        {
          type   : 'checked',
          prompt : 'Please select an option'
        }
        ]
      }
    }
  });

      $('#validateEvoucher2')
        .form({
          inline: true,
          on: 'blur',
          fields: {
            'evoucher[first_name]': {
              identifier: 'evoucher[first_name]',
              rules: [{
              type: 'empty',
                prompt: 'Please enter First Name'
              },
        {
          type   : 'maxLength[150]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/[a-zA-Z\s,.-]/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'evoucher[middle_name]': {
        identifier  : 'evoucher[middle_name]',
        optional    : 'true',
        rules: [{
          type   : 'maxLength[150]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/[a-zA-Z\s,.-]/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'evoucher[last_name]': {
        identifier: 'evoucher[last_name]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Last Name'
        },
        {
          type   : 'maxLength[150]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/[a-zA-Z\s,.-]/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'evoucher[suffix]': {
        identifier  : 'evoucher[suffix]',
        optional    : 'true',
        rules: [{
          type   : 'maxLength[10]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/[a-zA-Z\s,.-]/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'evoucher[birthdate]': {
        identifier: 'evoucher[birthdate]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Birthdate'
        },
        {
          type   : 'checkAge[param]',
          prompt : 'You are not allowed to avail the package in the e-voucher reason: Age is not eligible'
        }]
      },
      'evoucher[civil_status]': {
        identifier: 'evoucher[civil_status]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Civil Status'
        }]
      },
      'evoucher[mobile]': {
        identifier: 'evoucher[mobile]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Mobile Number'
        },
        {
          type   : 'checkEditMobile[param]',
          prompt : 'Mobile Number already exists'
        },
        {
          type   : 'mobileChecker2[param]',
          prompt : 'Please enter a valid mobile number'
        },
        {
          type   : 'mobilePrefixChecker2[param]',
          prompt : 'Invalid Mobile Number prefix'
        }
        ]
      },
      'evoucher[email]': {
        identifier: 'evoucher[email]',
        optional: 'true',
        rules: [
        {
          type   : 'regExp[/^[0-9A-Za-z@._-]*$/]',
          prompt : 'Only alphanumeric characters and special characters (@._-) are allowed'
        },
        {
          type   : 'email',
          prompt : 'Please enter a valid email'
        }]
      },
      'evoucher[gender]': {
        identifier: 'evoucher[gender]',
        rules: [
        {
          type   : 'checked',
          prompt : 'Please select an option'
        }
        ]
      }
    }
  });

  let pic = $('#evoucher_primary_id_data').val();

  if(pic == "") {
    $('#validateEvoucher2')
    .form({
      inline: true,
      on: 'blur',
      fields: {
        'evoucher[first_name]': {
          identifier: 'evoucher[first_name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter First Name'
          },
          {
            type   : 'maxLength[150]',
            prompt : 'Please enter at most {ruleValue} characters'
          },
          {
            type   : 'regExp[/[a-zA-Z\s,.-]/]',
            prompt : 'Only letters and characters (.,-) are allowed'
          }]
        },
        'evoucher[middle_name]': {
          identifier  : 'evoucher[middle_name]',
          optional    : 'true',
          rules: [{
            type   : 'maxLength[150]',
            prompt : 'Please enter at most {ruleValue} characters'
          },
          {
            type   : 'regExp[/[a-zA-Z\s,.-]/]',
            prompt : 'Only letters and characters (.,-) are allowed'
          }]
        },
        'evoucher[last_name]': {
          identifier: 'evoucher[last_name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Last Name'
          },
          {
            type   : 'maxLength[150]',
            prompt : 'Please enter at most {ruleValue} characters'
          },
          {
            type   : 'regExp[/[a-zA-Z\s,.-]/]',
            prompt : 'Only letters and characters (.,-) are allowed'
          }]
        },
        'evoucher[suffix]': {
          identifier  : 'evoucher[suffix]',
          optional    : 'true',
          rules: [{
            type   : 'maxLength[10]',
            prompt : 'Please enter at most {ruleValue} characters'
          },
          {
            type   : 'regExp[/[a-zA-Z\s,.-]/]',
            prompt : 'Only letters and characters (.,-) are allowed'
          }]
        },
        'evoucher[birthdate]': {
          identifier: 'evoucher[birthdate]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          },
          {
            type   : 'checkAge[param]',
            prompt : 'You are not allowed to avail the package in the e-voucher reason: Age is not eligible'
          }]
        },
        'evoucher[civil_status]': {
          identifier: 'evoucher[civil_status]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Civil Status'
          }]
        },

        'evoucher[mobile]': {
          identifier: 'evoucher[mobile]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Mobile Number'
          },
          {
            type   : 'checkMobile[param]',
            prompt : 'Mobile Number already exists'
          },
          {
            type   : 'mobileChecker2[param]',
            prompt : 'Please enter a valid mobile number'
          },
          {
            type   : 'mobilePrefixChecker2[param]',
            prompt : 'Invalid Mobile Number prefix'
          }
          ]
        },

        'evoucher[email]': {
          identifier: 'evoucher[email]',
          optional: 'true',
          rules: [
          {
            type   : 'regExp[/^[0-9A-Za-z@._-]*$/]',
            prompt : 'Only alphanumeric characters and special characters (@._-) are allowed'
          },
          {
            type   : 'email',
            prompt : 'Please enter a valid email'
          }]
        },
        'evoucher[gender]': {
          identifier: 'evoucher[gender]',
          rules: [
          {
            type   : 'checked',
            prompt : 'Please select gender'
          }
          ]
        }
        // 'evoucher[primary_id]': {
        //   identifier: 'evoucher[primary_id]',
        //   rules: [{
        //     type   : 'empty',
        //     prompt : 'Please upload Primary ID'
        //   }]
        // }
      }
    })
  }

    }
  })

  // PRIMARY CAPTURE PHOTO

  $('#capture_primary').on('click', function(){
    let data;
    $('#modal_facial_capture')
    .modal({ autofocus: false, closable: false, observeChanges: true })
    .modal("show");
    var video;
    var webcamStream;
    var video = document.getElementById('video');
    var canvas = document.getElementById('canvas');
    var photo = document.getElementById('primary-photo-cam');
    var track;

    function clearphoto() {
      var context = canvas.getContext('2d');
      context.fillStyle = "#FFF";
      context.fillRect(0, 0, canvas.width, canvas.height);

      var data = canvas.toDataURL('image/png');
      photo.setAttribute('src', data);
    }

    navigator.mediaDevices.getUserMedia({ video: true, audio: false })
      .then(function(stream) {
          video.srcObject = stream;
          track = stream.getTracks()[0];
          video.play();
      })
      .catch(function(err) {
    });

    // TAKE PHOTO
    $('#take_image').on('click', function() {
      var context = canvas.getContext('2d');
      canvas.width = 320;
      canvas.height = 240;
      context.drawImage(video, 0, 0, 320, 240);

      data = canvas.toDataURL('image/png');
      $('p[role="append_new_capture"]').empty()

    })

    // SAVE PHOTO
    $('#submit_capture').on('click', function(e) {
      $('#photo').attr('src', data);
      $('#primary-photo-cam').val(data)
      $('#photo-web-cam').val(data)

      if($('#photo-web-cam').val() == ""){
        let error = '<div id="message" class="ui negative message"><ul class="list">'
        $('div[id="message"]').remove()
        $('p[role="append_new_capture"]').append(error + '<li>Please take a photo.</li> </ul> </div>')
        e.preventDefault()
      } else {
        track.stop();
        clearphoto();
        $('#upload_primary').hide()
        $('#remove_primary_capture').show();
        $('.upload_txt_primary_capture').text('evoucher_primary_id.png ')
        $('#photo-web-cam').val("")
        $('#modal_facial_capture').modal("hide");
      }
    })

    $('.close.icon').on('click', function() {
      track.stop();
      clearphoto();
    })

    $('#remove_primary_capture').on('click', function() {
      $('#primary-photo-cam').val("")
      $('#primary_id').val(null);
      $('.upload_txt_primary_capture').text('Capture Photo ')
      $('.upload_txt_primary').text('Upload Primary ID ')
      $('#capture_primary').show()
      $('#upload_primary').show()
      $(this).hide();
    })
  })

  // SECONDARY CAPTURE PHOTO

  $('#capture_secondary').on('click', function(){
    let data;

    $('#modal_facial_capture2')
    .modal({ autofocus: false, closable: false, observeChanges: true })
    .modal("show");
    var video;
    var webcamStream;
    var video = document.getElementById('video2');
    var canvas = document.getElementById('canvas2');
    var photo = document.getElementById('secondary-photo-cam');
    var track;

    function clearphoto() {
      var context = canvas.getContext('2d');
      context.fillStyle = "#FFF";
      context.fillRect(0, 0, canvas.width, canvas.height);

      var data = canvas.toDataURL('image/png');
      photo.setAttribute('src', data);
    }

    navigator.mediaDevices.getUserMedia({ video: true, audio: false })
      .then(function(stream) {
          video.srcObject = stream;
          track = stream.getTracks()[0];
          video.play();
      })
      .catch(function(err) {
    });

    // TAKE PHOTO
    $('#take_image2').on('click', function() {
      var context = canvas.getContext('2d');
      canvas.width = 320;
      canvas.height = 240;
      context.drawImage(video, 0, 0, 320, 240);

      data = canvas.toDataURL('image/png');
      $('p[role="append_new_capture2"]').empty()

    })

    // SAVE PHOTO
    $('#submit_capture2').on('click', function(e) {
      $('#photo2').attr('src', data);
      $('#secondary-photo-cam').val(data)
      $('#photo-web-cam2').val(data)

      if($('#photo-web-cam2').val() == ""){
        let error = '<div id="message" class="ui negative message"><ul class="list">'
        $('div[id="message"]').remove()
        $('p[role="append_new_capture2"]').append(error + '<li>Please take a photo.</li> </ul> </div>')
        e.preventDefault()
      } else {
        track.stop();
        clearphoto();
        $('#upload_secondary').hide()
        $('#remove_secondary_capture').show();
        $('.upload_txt_secondary_capture').text('evoucher_secondary_id.png ')
        $('#photo-web-cam2').val("")
        $('#modal_facial_capture2').modal("hide");
      }
    })

    $('.close.icon').on('click', function() {
      track.stop();
      clearphoto();
    })

    $('#remove_secondary_capture').on('click', function() {
      $('#secondary-photo-cam').val("")
      $('#secondary_id').val(null);
      $('.upload_txt_secondary_capture').text('Capture Photo ')
      $('.upload_txt_secondary').text('Upload Secondary ID ')
      $('#capture_secondary').show()
      $('#upload_secondary').show()
      $(this).hide();
    })
  })
});
