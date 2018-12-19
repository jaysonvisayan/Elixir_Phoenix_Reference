onmount('div[id="inpatient"]', function() {

  validate_admission_date()
 $('#invalid_emergency_submit').on('click', function() {
        $('div[id="message_emergency"]').remove()
        $('p#no_procedure_ruv').append('<div id="message_emergency" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>Please add at least one Disease/Procedure or RUV.</li> </ul> </div>')
        $("html, body").animate({
            scrollTop: 0
        }, "slow");
        return false;
    })

    var datetime = null,
            date = null;

    var update = function () {
        date = moment(new Date())
        datetime.html(date.format('dddd, MMMM Do YYYY, h:mm:ss a'));
    };

    $(document).ready(function(){
        datetime = $('#date_created')
        update();
        setInterval(update, 1000);
    });

    let start_date = $('input[name="authorization[start_date]"]').val()
    $('input#start_date').val(moment(start_date).format("YYYY-MM-DD"))
    $('label#show_date_created').html(moment(start_date).format("YYYY-MM-DD"))
    $('label#valid_until').html(moment(start_date).add(2, 'days').format("YYYY-MM-DD"))
    $('#emergency_submit').on('click', function() {
        $('#inpatient_form')
            .form({
                inline: true,
                on: 'blur',
                fields: {
                    'authorization[start_date]': {
                        identifier: 'authorization[start_date]',
                        rules: [{
                            type: 'empty',
                            prompt: 'Please enter start date'
                        }]
                    },
                    'authorization[practitioner_id]': {
                        identifier: 'authorization[practitioner_id]',
                        rules: [{
                            type: 'empty',
                            prompt: 'Please select a practitioner'
                        }]
                    },
                    'chief_complaint': {
                        identifier: 'authorization[chief_complaint]',
                        rules: [{
                            type: 'maxLength[1000]',
                            prompt: 'Chief Complaint should not exceed 1000 characters'
                        }]
                    },
                    'internal_remarks': {
                        identifier: 'authorization[internal_remarks]',
                        rules: [{
                            type: 'maxLength[1000]',
                            prompt: 'Inernal Remarks should not exceed 1000 characters'
                        }]
                    }
                }
            })
    })

    let currentDate = new Date()

    $('#ip_admission_date').calendar({
        type: 'date',
        ampm: false,
        initialDate: null,
        minDate: new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate() - 3),
        monthFirst: false,
        onChange: function(discharge_date, text, mode){
          discharge_date = new Date(discharge_date)
          //$('input[name="authorization[discharge_datetime]"]').val(discharge_date)
          $('#ip_discharge_date').calendar("set date", discharge_date)
          let end = $('#ip_discharge_date').calendar("get date", date);
          let days = (discharge_date - end) / (1000 * 60 * 60 * 24);
          let roundedValue = Math.round(days * 10) / 10
          $('#lengthOfStay').val(roundedValue)
          $('#btnAddRoomAndBoard').removeClass("disabled")
          validate_admission_date_select(date)
        },
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
                return year + '-' + month + '-' + day;
            }
        }
    })

    $('#ip_discharge_date').calendar({
        type: 'date',
        ampm: false,
        startCalendar: $('#ip_admission_date'),
        monthFirst: false,
        onChange: function(date, text, mode){
          let start = $('#ip_admission_date').calendar("get date", date);
          let days = (date - start) / (1000 * 60 * 60 * 24);
          let roundedValue = Math.round(days * 10) / 10
          $('#lengthOfStay').val(roundedValue)
        },
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
                return year + '-' + month + '-' + day;
            }
        }
    })

    $('#btnDeleteDraft').on('click', function(){
       swal({
      title: 'Delete LOA request?',
      text: 'Deleting this LOA request will automatically remove this request from the system.',
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Request',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Request',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      showCloseButton: true,
      allowOutsideClick: false
    }).catch(swal.noop)
  })

  function validate_admission_date(){
    let admissionDate = $('input[name="authorization[admission_datetime]"]').val()
    let dischargeDate = $('input[name="authorization[discharge_datetime]"]').val()
    if(admissionDate == ""){
      $('#btnAddRoomAndBoard').addClass("disabled")
    }
  }

  function validate_admission_date_select(date){
    if(date == ""){
      $('#btnAddRoomAndBoard').addClass("disabled")
    }
  }

  $('#btn_approve_loa').on('click', function(){
    let authorization_id = $(this).attr('authorization_id')
    const csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url: `/authorizations/${authorization_id}/approve_authorization`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        if (response.message == undefined)
        {
          let obj = JSON.parse(response)
          swal({
            allowOutsideClick: false,
            allowEnterKey: false,
            allowEscapeKey: false,
            title: 'LOA Request',
            text: `Successfully Approved LOA! LOA No: ${obj.loa_number}`,
            type: 'warning',
            showCancelButton: true,
            confirmButtonText: 'OK',
            confirmButtonClass: 'ui positive button',
            buttonsStyling: false
          }).then(function () {
              window.location.replace(`/authorizations`);
          })
          $('button[class="swal2-cancel"]').remove()
        }
        else
        {
          swal({
            allowOutsideClick: false,
            allowEnterKey: false,
            allowEscapeKey: false,
            title: 'LOA Request',
            text: `${response.message}`,
            type: 'error',
            showCancelButton: true,
            confirmButtonText: 'OK',
            confirmButtonClass: 'ui positive button',
            buttonsStyling: false
          }).then(function () {
          })
          $('button[class="swal2-cancel"]').remove()
        }
      }
    })
  })

  let success = () => {
    swal({
      type: 'success',
      title: 'Successfully disapproved LOA.',
    }).then(() => {
        window.location.replace(`/authorizations`);
    })
  }

  $('#btn_disapprove_loa').on('click', function(){
    swal({
      allowOutsideClick: false,
      allowEnterKey: false,
      allowEscapeKey: false,
      title: 'Disapprove LOA?',
      type: 'warning',
      text: 'Please enter Reason for disapproving this LOA',
      input: 'text',
      confirmButtonText: 'Submit',
      showCancelButton: true,
      confirmButtonText: '<i class="icon check"></i> Yes, Disapprove LOA',
      confirmButtonColor: '#A9A9A9',
      cancelButtonText: '<i class="icon close"></i> No, Review LOA Details',
      confirmButtonClass: 'ui gray small button',
      cancelButtonClass: 'ui gray small button',
      reverseButtons: true,
      preConfirm: (value) => {
        return new Promise((resolve) => {
            if (value == "") {
              swal.showValidationError('Please enter reason')
              $('.swal2-confirm.swal2-styled').prop('disabled', false)
              $('.swal2-cancel.swal2-styled').prop('disabled', false)
            } else {
              resolve()
            }
        })
      },
    }).then((result) => {
      let authorization_id = $(this).attr('authorization_id')
      const csrf = $('input[name="_csrf_token"]').val();
      $.ajax({
        url: `/authorizations/${authorization_id}/disapprove_authorization/${result}`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'GET',
        success: function(response){
          let decoded = JSON.parse(response)
          if(decoded){
            success()
          } else {
            alert('Failed to disapprove LOA')
          }
        }
      })
    })
  })
})

onmount('div[role="rb_inpatient_modal"]', function(){
  console.log(2123)

  $('input[name="authorization[room_number]"]').on('keyup', function(){
    if($(this).val() != ""){
    let csrf = $('input[name="_csrf_token"]').val();
    let room_number = $(this).val()
    $.ajax({
        url: `/authorizations/get_facility_room_rate/${room_number}`,
        headers: {
            "X-CSRF-TOKEN": csrf
        },
        type: 'get',
        success: function(response) {
          const data = JSON.parse(response)
          $('input[name="authorization[room_category]"]').val(data.facility_room_type)
          $('input[name="authorization[room_rate]"]').val(data.facility_room_rate)
        },
    })
    }
    else{
      $('input[name="authorization[room_category]"]').val("")
      $('input[name="authorization[room_rate]"]').val("")
    }
  })

  if($('#btnAddRoomAndBoard').attr('arbID') !="" ){
    $('#btnAddRoomAndBoard').removeClass('disabled')
  }
})

onmount('div[name="formValidateStep4Inpatient"]', function() {
    const procedure_count = $('#authorizationProcedureCount').val()
    const ruv_count = $('#authorizationRUVCount').val()

    $.fn.form.settings.rules.checkProcedureCount = function() {
        if (procedure_count == 0 && ruv_count == 0) {
            alertify.error('<i class="close icon"></i><p>Please select at least one Procedure or RUV!</p>')
            return false
        } else {
            return true
        }
    }

    function chiefComplaintChecker() {
        let chief_complaint = $('textarea[name="authorization[chief_complaint]"]').val()
        if (chief_complaint.length > 1000) {
            return false
        } else {
            return true
        }
    }
    $('div[id="btnAddRoomAndBoard"]').on('click', function() {
      $('div[role="rb_inpatient_modal"]')
          .modal({
              closable: false,
              observeChanges: true,
              onShow: function() {
                let currentDate = new Date()
                let admissionDateVal = $('#ip_admission_date').calendar("get date", currentDate)
                let dischargeDateVal = $('#ip_discharge_date').calendar("get date", currentDate)
                if($('#btnAddRoomAndBoard').attr('arbID') == ""){
                $('div[name="transfer_date"]').hide()
                $('div[name="transfer_time"]').hide()
                $('#room_admission_date').calendar({
                  type: 'date',
                  ampm: false,
                  startDate: $('#ip_admission_date'),
                  monthFirst: false,
                  minDate: new Date(admissionDateVal.getFullYear(), admissionDateVal.getMonth(), admissionDateVal.getDate()),
                   maxDate: new Date(dischargeDateVal.getFullYear(), dischargeDateVal.getMonth(), dischargeDateVal.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
                $('.time_from').calendar({
                  ampm: false,
                  type: 'time',
                  // endCalendar: $('.time_to')
                });
                }else{
                  let csrf = $('input[name="_csrf_token"]').val();
                  let arb_id = $('#btnAddRoomAndBoard').attr('arbID')
                  $.ajax({
                    url: `/authorizations/get_authorization_room/${arb_id}`,
                     headers: {
                      "X-CSRF-TOKEN": csrf
                    },
                    type: 'get',
                    success: function(response) {
                      const data = JSON.parse(response)
                      console.log(data)
                      $('input[name="authorization[admission_date]"]').val(data.admission_date)
                      $('input[name="authorization[admission_time]"]').val(data.admission_time)
                      $('input[name="authorization[admission_date]"]').attr("readonly", true)
                      $('input[name="authorization[admission_time]"]').attr("readonly", true)
                      $('#prev_authorization_room_id').val(arb_id)
                      $('div[name="transfer_date"]').show()
                      $('div[name="transfer_time"]').show()
                $('#room_transfer_date').calendar({
                  type: 'date',
                  ampm: false,
                  startDate: $('#room_admission_date'),
                  monthFirst: false,
                  minDate: new Date(data.admission_date),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
                $('#room_transfer_time').calendar({
                  ampm: false,
                  type: 'time',
                  // endCalendar: $('.time_to')
                });
                    },
                  })
                }
              }
          })
      .modal('show');
    });

  $('.edit_arb').on('click', function(){
    let authorization_room_id = $(this).attr('authorization_room')
    let admission_date = $(this).attr('admission_date')
    let admission_time = $(this).attr('admission_time')
    let transfer_date = $(this).attr('transfer_date')
    let transfer_time = $(this).attr('transfer_time')
    let room_type = $(this).attr('room_type')
    let room_number = $(this).attr('room_number')
    let room_rate = $(this).attr('room_rate')
    $('input[name="authorization[admission_date]"]').val(admission_date)
    $('input[name="authorization[admission_time]"]').val(admission_time)
    $('input[name="authorization[transfer_date]"]').val(transfer_date)
    $('input[name="authorization[transfer_time]"]').val(transfer_time)
    $('input[name="authorization[room_category]"]').val(room_type)
    $('input[name="authorization[room_number]"]').val(room_number)
    $('input[name="authorization[room_rate]"]').val(room_rate)
    $('#authorization_room_id').val(authorization_room_id)
    $('#room_and_board_submit').removeClass()
    $('#room_and_board_submit').addClass('ui right floated blue button')
    $('#room_and_board_submit').html('<i class="save icon"></i>Update')
  $('div[role="rb_inpatient_modal"]').modal({
      closable: false,
      autofocus: false,
      observeChanges: true
    }).modal('show')
  })

    $('.btnRemoveRoomAndBoard').on('click', function() {
      let authorization_id = $(this).attr('authorization_id')
      let auth_room_and_board_id = $(this).attr('authorization_room_id')
      swal({
        title: 'Delete Room and Board?',
        text: 'Deleting this Room will permanently remove it from the system.',
        type: 'question',
        showCancelButton: true,
        cancelButtonText: '<i class="remove icon"></i> No, Keep Room',
        confirmButtonText: '<i class="check icon"></i> Yes, Delete Room',
        cancelButtonClass: 'ui tiny negative button',
        confirmButtonClass: 'ui tiny positive button',
        reverseButtons: true,
        buttonsStyling: false
      }).then(function() {
        window.location.href = `/authorizations/${authorization_id}/delete_room_and_board/${authorization_room_id}`
      }).catch(swal.noop)
    })

    $('div[id="btnAddPractitioner"]').on('click', function() {
      $('div[role="prac_inpatient_modal"]')
        .modal({
            closable: false,
            observeChanges: true,
            onShow: function() {
                $('#unit_field').removeClass('error')
                $('#unit_field').find('.prompt').remove()
                $('#procedure_field').removeClass('error')
                $('#procedure_field').find('.prompt').remove()
                $('div[id="message"]').remove()
                $('select#diagnosis').dropdown('clear')
                $('select#procedures').dropdown('clear')
            }
        })
      .modal('show');
    });

    $('.btnRemovePractitioner').on('click', function() {
        let authorization_procedure_id = $(this).attr('authorization_procedure_id')
        swal({
            title: 'Delete Disease/Procedure?',
            text: 'Deleting this Disease/Procedure will permanently remove it from the system.',
            type: 'question',
            showCancelButton: true,
            cancelButtonText: '<i class="remove icon"></i> No, Keep Disease/Procedure',
            confirmButtonText: '<i class="check icon"></i> Yes, Delete Disease/Procedure',
            cancelButtonClass: 'ui tiny negative button',
            confirmButtonClass: 'ui tiny positive button',
            reverseButtons: true,
            buttonsStyling: false
        }).then(function() {
            window.location.replace(`/authorizations/${authorization_procedure_id}/delete_emergency_authorization_procedure`);
        }).catch(swal.noop)
    })

    $('div[id="btnAddDiseaseProcedure"]').on('click', function() {
            //let authorization_date = $('input[name="authorization[admission_datetime]"]').val()
            //let chief_complaint = $('textarea[id="authorization_chief_complaint"]').val()
            //let practitioner_id = $('select[name="authorization[practitioner_id]"]').val()
            //let special_approval = $('select[name="authorization[special_approval_id]"]').val()
            //let internal_remarks = $('textarea[name="authorization[internal_remarks]"]').val()
            //$('input[name="authorization[datetime]"]').val(authorization_date)
            //$('input[name="authorization[chief_complaint]"]').val(chief_complaint)
            //$('input[name="authorization[practitioner_id]"]').val(practitioner_id)
            //$('input[name="authorization[special_approval]"]').val(special_approval)
            //$('input[name="authorization[internal_remarks]"]').val(internal_remarks)
            $('div[role="dp_inpatient_modal"]')
                .modal({
                    closable: false,
                    observeChanges: true,
                    onShow: function() {
                        $('#unit_field').removeClass('error')
                        $('#unit_field').find('.prompt').remove()
                        $('#procedure_field').removeClass('error')
                        $('#procedure_field').find('.prompt').remove()
                        $('div[id="message"]').remove()
                        $('select#diagnosis').dropdown('clear')
                        $('select#procedures').dropdown('clear')
                    }
                })
                .modal('show');
    });

    $('.btnRemoveProcedure').on('click', function() {
        let authorization_procedure_id = $(this).attr('authorization_procedure_id')
        swal({
            title: 'Delete Disease/Procedure?',
            text: 'Deleting this Disease/Procedure will permanently remove it from the system.',
            type: 'question',
            showCancelButton: true,
            cancelButtonText: '<i class="remove icon"></i> No, Keep Disease/Procedure',
            confirmButtonText: '<i class="check icon"></i> Yes, Delete Disease/Procedure',
            cancelButtonClass: 'ui tiny negative button',
            confirmButtonClass: 'ui tiny positive button',
            reverseButtons: true,
            buttonsStyling: false
        }).then(function() {
            window.location.replace(`/authorizations/${authorization_procedure_id}/delete_emergency_authorization_procedure`);
        }).catch(swal.noop)
    })

    $('.btnRemoveRUV').on('click', function() {
        let authorization_ruv_id = $(this).attr('authorization_ruv_id')
        swal({
            title: 'Delete RUV?',
            text: 'Deleting this RUV will permanently remove it from the system.',
            type: 'question',
            showCancelButton: true,
            cancelButtonText: '<i class="remove icon"></i> No, Keep RUV',
            confirmButtonText: '<i class="check icon"></i> Yes, Delete RUV',
            cancelButtonClass: 'ui tiny negative button',
            confirmButtonClass: 'ui tiny positive button',
            reverseButtons: true,
            buttonsStyling: false
        }).then(function() {
            window.location.replace(`/authorizations/${authorization_ruv_id}/delete_emergency_authorization_ruv`);
        }).catch(swal.noop)
    })

    $('#unit').keypress(function(evt) {
        evt = (evt) ? evt : window.event;
        var charCode = (evt.which) ? evt.which : evt.keyCode;
        if (charCode == 8 || charCode == 37) {
            return true;
        } else if (charCode == 46) {
            return false;
        } else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
            return false;
        } else if (this.value.length == 0 && evt.which == 48) {
            return false;
        }

        return true;
    });

});

$('#empty_diagnosis').on('click', function() {
    $('div[id="message_emergency"]').remove()
    $('p#no_diagnosis').append('<div id="message_emergency" class="ui negative message"> <div class="header">There were some errors with your submission </div> <ul class="list"><li>Please add at least one diagnosis.</li> </ul> </div>')
})

onmount('button[id="append_emergency_procedure"]', function() {
    function chiefComplaintChecker() {
        let chief_complaint = $('textarea[name="authorization[chief_complaint]"]').val()
        if (chief_complaint.length > 1000) {
            return false
        } else {
            return true
        }
    }
    $('button[id="append_emergency_procedure"]').on('click', function() {

        let procedures = $("select[id='procedures'] option:selected").val();
        let unit = $('#unit').val()
        let amount = $('#amount').val()

        $('#unit_field').removeClass('error')
        $('#unit_field').find('.prompt').remove()
        $('#procedure_field').removeClass('error')
        $('#procedure_field').find('.prompt').remove()
        if ((unit == "") || (procedures == "")) {
            if (procedures == "") {
                $('#procedure_field').addClass('error')
                $('#procedure_field').append(`<div class="ui basic red pointing prompt label transition visible">Please select a payor procedure</div>`)
            } else {
                $('#unit_field').addClass('error')
                $('#unit_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter unit</div>`)
            }
        } else {
            $('div[id="message"]').remove()
            let number = $('#number').val()
            $("#number").val(parseInt(number) + 1)
            let procedure_select = $('#procedure_select').clone()
            let i = $("#number").val()
            $('div#append').append(procedure_select)

            $('div#append').find('div#procedure_select').attr('id', 'procedure[' + i + ']').attr('number', i)
            $('div#append').find('select[role="procedures"]').attr('id', 'procedure_select[' + i + '][procedure_id]').attr('name', 'procedure[' + i + '][procedure_id]')
            $('div#append').find('div.dropdown.procedure').addClass('disabled')
            let select_value = $('select[id="procedures"]').dropdown('get value')
            let select_text = $('select[id="procedures"]').dropdown('get text')
            $('select[name="procedure[' + i + '][procedure_id]"]').dropdown('set value', select_value)
            let appended = $('select[name="procedure[' + i + '][procedure_id]"]').val()
            $('#procedure').find('.active.selected').remove()
            $('select[id="procedures"] option[value="' + select_value + '"]').remove()
            $('div#append').find('select[role="procedures"]').removeAttr('role')

            $('div#append').find('input[role="unit"]').attr('id', 'procedure_select[' + i + '][unit]').attr('name', 'procedure[' + i + '][unit]').addClass('validate_required').prop('readonly', true)
            $('div#append').find('input[role="unit"]').removeAttr('role')

            $('div#append').find('input[role="amount"]').attr('id', 'procedure_select[' + i + '][amount]').attr('name', 'procedure[' + i + '][amount]').addClass('validate_required')
            $('div#append').find('input[role="amount"]').removeAttr('role')

            $('#procedure_select').find('input#unit').val('')
            $('#procedure_select').find('input#amount').val('')
            $('select[name="procedure[' + i + '][procedure_id]"]').dropdown('set value', select_value)
            $('#procedures').dropdown('clear')
            $('.dropdown').dropdown()
            $('#append').find('#add_label').css('visibility', 'hidden');
            $('div#append').find('#append_emergency_procedure').html('<i class="trash icon"></i>')
            $('div#append').find('#append_emergency_procedure').removeClass('basic')
            $('div#append').find('#append_emergency_procedure').addClass('red')
            $('div#append').find('#append_emergency_procedure').attr('id', 'delete[' + i + ']')
            $('select[id="procedures"]').dropdown('clear')

            $('body').on('click', 'button[id="delete[' + i + ']"]', function() {
                let text = $('select[id="procedure_select[' + i + '][procedure_id]"]').dropdown('get text')
                let value = $('select[id="procedure_select[' + i + '][procedure_id]"]').dropdown('get value')
                $('select[id="procedures').append($('<option>', {
                    value: value,
                    text: text
                }))
                $('div#append').find('div[number=' + i + ']').find('div.dropdown.procedure').remove()
                $('div#append').find('div[number=' + i + ']').remove()
                $('#amount').val('')
                $('#unit').val('')
            })
            $('#amount').val('')
            $('#amount').removeData()
            $('#unit').prop("readonly", true)
        }
    })

    $("select[id='procedures']").on('change', function(e) {
        let facility_id = $('input[name="authorization[facility_id]"]').val()
        let csrf = $('input[name="_csrf_token"]').val();
        let hidden_procedure = $("#hidden_procedure").val($("select[id='procedures']").val())
        let payor_procedure_id = $("#hidden_procedure").val()
        $('#amount').val('')
        $('#unit').val('')
        if ($(this).val().length > 0) {
            $('#unit_field').removeClass('error')
            $('#unit_field').find('.prompt').remove()
            $('#procedure_field').removeClass('error')
            $('#procedure_field').find('.prompt').remove()
        }
        $.ajax({
            url: `/api/v1/authorizations/${payor_procedure_id}/get_emergency_solo_amount/${facility_id}`,
            headers: {
                "X-CSRF-TOKEN": csrf
            },
            type: 'get',
            success: function(response) {
                const data = JSON.parse(response)
                $('#dummy_amount').val(data)
            },
        })
        $('#unit').prop("readonly", false)
    })

    $("#unit").on('keyup', function(e) {
        if ($(this).val().length > 0) {
            let unit = $('#unit').val()
            let amount = $('#dummy_amount').val()
            $('#unit_field').removeClass('error')
            $('#unit_field').find('.prompt').remove()
            $('#amount').val(unit*amount)
        } else {
            $('#unit').val('')
            $('#amount').val('')
        }
    })
    $('.actions').find('.btnAddEmergencyProcedure').on('click', function(e) {
        $(this).find('.btnAddEmergencyProcedure').removeAttr('type')
        let input_checker = true
        if (validate_text_inputs() == false) {
            input_checker = false
        }

        function validate_text_inputs() {
            let valid = true
            $('.validate_required').each(function() {
                $(this).on('keyup', function(e) {
                    if ($(this).val().length > 0) {
                        $(this).closest('div').removeClass('error')
                        $(this).closest('div').find('.prompt').remove()
                    }
                })
                $(this).closest('div').removeClass('error')
                $(this).closest('div').find('.prompt').remove()
                let field = $(this).val()
                if (field == "") {
                    let field_name = $(this).closest('div').find('label').html().toLowerCase()
                    $(this).closest('div').addClass('error')
                    $(this).closest('div').append(`<div class="ui basic red pointing prompt label transition visible">Please enter ${field_name}</div>`)
                    valid = false
                }
            })
            return valid
        }

        let diagnosis = $('#diagnosis').val()
        if (diagnosis == "") {
            $('#diagnosis_field').removeClass('error')
            $('#diagnosis_field').find('.prompt').remove()
            $('#diagnosis_field').addClass('error')
            $('#diagnosis_field').append(`<div class="ui basic red pointing prompt label transition visible">Please select a diagnosis</div>`)
        } else if (input_checker == true) {
            if ($('div#append').html().length == 0) {
                $('div[id="message"]').remove()
                $('p#no_procedure').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div> <ul class="list"><li>Please add at least one procedure.</li> </ul> </div>')
            } else {
                $('.actions').find('.btnAddEmergencyProcedure').removeAttr('type')
            }
        }
        $("#diagnosis").on('keyup', function(e) {
            if ($(this).val().length > 0) {
                $('#diagnosis_field').removeClass('error')
                $('#diagnosis_field').find('.prompt').remove()
            }
        })
    })

    $('#btnAddEmergencyRUV').on('click', function() {
        let chief_complaint_checker = chiefComplaintChecker()
        if ($('input[id="authorization_start_date"]').val() == "" || $('select[id="authorization_practitioner_id"]').val() == "" || chief_complaint_checker == false) {
            if (chief_complaint_checker == true) {
                alertify.error('<i id="notification_error" class="close icon"></i><p>Please select a practitioner first</p>');
            } else {
                alertify.error('<i class="close icon"></i><div class="header">Please select Practitioner first, Chief Complaint should not exceed 1000 characters</p>');
            }
        } else {
            if ($('select[name="authorization[ruv_id]"]').val() == "") {
                $('select[name="authorization[ruv_id]"]').closest('.dropdown').closest('.field').addClass('error')
                $('select[name="authorization[ruv_id]"]').closest('.dropdown').closest('.field').append('<div class="ui basic red pointing prompt label transition visible">Please enter RUV</div>')
            } else {
                let authorization_id = $('input[name="authorization[authorization_id]"]').val()
                let facility_ruv_id = $('select[name="authorization[ruv_id]"]').val()
                let practitioner_id = $('select[name="authorization[practitioner_id]"').val()
                let authorization_date = $('input[name="authorization[admission_datetime]"]').val()
                let csrf = $('input[name="_csrf_token"]').val();
                $.ajax({
                    url: `/authorizations/${authorization_id}/create_emergency_authorization_ruv`,
                    headers: {
                        "X-CSRF-TOKEN": csrf
                    },
                    data: {
                        authorization_params: {
                            "facility_ruv_id": facility_ruv_id,
                            "practitioner_id": practitioner_id,
                            "admission_datetime": authorization_date
                        }
                    },
                    type: 'post',
                    success: function(response) {
                        location.reload()
                    },
                })
            }
        }
    })

    $('select[name="authorization[ruv_id]"]').on('change', function() {
        $(this).closest('.dropdown').closest('.field').removeClass('error')
        $(this).closest('.dropdown').closest('.field').find('.prompt').remove()
    })
})

onmount('div[role="LOAFileUpload"]', function() {

    function alert_error_file() {
        alertify.error('<i id="notification_error" class="close icon"></i><p>Acceptable file types are jpg, jpeg and png.</p>');
        alertify.defaults = {
            notifier: {
                delay: 5,
                position: 'top-right',
                closeButton: false
            }
        };
    }

    function alert_error_size() {
        alertify.error('<i id="notification_error" class="close icon"></i><p>Maximum file size is 5 MB.</p>');
        alertify.defaults = {
            notifier: {
                delay: 5,
                position: 'top-right',
                closeButton: false
            }
        };
    }


    let counter = 1
    let delete_array = []

    $('#addFile').on('click', function() {
        let file_id = '#file_' + counter
        $('#filePreviewContainer').append(`<input type="file" class="display-none" id="file_${counter}" name="facility[files][]">`)
        $(file_id).on('change', function() {
            let file = $(file_id)[0].files[0]
            let file_type = $(file_id)[0].files[0].type
            let file_name = $(file_id)[0].files[0].name
            let icon = 'file outline'
            if ((file_name.indexOf('.png') >= 0) || (file_name.indexOf('.jpg') >= 0) || (file_name.indexOf('.jpeg') >= 0)) {
                if (file.size < 5444444) {
                    file = (window.URL || window.webkitURL).createObjectURL(file)
                } else {
                    $(this).val('')
                    alert_error_size()
                }
            } else {
                $(this).val('')
                alert_error_file()
            }
            if ($(this).val() != '') {
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
