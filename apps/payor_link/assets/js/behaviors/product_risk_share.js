onmount('div[id="product_risk_shares"]', function () {

  let facility_options = []
  let procedure_options = []

  $('.title.facility_accordion').each(function(){
    let coverage_id = $(this).attr('coverageID');
    let af_type = $('#at_' + coverage_id).val()
    let naf_type = $('#nat_' + coverage_id).val()

    let af_covered_amount = $('#aca_' + coverage_id).val()
    let af_covered_percentage = $('#acp_' + coverage_id).val()
    let naf_covered_amount = $('#naca_' + coverage_id).val()
    let naf_covered_percentage = $('#nacp_' + coverage_id).val()
    //  if(af_type == "N/A" || af_type == "CoInsurance"){
    //    $('#ac_' + coverage_id).val(af_covered_percentage)
    //  } else if(af_type == "Copayment"){
    //    $('#ac_' + coverage_id).val(af_covered_amount)
    //  }

    //  if(naf_type == "N/A" || naf_type == "CoInsurance"){
    //    $('#nac_' + coverage_id).val(naf_covered_percentage)
    //  } else if(naf_type == "Copayment"){
    //    $('#nac_' + coverage_id).val(naf_covered_amount)
    //  }
  });

  $('a.btnFacility_edit').on('click', function(){
    let product_id = $(this).attr('productID');
    let coverage_id = $(this).attr('coverageID');
    let product_coverage_id = $(this).attr('productCoverageID');
    let csrf_load_f = $('input[name="_csrf_token"]').val();
    let product_risk_share_id = $(this).attr('risk_share');
    let facility = $(this).attr('facility');
    let csrf_get_f = $('input[name="_csrf_token"]').val();

    $('.rs_f_valid .field.error').removeClass( "error" );
    $('.rs_f_valid.error').removeClass( "error" );

    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });

    $('#f_name').html('');
    $('#f_name').append('<option value="">Select Facility</option>');
    $('#rs_facility_validation > div.field.disable_all > div > div.text').empty()
    $('#f_name').dropdown();

    $('#btnSubmit').hide()
    $('#btnEdit').show()
    $('#btn_delete_facility').show()
    $("#btn_delete_facility").removeClass('disabled');
    $.ajax({
      url:`/products/${product_coverage_id}/included_product_risk_share/`,
      headers: {"X-CSRF-TOKEN": csrf_load_f},
      type: 'get',
      success: function(response){
        let obj = JSON.parse(response);
        facility_options.length = 0
        for (let facility of obj) {
          let new_row = `<option value="${facility.id}">${facility.display}</option>`
          $('#f_name').append(new_row)
          facility_options.push(facility.id)
        }
        $('#f_name').dropdown();
      }
    });

    $.ajax({
      url:`/products/${product_risk_share_id}/get_product_risk_share/${facility}`,
      headers: {"X-CSRF-TOKEN": csrf_get_f},
      type: 'get',
      success: function(response){
        let obj = JSON.parse(response);
        $('#f_name').val(obj.facility.id).change();
        $('#f_type').dropdown('set selected', obj.type);
        maskRiskShareModals($('#f_type'), $("#f_value"), 'facility', 'f_value')
        if(obj.type == "Copayment"){
          $('#f_value').val(obj.value_amount);
        } else {
          $('#f_value').val(obj.value_percentage);
        }
        $('#f_covered').val(obj.covered);
        $('#prsID').val(obj.product_coverage_risk_share.id);
        $('#f_prsfID').val(obj.id);
        $('#btn_prsfID').val(obj.id);
        $('.disable_all').addClass('disabled');
        $('#add_facility').modal({autofocus: false}).modal('show');
      }
    });
  });

  $('a.btnFacility').on('click', function(){
    let product_id = $(this).attr('productID');
    let coverage_id = $(this).attr('coverageID');
    let product_coverage_id = $(this).attr('productCoverageID');
    let csrf_load_f = $('input[name="_csrf_token"]').val();
    let product_risk_share_id = $(this).attr('risk_share');
    let facility = $(this).attr('facility');
    let csrf_get_f = $('input[name="_csrf_token"]').val();

    $('.rs_f_valid .field.error').removeClass( "error" );
    $('.rs_f_valid.error').removeClass( "error" );

    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });

    $('#f_name').html('');
    $('#f_name').append('<option value="">Select Facility</option>');
    $('#rs_facility_validation > div.field.disable_all > div > div.text').empty()
    $('#f_name').dropdown();

    $("#btnSubmit").html('<i class="plus icon"></i>Add');
    $('#btnSubmit').show()
    $('#btnEdit').hide()
    $('#btn_delete_facility').hide()
    $('#rs_facility_validation > div.field.disable_all > div > div.text').empty()
    $('#f_prsfID').val('');
    $('#btn_prsfID').val('');

    $.ajax({
      url:`/products/${product_coverage_id}/product_risk_share/`,
      headers: {"X-CSRF-TOKEN": csrf_load_f},
      type: 'get',
      success: function(response){
        let obj = JSON.parse(response);
        facility_options.length = 0
        for (let facility of obj) {
          let new_row = `<option value="${facility.id}">${facility.display}</option>`
          $('#f_name').append(new_row)
          facility_options.push(facility.id)
        }
        $('#f_name').dropdown();
      }
    });

    $.ajax({
      url:`/products/${product_risk_share_id}/get_product_risk_share`,
      headers: {"X-CSRF-TOKEN": csrf_get_f},
      type: 'get',
      success: function(response){
        let obj = JSON.parse(response);
        let product_risk_share_id = obj.id;
        $('#prsID').val(product_risk_share_id);
        $('#f_name').removeAttr('disabled');
        $('#f_name').val("").change();
        $('#f_type').val("");
        $('#f_value').val("");
        $('#f_covered').val("");
        $(".disable_all").removeClass('disabled');
        $('#add_facility').modal({autofocus: false}).modal('show');
        maskRiskShareModals($('#f_type'), $("#f_value"), 'facility', 'f_value')
      }
    });
  });



  function maskRiskShareModals(selector, value, modal_opened, value_by_id){
    let validation_field = '#rs_' + modal_opened + '_validation'
    let modal_type = `product[${modal_opened}_id]`
    let option_array = [];
    if(modal_opened == 'facility'){
      option_array = facility_options
    } else if(modal_opened == 'procedure') {
      option_array = procedure_options
    }
    $.fn.form.settings.rules.checkDropDownValue = function(param) {
      return option_array.indexOf(param) > -1 ? true : false
    }
    if (selector.val() == 'Copayment'){
      $("#" + modal_opened + "_value_label").text('PHP')
      var Inputmask = require('inputmask');
      var im = new Inputmask("decimal", {
        min: '1',
        allowMinus:false,
        radixPoint: ".",
        groupSeparator: ",",
        digits: 2,
        autoGroup: true,
        // prefix: '₱ ',
        rightAlign: false,
        oncleared: function () { self.Value(''); }
      });
      im.mask(value);

      $(validation_field)
      .form({
        inline : true,
        on     : 'blur',
        fields: {
          modal_type: {
            identifier: modal_type,
            rules: [
              {
                type   : 'empty',
                prompt : `Please enter a ${modal_opened}.`
              }
            ]
          },
          modal_type: {
            identifier: modal_type,
            rules: [
              {
                type   : 'checkDropDownValue[param]',
                prompt : `Record was not found. Please enter a valid ${modal_opened}.`
              }
            ]
          },
          'product[type]': {
            identifier: 'product[type]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter a type.'
              }
            ]
          },
          'product[value]': {
            identifier: 'product[value]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter a value.'
              }
            ]
          },
          'product[covered]': {
            identifier: 'product[covered]',
            rules: [
              {
                type   : 'integer[1..100]',
                prompt : 'Please enter a covered value between 1 to 100.'
              }
            ]
          }
        },
        onSuccess: function(event, fields){
          var input = document.getElementById(value_by_id);
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          $(value).val(unmasked)
        }
      });
    } else {
      $("#" + modal_opened + "_value_label").text('%')
      var Inputmask = require('inputmask');
      var im = new Inputmask("numeric", {
        min: '1',
        allowMinus:false,
        max: 100,
        rightAlign: false
      });
      im.mask(value);

      $(validation_field)
      .form({
        inline : true,
        on     : 'blur',
        fields: {
          modal_type: {
            identifier: modal_type,
            rules: [
              {
                type   : 'empty',
                prompt : `Please enter a ${modal_opened}.`
              }
            ]
          },
          modal_type: {
            identifier: modal_type,
            rules: [
              {
                type   : 'checkDropDownValue[param]',
                prompt : `Record was not found. Please enter a valid ${modal_opened}.`
              }
            ]
          },
          'product[type]': {
            identifier: 'product[type]',
            rules: [
              {
                type   : 'empty',
                prompt : 'Please enter a type.'
              }
            ]
          },
          'product[value]': {
            identifier: 'product[value]',
            rules: [
              {
                type   : 'integer[1..100]',
                prompt : 'Please enter a value between 1 to 100.'
              }
            ]
          },
          'product[covered]': {
            identifier: 'product[covered]',
            rules: [
              {
                type   : 'integer[1..100]',
                prompt : 'Please enter a covered value between 1 to 100.'
              }
            ]
          }
        }
      });
    }
  }

  //september 30 2017
  // for exempted facility dropdown Coinsurance and Copayment
  $('#f_type').on('change', function(){
    maskRiskShareModals($(this), $("#f_value"), 'facility', 'f_value')
  })
  $('#p_type').on('change', function(){
    maskRiskShareModals($(this), $("#p_value"), 'procedure', 'p_value')
  })


  // for exempted facility payor procedure dropdown Coinsurance and Copayment
  $('#p_type').on('change', function(){
    maskRiskShareModals($(this), $("#p_value"), 'procedure', 'p_value')
  })

  $('#p_name').on('change', function(){
    $('#prsfpID').val($(this).val())
  });


  function checkProcedure(product_risk_share_facility_id, procedure, product_id){
    $('#p_name').html('');
    $('#p_name').append('<option value="">Select Procedure</option>');
    $('#rs_procedure_validation > div.field.disable_all > div > div.text').empty()
    $('#p_name').dropdown();

    let csrf_load_p = $('input[name="_csrf_token"]').val();
    let csrf_get_p = $('input[name="_csrf_token"]').val();

    let p_option = $('#p_name').val();

    if (procedure == ''){
      $('div[id="add_procedure"]').find('#prsfpID').val('');

      $.ajax({
        url:`/products/${product_id}/product_risk_share_facility/${product_risk_share_facility_id}`,
        headers: {"X-CSRF-TOKEN": csrf_load_p},
        type: 'get',
        success: function(response){
          let obj = JSON.parse(response);
          procedure_options.length = 0
          for (let procedure of obj) {
            let new_row = `<option value="${procedure.id}">${procedure.display}</option>`
            $('#p_name').append(new_row)
            procedure_options.push(procedure.id)
          }
          $('#p_name').dropdown();

          $.ajax({
            url:`/products/${product_risk_share_facility_id}/get_product_risk_share_facility`,
            headers: {"X-CSRF-TOKEN": csrf_get_p},
            type: 'get',
            success: function(response){
              let obj = JSON.parse(response);
              let product_risk_share_facility_id = obj.id;
              $('div[id="add_procedure"]').find('#p_prsfID').val(obj.id);
              $('#p_name').val("").change();
              $('#p_type').val("");
              $('#p_value').val("");
              $('#p_covered').val("");
              $('#add_procedure').modal({autofocus: false}).modal('show');
              maskRiskShareModals($('#p_type'), $("#p_value"), 'procedure', 'p_value')
            }
          });
        }
      });

    } else {
      $.ajax({
        url:`/products/${product_id}/included_product_risk_share_facility/${product_risk_share_facility_id}`,
        headers: {"X-CSRF-TOKEN": csrf_load_p},
        type: 'get',
        success: function(response){
          let obj = JSON.parse(response);
          procedure_options.length = 0
          for (let procedure of obj) {
            let new_row = `<option value="${procedure.id}">${procedure.display}</option>`
            $('#p_name').append(new_row)
            procedure_options.push(procedure.id)
          }
          $('#p_name').dropdown();
          $.ajax({
            url:`/products/${product_risk_share_facility_id}/get_product_risk_share_facility/${procedure}`,
            headers: {"X-CSRF-TOKEN": csrf_get_p},
            type: 'get',
            success: function(response){
              let obj = JSON.parse(response);

              $('#p_name').val(obj.facility_payor_procedure.id).change();
              $('#p_type').dropdown('set selected', obj.type);
              maskRiskShareModals($('#p_type'), $("#p_value"), 'procedure')
              if(obj.type == "Copayment"){
                $('#p_value').val(obj.value_amount);
              } else {
                $('#p_value').val(obj.value_percentage);
              }
              $('#p_covered').val(obj.covered);
              $('div[id="add_procedure"]').find('#p_prsfID').val(obj.product_coverage_risk_share_facility.id);
              $('div[id="add_procedure"]').find('#pcrsfpp').val(obj.id);
              $('div[id="add_procedure"]').find('#prsfpID').val(obj.facility_payor_procedure.id)
              $('#add_procedure').modal({autofocus: false}).modal('show');

              maskRiskShareModals($('#p_type'), $("#p_value"), 'procedure', 'p_value')
            }
          });
        }
      });

    }
  }

  $('a.btnProcedure').on('click', function(){
    $('.rs_p_valid .field.error').removeClass( "error" );
    $('.rs_p_valid.error').removeClass( "error" );

    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });
    $("#btnpSubmit").html('<i class="plus icon"></i>Add');
    $('#btnpSubmit').addClass('blue');
    $('#btnpEdit').hide()
    $('#btn_delete_procedure').hide()
    $('.disable_all').removeClass('disabled');
    $('#btnpSubmit').show()
    $('#fname').val('').change();


    // for product_risk_share_facility_procedure: remove procedure in list if it is existing in loop
    let product_risk_share_facility_id = $(this).attr('risk_share_facility');
    $('#p_prsfID').val(product_risk_share_facility_id);
    let procedure = $(this).attr('procedure');
    let product_id = $(this).attr('productID');
    checkProcedure(product_risk_share_facility_id, procedure, product_id)
  });

  $('a.editBtnProcedure').on('click', function(){
    $('.rs_p_valid .field.error').removeClass( "error" );
    $('.rs_p_valid.error').removeClass( "error" );

    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });
    $("#btnpSubmit").html('<i class="save icon"></i>Save');
    $('#btnpedit').show()
    $('#btnpSubmit').addClass('blue');
    $('#btn_delete_procedure').show()
    $('#btnpSubmit').hide()
    $('.disable_all').addClass('disabled');
    $('#btnpEdit').show()
    $("#btn_delete_procedure").removeClass('disabled');

    let product_risk_share_facility_id = $(this).attr('risk_share_facility');
    $('#p_prsfID').val(product_risk_share_facility_id);
    let procedure = $(this).attr('procedure');
    let product_id = $(this).attr('productID');
    checkProcedure(product_risk_share_facility_id, procedure, product_id)
  });

  $("#btnEdit").click(function(){
    $(".disable_fields").removeClass('disabled');
    $(this).hide()
    $("#btnSubmit").html('<i class="save icon"></i>Save');
    $("#btnSubmit").show()
    $("#btn_delete_facility").addClass('disabled');
  });

  $("#btnpEdit").click(function(){
    $(".disable_field").removeClass('disabled');
    $(this).hide()
    $("#btnpSubmit").html('<i class="save icon"></i>Save');
    $("#btnpSubmit").show()
    $("#btn_delete_procedure").addClass('disabled');
  });

  $("#btn_delete_facility").click(function() {
    let id = $('#f_prsfID').val()

    $('#f_removal_confirmation').modal('show');
    $('#confirmation_f_id').val(id);

  });

  $('#confirmation_cancel_f').click(function(){
    $('#add_facility').modal({autofocus: false}).modal('show');
  });


  $('#confirmation_submit_f').click(function(){
    let id = $('#confirmation_f_id').val();

    let csrf = $('input[name="_csrf_token"]').val()
    $.ajax({
      url: `/delete_prs_facility/${id}`,
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      type: 'delete',
      success: function(response) {
        window.location.reload()
      },
      error: function(error) {
        alert("Invalid facility id")
      },
    })
  });

  $('#confirmation_cancel_fpp').click(function(){
    $('#add_procedure').modal({autofocus: false}).modal('show');
  });

  $('#confirmation_submit_fpp').click(function(){
    let id = $('#confirmation_fpp_id').val();

    let csrf = $('input[name="_csrf_token"]').val()
    $.ajax({
      url: `/delete_prs_procedure/${id}`,
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      type: 'delete',
      success: function(response) {
        window.location.reload()
      },
      error: function(error) {
        alert("Invalid procedure id")
      },
    })
  });

  $("#btn_delete_procedure").click(function() {
    let id = $('#pcrsfpp').val()

    $('#fpp_removal_confirmation').modal('show');
    $('#confirmation_fpp_id').val(id);
  });

  /*
     $("#f_type").change(function(){
     let value = $(this).val();
     if(value == "Copayment"){
     $('.covered_label').text('php');
     } else {
     $('.covered_label').text('%');
     }
     });

     $("#p_type").change(function(){
     let value = $(this).val();
     if(value == "Copayment"){
     $('.p_covered_label').text('php');
     } else {
     $('.p_covered_label').text('%');
     }
     });*/

  function rs_validation_disable_value(coverage, select_value, selector){
    let value = selector + 'value_' + coverage;
    let value_label = selector + 'value_label_' + coverage;
    let value_rs = selector + 'value_rs_' + coverage;
    switch(select_value){
      case 'N/A':
        $(value).addClass('disabled');
      $(value_label).text('%');
      $(value_rs).val('');
      break;
      case 'Copayment':
        $(value).removeClass('disabled');
      $(value_label).text('php');

      // masking for af/naf_value Decimal
      var Inputmask = require('inputmask');
      var im = new Inputmask("decimal", {
        min: '1',
        allowMinus:false,
        radixPoint: ".",
        groupSeparator: ",",
        digits: 2,
        autoGroup: true,
        // prefix: '₱ ',
        rightAlign: false,
        oncleared: function () { self.Value(''); }
      });
      im.mask($(value_rs));
      break;

      case 'CoInsurance':
        $(value).removeClass('disabled');
      $(value_label).text('%');

      // masking for af/naf_value Percentage
      var Inputmask = require('inputmask');
      var im = new Inputmask("numeric", {
        min: '1',
        allowMinus:false,
        max: 100,
        rightAlign: false
      });
      im.mask($(value_rs));
      break;
    }
  }

  // start of risk_share_validation_fields
  function rs_validation_fields(coverage_id){
    let af_select = '#af_select_' + coverage_id;
    let af_select_val = $(af_select).val();
    let naf_select = '#naf_select_' + coverage_id;
    let naf_select_val = $(naf_select).val();

    $('.rs_validation .field.error').removeClass( "error" );
    $('.rs_validation.error').removeClass( "error" );

    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });

    if(af_select_val == 'N/A' && naf_select_val == 'N/A'){
      // alert('af_N/A naf_N/A')
      $('.rs_validation').form({
        inline : true,
        on     : 'blur',
        fields: {
          'product[af_covered_percentage]': {
            identifier: 'product[af_covered_percentage]',
            rules: [
              {
                type   : 'integer[1..100]',
                prompt : 'Please enter Accredited Facility\'s covered after risk share value between 1 to 100.'
              }
            ]
          },
          'product[naf_covered_percentage]': {
            identifier: 'product[naf_covered_percentage]',
            rules: [
              {
                type   : 'integer[1..100]',
                prompt : 'Please enter Non-Accredited Facility\'s covered after risk share value between 1 to 100.'
              }
            ]
          },
          naf_reimbursible: {
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter Non-Accredited Facility\'s reimbursability.',
              }
            ]
          }
        }
      });
    } else if(af_select_val == 'N/A'){
      if(naf_select_val == 'Copayment'){
        // alert('af_N/A naf_Copayment')
        $('.rs_validation').form({
          inline : true,
          on     : 'blur',
          fields: {
            'product[naf_value]': {
              identifier: 'product[naf_value]',
              rules: [
                {
                  type   : 'empty',
                  prompt : 'Please enter Non-Accredited Facility\'s value.'
                }
              ]
            },
            'product[af_covered_percentage]': {
              identifier: 'product[af_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            'product[naf_covered_percentage]': {
              identifier: 'product[naf_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            naf_reimbursible: {
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter Non-Accredited Facility\'s reimbursability.',
                }
              ]
            }
          },
          //  af_value_N/A and naf_value_Copayment
          onSuccess: function(event, fields){
            let value_by_id = 'naf_value_rs_' + coverage_id;
            let value = '#naf_value_rs_' + coverage_id;
            var input = document.getElementById(value_by_id);
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $(value).val(unmasked)
          }
        });
      } else if(naf_select_val == 'CoInsurance') {
        // alert('naf_Coinsurance bes')
        $('.rs_validation').form({
          inline : true,
          on     : 'blur',
          fields: {
            'product[naf_value]': {
              identifier: 'product[naf_value]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s value between 1 to 100.'
                }
              ]
            },
            'product[af_covered_percentage]': {
              identifier: 'product[af_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            'product[naf_covered_percentage]': {
              identifier: 'product[naf_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            naf_reimbursible: {
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter Non-Accredited Facility\'s reimbursability.',
                }
              ]
            }
          }
        });
      }
    } else if(af_select_val == 'Copayment') {
      if(naf_select_val == 'Copayment') {
        //  alert('af_Copayment naf_Copayment')
        $('.rs_validation').form({
          inline : true,
          on     : 'blur',
          fields: {
            'product[af_value]': {
              identifier: 'product[af_value]',
              rules: [
                {
                  type   : 'empty',
                  prompt : 'Please enter Accredited Facility\'s value.'
                }
              ]
            },
            'product[naf_value]': {
              identifier: 'product[naf_value]',
              rules: [
                {
                  type   : 'empty',
                  prompt : 'Please enter Non-Accredited Facility\'s value.'
                }
              ]
            },
            'product[af_covered_percentage]': {
              identifier: 'product[af_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            'product[naf_covered_percentage]': {
              identifier: 'product[naf_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            naf_reimbursible: {
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter Non-Accredited Facility\'s reimbursability.',
                }
              ]
            }
          },
          // for unmasking of af_value_amount and naf_value_amount
          onSuccess: function(event, fields){
            let af_value_by_id = 'af_value_rs_' + coverage_id;
            let af_value = '#af_value_rs_' + coverage_id;
            var input = document.getElementById(af_value_by_id);
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $(af_value).val(unmasked)

            let naf_value_by_id = 'naf_value_rs_' + coverage_id;
            let naf_value = '#naf_value_rs_' + coverage_id;
            var input = document.getElementById(naf_value_by_id);
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $(naf_value).val(unmasked)
          }
        });
      } else if(naf_select_val == 'CoInsurance') {
        //  alert('naf_Coinsurance bes2')
        $('.rs_validation').form({
          inline : true,
          on     : 'blur',
          fields: {
            'product[af_value]': {
              identifier: 'product[af_value]',
              rules: [
                {
                  type   : 'empty',
                  prompt : 'Please enter Accredited Facility\'s value.'
                }
              ]
            },
            'product[naf_value]': {
              identifier: 'product[naf_value]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s value between 1 to 100.'
                }
              ]
            },
            'product[af_covered_percentage]': {
              identifier: 'product[af_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            'product[naf_covered_percentage]': {
              identifier: 'product[naf_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            naf_reimbursible: {
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter Non-Accredited Facility\'s reimbursability.',
                }
              ]
            }
          },
          //here
          onSuccess: function(event, fields){
            let af_value_by_id = 'af_value_rs_' + coverage_id;
            let af_value = '#af_value_rs_' + coverage_id;
            var input = document.getElementById(af_value_by_id);
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $(af_value).val(unmasked)
          }
        });
      } else {
        // alert('af_value only')
        $('.rs_validation').form({
          inline : true,
          on     : 'blur',
          fields: {
            'product[af_value]': {
              identifier: 'product[af_value]',
              rules: [
                {
                  type   : 'empty',
                  prompt : 'Please enter Accredited Facility\'s value.'
                }
              ]
            },
            'product[af_covered_percentage]': {
              identifier: 'product[af_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            'product[naf_covered_percentage]': {
              identifier: 'product[naf_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            naf_reimbursible: {
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter Non-Accredited Facility\'s reimbursability.',
                }
              ]
            }
          },
          // for unmasking of af_value_amount only
          onSuccess: function(event, fields){
            let value_by_id = 'af_value_rs_' + coverage_id;
            let value = '#af_value_rs_' + coverage_id;
            var input = document.getElementById(value_by_id);
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $(value).val(unmasked)
          }
        });
      }
    }  else if(af_select_val == 'CoInsurance') {
      if(naf_select_val == 'Copayment') {
        // alert('af_Coinsurance naf_Copayment')
        $('.rs_validation').form({
          inline : true,
          on     : 'blur',
          fields: {
            'product[af_value]': {
              identifier: 'product[af_value]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s value.'
                }
              ]
            },
            'product[naf_value]': {
              identifier: 'product[naf_value]',
              rules: [
                {
                  type   : 'empty',
                  prompt : 'Please enter Non-Accredited Facility\'s value.'
                }
              ]
            },
            'product[af_covered_percentage]': {
              identifier: 'product[af_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            'product[naf_covered_percentage]': {
              identifier: 'product[naf_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            naf_reimbursible: {
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter Non-Accredited Facility\'s reimbursability.',
                }
              ]
            }
          },
          // for unmasking naf_value only
          onSuccess: function(event, fields){
            let value_by_id = 'naf_value_rs_' + coverage_id;
            let value = '#naf_value_rs_' + coverage_id;
            var input = document.getElementById(value_by_id);
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $(value).val(unmasked)
          }
        });
      } else if(naf_select_val == 'CoInsurance') {
        //    alert('Coninsurace')
        $('.rs_validation').form({
          inline : true,
          on     : 'blur',
          fields: {
            'product[af_value]': {
              identifier: 'product[af_value]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s value between 1 to 100.'
                }
              ]
            },
            'product[naf_value]': {
              identifier: 'product[naf_value]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s value between 1 to 100.'
                }
              ]
            },
            'product[af_covered_percentage]': {
              identifier: 'product[af_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            'product[naf_covered_percentage]': {
              identifier: 'product[naf_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            naf_reimbursible: {
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter Non-Accredited Facility\'s reimbursability.',
                }
              ]
            }
          }
        });
      } else {
        //  alert('af_Coninsurance naf_Coinsurance')
        $('.rs_validation').form({
          inline : true,
          on     : 'blur',
          fields: {
            'product[af_value]': {
              identifier: 'product[af_value]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s value between 1 to 100.'
                }
              ]
            },
            'product[af_covered_percentage]': {
              identifier: 'product[af_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            'product[naf_covered_percentage]': {
              identifier: 'product[naf_covered_percentage]',
              rules: [
                {
                  type   : 'integer[1..100]',
                  prompt : 'Please enter Non-Accredited Facility\'s covered after risk share value between 1 to 100.'
                }
              ]
            },
            naf_reimbursible: {
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter Non-Accredited Facility\'s reimbursability.',
                }
              ]
            }
          }
        });
      }
    }
  }

  let load_coverage_id = $('#last_coverage_id').val();
  let load_af_select = '#af_select_' + load_coverage_id;
  let load_af_select_val = $(load_af_select).val();
  let load_naf_select = '#naf_select_' + load_coverage_id;
  let load_naf_select_val = $(load_naf_select).val();

  rs_validation_disable_value(load_coverage_id, load_af_select_val, '#af_');
  rs_validation_disable_value(load_coverage_id, load_naf_select_val, '#naf_');
  rs_validation_fields(load_coverage_id);

  $('.title.facility_accordion').click(function(){
    let coverage_id = $(this).attr('coverageID');
    let af_select = '#af_select_' + coverage_id;
    let af_select_val = $(af_select).val();
    let naf_select = '#naf_select_' + coverage_id;
    let naf_select_val = $(naf_select).val();

    let last_coverage_id = $('#last_coverage_id').val()
    let content_id = '#content_' + last_coverage_id;

    $(content_id).removeClass('active');

    let product_id = $(this).attr('productID');
    let csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/products/${product_id}/update_prsf_coverage/${coverage_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'PUT',
      success: function(response){
        let obj = JSON.parse(response)
      }
    });

    rs_validation_disable_value(coverage_id, af_select_val, '#af_');
    rs_validation_disable_value(coverage_id, naf_select_val, '#naf_');
    rs_validation_fields(coverage_id);
  });

  $('.af_select').change(function(){
    let coverage_id = $(this).attr('coverage');
    let select_value = $(this).val();
    rs_validation_fields(coverage_id);
    rs_validation_disable_value(coverage_id, select_value, '#af_');
  });

  $('.naf_select').change(function(){
    let coverage_id = $(this).attr('coverage');
    let select_value = $(this).val();
    rs_validation_fields(coverage_id);
    rs_validation_disable_value(coverage_id, select_value, '#naf_');
  });

  // for product_coverage_risk_share_facility and product_coverage_risk_share_facility_payor_procedure card label_value masking
  var im = new Inputmask("decimal", {
    min: '1',
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('.card_mask_value'));

  $('#step6_nxt').on('click', function(){
    let p_id = $(this).attr('productID')
    let nxtStep = $(this).attr('nxt_step')
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${p_id}/next_btn/${nxtStep}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'GET',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.replace('/products/' + p_id + '/setup?step=' + nxtStep)
      }
    });
  })

});
