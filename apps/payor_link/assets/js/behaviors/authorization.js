onmount('div[name="authorization_coverage"]', function() {

  $('button[id="btn_authorization_coverage_id"]').click(function() {
    $('label[id="coverage_name"]').text($(this).attr("name"))
    $('label[id="coverage_description"]').text($(this).attr("text"))
    $('input[name="authorization[coverage_id]"]').val($(this).attr("value"))
  })

});

onmount('div[role="ConsultLOAFileUpload"]', function() {

    const alert_error_file = () => {
      alertify.error('<i id="notification_error" class="close icon"></i><p>Acceptable file types are jpg, jpeg and png.</p>');
      alertify.defaults = {
        notifier: {
          delay: 5,
          position: 'top-right',
          closeButton: false
        }
      };
    }

    const alert_error_size = () => {
      alertify.error('<i id="notification_error" class="close icon"></i><p>Maximum file size is 5 MB.</p>');
      alertify.defaults = {
        notifier: {
          delay: 5,
          position: 'top-right',
          closeButton: false
        }
      };
    }

    const alert_error_duplicate = () => {
      alertify.error('<i id="notification_error" class="close icon"></i><p>File has already been uploaded.</p>');
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
        $('#filePreviewContainer').append(`<input type="file" style="display: none" id="file_${counter}" name="authorization[files][]">`)
        $(file_id).on('change', function() {
            let file = $(file_id)[0].files[0]
            let file_type = $(file_id)[0].files[0].type
            let file_name = $(file_id)[0].files[0].name
            let icon = 'file outline'
            if ((file_name.indexOf('.png') >= 0) || (file_name.indexOf('.jpg') >= 0) || (file_name.indexOf('.jpeg') >= 0)) {
                if (file.size < 5000000) {
                    // file = (window.URL || window.webkitURL).createObjectURL(file)
                    let reader = new FileReader()
                    reader.readAsDataURL(file)
                    reader.onload = function () {
                      let authorization_id = $('#authorization_authorization_id').val()
                      let user_id = $('#authorization_user_id').val()
                      let csrf = $('input[name="_csrf_token"]').val()
                      $.ajax({
                        type: "POST",
                        url:`/authorizations/${authorization_id}/upload_file`,
                        headers: { "X-CSRF-TOKEN": csrf },
                        data: {
                          file_name: file_name,
                          file: reader.result,
                          user_id: user_id
                        },
                        success: function(response) {
                          let result = response.result
                          let id = response.id
                          if(result == "success"){
                            let new_row =
                              `\
                                <div class="item file-item">\
                                  <div class="right floated content">\
                                    <div class="ui small basic icon buttons">\
                                      <button class="ui button remove-file" fileID="${id}" type="button"><i class="trash icon"></i></button>\
                                    </div>\
                                  </div>\
                                  <i class="big ${icon} icon"></i>\
                                  <div class="content">\
                                    ${file_name}\
                                  </div>\
                                </div>\
                                `
                            $('#filePreviewContainer').append(new_row)
                          } else {
                            alert_error_duplicate()
                          }
                        }
                      })
                    };
                } else {
                    $(this).val('')
                    alert_error_size()
                }
            } else {
                $(this).val('')
                alert_error_file()
            }
        })
        $(file_id).click()
        counter++
    })

    $('body').on('click', '.remove-file', function() {
        let file_id = $(this).attr('fileID')
        let csrf = $('input[name="_csrf_token"]').val()
        let container = $(this).closest('.file-item')

        $.ajax({
          type: "DELETE",
          url:`/authorizations/${file_id}/delete_file`,
          headers: { "X-CSRF-TOKEN": csrf },
          success: function(response) {
            container.remove()
          }
        })
    })
});

onmount('div[name="formValidateStep4Consult"]', function(){

  var im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('input[name="authorization[special_approval_amount]"]'));

  $('input[name="authorization[special_approval_amount]"]').keyup(function(){
    $('#submit').removeClass('disabled')
    let value = parseFloat($(this).val().replace(/,/g, ''))
    if(value > parseFloat('9999.99')){
      alertify.error('<i class="close icon"></i>Special Approval Amount can\'t be greater than PHP 9,999.99.')
      $(this).val('9,999.99')
    }
  })

  $('#form_consult').submit(() => {
    let file_upload_state = $('div[role="ConsultLOAFileUpload"]').is(":visible")
    if(file_upload_state == true){
      let count = 0
      $('.file-item').each(function(){
        count++
      })
      if(count > 0){
        return true
      } else {
        alertify.error('<i class="close icon"></i>Please attach at least one document.')
        return false
      }
    } else {
      return true
    }
  })

  $('#append_specialization').hide()
  function checkValidation() {
    let cfo_status
    let sa_status

    if($('textarea[name="authorization[chief_complaint_others]"]').hasClass('hidden') == false) {
      cfo_status = true
    } else {
      cfo_status = false
    }

    if($('#sa_field').hasClass('hidden') == false) {
      sa_status = true
    } else {
      sa_status = false
    }

    if(cfo_status == true && sa_status == true) {
      withSA_CFO_FormValidation()
    } else if(cfo_status == true) {
      withCFO_FormValidation()
    } else if(sa_status == true) {
      withSA_FormValidation()
    } else {
      generalFormValidation()
    }
  }

  function generalFormValidation() {
    $('#form_consult')
    .form({
      inline : true,
      fields: {
        'authorization[consultation_type]': {
          identifier: 'authorization[consultation_type]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a consultation_type.'
            }
          ]
        },
        'authorization[practitioner_specialization_id]': {
          identifier: 'authorization[practitioner_specialization_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a practitioner.'
            }
          ]
        },
        'authorization[diagnosis_id]': {
          identifier: 'authorization[diagnosis_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a diagnonsis.'
            }
          ]
        }
      }
    })
  }

  function withCFO_FormValidation() {
    $('#form_consult')
    .form({
      inline : true,
      fields: {
        'authorization[consultation_type]': {
          identifier: 'authorization[consultation_type]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a consultation fee.'
            }
          ]
        },
        'authorization[chief_complaint_others]': {
          identifier: 'authorization[chief_complaint_others]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a reason.'
            }
          ]
        },
        'authorization[practitioner_specialization_id]': {
          identifier: 'authorization[practitioner_specialization_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a practitioner.'
            }
          ]
        },
        'authorization[diagnosis_id]': {
          identifier: 'authorization[diagnosis_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a diagnonsis.'
            }
          ]
        }
      }
    })
  }

  function withSA_FormValidation() {
    $('#form_consult')
    .form({
      inline : true,
      fields: {
        'authorization[consultation_type]': {
          identifier: 'authorization[consultation_type]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a consultation fee.'
            }
          ]
        },
        'authorization[practitioner_specialization_id]': {
          identifier: 'authorization[practitioner_specialization_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a practitioner.'
            }
          ]
        },
        'authorization[special_approval_id]': {
          identifier: 'authorization[special_approval_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a special approval.'
            }
          ]
        },
        'authorization[special_approval_amount]': {
          identifier: 'authorization[special_approval_amount]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a special approval amount.'
            }
          ]
        },
        'authorization[diagnosis_id]': {
          identifier: 'authorization[diagnosis_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a diagnonsis.'
            }
          ]
        }
      }
    })
  }

  function withSA_CFO_FormValidation() {

    $('#form_consult')
    .form({
      inline : true,
      fields: {
        'authorization[consultation_type]': {
          identifier: 'authorization[consultation_type]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a consultation fee.'
            }
          ]
        },
        'authorization[chief_complaint_others]': {
          identifier: 'authorization[chief_complaint_others]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a reason.'
            }
          ]
        },
        'authorization[practitioner_specialization_id]': {
          identifier: 'authorization[practitioner_specialization_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a practitioner.'
            }
          ]
        },
        'authorization[special_approval_id]': {
          identifier: 'authorization[special_approval_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a special approval.'
            }
          ]
        },
        'authorization[special_approval_amount]': {
          identifier: 'authorization[special_approval_amount]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a special approval amount.'
            }
          ]
        },
        'authorization[diagnosis_id]': {
          identifier: 'authorization[diagnosis_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a diagnonsis.'
            }
          ]
        }
      }
    })
  }

  let _is_member_pay_checker;

  $('select[name="authorization[chief_complaint]"]').on('change', function(){
    $('#submit').removeClass('disabled')
    if($(this).val() == "Others") {
      $('textarea[name="authorization[chief_complaint_others]"]').removeClass('hidden')
    } else {
      $('textarea[name="authorization[chief_complaint_others]"]').addClass('hidden')
    }
  })

  $('input[name="authorization[isMemberPay][]"]').change(function(){
    $('#submit').removeClass('disabled')
    _is_member_pay_checker = $(this).is(':checked') ? 'checked' : 'unchecked';
    let member_pays = $('input[name="authorization[member_pays2]"]').val()
    let special_approval_amount = $('input[name="authorization[special_approval_amount2]"]').val()
    let vat_status = $('input[name="authorization[vat_status]"]').val()

    let total_member_pays = parseFloat(member_pays) + parseFloat(special_approval_amount)
    let member_pay
    let member_vat_amount

    if (vat_status == "Vatable") {
          /*MEMBER PAY VAT*/
      member_pay = Math.round((parseFloat(member_pays) / parseFloat(1.12)))
      member_vat_amount = Math.round((parseFloat(member_pay) * parseFloat(0.12)))
    }
    else
    {
      member_pay = member_pays
      member_vat_amount = 0
    }

    if($('input[name="authorization[isMemberPay][]"]').prop('checked') == true) {
      /*MEMBER PAYS*/
      $('#submit').removeClass('disabled')
      $('#acc_member_total').text(member_pays)
      $('#authorization_member_total').text(member_pays)
      $('#acc_member_covered_portion').text(member_pay)
      $('#acc_member_vat_amount').text(member_vat_amount)
      $('#authorization_member_total').text(member_pays)
      $('input[name="authorization[member_vat_amount]"]').val(member_vat_amount)
      $('input[name="authorization[member_portion]"]').val(member_pay)
      $('input[name="authorization[member_pays]"]').val(member_pays)

      /*SPECIAL APPROVAL*/
      $('#authorization_special_approval_total').text(0)
      $('#acc_special_approval_total').text(0)
      $('#acc_special_approval_covered_portion').text(0)
      $('#acc_special_approval_vat_amount').text(0)
      $('input[name="authorization[special_approval_amount2]"]').val(0)
      $('input[name="authorization[special_approval_portion]"]').val(0)
      $('input[name="authorization[special_approval_vat_amount]"]').val(0)

      $('#sa_field').addClass('hidden')
      $('#sa_cont').addClass('hidden')

      checkValidation()
    } else {

      /*MEMBER PAYS*/
      $('#acc_member_total').text(0)
      $('#authorization_member_total').text(0)
      $('#acc_member_covered_portion').text(0)
      $('#acc_member_vat_amount').text(0)
      $('#authorization_member_total').text(0)
      $('input[name="authorization[member_vat_amount]"]').val(0)
      $('input[name="authorization[member_portion]"]').val(0)
      $('input[name="authorization[member_pays]"]').val(0)

      /*SPECIAL APPROVAL*/
      $('#authorization_special_approval_total').text(member_pays)
      $('#acc_special_approval_total').text(member_pays)
      $('#acc_special_approval_covered_portion').text(member_pay)
      $('#acc_special_approval_vat_amount').text(member_vat_amount)
      $('input[name="authorization[special_approval_amount2]"]').val(member_pays)
      $('input[name="authorization[special_approval_portion]"]').val(member_pay)
      $('input[name="authorization[special_approval_vat_amount]"]').val(member_vat_amount)

      $('#sa_field').removeClass('hidden')
      $('#sa_cont').removeClass('hidden')

      checkValidation()
    }
  })

  $('select#authorization_practitioner_specialization_id').select2({
    placeholder: "Select practitioner",
    theme: "bootstrap",
    minimumInputLength: 3
  })

  $('#filter_specialization').click(function(){
    let f_id = $(this).attr('f_id')
    $('#f_id').val(f_id)
    $('#psf_modal').modal('show')
  })

  $('select[name="authorization[chief_complaint]"]').on('change', function(){
    $('#submit').removeClass('disabled')
    if($(this).val() == "Others") {
      $('textarea[name="authorization[chief_complaint_others]"]').removeClass('hidden')
      checkValidation()
    } else {
      $('textarea[name="authorization[chief_complaint_others]"]').addClass('hidden')
      checkValidation()
    }
  })

  $("input[name='authorization[special_approval_amount]']").on("change paste keyup", function()
  {
    $('#submit').removeClass('disabled')
    let member_pays = parseFloat($('input[name="authorization[member_pays2]"]').val().replace(/,/g, ''))
    let vat_status = $('input[name="authorization[vat_status]"]').val()
    let special_approval_amount

    if($(this).val() == "") {
      special_approval_amount = "0"
      $(this).val('0')
    } else {
      special_approval_amount = parseFloat($(this).val().replace(/,/g, ''))
    }
    let member_pay
    let member_vat_amount
    let sa_portion
    let sa_vat_amount
    let remaining_member_pays = +((parseFloat(member_pays) - parseFloat(special_approval_amount)).toFixed(2))

    if (vat_status == "Vatable") {
      member_pay = Math.round((parseFloat(remaining_member_pays) / parseFloat(1.12)))
      member_vat_amount = Math.round((parseFloat(member_pay) * parseFloat(0.12)))
      sa_portion = Math.round((parseFloat(special_approval_amount) / parseFloat(1.12)))
      sa_vat_amount = Math.round((parseFloat(sa_portion) * parseFloat(0.12)))
    }
    else
    {
      member_pay = remaining_member_pays
      member_vat_amount = 0
      sa_portion = Math.round((parseFloat(special_approval_amount) / parseFloat(1.12)))
      sa_vat_amount = Math.round((parseFloat(sa_portion) * parseFloat(0.12)))
    }

    if (parseFloat(special_approval_amount) > parseFloat(member_pays))
    {
      $('input[name="authorization[member_pays]"]').val(0)
      $('input[name="authorization[special_approval_amount2]"]').val(special_approval_amount)

      $('#authorization_member_total').text(0)
      $('#authorization_special_approval_total').text(special_approval_amount)
      $('#acc_special_approval_total').text(special_approval_amount)
      $('input[name="authorization[special_approval_portion]"]').val(0)
      $('input[name="authorization[special_approval_vat_amount]"]').val(0)
      $('#acc_special_approval_covered_portion').text(0)
      $('#acc_special_approval_vat_amount').text(0)
    }
    else
    {
      /*MEMBER PAYS*/
      $('#acc_member_total').text(remaining_member_pays)
      $('#authorization_member_total').text(remaining_member_pays)
      $('#acc_member_covered_portion').text(member_pay)
      $('#acc_member_vat_amount').text(member_vat_amount)
      $('#authorization_member_total').text(remaining_member_pays)
      $('input[name="authorization[member_vat_amount]"]').val(member_vat_amount)
      $('input[name="authorization[member_portion]"]').val(member_pay)
      $('input[name="authorization[member_pays]"]').val(remaining_member_pays)

      /*SPECIAL APPROVAL*/
      $('#authorization_special_approval_total').text(special_approval_amount)
      $('#acc_special_approval_total').text(special_approval_amount)
      $('#acc_special_approval_covered_portion').text(sa_portion)
      $('#acc_special_approval_vat_amount').text(sa_vat_amount)
      $('input[name="authorization[special_approval_amount2]"]').val(special_approval_amount)
      $('input[name="authorization[special_approval_portion]"]').val(sa_portion)
      $('input[name="authorization[special_approval_vat_amount]"]').val(sa_vat_amount)
    }

  });

  $("input[name='authorization[special_approval_amount]']").keypress(function (evt)
  {
    $('#submit').removeClass('disabled')
    evt = (evt) ? evt : window.event;
    var charCode = (evt.which) ? evt.which : evt.keyCode;
    if (charCode == 8 || charCode == 37) {
      return true;
    } else if (charCode == 46 && $(this).val().indexOf('.') != -1) {
      return false;
    } else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
      return false;
    }
    return true;

  });


  $('select[name="authorization[special_approval_id]"]').change(function(){
    $('#submit').removeClass('disabled')
    $('#saa_field').removeClass('hidden')
  })

  if($('input[name="authorization[isMemberPay][]"]').prop('checked') == true) {
    $('#sa_field').addClass('hidden')
    $('#sa_cont').addClass('hidden')
    $('#authorization_special_approval_id').dropdown('restore defaults')
  } else {
    $('#sa_cont').removeClass('hidden')
    $('#sa_field').removeClass('hidden')
    $('#saa_field').addClass('hidden')
    $('#authorization_special_approval_id').dropdown('restore defaults')
  }

  $('#submit').on('click', function(e){
    const consultation_type = $('select[name="authorization[consultation_type]"]').val();
    const practitioner = $('select[name="authorization[practitioner_specialization_id]"]').val();
    const diagnosis = $('select[name="authorization[diagnosis_id]"]').val();

    let member_pays = $('input[name="authorization[member_pays2]"]').val()
    let special_approval_amounts = $('input[name="authorization[special_approval_amount]"]').val()
    let special_approval_amount = Number(special_approval_amounts.replace(/[^0-9\.-]+/g,""))

    if (_is_member_pay_checker == "unchecked") {
      if (parseFloat(special_approval_amount) > parseFloat(member_pays))
      {
        $('#saa_field').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#saa_field').addClass('error')
        $('#saa_field').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Special Approval Amount must not be greater than Member Pays.</div>')
      }
      else if (special_approval_amount == "")
      {
        $('#saa_field').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#saa_field').addClass('error')
        $('#saa_field').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please enter special approval amount.</div>')
      }
      else if (special_approval_amount == ".")
      {
        $('#saa_field').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#saa_field').addClass('error')
        $('#saa_field').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please enter special approval amount.</div>')
      }
      else if (special_approval_amount == 0)
      {
        $('#saa_field').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#saa_field').addClass('error')
        $('#saa_field').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please enter other value.</div>')
      }
      else if(consultation_type == "" || practitioner == "" || diagnosis == ""){
        $('#form_consult').submit()
        e.preventDefault()
      }
      else if(consultation_type != "" && practitioner != "" && diagnosis != "" && parseFloat(special_approval_amount) <= parseFloat(member_pays)){
        swal({
          title: 'Request LOA',
          html: 'You are submitting an OP Consultation Request of LOA.<br>If Yes, Request LOA, generation of LOA shall occur.<br>If No, Don’t Request LOA, user shall be redirected back to the request page.',
          showCancelButton: true,
          cancelButtonText: '<i class="remove icon"></i> No',
          confirmButtonText: '<i class="check icon"></i> Yes',
          cancelButtonClass: 'ui negative button',
          confirmButtonClass: 'ui positive button',
          reverseButtons: true,
          buttonsStyling: false
        }).then(function (){
          $('#form_consult').submit()
        })
      }
      else{
      }
    }
    else
    {
      if(consultation_type == "" || practitioner == "" || diagnosis == ""){
        $('#form_consult').submit()
        e.preventDefault()
      }
      else{
        swal({
          title: 'Request LOA',
          html: 'You are submitting an OP Consultation Request of LOA.<br>If Yes, Request LOA, generation of LOA shall occur.<br>If No, Don’t Request LOA, user shall be redirected back to the request page.',
          showCancelButton: true,
          cancelButtonText: '<i class="remove icon"></i> No',
          confirmButtonText: '<i class="check icon"></i> Yes',
          cancelButtonClass: 'ui negative button',
          confirmButtonClass: 'ui positive button',
          reverseButtons: true,
          buttonsStyling: false
        }).then(function (){
          $('#form_consult').submit()
        })
      }
    }
  });

  $('#cancel_edit').on('click', function(){
    const authorization_id = $(this).attr('authorization_id')
    window.location.replace(`/authorizations/${authorization_id}/cancel_edit_opc`);
  })

  $('#btnSaveAuthorization').on('click', function(e){
    const authorization_id = $(this).attr('authorization_id')
    const consultation_type = $('select[name="authorization[consultation_type]"]').val();
    const practitioner_specialization_id = $('select[name="authorization[practitioner_specialization_id]"]').val();
    const diagnosis_id = $('select[name="authorization[diagnosis_id]"]').val();
    const chief_complaint = $('select[name="authorization[chief_complaint]"]').val()
    const chief_complaint_others = $('#authorization_chief_complaint_others').val()
    const consultation_fee = $('input[name="authorization[consultation_fee]"]').val()
    const pre_existing_amount = $('input[name="authorization[pre_existing_amount]"]').val()

    const member_product_id = $('input[name="authorization[member_product_id]"]').val()
    const product_benefit_id = $('input[name="authorization[product_benefit_id]"]').val()
    const product_exclusion_id = $('input[name="authorization[product_exclusion_id]"]').val()
    const total_amount = $('input[name="authorization[total_amount]"]').val()
    const internal_remarks = $('textarea[name="authorization[internal_remarks]"]').val()

    /* MEMBER PAYS*/
    const member_pays = $('input[name="authorization[member_pays]"]').val()
    const member_portion = $('input[name="authorization[member_portion]"]').val()
    const member_vat_amount = $('input[name="authorization[member_vat_amount]"]').val()

    /* PAYOR PAYS*/
    const payor_pays = $('input[name="authorization[payor_pays]"]').val()
    const payor_portion = $('input[name="authorization[payor_portion]"]').val()
    const payor_vat_amount = $('input[name="authorization[payor_vat_amount]"]').val()

    /*SPECIAL APPROVAL AMOUNT*/
    const special_approval_amount2 = $('input[name="authorization[special_approval_amount2]"]').val()
    const sa_portion = $('input[name="authorization[special_approval_portion]"]').val()
    const sa_vat_amount = $('input[name="authorization[special_approval_vat_amount]"]').val()

    let special_approval_id

    if(_is_member_pay_checker == "checked"){
      special_approval_id = ""
    } else {
      special_approval_id = $('select[name="authorization[special_approval_id]"]').val()
    }

    if(consultation_type == "" && practitioner_specialization_id == "" && diagnosis_id == "" && chief_complaint == ""){
      swal({
        title: 'Save LOA',
        html: 'You are saving an OP Consultation Request of LOA.<br>If Yes, Save LOA, generation of LOA shall occur.<br>If No, Don’t Save LOA, user shall be remain on the page.',
        showCancelButton: true,
        cancelButtonText: '<i class="remove icon"></i> No',
        confirmButtonText: '<i class="check icon"></i> Yes',
        cancelButtonClass: 'ui negative button',
        confirmButtonClass: 'ui positive button',
        reverseButtons: true,
        buttonsStyling: false
      }).then(function (){
        window.location.replace(`/authorizations/${authorization_id}/save_draft`);
      })
    }
    else if(consultation_type == "" || practitioner_specialization_id == "" || diagnosis_id == ""){
      swal({
        title: 'Save LOA',
        html: 'You are saving an OP Consultation Request of LOA.<br>If Yes, Save LOA, generation of LOA shall occur.<br>If No, Don’t Save LOA, user shall be remain on the page.',
        showCancelButton: true,
        cancelButtonText: '<i class="remove icon"></i> No',
        confirmButtonText: '<i class="check icon"></i> Yes',
        cancelButtonClass: 'ui negative button',
        confirmButtonClass: 'ui positive button',
        reverseButtons: true,
        buttonsStyling: false
      }).then(function (){
        window.location.replace(`/authorizations/${authorization_id}/save_authorization_data/?consultation_type=${consultation_type}\
          +&diagnosis_id=${diagnosis_id}\
          +&chief_complaint=${chief_complaint}\
          +&chief_complaint_others=${chief_complaint_others}\
          +&consultation_fee=${consultation_fee}\
          +&pre_existing_amount=${pre_existing_amount}\
          +&member_pays=${member_pays}\
          +&member_portion=${member_portion}\
          +&member_vat_amount=${member_vat_amount}\
          +&payor_pays=${payor_pays}\
          +&payor_portion=${payor_portion}\
          +&payor_vat_amount=${payor_vat_amount}\
          +&special_approval_amount2=${special_approval_amount2}\
          +&special_approval_portion=${sa_portion}\
          +&special_approval_vat_amount=${sa_vat_amount}\
          +&special_approval_id=${special_approval_id}\
          +&member_product_id=${member_product_id}\
          +&product_benefit_id=${product_benefit_id}\
          +&product_exclusion_id=${product_exclusion_id}\
          +&total_amount=${total_amount}\
          +&practitioner_specialization_id=${practitioner_specialization_id}\
          +&internal_remarks=${internal_remarks}`);
      })
    }
    else{
      swal({
        title: 'Save LOA',
        html: 'You are saving an OP Consultation Request of LOA.<br>If Yes, Save LOA, generation of LOA shall occur.<br>If No, Don’t Save LOA, user shall be remain on the page.',
        showCancelButton: true,
        cancelButtonText: '<i class="remove icon"></i> No',
        confirmButtonText: '<i class="check icon"></i> Yes',
        cancelButtonClass: 'ui negative button',
        confirmButtonClass: 'ui positive button',
        reverseButtons: true,
        buttonsStyling: false
      }).then(function (){
        window.location.replace(`/authorizations/${authorization_id}/save_authorization_data/?consultation_type=${consultation_type}\
          +&diagnosis_id=${diagnosis_id}\
          +&chief_complaint=${chief_complaint}\
          +&chief_complaint_others=${chief_complaint_others}\
          +&consultation_fee=${consultation_fee}\
          +&pre_existing_amount=${pre_existing_amount}\
          +&member_pays=${member_pays}\
          +&member_portion=${member_portion}\
          +&member_vat_amount=${member_vat_amount}\
          +&payor_pays=${payor_pays}\
          +&payor_portion=${payor_portion}\
          +&payor_vat_amount=${payor_vat_amount}\
          +&special_approval_amount2=${special_approval_amount2}\
          +&special_approval_portion=${sa_portion}\
          +&special_approval_vat_amount=${sa_vat_amount}\
          +&special_approval_id=${special_approval_id}\
          +&member_product_id=${member_product_id}\
          +&product_benefit_id=${product_benefit_id}\
          +&product_exclusion_id=${product_exclusion_id}\
          +&total_amount=${total_amount}\
          +&practitioner_specialization_id=${practitioner_specialization_id}\
          +&internal_remarks=${internal_remarks}`);
      })
    }
  })

  $('#btnCancelAuthorization').on('click', function(){
    let authorization_id = $(this).attr('authorization_id')
    swal({
      title: 'Cancel Loa Request?',
      text: `Canceling this LOA request will automatically delete this request from the system`,
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Cancel Request',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Request',
      confirmButtonClass: 'ui positive button',
      cancelButtonClass: 'ui negative button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false

    }).then(function() {
      window.location.replace(`/authorizations/${authorization_id}/delete_authorization`);
    })
  })

  $('#btnDeleteDraftAuthorization').on('click', function(){
    let authorization_id = $(this).attr('authorization_id')
    swal({
      title: 'Delete Loa Request?',
      text: `Deleting this LOA request will automatically remove this request from the system.`,
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Request',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Request',
      confirmButtonClass: 'ui positive button',
      cancelButtonClass: 'ui negative button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false

    }).then(function() {
      window.location.replace(`/authorizations/${authorization_id}/delete_authorization`);
    })
  })

  $('select[name="authorization[consultation_type]"]').on('change', function(){
    $('#submit').removeClass('disabled')
    if($('select[name="authorization[consultation_type]"] option:selected').val() == "initial")
    {
      let temp = 'Z71.1 | PERSONS ENCOUNTERING HEALTH SERVICES FOR OTHER COUNSELLING AND MEDICAL ADVICE, NOT ELSEWHERE CLASSIFIED: Person with feared complaint in whom no diagnosis is made'
      let value = $('select[name="authorization[diagnosis_id]"] > option:contains("Z71.1")').val()
      let container = $('select#authorization_diagnosis_id').closest('div')
      $('select#authorization_diagnosis_id').val(value).trigger('change')
      container.find('.ui.basic.red.pointing.prompt.label.transition').removeClass('visible')
      container.find('.ui.basic.red.pointing.prompt.label.transition').addClass('hidden')
      container.removeClass('error')
    }
  })

  $('select[name="authorization[diagnosis_id]"]').on('change', function(){
    $('#submit').removeClass('disabled')
    const csrf = $('input[name="_csrf_token"]').val();
    if ($('#authorization_practitioner_specialization_id').val() != "" && $(this).val()) {
      let practitioner_specialization_id = $('#authorization_practitioner_specialization_id').val()
      let params = {practitioner_specialization_id: practitioner_specialization_id, diagnosis_id: $(this).val()}
      let authorization_id = $('input[name="authorization[authorization_id]"]').val()
      $.ajax({
        url: `/authorizations/${authorization_id}/compute_consultation`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'post',
        data: {params: params},
        dataType: 'json',
        success: function(response){
          $('#MemberPayField').addClass('hidden')
          $('input[name="authorization[isMemberPay][]"]').prop('checked', true)
          $('#authorization_special_approval_id').dropdown('restore defaults')
          $('#saa_field').addClass('hidden')
          $('#sa_field').addClass('hidden')
          $('#sa_cont').addClass('hidden')

          let obj = JSON.parse(response)
          let pre_existing_amount = ""
          let vat_status = obj.vat_status
          let payor_pay = Math.round(obj.payor_pays)
          let member_pay = Math.round(obj.member_pays)
          let member_pay2
          let payor_pay2
          let vat_amount
          let member_vat_amount
          let payor_vat_amount
          let consultation_fee

          if (obj.consultation_fee == 0) {
            alertify.error('<i class="close icon"></i><p>The practitioner you selected does not have consultation fee setup for this facility.</p>')
            $('#authorization_practitioner_specialization_id').val('').trigger('change')
          } else {

            if (vat_status == "Vatable") {
              /*PAYOR PAY VAT*/
              consultation_fee = Math.round(((parseFloat(obj.payor_pays) + parseFloat(obj.member_pays)) / parseFloat(1.12)))
              payor_pay = Math.round((parseFloat(payor_pay) / parseFloat(1.12)))
              payor_vat_amount = Math.round((parseFloat(payor_pay) * parseFloat(0.12)))

              /*MEMBER PAY VAT*/
              member_pay = Math.round((parseFloat(member_pay) / parseFloat(1.12)))
              member_vat_amount = Math.round((parseFloat(member_pay) * parseFloat(0.12)))

              let vat_amount_sub = Math.round((parseFloat(consultation_fee) / parseFloat(1.12)))
              vat_amount = Math.round((parseFloat(consultation_fee) * parseFloat(0.12)))
            }
            else
            {
              consultation_fee = Math.round(parseFloat(obj.payor_pays) + parseFloat(obj.member_pays))
              payor_pay = payor_pay
              member_pay = member_pay
              vat_amount = 0
              payor_vat_amount = 0
              member_vat_amount = 0
            }

            if (obj.pre_existing_amount == null)
            {
              pre_existing_amount = 0
            }
            else
            {
              pre_existing_amount = Math.round(obj.pre_existing_amount)
            }

            let total_amount = Math.round(parseFloat(obj.payor_pays) + parseFloat(obj.member_pays))

            $('input[name="authorization[vat_status]"]').val(vat_status)
            $('input[name="authorization[consultation_fee]"]').val(consultation_fee)
            $('input[name="authorization[total_amount]"]').val(total_amount)
            $('input[name="authorization[payor_pays]"]').val(Math.round(obj.payor_pays))
            $('input[name="authorization[member_pays]"]').val(Math.round(obj.member_pays))
            $('input[name="authorization[member_pays2]"]').val(Math.round(obj.member_pays))
            $('input[name="authorization[vat_amount]"]').val(vat_amount)
            $('input[name="authorization[pre_existing_amount]"]').val(pre_existing_amount)
            $('input[name="authorization[member_product_id]"]').val(obj.member_product_id)
            $('input[name="authorization[product_benefit_id]"]').val(obj.product_benefit_id)

            /*Accordion Data*/
            if(pre_existing_amount > 0)
            {
              $('#payor_pre_existing_condition1').show()
              $('#payor_pre_existing_condition2').show()
              $('#member_pre_existing_condition1').show()
              $('#member_pre_existing_condition2').show()
              $('#acc_payor_covered_portion_label').text('COVERED PORTION AFTER PRE EXISTING CONDITION')
              $('#acc_member_covered_portion_label').text('UNCOVERED PORTION AFTER PRE EXISTING CONDITION')
            }
            else
            {
              $('#payor_pre_existing_condition1').hide()
              $('#payor_pre_existing_condition2').hide()
              $('#member_pre_existing_condition1').hide()
              $('#member_pre_existing_condition2').hide()
              $('#acc_payor_covered_portion_label').text('COVERED PORTION')
              $('#acc_member_covered_portion_label').text('UNCOVERED PORTION')
            }

            $('#acc_consultation_fee').text(consultation_fee)
            $('#acc_pre_existing_amount').text(pre_existing_amount)
            $('#acc_vat_amount').text(vat_amount)
            $('#acc_total_amount').text(total_amount)
            $('#member_product_code').text(obj.product_code)
            $('#payor_product_code').text(obj.product_code)

            /*PAYOR PAYS*/
            $('#acc_payor_total').text(Math.round(obj.payor_pays))
            $('#authorization_payor_total').text(Math.round(obj.payor_pays))
            $('#acc_payor_covered_portion').text(payor_pay)
            $('#acc_payor_vat_amount').text(payor_vat_amount)
            $('input[name="authorization[payor_vat_amount]"]').val(payor_vat_amount)
            $('input[name="authorization[payor_portion]"]').val(payor_pay)

            /*MEMBER PAYS*/
            $('#acc_member_total').text(Math.round(obj.member_pays))
            $('#authorization_member_total').text(Math.round(obj.member_pays))
            $('#acc_member_covered_portion').text(member_pay)
            $('#acc_member_vat_amount').text(member_vat_amount)
            $('input[name="authorization[member_vat_amount]"]').val(member_vat_amount)
            $('input[name="authorization[member_portion]"]').val(member_pay)

            /*SPECIAL APPROVAL*/
            $('#authorization_special_approval_total').text(0)
            $('#acc_special_approval_total').text(0)
            $('#acc_special_approval_covered_portion').text(0)
            $('#acc_special_approval_vat_amount').text(0)
            $('input[name="authorization[special_approval_amount2]"]').val(0)
            $('input[name="authorization[special_approval_portion]"]').val(0)
            $('input[name="authorization[special_approval_vat_amount]"]').val(0)

            if (obj.member_pays > 1) {
              $('#MemberPayField').removeClass('hidden')
              $('input[name="authorization[special_approval_amount]"]').val(Math.round(obj.member_pays))
            } else {
              $('#MemberPayField').addClass('hidden')
            }

          }

        },
        error: function(){
          alertify.error('<i class="close icon"></i><p>Error</p>')
        }
      })
    }
  });

  $("#authorization_internal_remarks").on("keydown", function(e){
    $('#submit').removeClass('disabled')
  });

  $('select[name="authorization[practitioner_specialization_id]"]').on('change', function(){
    $('#submit').removeClass('disabled')
    const csrf = $('input[name="_csrf_token"]').val();
    if ($('#authorization_diagnosis_id').val() != "" && $(this).val()) {
      let diagnosis_id = $('#authorization_diagnosis_id').val()
      let params = {diagnosis_id: diagnosis_id, practitioner_specialization_id: $(this).val()}
      let authorization_id = $('input[name="authorization[authorization_id]"]').val()
      $.ajax({
        url: `/authorizations/${authorization_id}/compute_consultation`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'post',
        data: {params: params},
        dataType: 'json',
        success: function(response){
          $('#MemberPayField').addClass('hidden')
          $('input[name="authorization[isMemberPay][]"]').prop('checked', true)
          $('#authorization_special_approval_id').dropdown('restore defaults')
          $('#saa_field').addClass('hidden')
          $('#sa_field').addClass('hidden')
          $('#sa_cont').addClass('hidden')

          let obj = JSON.parse(response)
          let pre_existing_amount = ""
          let vat_status = obj.vat_status
          let payor_pay = Math.round(obj.payor_pays)
          let member_pay = Math.round(obj.member_pays)
          let member_pay2
          let payor_pay2
          let vat_amount
          let member_vat_amount
          let payor_vat_amount
          let consultation_fee

          if (obj.consultation_fee == 0) {
            alertify.error('<i class="close icon"></i><p>The practitioner you selected does not have consultation fee setup for this facility.</p>')
            $('#authorization_practitioner_specialization_id').val('').trigger('change')
          } else {

            if (vat_status == "Vatable") {
              /*PAYOR PAY VAT*/
              consultation_fee = Math.round(((parseFloat(obj.payor_pays) + parseFloat(obj.member_pays)) / parseFloat(1.12)))
              payor_pay = Math.round((parseFloat(payor_pay) / parseFloat(1.12)))
              payor_vat_amount = Math.round((parseFloat(payor_pay) * parseFloat(0.12)))

              /*MEMBER PAY VAT*/
              member_pay = Math.round((parseFloat(member_pay) / parseFloat(1.12)))
              member_vat_amount = Math.round((parseFloat(member_pay) * parseFloat(0.12)))

              let vat_amount_sub = Math.round((parseFloat(consultation_fee) / parseFloat(1.12)))
              vat_amount = Math.round((parseFloat(consultation_fee) * parseFloat(0.12)))
            }
            else
            {
              consultation_fee = Math.round(parseFloat(obj.payor_pays) + parseFloat(obj.member_pays))
              payor_pay = payor_pay
              member_pay = member_pay
              vat_amount = 0
              payor_vat_amount = 0
              member_vat_amount = 0
            }

            if (obj.pre_existing_amount == null)
            {
              pre_existing_amount = 0
            }
            else
            {
              pre_existing_amount = Math.round(obj.pre_existing_amount)
            }

            let total_amount = Math.round(parseFloat(obj.payor_pays) + parseFloat(obj.member_pays))

            $('input[name="authorization[vat_status]"]').val(vat_status)
            $('input[name="authorization[consultation_fee]"]').val(consultation_fee)
            $('input[name="authorization[total_amount]"]').val(total_amount)
            $('input[name="authorization[payor_pays]"]').val(Math.round(obj.payor_pays))
            $('input[name="authorization[member_pays]"]').val(Math.round(obj.member_pays))
            $('input[name="authorization[member_pays2]"]').val(Math.round(obj.member_pays))
            $('input[name="authorization[vat_amount]"]').val(vat_amount)
            $('input[name="authorization[pre_existing_amount]"]').val(pre_existing_amount)
            $('input[name="authorization[member_product_id]"]').val(obj.member_product_id)
            $('input[name="authorization[product_benefit_id]"]').val(obj.product_benefit_id)

            /*Accordion Data*/
            if(pre_existing_amount > 0)
            {
              $('#payor_pre_existing_condition1').show()
              $('#payor_pre_existing_condition2').show()
              $('#member_pre_existing_condition1').show()
              $('#member_pre_existing_condition2').show()
              $('#acc_payor_covered_portion_label').text('COVERED PORTION AFTER PRE EXISTING CONDITION')
              $('#acc_member_covered_portion_label').text('UNCOVERED PORTION AFTER PRE EXISTING CONDITION')
            }
            else
            {
              $('#payor_pre_existing_condition1').hide()
              $('#payor_pre_existing_condition2').hide()
              $('#member_pre_existing_condition1').hide()
              $('#member_pre_existing_condition2').hide()
              $('#acc_payor_covered_portion_label').text('COVERED PORTION')
              $('#acc_member_covered_portion_label').text('UNCOVERED PORTION')
            }

            $('#acc_consultation_fee').text(consultation_fee)
            $('#acc_pre_existing_amount').text(pre_existing_amount)
            $('#acc_vat_amount').text(vat_amount)
            $('#acc_total_amount').text(total_amount)
            $('#member_product_code').text(obj.product_code)
            $('#payor_product_code').text(obj.product_code)

            /*PAYOR PAYS*/
            $('#acc_payor_total').text(Math.round(obj.payor_pays))
            $('#authorization_payor_total').text(Math.round(obj.payor_pays))
            $('#acc_payor_covered_portion').text(payor_pay)
            $('#acc_payor_vat_amount').text(payor_vat_amount)
            $('input[name="authorization[payor_vat_amount]"]').val(payor_vat_amount)
            $('input[name="authorization[payor_portion]"]').val(payor_pay)

            /*MEMBER PAYS*/
            $('#acc_member_total').text(Math.round(obj.member_pays))
            $('#authorization_member_total').text(Math.round(obj.member_pays))
            $('#acc_member_covered_portion').text(member_pay)
            $('#acc_member_vat_amount').text(member_vat_amount)
            $('input[name="authorization[member_vat_amount]"]').val(member_vat_amount)
            $('input[name="authorization[member_portion]"]').val(member_pay)

            /*SPECIAL APPROVAL*/
            $('#authorization_special_approval_total').text(0)
            $('#acc_special_approval_total').text(0)
            $('#acc_special_approval_covered_portion').text(0)
            $('#acc_special_approval_vat_amount').text(0)
            $('input[name="authorization[special_approval_amount2]"]').val(0)
            $('input[name="authorization[special_approval_portion]"]').val(0)
            $('input[name="authorization[special_approval_vat_amount]"]').val(0)

            if (obj.member_pays > 1) {
              $('#MemberPayField').removeClass('hidden')
              $('input[name="authorization[special_approval_amount]"]').val(Math.round(obj.member_pays))
            } else {
              $('#MemberPayField').addClass('hidden')
            }

          }

        },
        error: function(){
          alertify.error('<i class="close icon"></i><p>Error</p>')
        }
      })
    }
  });
  setTimeout(function () {
    $('.search-dropdown').dropdown({ fullTextSearch: true, sortSelect: true, match:'text'});
  }, 1)

  checkValidation()
});

onmount('div[id="psf_modal"]', function(){
  $('#filter_submit').on('click', function(){
    let val = $('.ui.radio.checkbox.checked').find('label').text()
    let f_id = $('#f_id').val()
    if(val == "") {
      $('.ajs-message.ajs-error.ajs-visible').remove()
      alertify.error('<i class="close icon"></i><p>Please select a specialization.</p>')
    } else {
      const csrf = $('input[name="_csrf_token"]').val();
      $.ajax({
        url: `/authorizations/${f_id}/filter_specialization/${val}`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        success: function(response){
          let obj = JSON.parse(response)
          $('select#authorization_practitioner_specialization_id').select2("destroy").empty();
          for(let option of obj){
            let new_row = `<option value="${option.value}">${option.display}</option>`
            $('select#authorization_practitioner_specialization_id').append(new_row)
          }
          $('select#authorization_practitioner_specialization_id').select2({
            placeholder: "Select practitioner",
            theme: "bootstrap",
            minimumInputLength: 3
          })
          $('select#authorization_practitioner_specialization_id').val('').trigger('change')
          $('#psf_modal').modal('hide')
        }
      })
      $('#append_specialization').show()
      $('#spec_val').text(val)

    }
  })

  $('#filter_all_specialization').on('click', function(){

    let f_id = $(this).attr('f_id')
    const csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url: `/authorizations/${f_id}/filter_all_specialization`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let obj = JSON.parse(response)
        $('select#authorization_practitioner_specialization_id').select2("destroy").empty();
        for(let option of obj){
          let new_row = `<option value="${option.value}">${option.display}</option>`
          $('select#authorization_practitioner_specialization_id').append(new_row)
        }
        $('select#authorization_practitioner_specialization_id').select2({
          placeholder: "Select practitioner",
          theme: "bootstrap",
          minimumInputLength: 3
        })
        $('select#authorization_practitioner_specialization_id').val('').trigger('change')
        $('#psf_modal').modal('hide')
      }
    })
    $('#append_specialization').hide()
  })
})

//PIN select
onmount('div[role="pin-select-map"]', function(e) {
  var script = document.createElement("script");
  script.type = "text/javascript";
  script.src = "https://maps.googleapis.com/maps/api/js?key=AIzaSyB-FlYg_DB4v-UcHCH2XxX6MWy0qSF-9C4&callback=initMap";
  script.setAttribute = ("async", "async");
  script.setAttribute = ("defer", "defer");
  document.body.appendChild(script);
  var map, marker;

  if ($('input[id="result_facilities"]').val() == "" || $('input[id="result_facilities"]').val() == null){
    window.initMap = function() {
      map = new google.maps.Map(document.getElementById('map'), {
        center: {lat: 14.599512, lng: 120.984222},
        zoom: 20,
        size: new google.maps.Size(200, 200)
      });
    }
  } else {
    window.initMap = function() {
      map = new google.maps.Map(document.getElementById('map'), {
        center: {lat: 14.599512, lng: 120.984222},
        zoom: 15,
        size: new google.maps.Size(200, 200)
      });

      var arr_facility = JSON.parse($('input[id="result_facilities"]').val())
      var bounds = new google.maps.LatLngBounds();

      if (arr_facility != null){
        for(let i=0; i < arr_facility.length; i++){

        if(arr_facility[i].latitude != '' &&
            arr_facility[i].longitude != '' &&
            !isNaN(arr_facility[i].latitude) &&
            !isNaN(arr_facility[i].longitude) &&
            arr_facility[i].latitude != null &&
            arr_facility[i].longitude != null
        ){

          var position = new google.maps.LatLng(parseFloat(arr_facility[i].latitude), parseFloat(arr_facility[i].longitude));
          bounds.extend(position);

          marker = new google.maps.Marker({
            position: position,
            map: map,
            clickable: true,
            title: arr_facility[i].code + ': ' + arr_facility[i].name
         });

        google.maps.event.addListener(marker, 'click', function(){
          var member_facilities = JSON.parse($('input[id="member_facilities"]').val());
          if (member_facilities.filter(function(e) { return e.code == arr_facility[i].code; }).length > 0) {
            var address = arr_facility[i].line_1 + ' ' +
                          arr_facility[i].line_2 + ' ' +
                          arr_facility[i].city + ' ' +
                          arr_facility[i].province + ' ' +
                          arr_facility[i].region + ' ' +
                          arr_facility[i].country + ', '  +
                          arr_facility[i].postal_code

            $('#facility_code').html(arr_facility[i].code);
            $('#facility_name').html(arr_facility[i].name);
            $('#facility_type').html((arr_facility[i].type.text == null) ? arr_facility[i].type : arr_facility[i].type.text);
            $('#facility_category').html((arr_facility[i].category.text == null) ? arr_facility[i].category : arr_facility[i].category.text);
            $('#facility_address').html(address);
            $('#facility_contact_number').html(arr_facility[i].phone_no);
            $('input[name="authorization[facility_id]"]').val(arr_facility[i].id);
            $('input[name="authorization[facility_code]"]').val(arr_facility[i].code);
          } else {
            alertify.error('<i class="close icon"></i>Member is not allowed to access this facility.')
            $('#facility_code').html('');
            $('#facility_name').html('');
            $('#facility_type').html('');
            $('#facility_category').html('');
            $('#facility_address').html('');
            $('#facility_contact_number').html('');
            $('input[name="authorization[facility_id]"]').val('');
            $('input[name="authorization[facility_code]"]').val('');
          }
        });

        map.fitBounds(bounds);

      }
      }
    }
  }
}
});

$('div[role="validate_member"]', function(){
  $('#validate_member').modal({closable: false}).modal("show");

  $('#validate_member').find('.card').on('click', function(){
    $('.card').removeAttr("style")
    $(this).css("background-color", "#00DDFB");
    let member_id = $(this).attr("MemberID");
    let member_status = $(this).attr("MemberStatus");
    let account_status = $(this).attr("AccountStatus");

    $('div[id="message"]').html('');
    $('div[id="message"]').hide();

    $('#validate_member').find('input[name="authorization[member_id]"]').val(member_id);
    $('#validate_member').find('input[id="member_status"]').val(member_status);
    $('#validate_member').find('input[id="account_status"]').val(account_status);
    $('#validate_member').find('button[role="submit_member"]').prop("disabled", false);
  });

  if ($('input[name="authorization[member_id]"]').val() == "")  {
    $('#validate_member').find('button[role="submit_member"]').prop("disabled", true);
  } else {
    $('#validate_member').find('button[role="submit_member"]').prop("disabled", false);
  }

  $('#select_validate_member').on('click', function(e){
    if ($('input[id="member_status"]').val() == "Active" && $('input[id="account_status"]').val() == "Active") {
      $('div[id="message"]').html('');
      $('div[id="message"]').hide();
    } else {
      $('div[id="message"]').html("Member is not Active. Only active members are allowed to request LOA.");
      $('div[id="message"]').show();
      e.preventDefault();
    }
  });

});

onmount('div[name="authorization_facility"]', function() {
  let birthdate = moment($('label[id="member_birthdate"]').text()).format("MM-DD-YYYY");
  let age = Math.floor(moment().diff(birthdate, 'years', true))
  $('label[id="member_birthdate"]').text(birthdate);
  $('label[id="member_age"]').text(age);

  $("#formFacilitySearch").submit(function(e){

    if ($('#search_code').val() == '' &&
        $('#search_address').val() == '' &&
        $('#search_city').val() == '' &&
        $('#search_province').val() == '' &&
        $('#search_type').val() == '' &&
        $('#search_status').val() == '') {

          $('div[id="search_criteria_error"]').html(
          '<div class="ui negative message">' +
          '<p>Please enter at least one search criteria.</p>' +
          '</div>'
          );

          e.preventDefault();
    } else {
      $('div[id="search_criteria_error"]').html('');
    }
  });
});

onmount('div[id="facility_search"]', function(){
  let member_id = $('input[name="authorization[member_id]"]').val();
  var facilities = JSON.parse($('input[id="facilities"]').val());
  var map, marker;

  $('.ui.search').search({
    source: facilities,
    showNoResults: true,
    maxResults: 10,
    searchFields: ['title'],
    onSelect: function(result, response) {

      var member_facilities = JSON.parse($('input[id="member_facilities"]').val());

      if (member_facilities.filter(function(e) { return e.code == result.code; }).length > 0) {
        map = new google.maps.Map(document.getElementById('map'), {
          center: {lat: 14.599512, lng: 120.984222},
          zoom: 15,
          size: new google.maps.Size(200, 200)
        });

        var bounds = new google.maps.LatLngBounds();

        if (result != null){
          var position = new google.maps.LatLng(parseFloat(result.latitude), parseFloat(result.longitude));
          bounds.extend(position);

          marker = new google.maps.Marker({
            position: position,
            map: map,
            clickable: true,
            title: result.code
          });

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
      } else {
        alertify.error('<i class="close icon"></i>Member is not allowed to access this facility.')
        $('#facility_code').html('');
        $('#facility_name').html('');
        $('#facility_type').html('');
        $('#facility_category').html('');
        $('#facility_address').html('');
        $('#facility_contact_number').html('');
        $('input[name="authorization[facility_id]"]').val('');
        $('input[name="authorization[facility_code]"]').val('');
      }
    },
    minCharacters: 0
  });
});


onmount('div[name="formConsultation"]', function() {

  $('#reschedule_button').on('click', function() {
    $('#reschedule_modal')
    .modal({
      closable: true,
      autofocus: false,
      observeChanges: true
    })
    .modal('show')
  })

  $('#no_reschedule_loa_button').on('click', function() {
  $('#reschedule_modal').modal('hide')
  })

 $('#yes_reschedule_loa_button').on('click', function() {
   let authorization_id = $(this).attr('authorization_id')
   const csrf = $('input[name="_csrf_token"]').val();
   $.ajax({
     url: `/authorizations/${authorization_id}/reschedule`,
     headers: {"X-CSRF-TOKEN": csrf},
     type: 'get',
     success: function(response){
       alertify.success('Sucessfully rescheduled LOA')
       window.location.replace(`/authorizations/${response.authorization_id}/`)
     }})
  })

  $('#showLogs').click(function() {
    $('#authorizationLogsModal').modal('show')
  })

  $('.print-consult').click(function() {
    let authorization_id = $(this).attr('authorization_id')
    window.open(`/authorizations/${authorization_id}/print_authorization`, '_blank')
  });

  $('p[class="date_created"]').each(function(){
     let date = $(this).html();
     var days = moment(moment(date).add(2, 'd').format('MMMM DD, YYYY h:mm a'))
     $(this).html(moment(date).format('MMMM DD, YYYY h:mm a'));
     $('#valid_until').text(days)
     let valid_until = $('#valid_until').html();
     $('#valid_until').html(moment(valid_until).format('MMMM DD, YYYY h:mm a'))
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

  $('#btn_edit_loa').on('click', function(){
    let authorization_id = $(this).attr('authorization_id')
    const csrf = $('input[name="_csrf_token"]').val();
    let coverage = "OPC"
    var req =
      $.ajax({
      url:`/authorizations/${authorization_id}/edit_status_checker`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'GET',
      beforeSend: function()
      {
        $('#overlay').css("display", "block");
      },
      complete: function()
      {
        $('#overlay').delay(100000).fadeOut();
      }
      });

    req.done(function (data){
      if (data.is_edited == false)
      {
        window.location.replace(`/authorizations/${coverage}/${authorization_id}/edit`);
      }
      else
      {
        $('#overlay').css("display", "none");
        alertify.warning(`<i class="close icon"></i> <p>LOA cannot be edited. Reason: LOA is currently being processed by ${data.username} </p>`);
      }
    })
  })
});

// ACU
onmount('div[name="formValidateStep4Acu"]', function(){
  const csrf = $('input[name="_csrf_token"]').val();
  var authorization_id = $('input[name="authorization[authorization_id]"]').val();
  var facility_id = $('input[name="authorization[facility_id]"]').val();

  $('#form_acu').form({
    on: 'blur',
    inline: true,
    fields: {
      'authorization[room_id]': {
        identifier: 'authorization[room_id]',
        rules: [{
          type   : 'empty',
          prompt : 'Please select a room'
        }]
      },
      'authorization[admission_datetime]': {
        identifier: 'authorization[admission_datetime]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter admission date'
        }]
      },
      'authorization[discharge_datetime]': {
        identifier: 'authorization[discharge_datetime]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter discharge date'
        }]
      }
    }
  });

  var today = new Date();

  $('#admissionDate').calendar({
    type: 'date',
    startMode: 'day',
    minDate:  new Date(today.getFullYear(), today.getMonth(), today.getDate() - 3),
    endCalendar: $('#dischargeDate'),
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
    },
    onChange: function(date, text, mode) {
      compute(text, "")
    }
  });

  $('#dischargeDate').calendar({
    type: 'date',
    startMode: 'day',
    minDate:  new Date(today.getFullYear(), today.getMonth(), today.getDate() - 3),
    startCalendar: $('#admissionDate'),
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
    },
    onChange: function(date, text, mode) {
      compute("", text)
    }
  });

  // ACU Type : Executive - Inpatient
  if ($('input[name="authorization[acu_type]"]').val() == "Executive - Inpatient") {
    // Default RNB
    var room_id = $('select[name="authorization[room_id]"]').val();
    var package_rate = $('input[name="authorization[package_rate]"]').val();

    var params = {facility_id, room_id: room_id};

    $.ajax({
      url: `/authorizations/${authorization_id}/get_facility_room`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'post',
      data: {params: params},
      dataType: 'json',
      success: function(response){
        let obj = JSON.parse(response)
        var room_rate = obj.room_rate
        var total = +package_rate + +room_rate

        $('input[name="authorization[room_rate]"]').val(room_rate)
        $('input[name="authorization[payor_covered]"]').val(total)
        $('input[name="authorization[total_amount]"]').val(total)
      },
      error: function(){}
    });
    // End Default RNB

    // Different RNB
    $('select[name="authorization[room_id]"]').on('change', function(){
      var rnb = $(this).attr('rnb')
      var rnb_amount = $(this).attr('rnbAmount')
      var rnb_id = $(this).attr('rnbId')
      var rnb_hierarchy = $(this).attr('rnbHierarchy')
      var selected_room_id = $(this).val()

      var params = {facility_id, room_id: selected_room_id};

      $.ajax({
        url: `/authorizations/${authorization_id}/get_facility_room`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'post',
        data: {params: params},
        dataType: 'json',
        success: function(response){
          let obj = JSON.parse(response)
          var selected_room_rate = obj.room_rate
          var room_hierarchy = obj.room_hierarchy

          $('input[name="authorization[room_rate]"]').val(selected_room_rate)
          var admission = $('input[name="authorization[admission_datetime]"]').val()
          var discharge = $('input[name="authorization[discharge_datetime]"]').val()

          if (selected_room_rate && admission && discharge) {
            var date1 = new Date(admission)
            var date2 = new Date(discharge)
            var timeDiff = Math.abs(date2.getTime() - date1.getTime())
            var diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24))
            var days = diffDays + 1

            selected_room_rate = selected_room_rate * days
            $('input[name="authorization[room_rate]"]').val(selected_room_rate)
          }

          var params = {rnb: rnb, rnb_amount: rnb_amount, rnb_id: rnb_id, rnb_hierarchy: rnb_hierarchy, selected_room_id: selected_room_id,  selected_room_rate: selected_room_rate, selected_room_hierarchy: room_hierarchy, package_rate: package_rate}

          $.ajax({
            url: `/authorizations/${authorization_id}/compute_acu`,
            headers: {"X-CSRF-TOKEN": csrf},
            type: 'post',
            data: {params: params},
            dataType: 'json',
            success: function(response){
              let obj = JSON.parse(response)
              $('input[name="authorization[member_covered]"]').val(obj.member)
              $('input[name="authorization[payor_covered]"]').val(obj.payor)

              var total = +obj.payor + +obj.member
              $('input[name="authorization[total_amount]"]').val(total)
            },
            error: function(){}
          })
        },
        error: function(){}
      });
    });
    // End Different RNB
  };

  function compute(admission, discharge) {
    var room_id = $('select[name="authorization[room_id]"]').val();
    var package_rate = $('input[name="authorization[package_rate]"]').val();

    if (admission) {
      admission
    }
    else {
      var admission = $('input[name="authorization[admission_datetime]"]').val()
    }
    if (discharge) {
      discharge
    }
    else {
      var discharge = $('input[name="authorization[discharge_datetime]"]').val()
    }

    var params = {facility_id, room_id: room_id};

    $.ajax({
      url: `/authorizations/${authorization_id}/get_facility_room`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'post',
      data: {params: params},
      dataType: 'json',
      success: function(response){
        let obj = JSON.parse(response)
        var room_rate = obj.room_rate
        var room_hierarchy = obj.room_hierarchy

        if (room_rate && admission && discharge) {
          var date1 = new Date(admission)
          var date2 = new Date(discharge)
          var timeDiff = Math.abs(date2.getTime() - date1.getTime())
          var diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24))
          var days = diffDays + 1

          room_rate = room_rate * days
          $('input[name="authorization[room_rate]"]').val(room_rate)
        }

        var room = $('select[name="authorization[room_id]"]')
        var rnb = room.attr('rnb')
        var rnb_amount = room.attr('rnbAmount')
        var rnb_id = room.attr('rnbId')
        var rnb_hierarchy = room.attr('rnbHierarchy')
        var selected_room_id = room_id

        var params = {rnb: rnb, rnb_amount: rnb_amount, rnb_id: rnb_id, rnb_hierarchy: rnb_hierarchy, selected_room_id: selected_room_id,  selected_room_rate: room_rate, selected_room_hierarchy: room_hierarchy, package_rate: package_rate}

        $.ajax({
          url: `/authorizations/${authorization_id}/compute_acu`,
          headers: {"X-CSRF-TOKEN": csrf},
          type: 'post',
          data: {params: params},
          dataType: 'json',
          success: function(response){
            let obj = JSON.parse(response)
            $('input[name="authorization[member_covered]"]').val(obj.member)
            $('input[name="authorization[payor_covered]"]').val(obj.payor)

            var total = +obj.payor + +obj.member
            $('input[name="authorization[total_amount]"]').val(total)
          },
          error: function(){}
        })
      },
      error: function(){}
    });
  };
});

onmount('div[name="formShowAcu"]', function(){
  let date_created = $('#authorization_date_created').val();
  $('#show_date_created').text(moment(date_created).format("MMMM DD, YYYY hh:mm:ss A"));

  let valid_until = $('#authorization_valid_until').val();
  $('#show_valid_until').text(moment(valid_until).format("MMMM DD, YYYY"));

  $('#showLogs').click(function() {
    $('#authorizationLogsModal').modal('show')
  })
});
// End ACU
