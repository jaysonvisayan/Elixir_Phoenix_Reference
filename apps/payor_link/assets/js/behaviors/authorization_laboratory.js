onmount('form[id="oplab_form"]', function() {
    $('select#diagnosis').select2({
        placeholder: "Select diagnosis",
        theme: "bootstrap",
        minimumInputLength: 3
    })

    $('#date_issued').calendar({
        type: 'date',
        popupOptions: {
            position: 'right center',
            prefer: 'opposite',
            hideOnScroll: false
        },
        inline: false,
        formatter: {
            date: function(date, settings) {
                if (!date) return ''
                var day = date.getDate() + ''
                if (day.length < 2) {
                    day = '0' + day
                }
                var month = (date.getMonth() + 1) + ''
                if (month.length < 2) {
                    month = '0' + month
                }
                var year = date.getFullYear()
                return month + '/' + day + '/' + year
            }
        }
    })

    var im = new Inputmask("decimal", {
        allowMinus: false,
        radixPoint: ".",
        groupSeparator: ",",
        digits: 2,
        autoGroup: true,
        // prefix: '₱ ',
        rightAlign: false
    })
    var integer = new Inputmask("integer", {
        allowMinus: false,
        groupSeparator: ",",
        autoGroup: true,
        rightAlign: false
    })
    im.mask($('#senior_text'))
    im.mask($('#pwd_text'))
    im.mask($('#special_approval_amount'))
    integer.mask($('#unit'))

    $('#invalid_submit').on('click', function() {
        $('div[id="message"]').remove()
        $('p#no_procedure_ruv').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>At least one diagnosis is required.</li> </ul> </div>')
        $("html, body").animate({
            scrollTop: 0
        }, "slow")
        return false
    })

    $('#apds_submit').on('click', function() {
        $('div[id="message"]').remove()
        $('p#no_procedure_ruv').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>Adding procedure/s for at least one diagnosis is required.</li> </ul> </div>')
        $("html, body").animate({
            scrollTop: 0
        }, "slow")
        return false
    })

    $('#invalid_save').on('click', function() {
        $('div[id="message"]').remove()
        $('p#no_procedure_ruv').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>At least one diagnosis is required.</li> </ul> </div>')
        $("html, body").animate({
            scrollTop: 0
        }, "slow")
        return false
    })

    $('#apds_save').on('click', function() {
        $('div[id="message"]').remove()
        $('p#no_procedure_ruv').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>Adding procedure/s for at least one diagnosis is required.</li> </ul> </div>')
        $("html, body").animate({
            scrollTop: 0
        }, "slow")
        return false
    })

    var datetime = null,
        date = null

    var update = function() {
        date = moment(new Date())
        datetime.html(date.format('dddd, MMMM Do YYYY, h:mm:ss a'))
    }

    $(document).ready(function() {
        datetime = $('#date_created')
        update()
        setInterval(update, 1000)
    })

    let start_date = $('input[name="authorization[start_date]"]').val()
    $('input#start_date').val(moment(start_date).format("YYYY-MM-DD"))
    $('label#valid_until').html(moment(start_date).add(2, 'days').format("YYYY-MM-DD"))

    $('#save').on('click', function() {
        $('div[id="message"]').remove()
        $('#sos').val('save')
        $('#senior_field').removeClass('error')
        $('#senior_field').closest('.field').find('.prompt').remove()
        $('#pwd_field').removeClass('error')
        $('#pwd_field').closest('.field').find('.prompt').remove()
        $('#sa_amount').removeClass('error')
        $('#sa_amount').closest('.field').find('.prompt').remove()
        $('#sa_field').removeClass('error')
        $('#sa_field').closest('.field').find('.prompt').remove()
        if ($('#senior').is(':checked') && ($('#senior_text').val() == '')) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#senior_field').addClass('error')
            $('#senior_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter senior discount</div>`)
        }
        if ($('#pwd').is(':checked') && ($('#pwd_text').val() == '')) {
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#pwd_field').addClass('error')
            $('#pwd_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter pwd discount</div>`)
        }
        if (parseInt(String($('#senior_text').val()).replace(/\,/g, '')) > $('#hidden_total_amount').val()) {
            $('div[id="message"]').remove()
            $('#senior_field').addClass('error')
            $('p#no_procedure_ruv').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>Senior Citizen/PWD Discount must not be equal to or greater than the total amount of the procedures.</li> </ul> </div>')
            $("html, body").animate({
                scrollTop: 0
            }, "slow")
            return false
        } else if (parseInt(String($('#pwd_text').val()).replace(/\,/g, '')) > $('#hidden_total_amount').val()) {
            $('div[id="message"]').remove()
            $('#pwd_field').addClass('error')
            $('p#no_procedure_ruv').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>Senior Citizen/PWD Discount must not be equal to or greater than the total amount of the procedures.</li> </ul> </div>')
            $("html, body").animate({
                scrollTop: 0
            }, "slow")
            return false
        } else if ((parseInt(String($('#senior_text').val()).replace(/\,/g, '')) + parseInt(String($('#pwd_text').val()).replace(',', ''))) > $('#hidden_total_amount').val()) {
            $('div[id="message"]').remove()
            $('#senior_field').addClass('error')
            $('#pwd_field').addClass('error')
            $('p#no_procedure_ruv').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>Senior Citizen/PWD Discount must not be equal to or greater than the total amount of the procedures.</li> </ul> </div>')
            $("html, body").animate({
                scrollTop: 0
            }, "slow")
            return false
        } else if ($('#member_pay').is(':not(:checked)')) {
            if ($('#special_approval').val() == "") {
                $('#sa_field').addClass('error')
                $('#sa_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter Special Approval</div>`)
            } else if ($('#special_approval_amount').val() == "") {
                $('#sa_amount').addClass('error')
                $('#sa_amount').append(`<div class="ui basic red pointing prompt label transition visible">Please enter Special Approval Amount</div>`)
            } else if ($('#hidden_member_pay').val() < $('#special_approval_amount').val()) {
                $('#sa_amount').addClass('error')
                $('#sa_amount').append(`<div class="ui basic red pointing prompt label transition visible">Special Approval amount must not be greater than Total Member Pays.</div>`)
            } else {
                $('#submit').removeAttr('type')
            }
        } else if (($('#senior').is(':not(:checked)')) && ($('#pwd').is(':not(:checked)'))) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#submit').removeAttr('type')
        } else if (($('#senior').is(':checked') && ($('#senior_text').val() != '')) && ($('#pwd').is(':checked') && ($('#pwd_text').val() != ''))) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#submit').removeAttr('type')
        } else if ($('#senior').is(':not(:checked)') && ($('#pwd').is(':checked') && ($('#pwd_text').val() != ''))) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#submit').removeAttr('type')
        } else if (($('#senior').is(':checked') && ($('#senior_text').val() != '')) && ($('#pwd').is(':not(:checked)'))) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#submit').removeAttr('type')
        }
        $("#special_approval").on('change', function(e) {
            $('#sa_field').removeClass('error')
            $('#sa_field').closest('.field').find('.prompt').remove()
        })
    })

    $("special_approval_amount").on('keyup', function(e) {
        $('#sa_amount').removeClass('error')
        $('#sa_amount').closest('.field').find('.prompt').remove()
    })

    $('#submit').on('click', function() {
        $('div[id="message"]').remove()
        $('#sos').val('submit')
        $('#senior_field').removeClass('error')
        $('#senior_field').closest('.field').find('.prompt').remove()
        $('#pwd_field').removeClass('error')
        $('#pwd_field').closest('.field').find('.prompt').remove()
        $('#sa_amount').removeClass('error')
        $('#sa_amount').closest('.field').find('.prompt').remove()
        $('#sa_field').removeClass('error')
        $('#sa_field').closest('.field').find('.prompt').remove()
        if ($('#senior').is(':checked') && ($('#senior_text').val() == '')) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#senior_field').addClass('error')
            $('#senior_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter senior discount</div>`)
        }
        if ($('#pwd').is(':checked') && ($('#pwd_text').val() == '')) {
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#pwd_field').addClass('error')
            $('#pwd_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter pwd discount</div>`)
        }
        if (parseInt(String($('#senior_text').val()).replace(/\,/g, '')) > $('#hidden_total_amount').val()) {
            $('div[id="message"]').remove()
            $('#senior_field').addClass('error')
            $('p#no_procedure_ruv').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>Senior Citizen/PWD Discount must not be equal to or greater than the total amount of the procedures.</li> </ul> </div>')
            $("html, body").animate({
                scrollTop: 0
            }, "slow")
            return false
        } else if (parseInt(String($('#pwd_text').val()).replace(/\,/g, '')) > $('#hidden_total_amount').val()) {
            $('div[id="message"]').remove()
            $('#pwd_field').addClass('error')
            $('p#no_procedure_ruv').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>Senior Citizen/PWD Discount must not be equal to or greater than the total amount of the procedures.</li> </ul> </div>')
            $("html, body").animate({
                scrollTop: 0
            }, "slow")
            return false
        } else if ((parseInt(String($('#senior_text').val()).replace(/\,/g, '')) + parseInt(String($('#pwd_text').val()).replace(',', ''))) > $('#hidden_total_amount').val()) {
            $('div[id="message"]').remove()
            $('#senior_field').addClass('error')
            $('#pwd_field').addClass('error')
            $('p#no_procedure_ruv').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div><ul class="list"><li>Senior Citizen/PWD Discount must not be equal to or greater than the total amount of the procedures.</li> </ul> </div>')
            $("html, body").animate({
                scrollTop: 0
            }, "slow")
            return false
        } else if ($('#member_pay').is(':not(:checked)')) {
            if ($('#special_approval').val() == "") {
                $('#sa_field').addClass('error')
                $('#sa_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter Special Approval</div>`)
            } else if ($('#special_approval_amount').val() == "") {
                $('#sa_amount').addClass('error')
                $('#sa_amount').append(`<div class="ui basic red pointing prompt label transition visible">Please enter Special Approval Amount</div>`)
            } else if ($('#hidden_member_pay').val() < $('#special_approval_amount').val()) {
                $('#sa_amount').addClass('error')
                $('#sa_amount').append(`<div class="ui basic red pointing prompt label transition visible">Special Approval amount must not be greater than Total Member Pays.</div>`)
            } else {
                $('#submit').removeAttr('type')
            }
        } else if (($('#senior').is(':checked') && ($('#senior_text').val() != '')) && ($('#pwd').is(':checked') && ($('#pwd_text').val() != ''))) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#submit').removeAttr('type')
        } else if ($('#senior').is(':not(:checked)') && ($('#pwd').is(':checked') && ($('#pwd_text').val() != ''))) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#submit').removeAttr('type')
        } else if (($('#senior').is(':checked') && ($('#senior_text').val() != '')) && ($('#pwd').is(':not(:checked)'))) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#submit').removeAttr('type')
        } else if (($('#senior').is(':not(:checked)')) && ($('#pwd').is(':not(:checked)'))) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#submit').removeAttr('type')
        }
        $("#special_approval").on('change', function(e) {
            $('#sa_field').removeClass('error')
            $('#sa_field').closest('.field').find('.prompt').remove()
        })
    })

    $("#senior_text").on('keyup', function(e) {
        $('#senior_field').removeClass('error')
        $('#senior_field').closest('.field').find('.prompt').remove()
    })

    $("#pwd_text").on('keyup', function(e) {
        $('#pwd_field').removeClass('error')
        $('#pwd_field').closest('.field').find('.prompt').remove()
    })

    $('select[name="authorization[chief_complaint]"]').on('change', function() {
        if ($(this).val() == "Others") {
            $('#others').removeAttr('style')
            $('#others').attr('style', 'margin-top: 10px')
            $('#others').val('')
        } else {
            $('#others').hide()
        }
    })

    if ($('#others').val() != "") {
        $('#others').removeAttr('style')
        $('#others').attr('style', 'margin-top: 10px')
        $('select[name="authorization[chief_complaint]"]').dropdown('set selected', 'Others')
    }

    if ($('#senior').is(':checked')) {
        $('#senior_id').show()
        $('#senior_discount').show()
    } else {
        $('#senior_id').hide()
        $('#senior_discount').hide()
    }

    $("#senior").change(function() {
        if (this.checked) {
            $('#senior_field').removeClass('error')
            $('#senior_field').closest('.field').find('.prompt').remove()
            $('#senior_id').show()
            $('#senior_discount').val('')
            $('#senior_discount').show()
        } else {
            $('#senior_id').hide()
            $('#senior_discount').hide()
        }
    })

    if ($('#pwd').is(':checked')) {
        $('#pwd_id').show()
        $('#pwd_discount').show()
        $('#date_issued').show()
        $('#place_issued').show()
    } else {
        $('#pwd_id').hide()
        $('#pwd_discount').hide()
        $('#date_issued').hide()
        $('#place_issued').hide()
    }

    $("#pwd").change(function() {
        if (this.checked) {
            $('#pwd_field').removeClass('error')
            $('#pwd_field').closest('.field').find('.prompt').remove()
            $('#pwd_id').show()
            $('#pwd_discount').val('')
            $('#pwd_discount').show()
            $('#date_issued').show()
            $('#place_issued').show()
        } else {
            $('#pwd_id').hide()
            $('#pwd_discount').hide()
            $('#date_issued').hide()
            $('#place_issued').hide()
        }
    })

    $('#add_practitioner').on('click', function() {
        $('select[name="practitioner[practitioner_id]"]').dropdown('clear')
        $('select[name="practitioner[specialization_id]"]').dropdown('clear')
        $('select[name="practitioner[role]"]').dropdown('clear')
        $('input[name="practitioner[aps_id]"]').val('')
        $('#aps_submit').removeClass()
        $('#aps_submit').addClass('ui primary button')
        $('#aps_submit').html('<i class="add icon"></i>Add')
        $('#practitioner_header').html('Add Practitioner')
        let ad = $('#authorization_admission_datetime').val()
        let dd = $('#authorization_discharge_datetime').val()
        let cc = $('#authorization_chief_complaint').val()
        let cco = $('#others').val()
        let sd = $('#senior_text').val()
        let pwd = $('#pwd_text').val()
        let pi = $('#authorization_place_issued').val()
        let sa = $('#authorization_special_approval_id').val()
        let ir = $('#authorization_internal_remarks').val()

        $('#pra_ad').val(ad)
        $('#pra_dd').val(dd)
        $('#pra_cc').val(cc)
        $('#pra_cco').val(cco)
        $('#pra_sd').val(sd)
        $('#pra_pwd').val(pwd)
        $('#pra_pi').val(pi)
        $('#pra_sa').val(sa)
        $('#pra_ir').val(ir)

        $('#add_practitioner_modal').modal({
            closable: false,
            autofocus: false,
            observeChanges: true
        }).modal('show')
    })

    $('#add_dp').on('click', function() {
        let cc = $('#authorization_chief_complaint').val()
        let cco = $('#others').val()
        let sd = $('#senior_text').val()
        let pwd = $('#pwd_text').val()
        let sa = $('#authorization_special_approval_id').val()
        let ir = $('#authorization_internal_remarks').val()
        let pi = $('#authorization_place_issued').val()

        $('#dp_cc').val(cc)
        $('#dp_cco').val(cco)
        $('#dp_sd').val(sd)
        $('#dp_pwd').val(pwd)
        $('#dp_sa').val(sa)
        $('#dp_ir').val(ir)
        $('#dp_pi').val(pi)

        $('#unit_field').removeClass('error')
        $('#unit_field').find('.prompt').remove()
        $('#procedure_field').removeClass('error')
        $('#procedure_field').find('.prompt').remove()
        $('#practitioner_field').removeClass('error')
        $('#practitioner_field').find('.prompt').remove()
        $('#diagnosis_field').removeClass('error')
        $('#diagnosis_field').find('.prompt').remove()
        $('#unit').val('')
        $('#amount').val('')
        $('select[id="procedures"]').dropdown('clear')
        $('select[id="practitioners"]').dropdown('clear')
        $('#unit').attr('readonly', true)
        $('#diagnosis').dropdown('clear')
        $('#add_dp_modal').modal({
            closable: false,
            autofocus: false,
            observeChanges: true
        }).modal('show')
    })

    $('#practitioner_form').form({
        inline: true,
        on: 'blur',
        fields: {
            'practitioner[practitioner_id]': {
                identifier: 'practitioner[practitioner_id]',
                rules: [{
                    type: 'empty',
                    prompt: 'Please enter practitioner'
                }]
            },
            'practitioner[specialization_id]': {
                identifier: 'practitioner[specialization_id]',
                rules: [{
                    type: 'empty',
                    prompt: 'Please enter specialization'
                }]
            },
            'practitioner[role]': {
                identifier: 'practitioner[role]',
                rules: [{
                    type: 'empty',
                    prompt: 'Please enter role'
                }]
            },
        }
    })

    $('.remove_aps').on('click', function() {
        let a_id = $(this).attr('a_id')
        let aps_id = $(this).attr('aps_id')
        swal({
            title: 'Delete Practitioner?',
            text: 'Deleting this Practitioner will permanently remove it from the system.',
            type: 'question',
            showCancelButton: true,
            cancelButtonText: '<i class="remove icon"></i> No, Keep Practitioner',
            confirmButtonText: '<i class="check icon"></i> Yes, Delete Practitioner',
            cancelButtonClass: 'ui tiny negative button',
            confirmButtonClass: 'ui tiny positive button',
            reverseButtons: true,
            buttonsStyling: false
        }).then(function() {
            window.location.href = `/authorizations/${a_id}/delete_practitioner_specialization/${aps_id}`
        }).catch(swal.noop)
    })

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

    $('.edit_aps').on('click', function() {
        let practitioner = $(this).attr('practitioner')
        let specialization = $(this).attr('specialization')
        let role = $(this).attr('role')
        let aps_id = $(this).attr('aps_id')

        $('select[name="practitioner[practitioner_id]"]').closest('.field').removeClass('error')
        $('select[name="practitioner[practitioner_id]"]').closest('.field').find('.prompt').remove()
        $('select[name="practitioner[specialization_id]"]').closest('.field').removeClass('error')
        $('select[name="practitioner[specialization_id]"]').closest('.field').find('.prompt').remove()
        $('select[name="practitioner[role]"]').closest('.field').removeClass('error')
        $('select[name="practitioner[role]"]').closest('.field').find('.prompt').remove()
        $('select[name="practitioner[practitioner_id]"]').dropdown('set selected', practitioner)
        $('select[name="practitioner[specialization_id]"]').dropdown('set selected', specialization)
        $('select[name="practitioner[role]"]').dropdown('set selected', role)
        $('select[name="practitioner[practitioner_id]"]').dropdown('set value', practitioner)
        $('select[name="practitioner[specialization_id]"]').dropdown('set value', specialization)
        $('select[name="practitioner[role]"]').dropdown('set value', role)
        $('input[name="practitioner[aps_id]"]').val(aps_id)
        $('#practitioner_header').html('Update Practitioner')
        $('#aps_submit').removeClass()
        $('#aps_submit').addClass('ui blue button')
        $('#aps_submit').html('<i class="save icon"></i>Update')

        $('#add_practitioner_modal').modal({
            closable: false,
            autofocus: false,
            observeChanges: true
        }).modal('show')
    })

    $('.edit_adp').on('click', function() {
        let diagnosis = $(this).attr('diagnosis')
        let practitioner = $(this).attr('practitioner')
        let unit = $(this).attr('unit')
        let amount = $(this).attr('amount')
        let procedure = $(this).attr('procedure')
        let procedure_id = $(this).attr('procedure_id')
        let aid = $(this).attr('aid')

        $('#update_practitioner').val(practitioner)
        $('#update_diagnosis').val(diagnosis)
        $('#update_unit').val(unit)
        $('#update_amount').val(amount)
        $('#update_procedure').val(procedure)
        $("#hidden_update_procedure").val(procedure_id)
        $("#aid").val(aid)

        $('#update_dp_modal').modal({
            closable: false,
            autofocus: false,
            observeChanges: true
        }).modal('show')
    })

    $('select[name="practitioner[practitioner_id]"]').on('change', function() {
        const csrf = $('input[name="_csrf_token"]').val()
        let practitioner_id = $(this).val()
        $.ajax({
            url: `/practitioners/${practitioner_id}/get_specializations_by_practitioner`,
            headers: {
                "X-CSRF-TOKEN": csrf
            },
            type: 'GET',
            success: function(response) {
                if ($('select[name="practitioner[specialization_id]"]').val() != "") {
                    let value = $(this).val()
                    $('select[name="practitioner[specialization_id]"]').children('option:not(:first)').remove()
                    $(this).dropdown('set value', value)
                } else {
                    $('select[name="practitioner[specialization_id]"]').children('option').remove()
                }
                for (let specialization of response.specialization) {
                    $('select[name="practitioner[specialization_id]"]').append(`<option value=""></option>`)
                    $('select[name="practitioner[specialization_id]"]').append(`<option value="${specialization.id}">${specialization.name}</option>`)
                }
            }
        })
    })

    $('select[name="practitioner[specialization_id]"]').on('change', function() {
        const csrf = $('input[name="_csrf_token"]').val()
        let specialization_id = $(this).val()
        $.ajax({
            url: `/practitioners/${specialization_id}/get_practitioners_by_specialization`,
            headers: {
                "X-CSRF-TOKEN": csrf
            },
            type: 'GET',
            success: function(response) {
                if ($('select[name="practitioner[practitioner_id]"]').val() != "") {
                    let value = $(this).val()
                    $('select[name="practitioner[practitioner_id]"]').children('option:not(:first)').remove()
                    $(this).dropdown('set value', value)
                } else {
                    $('select[name="practitioner[practitioner_id]"]').children('option').remove()
                }
                for (let practitioner of response.practitioner) {
                    $('select[name="practitioner[practitioner_id]"]').append(`<option value=""></option>`)
                    $('select[name="practitioner[practitioner_id]"]').append(`<option value="${practitioner.id}">${practitioner.name}</option>`)
                }
            }
        })
    })


    $('select[name="practitioner[role]"]').on('change', function() {
        if ($(this).val() == "Others") {
            $('#others_pra').removeAttr('style')
            $('#others_pra').attr('style', 'margin-top: 10px')
            $('select[id="practitioner_role"]').removeAttr('name')
            $('#others_pra').attr('name', 'practitioner[role]')
        } else {
            $('#others_pra').hide()
            $('#others_pra').removeAttr('name')
            $('select[id="practitioner_role]').attr('name', 'practitioner[role]')
        }
    })

    $("select[id='practitioners']").on('change', function() {
        $('#practitioner_field').removeClass('error')
        $('#practitioner_field').find('.prompt').remove()
    })

    $('.btnRemoveProcedure').on('click', function() {
        let authorization_procedure_id = $(this).attr('authorization_procedure_id')
        swal({
            title: 'Delete Procedure/Diagnosis?',
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
            window.location.replace(`/authorizations/${authorization_procedure_id}/delete_authorization_procedure`)
        }).catch(swal.noop)
    })

    $('button[id="append_procedure"]').on('click', function() {

        let procedures = $("select[id='procedures'] option:selected").val()
        let practitioners = $("select[id='practitioners'] option:selected").val()
        let unit = $('#unit').val()
        let amount = $('#amount').val()

        $('#unit_field').removeClass('error')
        $('#unit_field').find('.prompt').remove()
        $('#procedure_field').removeClass('error')
        $('#procedure_field').find('.prompt').remove()
        $('#practitioner_field').removeClass('error')
        $('#practitioner_field').find('.prompt').remove()
        if ((unit == "") || (procedures == "") || (practitioners == "") || (amount == "")) {
            if (procedures == "") {
                $('#procedure_field').addClass('error')
                $('#procedure_field').append(`<div class="ui basic red pointing prompt label transition visible">Please select a payor procedure</div>`)
            } else if (unit == "") {
                $('#unit_field').addClass('error')
                $('#unit_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter unit</div>`)
            } else if (amount == "") {
                $('#unit').val('')
                $('#unit_field').addClass('error')
                $('#unit_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter unit</div>`)
            } else {
                $('#practitioner_field').addClass('error')
                $('#practitioner_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter practitioner</div>`)
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
            $('div#append').find('select[role="practitioners"]').attr('id', 'procedure_select[' + i + '][practitioner_id]').attr('name', 'procedure[' + i + '][practitioner_id]')

            $('div#append').find('select').css('pointer-events', 'none')
            $('div#append').find('select').find('.dropdown.icon').remove()
            $('.dropdown').dropdown()
            $('div#append').find('.ui.dropdown').css('pointer-events', 'none')
            $('div#append').find('.ui.dropdown').find('.dropdown.icon').remove()
            let select_value = $('select[id="procedures"]').val()
            let select_pra_value = $('select[id="practitioners"]').dropdown('get value')
            let select_pra_text = $('select[id="practitioners"]').dropdown('get text')
            $('select[name="procedure[' + i + '][procedure_id]"]').dropdown('set selected', select_value)
            $('select[name="procedure[' + i + '][practitioner_id]"]').dropdown('set value', select_pra_value)

            let appended = $('select[name="procedure[' + i + '][procedure_id]"]').val()
            let appended_pra = $('select[name="procedure[' + i + '][practitioner_id]"]').val()
            // $('#procedure_field').find('.active.selected').remove()

            // $('select[id="procedures"] option[value="' + select_value + '"]').remove()

            $('div#append').find('select[role="procedures"]').removeAttr('role')
            $('div#append').find('select[role="practitioners"]').removeAttr('role')

            $('div#append').find('input[role="unit"]').attr('id', 'procedure_select[' + i + '][unit]').attr('name', 'procedure[' + i + '][unit]').css('pointer-events', 'none')
            $('div#append').find('input[role="unit"]').removeAttr('role')

            $('div#append').find('input[role="amount"]').attr('id', 'procedure_select[' + i + '][amount]').attr('name', 'procedure[' + i + '][amount]').css('pointer-events', 'none')
            $('div#append').find('input[role="amount"]').removeAttr('role')

            $('#procedure_select').find('input#unit').val('')
            $('#procedure_select').find('input#amount').val('')

            $('select[name="procedure[' + i + '][procedure_id]"]').dropdown('set value', select_value)
            $('select[name="procedure[' + i + '][practitioner_id]"]').dropdown('set value', select_pra_value)

            $('#procedures').dropdown('clear')
            $('#practitioners').dropdown('clear')
            $('.dropdown').dropdown()
            $('#append').find('#add_label').css('visibility', 'hidden')
            $('div#append').find('#append_procedure').html('<i class="trash icon"></i>')
            $('div#append').find('#append_procedure').removeClass('basic')
            $('div#append').find('#append_procedure').addClass('red')
            $('div#append').find('#append_procedure').attr('id', 'delete[' + i + ']')
            $('select[id="procedures"]').dropdown('clear')
            $('select[id="practitioners"]').dropdown('clear')

            $('body').on('click', 'button[id="delete[' + i + ']"]', function() {
                // let text = $('select[id="procedure_select[' + i + '][procedure_id]"]').dropdown('get text')
                // let value = $('select[id="procedure_select[' + i + '][procedure_id]"]').dropdown('get value')
                // $('select[id="procedures"]').append($('<option>', {
                // value: value,
                // text: text
                // }))
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
        let selected_text = $(this).dropdown('get text')
        let amount = $(this).dropdown('get item', selected_text).attr('amount')
        let value = $(this).dropdown('get item', selected_text).attr('data-value')
        $(this).dropdown('set value', value)
        $("#hidden_amount").val(amount)
        $('#amount').val('')
        $('#unit').val('')
        if ($(this).val().length > 0) {
            $('#unit_field').removeClass('error')
            $('#unit_field').find('.prompt').remove()
            $('#procedure_field').removeClass('error')
            $('#procedure_field').find('.prompt').remove()
        }
        $('#unit').prop("readonly", false)
    })

    $('#unit').keypress(function(evt) {
        evt = (evt) ? evt : window.event
        var charCode = (evt.which) ? evt.which : evt.keyCode
        if (charCode == 8 || charCode == 37) {
            return true
        } else if (charCode == 46) {
            return false
        } else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
            return false
        } else if (this.value.length == 0 && evt.which == 48) {
            return false
        }
        return true
    })

    let facility_id = $('input[name="authorization[facility_id]"]').val()
    let csrf = $('input[name="_csrf_token"]').val()
    $("#unit").on('keyup', function(e) {
        if ($(this).val().length > 0) {
            let amount = $("#hidden_amount").val()
            let unit = parseInt(String($('#unit').val()).replace(/\,/g, ''))
            $('#unit_field').removeClass('error')
            $('#unit_field').find('.prompt').remove()
            $('input[name="authorization[amount]"]').val(amount * unit)
        } else {
            $('#unit').val('')
            $('#amount').val('')
        }
    })

    $('#update_unit').keypress(function(evt) {
        evt = (evt) ? evt : window.event
        var charCode = (evt.which) ? evt.which : evt.keyCode
        if (charCode == 8 || charCode == 37) {
            return true
        } else if (charCode == 46) {
            return false
        } else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
            return false
        } else if (this.value.length == 0 && evt.which == 48) {
            return false
        }
        return true
    })

    $("#update_unit").on('keyup', function(e) {
        if ($(this).val().length > 0) {
            let payor_procedure_id = $("#hidden_update_procedure").val()
            let unit = $('#update_unit').val()
            $('#update_unit_field').removeClass('error')
            $('#update_unit_field').find('.prompt').remove()
            var reg = /^[0-9 -()+]*$/
            if (String(unit).match(reg) == null) {
                $('#update_unit_field').addClass('error')
                $('#update_unit_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter 0-9 only.</div>`)
                $('#update_amount').val('')
            } else {
                $.ajax({
                    url: `/api/v1/authorizations/${payor_procedure_id}/get_amount/${facility_id}/${unit}`,
                    headers: {
                        "X-CSRF-TOKEN": csrf
                    },
                    type: 'get',
                    success: function(response) {
                        const data = JSON.parse(response)
                        $('#update_amount').val(data)
                    },
                })
            }
        } else {
            $('#update_unit').val('')
            $('#update_amount').val('')
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
            $('#diagnosis_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter diagnosis</div>`)
            // }
            // } else if (input_checker == true) {
            // if ($('div#append').html().length == 0) {
            // $('div[id="message"]').remove()
            // $('p#no_procedure').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div> <ul class="list"><li>Adding procedure/s for at least one diagnosis is required.</li> </ul> </div>')
        } else {
            $('.actions').find('.btnAddEmergencyProcedure').removeAttr('type')
        }
        // }
        $("#diagnosis").on('change', function() {
            $('#diagnosis_field').removeClass('error')
            $('#diagnosis_field').find('.prompt').remove()
        })
    })

    $('.actions').find('.btnUpdateEmergencyProcedure').on('click', function(e) {
        let unit = $('#update_unit').val()
        let amount = $('#update_amount').val()
        var reg = /^[0-9 -()+]*$/

        if (unit == "") {
            $('#update_unit_field').removeClass('error')
            $('#update_unit_field').find('.prompt').remove()
            $('#update_unit_field').addClass('error')
            $('#update_unit_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter unit</div>`)
        } else if (amount == "") {
            $('#update_unit').val('')
            $('#update_unit_field').removeClass('error')
            $('#update_unit_field').find('.prompt').remove()
            $('#update_unit_field').addClass('error')
            $('#update_unit_field').append(`<div class="ui basic red pointing prompt label transition visible">Please enter unit</div>`)
        } else {
            $(this).removeAttr('type')
        }
    })

    if ($('#member_pay').is(':not(:checked)')) {
        $('#sa_field').removeClass('hidden')
    }

    $("#member_pay").change(function() {
        if ($('#member_pay').is(':not(:checked)')) {
            $('#sa_field').removeClass('hidden')
        } else {
            $('#sa_field').addClass('hidden')
            $('#sa_amount').addClass('hidden')
            $('#sa_file').hide()
        }
    })
    $("#special_approval").on('change', function() {
        $('#sa_amount').removeClass('hidden')
        $('#sa_file').removeClass('hide')
        $('#sa_file').show()
    })

    function alert_error_file() {
        alertify.error('<i id="notification_error" class="close icon"></i><p>Acceptable file types are jpg, jpeg and png.</p>')
        alertify.defaults = {
            notifier: {
                delay: 5,
                position: 'top-right',
                closeButton: false
            }
        }
    }

    function alert_error_size() {
        alertify.error('<i id="notification_error" class="close icon"></i><p>Maximum file size is 5 MB.</p>')
        alertify.defaults = {
            notifier: {
                delay: 5,
                position: 'top-right',
                closeButton: false
            }
        }
    }


    let counter = 1
    let delete_array = []

    $('#addFile1').on('click', function() {
        console.log(123)
        let file_id = '#file_' + counter
        $('#filePreviewContainer1').append(`<input type="file" class="display-none" id="file_${counter}" name="facility[files][]">`)
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
                $('#filePreviewContainer1').append(new_row)
            }
        })
        $(file_id).click()
        counter++
    })
    let counter2 = 1
    let delete_array2 = []

    $('#addFile2').on('click', function() {
        let file_id = '#file_' + counter2
        $('#filePreviewContainer2').append(`<input type="file" class="display-none" id="file_${counter2}" name="facility[files][]">`)
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
              <button class="ui button remove-file2" fileID2="${file_id}" type="button">Remove</button>\
            </div>\
            <i class="big ${icon} icon"></i>\
            <div class="content">\
              ${file_name}\
            </div>\
          </div>\
          `
                $('#filePreviewContainer2').append(new_row)
            }
        })
        $(file_id).click()
        counter2++
    })

    $('body').on('click', '.remove-file', function() {
        let file_id = $(this).attr('fileID')
        $(file_id).remove()
        $(this).closest('.item').remove()
    })

    $('body').on('click', '.remove-uploaded', function() {
        let file_id = $(this).attr('fileID')
        $(this).closest('.item').remove()
        if (delete_array.includes(file_id) == false) {
            delete_array.push(file_id)
        }
        $('#deleteIDs').val(delete_array)
    })

    $('body').on('click', '.remove-file2', function() {
        let file_id = $(this).attr('fileID2')
        $(file_id).remove()
        $(this).closest('.item').remove()
    })

    $('body').on('click', '.remove-uploaded2', function() {
        let file_id = $(this).attr('fileID2')
        $(this).closest('.item').remove()
        if (delete_array2.includes(file_id) == false) {
            delete_array2.push(file_id)
        }
        $('#deleteIDs2').val(delete_array2)
    })

})