import { modal_cdt_benefit } from './modal_dental_cdt_benefit.js'
import { modal_diagnosis_benefit } from './modal_dental_diagnosis_benefit.js'
import { load_tbl_cdt } from './cdt_dental_benefit.js'

onmount('div[id="benefit_riders"]', function () {
  $('#benefit_form_dim').dimmer('show');
  $(document).ready(function () {
    $('.modal-open-main').click(function () {
      //$('.ui.rtp-modal').modal('show');
      $('.ui.modal:not(.ui.send-rtp-modal)').modal('show');
    });
  });

  $('.send-rtp-modal').modal('attach events', '.button.send-rtp');
  $('.benefit.modal').modal('attach events', '.modal-open-benefit');
  $('.packages.modal').modal('attach events', '.modal-open-package');
 // $('.complete.modal').modal('attach events', '.modal-open-complete');
  $('.facilities.modal').modal('attach events', '.modal-open-facilities');

  const csrf = $('input[name="_csrf_token"]').val();
  const benefit_code = $('input[name="benefit[code]"]').val()
  let bc_data
  let bc_array
  let benefit_limits

  $.ajax({
    url: `/get_all_benefit_code`,
    headers: {
      "X-CSRF-TOKEN": csrf
    },
    type: 'get',
    success: function(response) {
      bc_data = JSON.parse(response)
      bc_array = $.map(bc_data, function(value, index) {
        return [value.code]
      });

      let is_new = $('input[name="benefit_id"]').val() == undefined ? true : false
      if(is_new) {
        $('#benefit_form_dim').dimmer('hide');
        initializeBenefitCodeRule()
        initializeBenefitValidations()
      } else {
        load_benefit_data(
          $('input[name="benefit_id"]').val()
        )
      }
    },
    error: (xhr, ajaxOptions, thrownError) => {
      window.location.replace('/sign_out_error_dt')
    }
  })

  // continue validating benefit code
  // let timeout = null

  // $('input[name="benefit[code]"]').keyup(function () {
  //   clearTimeout(timeout)

  //   timeout = setTimeout(function() {
  //     console.log(
  //       $(this).val()
  //     )
  //   }, 1000)
  // })

  // $('input[name="benefit[code]"]')
  //   .api({
  //     url: '/web/benefits/check_benefit_code/{value}',
  //     onResponse: response => {
  //       event.preventDefault()
  //       event.stopPropagation()

  //       if(response.result) {
  //         $('#riders_form').form('remove prompt', 'benefit[code]', 'Benefit Code already exist.')
  //       } else {
  //         $('#riders_form').form('add prompt', 'benefit[code]', 'Benefit Code already exist.')
  //       }
  //     }
  //   })

  const initializeBenefitCodeRule = _ => {
    $.fn.form.settings.rules.checkBenefitCode = function(param) {
      return bc_array.indexOf(param) == -1 ? true : false
    }
  }


  const load_coverage_data = response => {
    $('#coverages_dropdown').dropdown('show')
    $.each(response.coverages, function(index, value) {
      $('#loaded_coverage_id').append(`<input type="hidden" class="current_coverage_id" value="${value.id}">`)
    })
  }

  const load_package_data = response => {
    $('#select-packages').dropdown('show')
    $.each(response.packages, function(index, value) {
      $('#loaded_package_id').append(`<input type="hidden" class="current_package_id" value="${value.id}">`)
    })
  }

  const load_acu_package_data = response => {
    $('#acu-select-packages').dropdown('show')
    $.each(response.packages, function(index, value) {
      $('#loaded_package_id').append(`<input type="hidden" class="current_package_id" value="${value.id}">`)
    })
  }

  const load_diagnosis_data = response => {
    let dt = $('#tbl_cdt').DataTable();
    $.each(response.diagnosis, function(index, value) {
      dt.row.add([
        `<span class="green selected_diagnosis_id">${value.code}</span>`,
        `<strong>${value.name}</strong><br><small class="thin dim">${value.description}</small>`,
        `${value.type}`,
        `<a href="#!" class="remove_diagnosis"><i class="green trash icon"></i></a><input type="hidden" name="benefit[diagnosis_ids][]" value="${value.id}">`
      ]).draw(false)
    })

    $('input[name="is_valid_diagnosis"]').val("true")

    initializeDeleteDiagnosis()
  }

  const load_procedure_data = response => {
    let dt = $('#tbl_package').DataTable();
    $.each(response.procedures, function(index, value) {
      dt.row.add([
        `-`,
        `${value.sp_code}`,
        `${value.sp_description}`,
        `${value.pp_code}`,
        `${value.pp_description}`,
        `-`,
        `-`,
        `<a href="#!" class="remove_package"><i class="green trash icon"></i></a>
        <span class="selected_procedure_id hidden">${value.pp_id}</span>
        <input type="hidden" name="benefit[procedure_ids][]" value="${value.pp_id}">`
      ]).draw(false)
    })
  }

  const load_peme = response => {
    load_coverage_data(response)
    load_acu_package_data(response)

    if(response.type == "Policy"){
      $('#bc_policy').attr('checked', true)
      $('#hide_availment_fields').hide();
      $('input[name="benefit[benefit_policy]"]').val("Policy")
      $('input[name="benefit[type]"]').val("Policy")
      policy_form_validation()
      $('.prompt').remove()
      $('#package_procedure_fields').find('div[class="field error"]').removeClass('error')
      $('#acu-select-packages').find('div[class="field error"]').removeClass('error')
      $('#riders_form').removeClass("success error warning");
    }else{
      $('#bc_availment').attr('checked', true)
      $('input[name="benefit[benefit_policy]"]').val("Availment")
      $('input[name="benefit[type]"]').val("Availment")
    }
  }

  const load_acu = response => {
    load_coverage_data(response)
    benefit_limits = response.limits

  if(response.type == "Policy"){
    $('#benefit_code2').val(response.code)
    $('#bc_policy').attr('checked', true)
    // $('#bc_availment').attr('disabled', true)
    $('#hide_availment_fields').hide();
    $('input[name="benefit[benefit_policy]"]').val("Policy")
    $('input[name="benefit[type]"]').val("Policy")
    policy_form_validation()
    $('.prompt').remove()
    $('#package_procedure_fields').find('div[class="field error"]').removeClass('error')
    $('#acu-select-packages').find('div[class="field error"]').removeClass('error')
    $('#riders_form').removeClass("success error warning");
  }
  else {
    load_acu_package_data(response)
    $('#acu_type').find('.ui.dropdown').dropdown(
      'set selected',
      response.acu_type
    )

    $('#acu_coverage').find('.ui.dropdown').dropdown(
      'set selected',
      response.acu_coverage
    )

    $('#bc_availment').attr('checked', true)
    $('input[name="benefit[benefit_policy]"]').val("Availment")
    $('input[name="benefit[type]"]').val("Availment")

    if(response.provider_access != null){
      if(response.provider_access.indexOf("Hospital") > -1) {
        $('#hospital')
          .closest('.ui.checkbox')
          .checkbox('check')
      }

      if(response.provider_access.indexOf("Clinic") > -1) {
        $('#clinic')
          .closest('.ui.checkbox')
          .checkbox('check')
      }

      if(response.provider_access.indexOf("Mobile") > -1) {
        $('#mobile')
          .closest('.ui.checkbox')
          .checkbox('check')
      }
    }

    $('#provider_access_value').val(response.provider_access)
  }
  }

  const load_maternity = response => {
    load_coverage_data(response)
    load_package_data(response)
    benefit_limits = response.limits
    load_diagnosis_data(response)
    load_procedure_data(response)

    $('#maternity_type')
      .find('.ui.dropdown')
      .dropdown(
        'set selected',
        response.maternity_type
      )

    let waiting_period_id = `#benefit_waiting_period_${response.waiting_period}`

    $('#Covered_Enrollees')
      .find('.ui.dropdown')
      .dropdown(
        'set selected',
        response.covered_enrollees
      )

    $(waiting_period_id)
      .closest('.ui.checkbox')
      .checkbox('check')

    if(response.type == "Policy"){
      $('#bc_policy').attr('checked', true)
      $('#hide_availment_fields').hide();
      $('input[name="benefit[benefit_policy]"]').val("Policy")
      $('input[name="benefit[type]"]').val("Policy")
      policy_form_validation()
      $('.prompt').remove()
      $('#package_procedure_fields').find('div[class="field error"]').removeClass('error')
      $('#acu-select-packages').find('div[class="field error"]').removeClass('error')
      $('#riders_form').removeClass("success error warning");
     }else{
      $('#bc_availment').attr('checked', true)
      $('input[name="benefit[benefit_policy]"]').val("Availment")
      $('input[name="benefit[type]"]').val("Availment")
     }

  }

  const load_dental = response => {
    if(response.type == "Policy"){
      $('#benefit_code2').val(response.code)
      $('#bc_policy').attr('checked', true)
      $('#hide_availment_fields').hide();
      $('input[name="benefit[benefit_policy]"]').val("Policy")
      $('input[name="benefit[type]"]').val("Policy")
      policy_form_validation()
      $('.prompt').remove()
      $('#package_procedure_fields').find('div[class="field error"]').removeClass('error')
      $('#acu-select-packages').find('div[class="field error"]').removeClass('error')
      $('#riders_form').removeClass("success error warning");
    }
    else {
      $('#bc_availment').attr('checked', true)
      $('input[name="benefit[benefit_policy]"]').val("Availment")
      $('input[name="benefit[type]"]').val("Availment")
    }
  }

  const load_normal = response => {
    load_coverage_data(response)
    load_package_data(response)
    benefit_limits = response.limits
    load_diagnosis_data(response)
    load_procedure_data(response)

    if(response.type == "Policy"){
      $('#bc_policy').attr('checked', true)
      $('#hide_availment_fields').hide();
      $('input[name="benefit[benefit_policy]"]').val("Policy")
      $('input[name="benefit[type]"]').val("Policy")
      policy_form_validation()
      $('.prompt').remove()
      $('#package_procedure_fields').find('div[class="field error"]').removeClass('error')
      $('#acu-select-packages').find('div[class="field error"]').removeClass('error')
      $('#riders_form').removeClass("success error warning");
     }else{
      $('#bc_availment').attr('checked', true)
      $('input[name="benefit[benefit_policy]"]').val("Availment")
      $('input[name="benefit[type]"]').val("Availment")
     }
  }

  const load_benefit_data = id => {
    $.ajax({
      url: `/web/benefits/load_benefit_data?id=${id}`,
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      type: 'get',
      success: function(response) {
        $('input[name="benefit[code]"]').val(response.code)
        $('input[name="benefit[name]"]').val(response.name)
        let coverages = []
        $.each(response.coverages, function(index, value) {
          coverages.push(
            value.code
          )
        })

        bc_array
          .splice(
            $.inArray(response.code, bc_array),
            1
          )

        initializeBenefitCodeRule()

        if(coverages.includes("PEME")) {
          load_peme(response)
        } else if(coverages.includes("ACU")) {
          load_acu(response)
        } else if(coverages.includes("MTRNTY")) {
          load_maternity(response)
        } else if(coverages.includes("DENTL")) {
          load_dental(response)
        }
        else {
          load_normal(response)
        }
        $('#benefit_form_dim').dimmer('hide')
      },
      error: (xhr, ajaxOptions, thrownError) => {
        window.location.replace('/sign_out_error_dt')
      }
    })
  }

  $.fn.form.settings.rules.checkType= function(param) {
    let type = []
    $('#availment_fields').find('input[type=checkbox]').each(function(){
      type.push($(this).is(':checked'))
    })

    if (type.includes(true)){
      $(`#availment_fields`).find('.field').removeClass('error') // removing error prompt radio_btn[type]

       return true
    } else{
      $(`#availment_fields`).find('.field').addClass('error') // adding error prompt radio_btn[type]

       return false
    }
  }

  const initializeBenefitValidations = _ => {
    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Benefit Code already exist.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a coverage.'
          }]
        },
        'benefit[package_ids]': {
          identifier: 'benefit[package_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one package.'
          }]
        },
        'is_valid_limit': {
          identifier: 'is_valid_limit',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a limit.'
          }]
        },
        'is_valid_diagnosis': {
          identifier: 'is_valid_diagnosis',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one diagnosis.'
          }]
        },
        'is_valid_procedure': {
          identifier: 'is_valid_procedure',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a procedure.'
          }]
        },
        'benefit[reimbursement]': {
          identifier: 'benefit[reimbursement]',
          rules: [{
            type: 'checkType',
            prompt: 'Select Atleast one availment.'
          }]
        },
      }
    })
  }

  const initializeDraftValidation = _ => {
    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Benefit Code already exist.'
          }]
        }
      }
    })
  }

  const maskDecimal = new Inputmask("decimal", {
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    removeMaskOnSubmit: true
  })

  const maskPercentage = new Inputmask("numeric", {
    max: 100,
    allowMinus:false,
    rightAlign: false
  })

  const maskNumeric = new Inputmask("numeric", {
    allowMinus:false,
    radixPoint: "",
    rightAlign: false
  })

  const initializeLimitModal = () => {
    $('.limit.modal')
      .modal({
        autofocus: false,
        closable: false,
        centered: false,
        observeChanges: true,
        selector: {
          deny: '#cancel_limit_form'
        }
      })
      .modal('attach events', '.modal-open-limit');
  }

  const initializeAcuLimitModal = () => {
    $('.acu_limit.modal')
      .modal({
        autofocus: false,
        closable: false,
        centered: false,
        observeChanges: true,
        selector: {
          deny: '#cancel_limit_form'
        },
        onShow: () => {
          initializeAcuLimitForm()
        }
      })
      .modal('attach events', '.modal-open-acu-limit');
  }

  const tbl_limit = $('#tbl_limit').DataTable()
  const acu_tbl_limit = $('#acu_tbl_limit').DataTable()
  let active_limit_row

  const addLimitRow = (id, coverage_name) => {
    if( $('input[name="benefit_id"]').val() != undefined ) {
      if(benefit_limits == "") {
        tbl_limit.row.add([
          `<span class="name" id="limit_${coverage_name}">${coverage_name}</span>`,
          `<span class="type">-</span>`,
          `<span class="amount">-</span>`,
          `<span class="class">-</span>`,
          `
          <span class="button">
            <a href="#!" class="mini modal-open-limit add_limit ui primary basic button">Add Limit</a>
            <input type="hidden" name="benefit[limits][]" value="${id}">
          </span
        `
        ]).draw()
      }
      else {
        $.each(benefit_limits, function(index, value) {
          let amount
          if(value.percentage != null) {
            amount = `${value.percentage} %`
          }
          if(value.amount != null) {
            amount = `${value.amount} PHP`
          }
          if(value.session != null) {
            amount = `${value.session}`
          }
          if(value.tooth != null) {
            amount = `${value.tooth} Tooth`
          }
          if(value.quadrant != null) {
            amount = `${value.quadrant} Quadrant`
          }
          tbl_limit.row.add([
            `<span class="name" id="limit_${coverage_name}">${coverage_name}</span>`,
            `<span class="type">${value.type}</span>`,
            `<span class="amount">${amount}</span>`,
            `<span class="class">${value.classification}</span>`,
            `
            <span class="button">
              <a href="#!" class="mini modal-open-limit edit_limit ui primary basic button">Edit Limit</a>
              <input type="hidden" name="benefit[limits][]" value="${id}&${value.type}&${amount}&${value.classification}">
            </span>
            `
          ]).draw()
        })

      }

      $('input[name="is_valid_limit"]').val("true")
      $('input[name="is_valid_procedure"]').val("true")
      initializeEditLimit()
    } else {
      tbl_limit.row.add([
        `<span class="name" id="limit_${coverage_name}">${coverage_name}</span>`,
        `<span class="type">-</span>`,
        `<span class="amount">-</span>`,
        `<span class="class">-</span>`,
        `
        <span class="button">
          <a href="#!" class="mini modal-open-limit add_limit ui primary basic button">Add Limit</a>
          <input type="hidden" name="benefit[limits][]" value="${id}">
        </span
        `
      ]).draw()
    }

    initializeLimitModal()

    $('.add_limit').click(function() {
      let row = $(this).closest('tr')
      let name = row.find('.name').text()
      let record = $(this).closest('td').find('input')
      active_limit_row = row
      // $('div[role="general"]').show()
      // $('div[role="dental"]').show()

      $('#limit_form').form('clear')
      if ( name == "Dental") {
        $('div[role="general"]').hide()
      } else {
        $('div[role="dental"]').hide()
      }
      $('input[name="limit_coverage"]').val(name)
      $('input[name="limit_id"]').val(record.val())
      // $('#limit_amount_field').addClass('disabled')
      $('#submit_limit_form').text("Add Limit")
    })
  }

  const addAcuLimitRow = (id, coverage_name) => {
    if ($('input[name="benefit_id"]').val() != undefined) {
      if(benefit_limits == "") {
      acu_tbl_limit.row.add([
        `<span class="name" id="limit_${coverage_name}">${coverage_name}</span>`,
        `<span class="type">-</span>`,
        `<span class="limit_session">-</span>`,
        `<span class="amount">-</span>`,
        `<span class="class">-</span>`,
        `
        <span class="button">
          <a href="#!" class="mini modal-open-acu-limit add_acu_limit ui primary basic button">Add Limit</a>
          <input type="hidden" name="benefit[limits][]" value="${id}">
        </span>
        `
      ]).draw()
      }
      else {
      $.each(benefit_limits, function(index, value) {
        if (value.type == "Sessions") {
          acu_tbl_limit.row.add([
            `<span class="name green" id="limit_${coverage_name}">${coverage_name}</span>`,
            `<span class="type">${value.type}</span>`,
            `<span class="limit_session">${value.session}</span>`,
            `<span class="amount">-</span>`,
            `<span class="class">${value.classification}</span>`,
            `
            <span class="button">
              <a href="#!" class="mini modal-open-acu-limit edit_acu_limit ui primary basic button">Edit Limit</a>
              <input type="hidden" name="benefit[limits][]" value="${id}&${value.type}&${value.session}&&${value.classification}">
            </span>
            `
          ]).draw()
        } else {
          acu_tbl_limit.row.add([
            `<span class="name2 green" id="limit_${coverage_name}">${coverage_name}</span>`,
            `<span class="type2">${value.type}</span>`,
            `<span class="limit_session2">-</span>`,
            `<span class="amount2">${value.amount} PHP</span>`,
            `<span class="class2">${value.classification}</span>`,
            `
            <span class="button2">
              <input type="hidden" name="benefit[limits][]" value="${id}&${value.type}&&${value.amount}&${value.classification}">
            </span>
            `
          ]).draw()
        }
      })

      }

      $('input[name="is_valid_acu_limit"]').val("true")
      $('input[name="is_valid_acu_procedure"]').val("true")

      initializeACUEditLimit()
    } else {
      acu_tbl_limit.row.add([
        `<span class="name" id="limit_${coverage_name}">${coverage_name}</span>`,
        `<span class="type">-</span>`,
        `<span class="limit_session">-</span>`,
        `<span class="amount">-</span>`,
        `<span class="class">-</span>`,
        `
        <span class="button">
          <a href="#!" class="mini modal-open-acu-limit add_acu_limit ui primary basic button">Add Limit</a>
          <input type="hidden" name="benefit[limits][]" value="${id}">
        </span>
        `
      ]).draw()
    }

    initializeAcuLimitModal()

    $('.add_acu_limit').click(function() {
      let row = $(this).closest('tr')
      let name = row.find('.name').text()
      let record = $(this).closest('td').find('input')
      active_limit_row = row

      $('#acu_limit_form').form('clear')
      $('input[name="limit_coverage"]').val(name)
      $('input[name="limit_id"]').val(record.val())

      $('input[name="limit_type"]').val("Sessions")
      $('input[name="limit_session"]').val(1)

      $('input[name="limit_type_peso"]').val("Peso")

      $('#acu_submit_limit_form').text("Add Limit")
    })
  }

  const show_diagnosis_fields = () => {
    $('#package_procedure_fields').removeClass('hidden')

    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Benefit Code already exist.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a coverage.'
          }]
        },
        // 'benefit[package_ids]': {
        //   identifier: 'benefit[package_ids]',
        //   rules: [{
        //     type: 'empty',
        //     prompt: 'Please enter a package.'
        //   }]
        // },
        'is_valid_limit': {
          identifier: 'is_valid_limit',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a limit.'
          }]
        },
        // 'is_valid_diagnosis': {
        //   identifier: 'is_valid_diagnosis',
        //   rules: [{
        //     type: 'empty',
        //     prompt: 'Please enter a diagnosis.'
        //   }]
        // },
        'is_valid_procedure': {
          identifier: 'is_valid_procedure',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a procedure.'
          }]
        }
      }
    })
  }

  const maternity_form_validation = () => {
    $('#package_procedure_fields').removeClass('hidden')

    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Benefit Code already exist.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a coverage.'
          }]
        },
        // 'benefit[package_ids]': {
        //   identifier: 'benefit[package_ids]',
        //   rules: [{
        //     type: 'empty',
        //     prompt: 'Please enter a package.'
        //   }]
        // },
        'is_valid_limit': {
          identifier: 'is_valid_limit',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a limit.'
          }]
        },
        'is_valid_diagnosis': {
          identifier: 'is_valid_diagnosis',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one diagnosis.'
          }]
        },
        'is_valid_procedure': {
          identifier: 'is_valid_procedure',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a procedure.'
          }]
        },
        'benefit[maternity_type]': {
          identifier: 'benefit[maternity_type]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a maternity type.'
          }]
        },
        'benefit[covered_enrollees]': {
          identifier: 'benefit[covered_enrollees]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a covered enrollees.'
          }]
        },
        'benefit[waiting_period]': {
          identifier: 'benefit[waiting_period]',
          rules: [{
            type: 'checked',
            prompt: 'Please enter a waiting period.'
          }]
        }

      }
    })
  }

  const peme_form_validation = () => {
    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Benefit Code already exist.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a coverage.'
          }]
        },
        'benefit[acu_package_ids]': {
          identifier: 'benefit[acu_package_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one package.'
          }]
        }
      }
    })
  }

  const dental_form_validation = () => {

    $.fn.form.settings.rules.checkAvailmentType = param => {
     let loa = $('#loa_facilitated').is(':checked') == true
     let reimbursement = $('#reimbursement').is(':checked') == true

        if ((loa || reimbursement) == true) {
          return true
        } else {
          return false
        }
      }

    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Enter code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Code is already taken.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Enter name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Select coverage.'
          }]
        },
        'benefit[limit_type]': {
          identifier: 'benefit[limit_type]',
          rules: [{
            type: 'empty',
            prompt: 'Select limit type.'
          }]
        },
        'benefit[frequency]': {
          identifier: 'benefit[frequency]',
          rules: [{
            type: 'empty',
            prompt: 'Select Frequency'
          }]
        },
        'benefit[loa_facilitated]': {
          identifier: 'benefit[loa_facilitated]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'benefit[reimbursement]': {
          identifier: 'benefit[reimbursement]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'is_valid_diagnosis': {
          identifier: 'is_valid_diagnosis',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one diagnosis.'
          }]
        }
      }
    })
  }

  const policy_form_validation = () => {
    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Benefit Code already exist.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a coverage.'
          }]
        },
        'benefit_classification': {
          identifier: 'benefit_classification',
          rules: [{
            type: 'empty',
            prompt: 'Please Select Classification.'
          }]
        }
        // 'benefit[acu_package_ids]': {
        //   identifier: 'benefit[acu_package_ids]',
        //   rules: [{
        //     type: 'empty',
        //     prompt: 'Please select atleast one package.'
        //   }]
        // }
      }
    })
  }

  const hide_diagnosis_fields = () => {
    $('#diagnosis_fields').addClass('hidden')
    $('#select-packages')
      .dropdown('clear')
    $('#tbl_package')
      .DataTable()
      .clear()
      .draw()
    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Benefit Code already exist.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a coverage.'
          }]
        },
        'benefit[acu_package_ids]': {
          identifier: 'benefit[acu_package_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one package.'
          }]
        },
        'benefit[acu_type]': {
          identifier: 'benefit[acu_type]',
          rules: [{
            type: 'empty',
            prompt: 'Please Select ACU Type.'
          }]
        },
        'benefit[acu_coverage]': {
          identifier: 'benefit[acu_coverage]',
          rules: [{
            type: 'empty',
            prompt: 'Please select ACU Coverage.'
          }]
        },
        'benefit[provider_access]': {
          identifier: 'benefit[provider_access]',
          rules: [{
            type: 'empty',
            prompt: 'Please atleast one provider access.'
          }]
        },
        'is_valid_acu_limit': {
          identifier: 'is_valid_acu_limit',
          rules: [{
            type: 'empty',
            prompt: 'Please enter an acu limit.'
          }]
        },
        'is_valid_acu_procedure': {
          identifier: 'is_valid_acu_procedure',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a procedure.'
          }]
        }
      },
      onSuccess: function(event, fields){
        // $('.modal.complete').modal('show')
      }
    })
  }
// var removed;
  $('#bclass_standard').change(function(){
    $('input[name="benefit[classification]"]').val("Standard")
  })

  $('#bclass_custom').change(function(){
    $('input[name="benefit[classification]"]').val("Custom")
  })

  $('#bc_policy').change(function(){
    // removed =
    policy_form_validation()
    $('#availment_fields').hide()
    $('#hide_availment_fields').hide();
    $('input[name="benefit[benefit_policy]"]').val("Policy")
    $('input[name="benefit[type]"]').val("Policy")
    $('input[name="benefit[loa_facilitated]"]').val('')
    $('input[name="benefit[reimbursement]"]').val('')
    $('.prompt').remove()
    $('#package_procedure_fields').find('div[class="field error"]').removeClass('error')
    $('#acu-select-packages').find('div[class="field error"]').removeClass('error')
    $('#riders_form').removeClass("success error warning");
  })

  let AddedValue = $('input[name="benefit[coverage_ids]"]').val()
  let AddedText = $('input[name="benefit[coverage_ids]"]').text()

  $('#coverages_dropdown').dropdown({
    apiSettings: {
      url: `/web/benefits/load_coverages?type=riders`,
      cache: false
    },
    onShow: () => {
      let current_coverage_div = $('#loaded_coverage_id')
      if(current_coverage_div.length > 0) {
        $('.current_coverage_id').each(function() {
          $('#coverages_dropdown').dropdown(
            'set selected',
            $(this).val()
          )
        })
        current_coverage_div.remove()
        $('#coverages_dropdown').addClass('disabled')
        return false
      }
    },
    onChange: (addedValue, addedText, $addedChoice) => {
     let benefit_policy = $('input[name="benefit[benefit_policy]"]').val()
     if(benefit_policy == "Policy") {
       if(addedText == "ACU" || addedText == "PEME" || addedText == "Dental"){
         $('#hide_benefit_classification').hide()
         $('#availment_fields').hide()
         policy_form_validation()
         $('.prompt').remove()
         $('#package_procedure_fields').find('div[class="field error"]').removeClass('error')
         $('#riders_form').removeClass("success error warning");
         AddedValue = addedValue
         AddedText = addedText
      }else {
         $('#availment_fields').hide()
         $('#hide_benefit_classification').show()
         policy_form_validation()
         $('.prompt').remove()
         $('#package_procedure_fields').find('div[class="field error"]').removeClass('error')
         $('#riders_form').removeClass("success error warning");
         AddedValue = addedValue
         AddedText = addedText
      }
     }
     else{
      if(addedText == "ACU") {
        tbl_limit
        .clear()
        .draw()

        acu_tbl_limit
        .clear()
        .draw()
        AddedValue = addedValue
        addAcuLimitRow(addedValue, addedText)
        $('#hide_benefit_classification').hide()
        $('#benefit_acu_type').prop("disabled", false)
        $('#acu_select').prop("disabled", false)
        $('#provider_access_value').prop("disabled", false)

        $('#benefit_maternity_type').prop("disable", true)
        $('#benefit_covered_enrollees').prop("disabled", true)
        $('input[name="benefit[waiting_period]"]').attr('disabled', true)

        $('input[name="benefit[package_ids]"]').attr("disabled", true)
        $('input[name="benefit[acu_package_ids]"]').attr("disabled", false)
        $('#acu_coverage').removeClass('hidden')
        $('#maternity_fields').addClass('hidden')

        $('#package_procedure_fields').addClass('hidden')
        $('#normal_limit_field').addClass('hidden')
        $('#acu_package_fields').removeClass('hidden')
        $('#acu_limit_field').removeClass('hidden')

        acu_xtra_params()
        hide_diagnosis_fields()
      }
      else if (addedText == "Maternity"){
        acu_tbl_limit
        .clear()
        .draw()

        tbl_limit
        .clear()
        .draw()

        AddedValue = addedValue
        addLimitRow(addedValue, addedText)
        $('#hide_benefit_classification').show()
        $('#benefit_maternity_type').prop("disabled", false)
        $('#benefit_covered_enrollees').prop("disabled", false)
        $('input[name="benefit[waiting_period]"]').attr('disabled', false)

        $('#benefit_acu_type').prop("disabled", true)
        $('#acu_select').prop("disabled", true)
        $('#provider_access_value').prop("disabled", true)

        $('input[name="benefit[package_ids]"]').attr("disabled", false)
        $('input[name="benefit[acu_package_ids]"]').attr("disabled", true)
        $('#normal_limit_field').removeClass('hidden')
        $('#acu_package_fields').addClass('hidden')
        $('#acu_limit_field').addClass('hidden')
        $('#acu_coverage').addClass('hidden')
        $('#maternity_fields').removeClass('hidden')

        $('#diagnosis_fields').removeClass('hidden')
        $('#btn_add_procedure_field').removeClass('hidden')
        maternity_form_validation()
      }
      else if(addedText == "PEME") {
        acu_tbl_limit
        .clear()
        .draw()

        tbl_limit
        .clear()
        .draw()

        AddedValue = addedValue
        // addLimitRow(addedValue, addedText)

        $('#benefit_maternity_type').prop("disabled", true)
        $('#benefit_covered_enrollees').prop("disabled", true)
        $('input[name="benefit[waiting_period]"]').attr('disabled', true)
        $('#hide_benefit_classification').hide()

        $('#benefit_acu_type').prop("disabled", true)
        $('#acu_select').prop("disabled", true)
        $('#provider_access_value').prop("disabled", true)

        $('#diagnosis_fields').addClass('hidden')
        $('#acu_package_fields').removeClass('hidden')
        $('#package_procedure_fields').addClass('hidden')
        $('#procedure_fields').css('display', 'none')
        $('#normal_limit_field').addClass('hidden')
        $('input[name="benefit[acu_package_ids]"]').attr("disabled", false)
        $('input[name="benefit[package_ids]"]').attr("disabled", true)

        $('#acu_coverage').addClass('hidden')
        $('#maternity_fields').addClass('hidden')

        peme_form_validation()
       }
       else if(addedText == "Dental") {
        acu_tbl_limit
        .clear()
        .draw()

        tbl_limit
        .clear()
        .draw()

        AddedValue = addedValue
        AddedText = addedText
        addLimitRow(addedValue, addedText)
        $('#hide_benefit_classification').addClass("hidden")
        $('#dental_fields').removeClass('hidden')
        $('#benefit_maternity_type').prop("disabled", true)
        $('#benefit_covered_enrollees').prop("disabled", true)
        $('input[name="benefit[waiting_period]"]').attr('disabled', true)

        $('#benefit_acu_type').prop("disabled", true)
        $('#acu_select').prop("disabled", true)
        $('#provider_access_value').prop("disabled", true)

        $('.diagnosis_datatable_dental').addClass('hidden')
        $('.diagnosis_datatable_dental').prop("disabled", true)
        $('#diagnosis_fields').removeClass('hidden')
        $('#acu_package_fields').addClass('hidden')
        $('#package_procedure_fields').addClass('hidden')
        $('#procedure_fields').css('display', 'none')
        $('#normal_limit_field').addClass('hidden')
        $('input[name="benefit[acu_package_ids]"]').attr("disabled", false)
        $('input[name="benefit[package_ids]"]').attr("disabled", true)
        $('#acu_limit_field').addClass('hidden')
        $('#acu_coverage').addClass('hidden')
        $('#maternity_fields').addClass('hidden')
        dental_params()
      }
      else{
        acu_tbl_limit
        .clear()
        .draw()

        tbl_limit
        .clear()
        .draw()
        AddedValue = addedValue
        AddedText = addedText
        addLimitRow(addedValue, addedText)
        $('#benefit_maternity_type').prop("disabled", true)
        $('#benefit_covered_enrollees').prop("disabled", true)
        $('input[name="benefit[waiting_period]"]').attr('disabled', true)

        $('#benefit_acu_type').prop("disabled", true)
        $('#acu_select').prop("disabled", true)
        $('#provider_access_value').prop("disabled", true)

        $('#hide_benefit_classification').show()
        $('input[name="benefit[package_ids]"]').attr("disabled", false)
        $('input[name="benefit[acu_package_ids]"]').attr("disabled", true)
        $('#normal_limit_field').removeClass('hidden')
        $('#acu_package_fields').addClass('hidden')
        $('#acu_limit_field').addClass('hidden')
        $('#acu_coverage').addClass('hidden')
        $('#maternity_fields').addClass('hidden')

        $('#diagnosis_fields').removeClass('hidden')
        $('#btn_add_procedure_field').removeClass('hidden')
        show_diagnosis_fields()
      }
    }

      $('#coverages_dropdown').dropdown('hide')
    }
  })

  //FOR CATEGORY RADIO BUTTON
  $('#loa_facilitated').change(function(){
    check_availment()
  })


  $('#reimbursement').change(function(){
    check_availment()
  })

  $('#bc_availment').change(function(){
    check_availment()
    $('#availment_fields').show()
    $('#hide_availment_fields').show();
    $('input[name="benefit[benefit_policy]"]').val("Availment")
    $('input[name="benefit[type]"]').val("Availment")
    let benefit_coverage = $("#coverages_dropdown").find('div[class="text"]').text()
      if( benefit_coverage == "ACU") {
        tbl_limit
        .clear()
        .draw()

        acu_tbl_limit
        .clear()
        .draw()
        addAcuLimitRow(AddedValue, "ACU")
        $('#benefit_acu_type').prop("disabled", false)
        $('#acu_select').prop("disabled", false)
        $('#provider_access_value').prop("disabled", false)

        $('#benefit_maternity_type').prop("disabled", true)
        $('#benefit_covered_enrollees').prop("disabled", true)
        $('input[name="benefit[waiting_period]"]').attr('disabled', true)

        $('input[name="benefit[package_ids]"]').attr("disabled", true)
        $('input[name="benefit[acu_package_ids]"]').attr("disabled", false)
        $('#acu_coverage').removeClass('hidden')
        $('#maternity_fields').addClass('hidden')

        $('#package_procedure_fields').addClass('hidden')
        $('#normal_limit_field').addClass('hidden')
        $('#acu_package_fields').removeClass('hidden')
        $('#acu_limit_field').removeClass('hidden')

        acu_xtra_params()
        hide_diagnosis_fields()
      }
      else if (benefit_coverage == "Maternity"){
        maternity_form_validation()
        acu_tbl_limit
        .clear()
        .draw()

        tbl_limit
        .clear()
        .draw()

        addLimitRow(AddedValue, "Maternity")
        $('#benefit_maternity_type').prop("disabled", false)
        $('#benefit_covered_enrollees').prop("disabled", false)
        $('input[name="benefit[waiting_period]"]').attr('disabled', false)

        $('#benefit_acu_type').prop("disabled", true)
        $('#acu_select').prop("disabled", true)
        $('#provider_access_value').prop("disabled", true)

        $('input[name="benefit[package_ids]"]').attr("disabled", false)
        $('input[name="benefit[acu_package_ids]"]').attr("disabled", true)
        $('#normal_limit_field').removeClass('hidden')
        $('#acu_package_fields').addClass('hidden')
        $('#acu_limit_field').addClass('hidden')
        $('#acu_coverage').addClass('hidden')
        $('#maternity_fields').removeClass('hidden')

        $('#diagnosis_fields').removeClass('hidden')
        $('#btn_add_procedure_field').removeClass('hidden')
      }
      else if(benefit_coverage == "PEME") {
        acu_tbl_limit
        .clear()
        .draw()

        tbl_limit
        .clear()
        .draw()

        // addLimitRow(AddedValue, "PEME")
        $('#benefit_maternity_type').prop("disabled", true)
        $('#benefit_covered_enrollees').prop("disabled", true)
        $('input[name="benefit[waiting_period]"]').attr('disabled', true)

        $('#benefit_acu_type').prop("disabled", true)
        $('#acu_select').prop("disabled", true)
        $('#provider_access_value').prop("disabled", true)

        $('#diagnosis_fields').addClass('hidden')
        $('#acu_package_fields').removeClass('hidden')
        $('#package_procedure_fields').addClass('hidden')
        $('#procedure_fields').css('display', 'none')
        $('#normal_limit_field').addClass('hidden')
        $('input[name="benefit[acu_package_ids]"]').attr("disabled", false)
        $('input[name="benefit[package_ids]"]').attr("disabled", true)

        $('#acu_coverage').addClass('hidden')
        $('#maternity_fields').addClass('hidden')
        peme_form_validation()
      }
      else if(benefit_coverage == "Dental") {
        load_tbl_cdt("11")

        acu_tbl_limit
        .clear()
        .draw()

        tbl_limit
        .clear()
        .draw()

        $('#hide_benefit_classification').addClass("hidden")
        $('#dental_fields').removeClass('hidden')
        $('#benefit_maternity_type').prop("disabled", true)
        $('#benefit_covered_enrollees').prop("disabled", true)
        $('input[name="benefit[waiting_period]"]').attr('disabled', true)

        $('#benefit_acu_type').prop("disabled", true)
        $('#acu_select').prop("disabled", true)
        $('#provider_access_value').prop("disabled", true)

        $('.diagnosis_datatable_dental').addClass('hidden')
        $('.diagnosis_datatable_dental').prop("disabled", true)
        $('#diagnosis_fields').removeClass('hidden')
        $('#acu_package_fields').addClass('hidden')
        $('#package_procedure_fields').addClass('hidden')
        $('#procedure_fields').css('display', 'none')
        $('#normal_limit_field').addClass('hidden')
        $('input[name="benefit[acu_package_ids]"]').attr("disabled", false)
        $('input[name="benefit[package_ids]"]').attr("disabled", true)
        $('#acu_limit_field').addClass('hidden')
        $('#acu_coverage').addClass('hidden')
        $('#maternity_fields').addClass('hidden')
        dental_params()
      } else {
        load_tbl_cdt("11")
        $(document).unbind('change').on('change', '.ui.fluid.dropdown.inclusion', function(){
          let page = $(this).find($('.text')).html()
          var table = $('#tbl_cdt').DataTable();
          let no = parseInt(page) -1
          table.page( no ).draw( 'page' );
        })

    }
  })


  $(document).unbind('change').on('change', '.ui.fluid.dropdown.inclusion', function(){
    let page = $(this).find($('.text')).html()
    var table = $('#tbl_cdt').DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  $('#limit_type_dropdown').dropdown({
    onChange: (addedValue, addedText, $addedChoice) => {
      $('#limit_amount_field').removeClass('disabled')

      if(addedValue == "Peso") {
        maskDecimal.mask('input[name="limit_amount"]')
        $('div[id="limit_amount_label"]').text('PHP')
        $('input[name="limit_type"]').val(addedValue)

      }

      if(addedValue == "Plan Limit Percentage") {
        maskPercentage.mask('input[name="limit_amount"]')
        $('div[id="limit_amount_label"]').text('%')
        $('input[name="limit_type"]').val(addedValue)

      }

      if(addedValue == "Sessions") {
        maskNumeric.mask('input[name="limit_amount"]')
        $('div[id="limit_amount_label"]').text('Session/s')
        $('input[name="limit_type"]').val(addedValue)

      }

      if(addedValue == "Tooth") {
        maskNumeric.mask('input[name="limit_amount"]')
        $('div[id="limit_amount_label"]').text('Tooth')
        $('input[name="limit_type"]').val(addedValue)
      }

      if(addedValue == "Quadrant") {
        maskNumeric.mask('input[name="limit_amount"]')
        $('div[id="limit_amount_label"]').text('Quadrant')
        $('input[name="limit_type"]').val(addedValue)
      }
    }
  })

  $('#limit_type_dropdown_general').dropdown({
    onChange: (addedValue, addedText, $addedChoice) => {
      $('#limit_amount_field').removeClass('disabled')

      if(addedValue == "Peso") {
        maskDecimal.mask('input[name="limit_amount"]')
        $('div[id="limit_amount_label"]').text('PHP')
        $('input[name="limit_type"]').val(addedValue)
      }

      if(addedValue == "Plan Limit Percentage") {
        maskPercentage.mask('input[name="limit_amount"]')
        $('div[id="limit_amount_label"]').text('%')
        $('input[name="limit_type"]').val(addedValue)
      }

      if(addedValue == "Sessions") {
        maskNumeric.mask('input[name="limit_amount"]')
        $('div[id="limit_amount_label"]').text('Session/s')
        $('input[name="limit_type"]').val(addedValue)

      }
    }
  })


  const acu_xtra_params = () => {

    let selected_type = $('#acu_type').find('option:selected').text();
    if (selected_type == "Regular") {
      $('#acu_coverage option[value="Inpatient"]').remove()
      $('.acu_type').removeClass('disabled')
      $('.acu_type').dropdown("set selected", "Outpatient")
      $('#acu_select').removeAttr('disabled')
    } else if (selected_type == "Executive") {
      $('.acu_type').removeClass('disabled')
      $('#acu_select').removeAttr('disabled')
    }

    if($('#acu_type').dropdown("get value") != "") {
      $('.acu_type').removeClass('disabled')
    }

    $('#acu_type').on('change', function() {
      let selected_type = $('#acu_type').find('option:selected').text();
      $('#acu_coverage option[value="Inpatient"]').remove()
      if (selected_type == "Regular") {
        $('#acu_select').dropdown('restore defaults')
        $('.acu_type').removeClass('disabled')
        $('.acu_type').dropdown("set selected", "Outpatient")
        $('#acu_select').removeAttr('disabled')
      } else if (selected_type == "Executive") {
        $('#acu_select').dropdown('restore defaults')
        $("#acu_select").append('<option value="Inpatient">Inpatient</option>')
        $('.acu_type').removeClass('disabled')
        $('#acu_select').removeAttr('disabled')
      }
    })

    $('input[type=checkbox]').on('change', function() {
      let prov_access = get_prov_access()
      $('#provider_access_value').val(prov_access)
    })

    let prov_val = $('#provider_access_value').val()

    if(prov_val.indexOf("Hospital") > -1) { $('#hospital').prop('checked', true) }
    if(prov_val.indexOf("Clinic") > -1) { $('#clinic').prop('checked', true) }
    if(prov_val.indexOf("Mobile") > -1) { $('#mobile').prop('checked', true) }
  }

  const check_availment = _ => {
    let check_loa_facilitated = $('#loa_facilitated').is(':checked')
    let check_reimbursement = $('#reimbursement').is(':checked')

    if(check_loa_facilitated) {
      $('input[name="benefit[loa_facilitated]"]').closest('.field').removeClass('error')
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('input[name="benefit[loa_facilitated]"]').val(true)
    }else {
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('input[name="benefit[loa_facilitated]"]').val(false)
    }
    if(check_reimbursement) {
      $('input[name="benefit[reimbursement]"]').val(true)
    }else {
      $('input[name="benefit[reimbursement]"]').val(false)
    }
    dental_form_validation()
    dental_peso_validation()
  }

  const get_prov_access = _ => {
    let hospital = $('#hospital').is(':checked')
    let clinic = $('#clinic').is(':checked')
    let mobile = $('#mobile').is(':checked')
    let prov_val

    if(hospital && clinic && mobile) {
      prov_val = "Hospital, Clinic and Mobile"
    } else if(hospital && clinic) {
      prov_val = "Hospital and Clinic"
    } else if(hospital && mobile) {
      prov_val = "Hospital and Mobile"
    } else if(mobile && clinic) {
      prov_val = "Clinic and Mobile"
    } else if(hospital) {
      prov_val = "Hospital"
    } else if(clinic) {
      prov_val = "Clinic"
    } else if(mobile) {
      prov_val = "Mobile"
    }

    return prov_val
  }

  $('#limit_form').form({
    on: 'blur',
    inline: true,
    fields: {
      'limit_type': {
        identifier: 'limit_type',
        rules: [{
          type: 'empty',
          prompt: 'Please enter a limit type.'
        }]
      },
      'limit_amount': {
        identifier: 'limit_amount',
        rules: [{
          type: 'empty',
          prompt: 'Please enter a limit amount.'
        }]
      },
      'limit_class': {
        identifier: 'limit_class',
        rules: [{
          type: 'checked',
          prompt: 'Please enter a limit classification.'
        }]
      }
    }
  });

  const initializeAcuLimitForm = () => {
    maskDecimal.mask('input[name="acu_limit_amount"]')

     $('#acu_limit_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'acu_limit_class': {
          identifier: 'acu_limit_class',
          rules: [{
            type: 'checked',
            prompt: 'Please enter a limit classification.'
          }]
        }
      }
    });

  }

  $('#submit_limit_form').click(() => {
    let result = $('#limit_form').form('validate form')
    if(result){
      let limit_type = $('input[name="limit_type"]').val()
      let limit_amount = $('input[name="limit_amount"]').val()
      let limit_class = $('input[name="limit_class"]:checked').val()
      let limit_id = $('input[name="limit_id"]').val()
      let limit_button = `
        <span class="button">
          <a href="#!" class="mini modal-open-limit edit_limit ui primary basic button">Edit Limit</a>
          <input type="hidden" name="benefit[limits][]" value="${limit_id}&${limit_type}&${limit_amount}&${limit_class}">
        </span>
      `

      let amount_label
      switch (limit_type) {
        case "Peso":
          amount_label = "PHP"
          break
        case "Plan Limit Percentage":
          amount_label = "%"
          break
        case "Sessions":
          amount_label = "Session/s"
          break
        case "Tooth":
          amount_label = "Tooth"
          break
        case "Quadrant":
          amount_label = "Quadrant"
          break
        default:
          break
      }

      active_limit_row.find('.type').text(limit_type)
      active_limit_row.find('.amount').text(`${limit_amount} ${amount_label}`)
      active_limit_row.find('.class').text(limit_class)
      active_limit_row.find('.button').html(limit_button)
      initializeLimitModal()
      initializeEditLimit()

      $('input[name="is_valid_limit"]').val("true")

      $('.limit.modal').modal('hide')
    }
  })

const dental_params = () => {

     dental_form_validation()

     $('#dental_limit_dropdown').on('change', function() {
      let dental_limit = $('input[name="benefit[limit_type]"]').val()
      if(dental_limit == "Peso"){

        $('#dental_site_dropdown').closest('.field').removeClass('error')
        $('input[name="benefit[name]"]').closest('.field').removeClass('error')
        $('#benefit_code').closest('.field').removeClass('error')
        $('#dental_benefit_limit_type_pesos').closest('.field').removeClass('error')
        $('#loa_facilitated').closest('.field').removeClass('error')
        $('#dental_frequency').closest('.field').removeClass('error')
        $('input[name="benefit[tooth_limit_amount]"]').val('clear')
        $('#peso_value').closest('.field').removeClass('error')
        $('#session_value').closest('.field').removeClass('error')
        $('#dental_benefit_session').closest('.field').removeClass('error')
        $('#dental_benefit_peso').closest('.field').removeClass('error')
        $('#dental_site_dropdown').dropdown('clear')
        $('#area_site').prop('checked', false)
        $('#area_quadrant').prop('checked', false)
        $('input[name="benefit[limit_session]"]').val('clear')
        $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
        $('input[name="benefit[limit_amount]"]').val('clear')
        $('input[name="benefit[tooth_limit_session]"]').val("clear")
        $('input[name="benefit[limit_tooth]"]').val("clear")
        $('#dental_benefit_limit_type_pesos').show()
        $('#dental_benefit_limit_type_session').hide()
        $('#dental_benefit_limit_type_tooth').hide()
        $('#dental_benefit_limit_type_area').hide()
        $('.radio_tooth').prop('checked', false)
        $("#tooth_peso_field").addClass('hidden')
        $("#tooth_session_field").addClass('hidden')

        dental_peso()
      }

      if(dental_limit == "Session") {

        $('#dental_site_dropdown').closest('.field').removeClass('error')
        $('input[name="benefit[name]"]').closest('.field').removeClass('error')
        $('#benefit_code').closest('.field').removeClass('error')
        $('#dental_benefit_limit_type_pesos').closest('.field').removeClass('error')
        $('#loa_facilitated').closest('.field').removeClass('error')
        $('#dental_frequency').closest('.field').removeClass('error')
        $('input[name="benefit[tooth_limit_amount]"]').val('clear')
        $('#peso_value').closest('.field').removeClass('error')
        $('#session_value').closest('.field').removeClass('error')
        $('#dental_benefit_session').closest('.field').removeClass('error')
        $('#dental_site_dropdown').dropdown('clear')
        $('#area_site').prop('checked', false)
        $('#area_quadrant').prop('checked', false)
        $('input[name="benefit[limit_session]"]').val('clear')
        $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
        $('input[name="benefit[limit_amount]"]').val('clear')
        $('input[name="benefit[tooth_limit_session]"]').val("clear")
        $('input[name="benefit[limit_tooth]"]').val("clear")
        $('#dental_benefit_limit_type_pesos').hide()
        $('#dental_benefit_limit_type_session').show()
        $('#dental_benefit_limit_type_tooth').hide()
        $('#dental_benefit_limit_type_area').hide()
        $('.radio_tooth').prop('checked', false)
        $("#tooth_peso_field").addClass('hidden')
        $("#tooth_session_field").addClass('hidden')

        dental_session()

      }

      if(dental_limit == "Tooth") {

        $('#dental_site_dropdown').closest('.field').removeClass('error')
        $('input[name="benefit[name]"]').closest('.field').removeClass('error')
        $('#benefit_code').closest('.field').removeClass('error')
        $('#dental_benefit_limit_type_pesos').closest('.field').removeClass('error')
        $('#loa_facilitated').closest('.field').removeClass('error')
        $('#dental_frequency').closest('.field').removeClass('error')
        $('input[name="benefit[tooth_limit_amount]"]').val('clear')
        $('#peso_value').closest('.field').removeClass('error')
        $('#session_value').closest('.field').removeClass('error')
        $('#dental_benefit_session').closest('.field').removeClass('error')
        $('#dental_site_dropdown').dropdown('clear')
        $('#area_site').prop('checked', false)
        $('#area_quadrant').prop('checked', false)
        $('input[name="benefit[limit_session]"]').val('clear')
        $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
        $('input[name="benefit[limit_amount]"]').val('clear')
        $('input[name="benefit[tooth_limit_session]"]').val("clear")
        $('input[name="benefit[limit_tooth]"]').val("clear")
        $('#dental_benefit_limit_type_pesos').hide()
        $('#dental_benefit_limit_type_session').hide()
        $('#dental_benefit_limit_type_tooth').show()
        $('#dental_benefit_limit_type_area').hide()
        dental_tooth()
      }

      if(dental_limit == "Area") {

        $('#dental_site_dropdown').closest('.field').removeClass('error')
        $('input[name="benefit[name]"]').closest('.field').removeClass('error')
        $('#benefit_code').closest('.field').removeClass('error')
        $('#dental_benefit_limit_type_pesos').closest('.field').removeClass('error')
        $('#loa_facilitated').closest('.field').removeClass('error')
        $('#dental_frequency').closest('.field').removeClass('error')
        $('input[name="benefit[tooth_limit_amount]"]').val('clear')
        $('#peso_value').closest('.field').removeClass('error')
        $('#session_value').closest('.field').removeClass('error')
        $('#dental_benefit_session').closest('.field').removeClass('error')
        $('#dental_site_dropdown').dropdown('clear')
        $('#area_site').prop('checked', false)
        $('#area_quadrant').prop('checked', false)
        $('input[name="benefit[limit_session]"]').val('clear')
        $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
        $('input[name="benefit[limit_amount]"]').val('clear')
        $('input[name="benefit[tooth_limit_session]"]').val("clear")
        $('input[name="benefit[limit_tooth]"]').val("clear")
        $('#dental_benefit_limit_type_pesos').hide()
        $('#dental_benefit_limit_type_session').hide()
        $('#dental_benefit_limit_type_tooth').hide()
        $('#dental_benefit_limit_type_area').show()
        $('.radio_tooth').prop('checked', false)
        $("#tooth_peso_field").addClass('hidden')
        $("#tooth_session_field").addClass('hidden')

        dental_area()
      }
    })
  }

  const dental_peso = () => {
    let im = new Inputmask("numeric", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false
    })
    im.mask($('#dental_benefit_peso'));

    $('#dental_benefit_peso').keydown(function(evt) {
      var value = $('#dental_benefit_peso').val()
      var selection = window.getSelection();
        if(evt.key == '.' || value.includes('.')) {
          if (value.length == 13 || evt.key == "-") {
            if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
            }
          }
      } else {
        if(value.length > 6 || evt.key == "-") {
          if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
          }
        }
      }
    })

    dental_peso_validation()
  }

  const dental_peso_validation = () => {

    $.fn.form.settings.rules.checkAvailmentType = param => {
     let loa = $('#loa_facilitated').is(':checked') == true
     let reimbursement = $('#reimbursement').is(':checked') == true

        if ((loa || reimbursement) == true) {
          return true
        } else {
          return false
        }
      }

     $.fn.form.settings.rules.checkZeroVal = param => {
     let value = $('#dental_benefit_peso').val();
        if (value == 0) {
           return false
        } else {
         return true
        }
      }

    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Enter code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Code is already taken.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Enter name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Select coverage.'
          }]
        },
        'benefit[limit_type]': {
          identifier: 'benefit[limit_type]',
          rules: [{
            type: 'empty',
            prompt: 'Select limit type.'
          }]
        },
        'benefit[limit_amount]': {
          identifier: 'benefit[limit_amount]',
          rules: [{
            type: 'empty',
            prompt: 'Enter limit amount.'
          },
          {
            type: 'checkZeroVal[param]',
            prompt: 'Cant accept "0" amount.'
          }]
        },
        'benefit[frequency]': {
          identifier: 'benefit[frequency]',
          rules: [{
            type: 'empty',
            prompt: 'Select Frequency'
          }]
        },
        'benefit[loa_facilitated': {
          identifier: 'benefit[loa_facilitated]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'benefit[reimbursement]': {
          identifier: 'benefit[reimbursement]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'is_valid_diagnosis': {
          identifier: 'is_valid_diagnosis',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one diagnosis.'
          }]
        }
      }
    })
  }

  const dental_session = () => {
    let im = new Inputmask("numeric", {
    radixPoint: ".",
    groupSeparator: ",",
    autoGroup: true,
    rightAlign: false
    })
    im.mask($('#dental_benefit_session'));
    dental_session_validation()
  }

  const dental_session_validation = () => {

    $.fn.form.settings.rules.checkAvailmentType = param => {
     let loa = $('#loa_facilitated').is(':checked') == true
     let reimbursement = $('#reimbursement').is(':checked') == true

        if ((loa || reimbursement) == true) {
          return true
        } else {
          return false
        }
      }

     $.fn.form.settings.rules.checkZeroVal = param => {
     let value = $('#dental_benefit_session').val();
        if (value == 0) {
           return false
        } else {
         return true
        }
      }

    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Enter code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Code is already taken.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Enter name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Select Coverage.'
          }]
        },
        'benefit[limit_type]': {
          identifier: 'benefit[limit_type]',
          rules: [{
            type: 'empty',
            prompt: 'Select limit type.'
          }]
        },
        'benefit[limit_session]': {
          identifier: 'benefit[limit_session]',
          rules: [{
            type: 'empty',
            prompt: 'Enter limit session.'
          },
          {
            type: 'checkZeroVal[param]',
            prompt: 'Cant accept "0" amount.'
          }]
        },
        'benefit[frequency]': {
          identifier: 'benefit[frequency]',
          rules: [{
            type: 'empty',
            prompt: 'Select Frequency'
          }]
        },
        'benefit[loa_facilitated]': {
          identifier: 'benefit[loa_facilitated]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'benefit[reimbursement]': {
          identifier: 'benefit[reimbursement]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'is_valid_diagnosis': {
          identifier: 'is_valid_diagnosis',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one diagnosis.'
          }]
        }
      }
    })
  }

  const dental_tooth = () => {

  var state = false;
  var prevVal;
  var val;
  var isChecked;
  var isChecked2;

   $('.dental_tooth_class').on('mousedown', function() {

    prevVal = $('.radio_tooth:checked').val();
    val = $(this).find('input').val();
    isChecked = $('#dental_tooth_session').find('input').is(':checked')
    isChecked2 = $('#dental_tooth_peso').find('input').is(':checked')

   })

  $('.dental_tooth_class').on('click', function() {

    if (state == false && val == "Session") {
      $('#session_id').prop('checked', true)
      $('#main_field').removeClass('error')
      state = true;
      $('#peso_id').prop('checked', false)
      $('#peso_value').closest('.field').removeClass('error')
      $('.radio_tooth').removeClass('error')
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('input[name="benefit[limit_tooth]"]').val("clear")
      $('input[name="benefit[limit_tooth]"]').val("Session")
      $("#tooth_session_field").removeClass('hidden')
      $("#tooth_peso_field").addClass('hidden')
      $('#peso_value').val('clear')
       let session_tooth = new Inputmask("numeric", {
        radixPoint: ".",
        groupSeparator: ",",
        autoGroup: true,
        rightAlign: false
        })
       session_tooth.mask($('#session_value'));
       session_field_validation()
    }
    else if (state == true && val == "Session") {
      $('#session_id').prop('checked', false)
      $('#session_value').closest('.field').removeClass('error')
      $("#tooth_session_field").addClass('hidden')
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('input[name="benefit[tooth_limit_session]"]').val("clear")
      $('input[name="benefit[limit_tooth]"]').val("clear")
       dental_tooth_validation()

      state = false;
    }
    else if (state == false && val == "Peso") {
      $('#peso_id').prop('checked', true)
      state = true;
      $('#session_id').prop('checked', false)
      $('#main_field').removeClass('error')
      $('#session_value').closest('.field').removeClass('error')
      $('.radio_tooth').removeClass('error')
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('input[name="benefit[tooth_limit_session]"]').val("clear")
      $('input[name="benefit[limit_tooth]"]').val("Peso")
      $("#tooth_session_field").addClass('hidden')
      $("#tooth_peso_field").removeClass('hidden')
       let peso_tooth = new Inputmask("numeric", {
        radixPoint: ".",
        groupSeparator: ",",
        digits: 2,
        autoGroup: true,
        rightAlign: false
       })
       peso_tooth.mask($('#peso_value'));


    $('#peso_value').keydown(function(evt) {
    var value = $('#peso_value').val()

    var selection = window.getSelection();
    if(evt.key == '.' || value.includes('.')) {
      if (value.length == 13 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    } else {
      if(value.length > 6 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    }
  })
    peso_field_validation()

    }
    else if (state == true && val == "Peso") {
      $('#peso_id').prop('checked', false)
      $("#tooth_peso_field").addClass('hidden')
      // $('#main_field').removeClass('error')
      $('#peso_value').closest('.field').removeClass('error')
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('input[name="benefit[tooth_limit_peso]"]').val("clear")
      $('input[name="benefit[limit_tooth]"]').val("clear")
       dental_tooth_validation()

      state = false;
    }

    if (prevVal == "Peso" && val == "Session" && state == false && isChecked == false) {
      $('#session_id').prop('checked', true)
      state = true;
      $('#peso_id').prop('checked', false)
      $('#main_field').removeClass('error')
      $('#peso_value').closest('.field').removeClass('error')
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('input[name="benefit[limit_tooth]"]').val("clear")
      $('input[name="benefit[limit_tooth]"]').val("Session")
      $("#tooth_session_field").removeClass('hidden')
      $("#tooth_peso_field").addClass('hidden')
      $('#peso_value').val('clear')
       let session_tooth = new Inputmask("numeric", {
        radixPoint: ".",
        groupSeparator: ",",
        autoGroup: true,
        rightAlign: false
        })
       session_tooth.mask($('#session_value'));
       session_field_validation()
    }

    if (prevVal == "Session" && val == "Peso" && state == false && isChecked2 == false) {
      $('#peso_id').prop('checked', true)
      $('#main_field').removeClass('error')
      state = true;
      $('#session_id').prop('checked', false)
       $('#session_value').closest('.field').removeClass('error')
       $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
       $('input[name="benefit[tooth_limit_session]"]').val("clear")
       $('input[name="benefit[limit_tooth]"]').val("Peso")
       $("#tooth_session_field").addClass('hidden')
       $("#tooth_peso_field").removeClass('hidden')
       let peso_tooth = new Inputmask("numeric", {
        radixPoint: ".",
        groupSeparator: ",",
        digits: 2,
        autoGroup: true,
        rightAlign: false
       })
       peso_tooth.mask($('#peso_value'));


    $('#peso_value').keydown(function(evt) {
    var value = $('#peso_value').val()

    var selection = window.getSelection();
    if(evt.key == '.' || value.includes('.')) {
      if (value.length == 13 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    } else {
      if(value.length > 6 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    }
  })
    peso_field_validation()
    }
    $('#error_div').remove()
  })

    dental_tooth_validation()
  }

  const dental_tooth_validation = () => {
    $.fn.form.settings.rules.checkAvailmentType = param => {
     let loa = $('#loa_facilitated').is(':checked') == true
     let reimbursement = $('#reimbursement').is(':checked') == true

        if ((loa || reimbursement) == true) {
          return true
        } else {
          return false
        }
      }

    $.fn.form.settings.rules.checkLimitToothType = param => {
     let session = $('.radio-session').is(':checked') == true
     let peso = $('.radio-peso').is(':checked') == true

        if ((session || peso) == true) {
          return true
        } else {
          return false
        }
      }

    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Enter code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Code is already taken.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Enter name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Select coverage.'
          }]
        },
        'benefit[limit_type]': {
          identifier: 'benefit[limit_type]',
          rules: [{
            type: 'empty',
            prompt: 'Select limit type.'
          }]
        },
        // 'benefit[tooth_session]': {
        //   identifier: 'benefit[tooth_session]',
        //   rules: [{
        //     type: 'checkLimitToothType[param]',
        //     prompt: 'Please select one.'
        //   }]
        // },

         'benefit[limit_tooth]': {
          identifier: 'benefit[limit_tooth]',
          rules: [{
            prompt: 'Please select one.'
          }]
        },
        'benefit[frequency]': {
          identifier: 'benefit[frequency]',
          rules: [{
            type: 'empty',
            prompt: 'Select Frequency.'
          }]
        },
        'benefit[loa_facilitated]': {
          identifier: 'benefit[loa_facilitated]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'benefit[reimbursement]': {
          identifier: 'benefit[reimbursement]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'is_valid_diagnosis': {
          identifier: 'is_valid_diagnosis',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one diagnosis.'
          }]
        }
      }
    })
    $('div[id="tooth_radio_fields"]').find('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
  }

  const session_field_validation = () => {
    $.fn.form.settings.rules.checkAvailmentType = param => {
     let loa = $('#loa_facilitated').is(':checked') == true
     let reimbursement = $('#reimbursement').is(':checked') == true

        if ((loa || reimbursement) == true) {
          return true
        } else {
          return false
        }
      }

     $.fn.form.settings.rules.checkZeroVal = param => {
     let value = $('#session_value').val();
        if (value == 0) {
           return false
        } else {
         return true
        }
      }

    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Enter code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Code is already taken.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Enter name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Select coverage.'
          }]
        },
        'benefit[limit_type]': {
          identifier: 'benefit[limit_type]',
          rules: [{
            type: 'empty',
            prompt: 'Select limit type.'
          }]
        },
        'benefit[limit_tooth]': {
          identifier: 'benefit[limit_tooth]',
          rules: [{
            type: 'empty',
            prompt: 'Please select one.'
          }]
        },
        'benefit[tooth_limit_session]': {
          identifier: 'benefit[tooth_limit_session]',
          rules: [{
            type: 'empty',
            prompt: 'Enter limit session.'
          },
          {
            type: 'checkZeroVal[param]',
            prompt: 'Cant accept "0" amount.'
          }]
        },
        'benefit[frequency]': {
          identifier: 'benefit[frequency]',
          rules: [{
            type: 'empty',
            prompt: 'Select Frequency'
          }]
        },
        'benefit[loa_facilitated]': {
          identifier: 'benefit[loa_facilitated]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'benefit[reimbursement]': {
          identifier: 'benefit[reimbursement]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'is_valid_diagnosis': {
          identifier: 'is_valid_diagnosis',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one diagnosis.'
          }]
        }
      }
    })
    $('div[id="tooth_radio_fields"]').find('.ui.basic.red.pointing.prompt.label.transition.visible').remove()

  }

  const peso_field_validation = () => {

    $.fn.form.settings.rules.checkAvailmentType = param => {
     let loa = $('#loa_facilitated').is(':checked') == true
     let reimbursement = $('#reimbursement').is(':checked') == true

        if ((loa || reimbursement) == true) {
          return true
        } else {
          return false
        }
      }

     $.fn.form.settings.rules.checkZeroVal = param => {
     let value = $('#peso_value').val();
        if (value == 0) {
           return false
        } else {
         return true
        }
      }

    $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Enter code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Code is already taken.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Enter name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Select coverage.'
          }]
        },
        'benefit[limit_type]': {
          identifier: 'benefit[limit_type]',
          rules: [{
            type: 'empty',
            prompt: 'Select limit type.'
          }]
        },
        'benefit[limit_tooth]': {
          identifier: 'benefit[limit_tooth]',
          rules: [{
            type: 'empty',
            prompt: 'Please select one.'
          }]
        },
        'benefit[tooth_limit_amount]': {
          identifier: 'benefit[tooth_limit_amount]',
          rules: [{
            type: 'empty',
            prompt: 'Enter limit amount.'
          },
          {
            type: 'checkZeroVal[param]',
            prompt: 'Cant accept "0" amount.'
          }]
        },
        'benefit[frequency]': {
          identifier: 'benefit[frequency]',
          rules: [{
            type: 'empty',
            prompt: 'Select Frequency'
          }]
        },
        'benefit[loa_facilitated]': {
          identifier: 'benefit[loa_facilitated]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'benefit[reimbursement]': {
          identifier: 'benefit[reimbursement]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'is_valid_diagnosis': {
          identifier: 'is_valid_diagnosis',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one diagnosis.'
          }]
        }
      }
    })
    $('div[id="tooth_radio_fields"]').find('.ui.basic.red.pointing.prompt.label.transition.visible').remove()

  }

  const dental_area = () => {
    let dental_array_return = []

    $('input.dental_area').change(function() {
      let checked = $(this).val();
        if ($(this).is(':checked')) {

        $('#dental_benefit_limit_type_area').closest('.field').removeClass('error')
        $('#dental_site_dropdown').closest('.field').removeClass('error')
        $('#dental_site').closest('.field').removeClass('error')
        $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
        dental_array_return.push(checked);
        dental_area_validation()

          if ($('#area_site').is(':checked') == true) {
                $('#dental_site_id').removeClass('hidden')
                dental_area_site_validation()
          }
      } else {
        dental_array_return.splice($.inArray(checked, dental_array_return),1);

          if($('#area_site').is(':checked') == false){
                $('#dental_site_dropdown').dropdown('clear')
                $('#dental_site_id').addClass('hidden')
          }

      }
    });
    dental_area_validation()
  }

  const dental_area_validation = () => {

    $.fn.form.settings.rules.checkAvailmentType = param => {
     let loa = $('#loa_facilitated').is(':checked') == true
     let reimbursement = $('#reimbursement').is(':checked') == true

        if ((loa || reimbursement) == true) {
          return true
        } else {
          return false
        }
      }

    $.fn.form.settings.rules.validLimitType = param => {
     let quadrant = $('#area_quadrant').is(':checked') == true
     let site = $('#area_site').is(':checked') == true

        if ((quadrant || site) == true) {
          return true
        } else {
          return false
        }
      }

      $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Enter code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Code is already taken.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Enter name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Select coverage.'
          }]
        },
        'benefit[limit_type]': {
          identifier: 'benefit[limit_type]',
          rules: [{
            type: 'empty',
            prompt: 'Select limit type.'
          }]
        },
        // 'benefit[limit_area_type][]': {
        //   identifier: 'benefit[limit_area_type][]',
        //   rules: [{
        //     type: 'checked',
        //     prompt: 'Please select one.'
        //   }]
        // },
        'benefit[frequency]': {
          identifier: 'benefit[frequency]',
          rules: [{
            type: 'empty',
            prompt: 'Select Frequency.'
          }]
        },
        'benefit[loa_facilitated]': {
          identifier: 'benefit[loa_facilitated]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'benefit[reimbursement]': {
          identifier: 'benefit[reimbursement]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'is_valid_diagnosis': {
          identifier: 'is_valid_diagnosis',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one diagnosis.'
          }]
        },
        'is_valid_limit_area_type': {
          identifier: 'is_valid_limit_area_type',
          rules: [{
            type: 'validLimitType[param]',
            prompt: 'Please select one.'
          }]
        }
      }
    })
  }

  const dental_area_site_validation = () => {
    $.fn.form.settings.rules.checkAvailmentType = param => {
     let loa = $('#loa_facilitated').is(':checked') == true
     let reimbursement = $('#reimbursement').is(':checked') == true

        if ((loa || reimbursement) == true) {
          return true
        } else {
          return false
        }
      }

    $.fn.form.settings.rules.validLimitType = param => {
     let quadrant = $('#area_quadrant').is(':checked') == true
     let site = $('#area_site').is(':checked') == true

        if ((quadrant || site) == true) {
          return true
        } else {
          return false
        }
      }

      $('#riders_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'benefit[code]': {
          identifier: 'benefit[code]',
          rules: [{
            type: 'empty',
            prompt: 'Enter code.'
          },
          {
            type: 'checkBenefitCode[param]',
            prompt: 'Code is already taken.'
          }]
        },
        'benefit[name]': {
          identifier: 'benefit[name]',
          rules: [{
            type: 'empty',
            prompt: 'Enter name.'
          }]
        },
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Select coverage.'
          }]
        },
        'benefit[limit_type]': {
          identifier: 'benefit[limit_type]',
          rules: [{
            type: 'empty',
            prompt: 'Select limit type.'
          }]
        },
        // 'benefit[limit_area_type][]': {
        //   identifier: 'benefit[limit_area_type][]',
        //   rules: [{
        //     type: 'empty',
        //     prompt: 'Please select one.'
        //   }]
        // },
        'benefit[limit_area][]': {
          identifier: 'benefit[limit_area][]',
          rules: [{
            type: 'empty',
            prompt: 'Select Site.'
          }]
        },
        'benefit[frequency]': {
          identifier: 'benefit[frequency]',
          rules: [{
            type: 'empty',
            prompt: 'Select Frequency.'
          }]
        },
        'benefit[loa_facilitated]': {
          identifier: 'benefit[loa_facilitated]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'benefit[reimbursement]': {
          identifier: 'benefit[reimbursement]',
          rules: [{
            type: 'checkAvailmentType[param]',
            prompt: 'Select availment type.'
          }]
        },
        'is_valid_diagnosis': {
          identifier: 'is_valid_diagnosis',
          rules: [{
            type: 'empty',
            prompt: 'Please select atleast one diagnosis.'
          }]
        },
        'is_valid_limit_area_type': {
          identifier: 'is_valid_limit_area_type',
          rules: [{
            type: 'validLimitType[param]',
            prompt: 'Please select one.'
          }]
        }
      }
    })
  }

  const initializeEditLimit = _ => {
    $('.edit_limit').click(function() {
      let row = $(this).closest('tr')
      let name = row.find('.name').text()
      let type = row.find('.type').text()
      let amount = row.find('.amount').text()
      let limit_class = row.find('.class').text()
      let record = $(this).closest('td').find('input')
      let value = record.val()
      let array_val = value.split("&")
      active_limit_row = row
      // $('div[role="general"]').show()
      // $('div[role="dental"]').show()

      $('#limit_form').form('clear')
      if ( name == "Dental") {
        $('div[role="general"]').hide()
      } else {
        $('div[role="dental"]').hide()
      }
      $('input[name="limit_coverage"]').val(name)
      $('#limit_type_dropdown').dropdown('set selected', type)

      if (name == "Dental") {
        $('#limit_type_dropdown').dropdown('set selected', type)
      } else {
        $('#limit_type_dropdown_general').dropdown('set selected', type)
      }

      $('input[name="limit_amount"]').val(amount)
      $(`input[name="limit_class"][value="${limit_class}"]`).prop('checked', true)
      $('input[name="limit_id"]').val(array_val[0])
      $('#add_limit_header').text("Update Limit")
      $('#submit_limit_form').text("Update")
    })
  }

  $('#acu_submit_limit_form').click(() => {
    let result = $('#acu_limit_form').form('validate form')
    if (result) {
      let limit_type = $('input[name="limit_type"]').val()
      let limit_session = $('input[name="limit_session"]').val()
      let limit_peso = $('input[name="acu_limit_amount"]').val()
      let acu_limit_class = $('input[name="acu_limit_class"]:checked').val()
      let limit_id = $('input[name="limit_id"]').val()
      $(`input[id="hidden_values_${limit_id}"]`).val("")
      let limit_button = `
        <span class="button">
          <a href="#!" class="mini modal-open-acu-limit edit_acu_limit ui primary basic button">Edit Limit</a>
          <input type="hidden" name="benefit[limits][]" id="hidden_values_${limit_id}" value="${limit_id}&${limit_type}&${limit_session}&&${acu_limit_class}">
        </span>
        `

      active_limit_row.find('.type').text(limit_type)
      active_limit_row.find('.limit_session').text(`${limit_session} Session`)
      // active_limit_row.find('.amount').text(`${limit_peso} PHP`)
      active_limit_row.find('.class').text(acu_limit_class)
      active_limit_row.find('.button').html(limit_button)

      if (limit_peso) {
        if ($('.name2')[0]) {
        } else {
          acu_tbl_limit.row.add([
            `<span class="name2 green" id="limit_ACU">ACU</span>`,
            `<span class="type2">-</span>`,
            `<span class="limit_session2">-</span>`,
            `<span class="amount2">-</span>`,
            `<span class="class2">-</span>`,
            `<span class="button2"></span>`
          ]).draw()
        }

        let limit_button2 = `
          <span class="button">
            <input type="hidden" name="benefit[limits][]" id="hidden_values_${limit_id}" value="${limit_id}&Peso&&${limit_peso}&${acu_limit_class}">
          </span>
          `

        $('.type2').text('Peso')
        $('.amount2').text(`${limit_peso} PHP`)
        $('.button2').html(limit_button2)
        $('.class2').text(acu_limit_class)
      } else {
        if ($('.name2')[0]) {
          let row = $('.name2').closest('tr')
          acu_tbl_limit.row(row).remove().draw()
        }
      }

      initializeAcuLimitModal()
      initializeACUEditLimit()
      $('input[name="is_valid_acu_limit"]').val("true")
      $('.acu_limit.modal').modal('hide')
    }
  })

  const initializeACUEditLimit = _ => {

    $('.edit_acu_limit').click(function() {
      let row = $(this).closest('tr')
      let name = row.find('.name').text()
      let type = row.find('.type').text()
      // let amount = row.find('.amount2).text()
      let amount
      if ($('.name2')[0]) {
        amount = $('.amount2').text()
      }
      let acu_limit_class = row.find('.class').text()
      let record = $(this).closest('td').find('input')
      let value = record.val()
      let array_val = value.split("&")
      active_limit_row = row

      $('#acu_limit_form').form('clear')
      $('input[name="limit_coverage"]').val(name)
      $('input[name="limit_type"]').val(type)
      $('input[name="limit_type"]').val("Sessions")
      $('input[name="limit_type_peso"]').val("Peso")
      $('input[name="limit_session"]').val(`1`)
      $('input[name="acu_limit_amount"]').val(amount)
      $('input[name="limit_id"]').val(array_val[0])
      $('#add_acu_limit_header').text("Update ACU Limit")
      $(`input[name="acu_limit_class"][value="${acu_limit_class}"]`).prop('checked', true)
      $('#acu_submit_limit_form').text("Update")
    })
    $('input[name="is_valid_acu_limit"]').val("true")

    $('.acu_limit.modal').modal('hide')
  }

  const initializeDiagnosisTbl = _ => {
    let selected_diagnosis_ids = []

    $('.selected_diagnosis_id').each(function() {
      selected_diagnosis_ids.push($(this).text())
    })

    let diagnosis_ids = selected_diagnosis_ids.join(",")

    $('.modal.diagnosis')
      .modal({
        autofocus: false,
        centered: false,
        observeChanges: true
      })
      .modal('show');

    modal_diagnosis_benefit(diagnosis_ids, csrf)
  }

  const initializeCdtTbl = _ => {
    let selected_diagnosis_ids = []

    $('.selected_diagnosis_id').each(function() {
      selected_diagnosis_ids.push($(this).text())
    })

    let diagnosis_ids = selected_diagnosis_ids.join(",")

    $('.modal.cdt')
      .modal({
        autofocus: false,
        centered: false,
        observeChanges: true
      })
      .modal('show');

    modal_cdt_benefit(diagnosis_ids, csrf)
  }

  $('#btn_add_diagnosis').click(function () {
    initializeDiagnosisTbl()
  })

  $('#btn_add_cdt').click(function () {
    initializeCdtTbl()
  })

function submit_diagnosis() {
   $('#btn_submit_diagnosis').click(function() {
      let is_all_selected = $('#diagnosis_select_all').is(":checked")

      let checked_diagnosis = $('input[class="diagnosis_chkbx"]:checked')
      if(checked_diagnosis.length > 0){
        let submit_btn = $(this)
        submit_btn.html('<span class="ui active tiny centered inline loader"></span>')
        if (is_all_selected) {
          let selected_diagnosis_ids = []

          $('.selected_diagnosis_id').each(function() {
            selected_diagnosis_ids.push($(this).text())
          })

          let diagnosis_ids = selected_diagnosis_ids.join(",")
          let type = $('#diagnosis_type_dropdown').dropdown('get value')
          $('#tbl_cdt').DataTable({
            "destroy": true,
            "ajax": $.fn.dataTable.dt_timeout(
              `/web/benefits/load_all_diagnosis?diagnosis_ids=${diagnosis_ids}&type=${type}`,
              csrf
            ),
            "deferRender": true,
            "drawCallback": function (settings) {
              submit_btn.html('Add')
              $('.modal.diagnosis').modal('hide');
            },
            "deferRender": true
          })
          } else {
          let dt = $('#tbl_cdt').DataTable();
          //dt.clear().draw()
          $('input[class="diagnosis_chkbx"]:checked').each(function() {
            dt.row.add([
              `<span class="green selected_diagnosis_id">${$(this).attr('code')}</span>`,
              `<strong>${$(this).attr('diagnosis_name')}</strong><br><small class="thin dim">${$(this).attr('description')}</small>`,
              // `${$(this).attr('diagnosis_type')}`,
  `<a href="#!" id="${$(this).attr('diagnosis_id')}" class="remove_diagnosis"><u style="color: gray">Remove</u></a><input type="hidden" name="benefit[diagnosis_ids][]" value="${$(this).attr('diagnosis_id')}">`
            ]).draw(false)
          })
          $('.modal.diagnosis').modal('hide');
          }

          $('input[name="is_valid_diagnosis"]').val("true")

        initializeDeleteDiagnosis()
      } else {
        alertify.error('<i class="close icon"></i>Please select at least one diagnosis')
      }
    })
  }


  // // Handle click on table cells with checkboxes
	 // $('#dt-dental-benefit').on('click', 'tbody td, thead th:first-child', function(e){
			// $(this).parent().find('label[type="text"]').trigger('click');
	// });

	// // Handle click on "Select all" control
	// $('thead input[name="select_all"]', table.table().container()).on('click', function(e){
  //   let id = "dt-dental-benefit"
  //   let results = $(`#${id} >tbody >tr`).length
  //   let selected_benefit_count_start = datatable.DataTable().page.info().start;
  //   let disabled_benefit_count_start = $('#dt-dental-benefit_wrapper').find('input[role="disabled_checkbox"]').length
  //   let selected_benefit_count_end = datatable.DataTable().page.info().end;
  //   let selected_benefit_count =  results - disabled_benefit_count_start
  //   let total_count = datatable.DataTable().page.info().recordsTotal;

  //   if(this.checked){
  //     $('#clear-select-message').remove()
  //     $('.dt-append').append(`<div class="ui attached message" id="clear-select-message" style="background-color: #fff8ea;"> \
  //     <p>All ${selected_benefit_count} benefits on this \
  //     page are selected <a id="select-all-benefits"> <span class="green"> <u> Select \
  //     all ${total_count} benefits </u> </span> </a> \
  //     </p></div>`)

  //     $('#dt-dental-benefit tbody input[type="checkbox"]:not(:checked)').trigger('click');
  //   } else {
  //     $('#clear-select-message').remove()
  //     $('#dt-dental-benefit tbody input[type="checkbox"]:checked').trigger('click');

  //   }

  // e.stopPropagation();
	// });

	// // Handle table draw event
	// table.on('draw', function(){
		// updateDataTableSelectAllCtrl(table); // Update state of "Select all" control
	// });

  // $(document).on('change', '.ui.fluid.search.dropdown.cdt', function(){
  //   let page = $(this).find($('.text')).html()
  //   var table = $('#tbl_add_diagnosis').DataTable();
  //   let no = parseInt(page) -1
  //   table.page( no ).draw( 'page' );
  // })

  // let cdt_search_id = $('#tbl_add_diagnosis_wrapper')

  // cdt_search_id.find('.dataTables_info').attr("style", "margin-left: 1rem;")

  // function append_jump_modal_cdt(page, pages){
  //   // let results = $('select[name="tbl_add_diagnosis_length"]').val()
  //   // $('.table > tbody  > tr').each(function(){
  //   //   $(this).attr('style', 'height:50px')
  //   // })

  //   let cdt_search_id = $('#tbl_add_diagnosis_wrapper')
  //   let results;

  //   if (results = cdt_search_id.find('.table > tbody  > tr').html().includes("matched your search")) {
  //     results = 0
  //   }
  //   else {
  //     results = cdt_search_id.find('.table > tbody  > tr').length
  //   }
  //   cdt_search_id.find('.table > tbody  > tr').each(function(){
  //     $(this).attr('style', 'height:50px')
  //   })


  //   cdt_search_id.find('div[role="jump"]').remove()
  //   cdt_search_id.find('div > div:nth-child(4) > div.left.aligned.two.wide.column.test').html('<button class=" send-rtp ui left floated primary button close" type="submit" id="btn_submit_diagnosis">Add</button>')
  //   cdt_search_id.find(".first.paginate_button, .last.paginate_button").hide()
  //   cdt_search_id.find('.one.wide').remove()
  //   cdt_search_id.find('.show').remove()
  //   cdt_search_id.find('#tbl_add_diagnosis_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
  //   cdt_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent()
  //   cdt_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
  //   `<div class="right aligned one wide column inline field"></div>\
  //   <div class="right aligned two wide column inline field" role="jump"> Jump to page: </div>\
  //   <div class="right aligned one wide column inline field" role="jump" id="jump_search_modal_cdt">\
  //     <select class="ui fluid search dropdown cdt" id="jump_modal_cdt">\
  //     </select>\
  //   </div>`
  //   )
  //   var select = $('#jump_modal_cdt')
  //   var options = []
  //   for(var x = 1; x < parseInt(pages) + 1; x++){
  //      options.push(`<option value='${x}'>${x}</option>`)
  //   }
  //   select.append(String(options.join('')))
  //   cdt_search_id.find('.ui.fluid.search.dropdown').dropdown()
  //   cdt_search_id
  //     .find(`#jump_search_modal_cdt > div > div.text`)
  //     .text(page + 1)

  //   cdt_search_id
  //     .find(`#jump_search_modal_cdt`)
  //     .closest('div')
  //     .closest('div')
  //     .closest('div')
  //     .closest('div')
  //     .find(`div[data-value="1"]`)
  //     .removeClass("active selected")

  //   cdt_search_id
  //     .find(`#jump_search_modal_cdt`)
  //     .closest('div')
  //     .closest('div')
  //     .closest('div')
  //     .closest('div')
  //     .find(`div[data-value="${page + 1}"]`)
  //     .addClass("active selected")

  //   $(document).find('input[class="search"]').keypress(function(evt) {
  //       evt = (evt) ? evt : window.event
  //       var charCode = (evt.which) ? evt.which : evt.keyCode
  //       if (charCode == 8) {
  //           return true
  //       } else if (charCode == 46) {
  //           return false
  //       } else if (charCode == 37) {
  //           return false
  //       }  else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
  //           return false
  //       } else if (this.value.length == 0 && evt.which == 48) {
  //           return false
  //       } else if (parseInt(this.value + String.fromCharCode(charCode)) > pages){
  //           return false
  //       }
  //       return true
  //   })
  // }

function add_search(table){
  let id = table[0].getAttribute("id")
  let value = $(`#${id}_filter`).val()

  if(value != 1){
    $(`#${id}_filter`).addClass('ui left icon input')
    $(`#${id}_filter`).find('label').after('<i class="search icon"></i>')
    $(`#${id}_filter`).find('input[type="search"]').unwrap()
    $(`#${id}_filter`).find('input[type="search"]').attr("placeholder", `Search`)
    $(`#${id}_filter`).find('input[type="search"]').append(`</div>`)
    $(`#${id}_filter`).val(1)
  }
}

  // $('#option').on('change', function () {
  //   var pages = $('#option').val()
  //   var page = $('#page').val()
  //   var select = $('#jump_modal_cdt')
  //   var options = []
  //   for(var x = 1; x < parseInt(pages) + 1; x++){
  //     if(parseInt(x) == parseInt(page) + 1){
  //       options.push(`<option value='${x}' selected>${x}</option>`)
  //     }
  //     else{
  //       options.push(`<option value='${x}'>${x}</option>`)
  //     }
  //   }
  //   select.append(String(options.join('')))

  //   if (page == 1) {
  //     select.dropdown('set selected', 2)
  //   } else {
  //     select.dropdown('set selected', page + 1)
  //   }
  // })

  $('#btn_cancel_diagnosis').click(function() {
    $('.modal.diagnosis').modal('hide');
  })

  $('#diagnosis_select_all').on('change', function () {
    let status = $(this).is(":checked")
    let dt = $("#tbl_add_diagnosis").DataTable()
    let rows = dt.rows({ 'search': 'applied' }).nodes()

    $('.diagnosis_chkbx', rows).each(function() {
      $(this).prop("checked", status)
    })

    initializeDiagnosisTbl()
  })

  const initializeDeleteDiagnosis = _ => {
    $(document).on('click', '.remove_diagnosis', function(e) {
      let id = $(this).attr('id')
      let row = $(`a[id="${id}"]`).closest('tr')
      let dt = $('#tbl_cdt').DataTable()
      dt.row(row)
        .remove()
        .draw()
    })
  }
//===================================================== normal tbl package ======================================================================//

  const tbl_package = $('#tbl_package').DataTable()
  $('#select-packages').dropdown({
    apiSettings: {
      url: `/web/benefits/load_packages`,
      cache: false
    },
    filterRemoteData: true,
    onShow: () => {
      let current_package_div = $('#loaded_package_id')
      if(current_package_div.length > 0) {
        $('.current_package_id').each(function() {
          $('#select-packages').dropdown(
            'set selected',
            $(this).val()
          )
        })
        current_package_div.remove()
        return false
      }
    },
    onAdd: (addedValue, addedText, $addedChoice) => {
      $('.div-dim').dimmer('show')
      $.ajax({
        url: `/web/benefits/get_package?id=${addedValue}`,
        headers: {
          "X-CSRF-TOKEN": csrf
        },
        type: 'get',
        success: function (response) {
          let selected_procedure_ids = []
          $('.selected_procedure_id').each(function () {
            selected_procedure_ids.push($(this).text())
          })
          $.each(response, function(key, value){

            if($.inArray( value.pp_id, selected_procedure_ids ) <= -1){
              let gender
              if(value.male && value.female){
                gender = 'M/F'
              } else if(value.male) {
                gender = 'M'
              } else if(value.female) {
                gender = 'F'
              }
              tbl_package.row.add([
                `<p class="package_indicator"><span class="green">${value.package_code} </span><br><span class="dim">${value.package_name}</span></p>`,
                `${value.sp_code}`,
                `${value.sp_description}`,
                `${value.pp_code}`,
                `${value.pp_description}`,
                `${value.age_from} - ${value.age_to} years`,
                `${gender}`,
                `
                <span class="selected_procedure_id hidden">${value.pp_id}</span>`
              ]).draw(false)
            }
          })

          $('.div-dim').dimmer('hide')
          // $('input[name="is_valid_procedure"]').val("true")
          $('.remove_package').click(function() {
            let row = $(this).closest('tr')
            tbl_package
              .row(row)
              .remove()
              .draw()
          })
        },
        error: (xhr, ajaxOptions, thrownError) => {
          window.location.replace('/sign_out_error_dt')
        }
      })
    },
    onRemove: (removedValue, removedText, $removedChoice) => {
      $('.package_indicator').each(function () {
        if ($(this).text() == removedText) {
          let row = $(this).closest('tr')
          tbl_package
            .row(row)
            .remove()
            .draw()
        }
      })
    }
  })
  //===================================================== normal tbl package ======================================================================//

  // ================================================ acu tbl package ==========================================================//

  const acu_tbl_package = $('#acu_tbl_package_acu').DataTable()
  $('#acu-select-packages').dropdown({
    apiSettings: {
      url: `/web/benefits/load_packages`,
      cache: false
    },
    filterRemoteData: true,
    onShow: () => {
      let current_package_div = $('#loaded_package_id')
      if(current_package_div.length > 0) {
        $('.current_package_id').each(function() {
          $('#acu-select-packages').dropdown(
            'set selected',
            $(this).val()
          )
        })
        current_package_div.remove()
        return false
      }
    },
    onAdd: (addedValue, addedText, $addedChoice) => {
      //current_package.push(addedValue)
      let current_package = $('#acu-select-packages').dropdown('get value')
      $('.div-dim').dimmer('show')
      $.ajax({
        url: `/web/benefits/set_benefit_package?current_package=${current_package}&newly_added_package=${addedValue}`,
        headers: {
          "X-CSRF-TOKEN": csrf
        },
        type: 'get',
        success: function (response) {

          let selected_procedure_ids = []
          $('.selected_procedure_id').each(function () {
            selected_procedure_ids.push($(this).text())
          })
          $.each(response, function(key, value){

            if($.inArray( value.pp_id, selected_procedure_ids ) <= -1){
              let gender
              if(value.male && value.female){
                gender = 'M/F'
              } else if(value.male) {
                gender = 'M'
              } else if(value.female) {
                gender = 'F'
              }
              acu_tbl_package.row.add([
                `<p class="package_indicator"><span class="green">${value.package_code} </span><br><span class="dim">${value.package_name}</span></p>`,
                `${value.sp_code}`,
                `${value.sp_description}`,
                `${value.pp_code}`,
                `${value.pp_description}`,
                `${value.age_from} - ${value.age_to} years`,
                `${gender}`,
                `
                <span class="selected_procedure_id hidden">${value.pp_id}</span>`
              ]).draw(false)
            }
          })


          $('.div-dim').dimmer('hide')
          $('input[name="is_valid_acu_procedure"]').val("true")
          $('.remove_package').click(function() {
            let row = $(this).closest('tr')
            acu_tbl_package
              .row(row)
              .remove()
              .draw()
          })
        },
        error: function (){
          alertify.error('<i class="close icon"></i>Package/s cannot be added. Selected package/s have overlapping age and gender.')
          $('#acu-select-packages').dropdown('remove selected', addedValue)
          $('.div-dim').dimmer('hide')
        }
      })
    },
    onRemove: (removedValue, removedText, $removedChoice) => {
      $('.package_indicator').each(function () {
        if ($(this).text() == removedText) {
          let row = $(this).closest('tr')
          acu_tbl_package
            .row(row)
            .remove()
            .draw()
        }
      })
    }
  })

  // ================================================ acu tbl package ==========================================================//

  $('#btn_add_procedure').click(function () {
    let selected_procedure_ids = []

    $('.selected_procedure_id').each(function() {
      selected_procedure_ids.push($(this).text())
    })

    let procedure_ids = selected_procedure_ids.join(",")

    $('.modal.procedure')
      .modal({
        autofocus: false,
      })
      .modal('show');

    $('#tbl_add_procedure').DataTable({
      "destroy": true,
      "pageLength": 5,
      "bLengthChange": false,
      "bFilter": true,
      "ajax": $.fn.dataTable.dt_timeout(
        `/web/benefits/load_procedure?procedure_ids=${procedure_ids}`,
        csrf
      ),
      "deferRender": true,
      "drawCallback": function (settings) {
        $('.modal.procedure')
          .modal({
            autofocus: false,
          })
          .modal('refresh');
      },
      "serverSide": true,
      "deferRender": true,
      "language": {
        "emptyTable": "No Records Found!",
        "zeroRecords": "No results found"
      }
    })
  })

  $('#btn_cancel_procedure').click(function() {
    $('.modal.procedure').modal('hide');
  })

  $('#btn_submit_procedure').click(function() {
    let checked_procedure = $('input[class="procedure_chkbx"]:checked')
    if(checked_procedure.length > 0){
      let dt = $('#tbl_package').DataTable();
      //dt.clear().draw()
      $('input[class="procedure_chkbx"]:checked').each(function() {
        dt.row.add([
          `-`,
          `${$(this).attr('sp_code')}`,
          `${$(this).attr('sp_name')}`,
          `${$(this).attr('pp_code')}`,
          `${$(this).attr('pp_name')}`,
          `-`,
          `-`,
          `<a href="#!" class="remove_package"><i class="green trash icon"></i></a>
          <span class="selected_procedure_id hidden">${$(this).attr('pp_id')}</span>
          <input type="hidden" name="benefit[procedure_ids][]" value="${$(this).attr('pp_id')}">`
        ]).draw(false)
      })
      $('.modal.procedure').modal('hide');

      $('input[name="is_valid_procedure"]').val("true")

      $('.remove_package').click(function() {
        let row = $(this).closest('tr')
        dt.row(row)
          .remove()
          .draw()
      })
    } else {
      alertify.error('<i class="close icon"></i>Please select at least one procedure.')
    }
  })

  $('#btnDiscard').click(function() {
    $('.modal.discard').modal({
        autofocus: false,
        closable: false,
        observeChanges: true,
        selector: {
          deny: '.deny.button',
          approve: '.approve.button'
        },
        onShow: () => {
          $('#discard-header').text('Delete Benefit?')
          $('#discard-description').text(`Deleting this Benefit will permanently remove it from the system.`)
          $('#discard-question').text('Are you sure you want to discard this benefit?')
        },
        onApprove: () => {
          if ($('input[name="benefit_id"]').length > 0) {
            $.ajax({
              url: `/web/benefits/delete_benefit/${ $('input[name="benefit_id"]').val() }`,
              headers: {
                "X-CSRF-TOKEN": csrf
              },
              type: 'delete'
            })
          }
          window.location.replace('/web/benefits')
          return false
        }
      })
      .modal('show')
  })

  $('#btnDraft').click(function() {
    let result_code = $('#riders_form').form('validate field', 'benefit[code]')
    let result_coverage = $('#riders_form').form('validate field', 'benefit[coverage_ids]')
    if(result_code && result_coverage) {
      $('.modal.confirmation')
      .modal({
        autofocus: false,
        closable: false,
        selector: {
          deny: '.deny.button',
          approve: '.approve.button'
        },
        onShow: () => {
          $('#confirmation-header').text('Save as Draft')
          $('#confirmation-description').text(`Saving as draft allows the halt
            of creation of this benefit which can be continued later.`)
          $('#confirmation-question').text('Do you want to save this as draft?')

          $('input[name="benefit[is_draft]"]').val('true')
          initializeDraftValidation()
        },
        onApprove: () => {
          //window.location.replace('/web/benefits')
          $('#riders_form').submit()
          return false
        },
        onDeny: () => {
          $('input[name="benefit[is_draft]"]').val('')
          initializeBenefitValidations()
        }
      })
      .modal('show')
    }
  })
})

onmount('#main_benefit_modals', function() {

  /////Discontinue Peme Benefit/////

  let benefit_id = $('input[name="benefit_id"]').val();

  $('#mainDiscontinueBenefitID').on('click', function(){
  let haha = $('#benefit_id_disabler').val()

  $('.discontinue').on('keypress', function (e) {
    var regex = new RegExp(/^[a-zA-Z0-9,. ]*$/);
    var str = String.fromCharCode(!e.charCode ? e.which : e.charCode);
    if (regex.test(str)) {
        return true;
    }

    e.preventDefault();
    return false;
  });

  $('#b_id').text(haha)
  $('#main_modalDiscontinuePeme').modal({autofocus: false, closable: false, observeChanges: true}).modal('show')
  let currentDate = new Date()
  let tomorrowsDate = currentDate.setDate(currentDate.getDate() + 1)
  $('#discontinueDate').calendar({
    type: 'date',
    minDate: new Date(tomorrowsDate),
    onChange: function (start_date, text, mode) {
      let start = new Date(start_date)
      let end_date = start.setDate(start.getDate() + 1)
      end_date = new Date(end_date)
      $('input[name="hidden-date"]').val(end_date)
      let start_date1 = start_date.setDate(start_date.getDate() -1)
      let new_end_date = moment(start_date1).add(1, 'year').calendar()
      new_end_date = moment(new_end_date).format("MMM-DD-YYYY")
      $('input[name="account[end_date]"]').val(new_end_date)
      $('input[name="account[start_date]"]').val(moment(start_date.setDate(start_date.getDate() +1)).format("MMM-DD-YYYY"))

      $('#account_end_date').calendar({
        type: 'date',
        minDate: new Date(end_date),
        formatter: {
          date: function (date, settings) {
            if (!date) return '';
            var month_names = ['Default', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
            var day = date.getDate() + '';
            if (day.length < 2) {
              day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
              month = month;
            }
            var year = date.getFullYear();
            return month_names[month] + '  ' + day + '  ' + year;
          }
        }
      })
    },
    formatter: {
        date: function (date, settings) {
            if (!date) return '';

            var month_names = ['Default', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
            var day = date.getDate() + '';
            if (day.length < 2) {
                day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
                month = month;
            }
            var year = date.getFullYear();
            if (year < date.getFullYear() || year > 9999){
              year.setFullYear(date.getFullYear);
              return month_names[month] + '-' + day + '-' + year;
            }
            else
              return month_names[month] + '  ' + day + '  ' + year;
        }
    }
  });
  })
  $('#reDirect').click(function(){
    $('#benefit_discontinue_date').val('')
    $('#discontinue_remarks').val('')
  })

  $('.valid_timezone').each(function(){
    let val = $(this).text()
    $(this).text(moment(val).format("MMMM DD, YYYY"));
  })

  $('#discontinue_benefit_form').form({
      inline: true,
      fields: {
        'benefit[discontinue_date]': {
          identifier: 'benefit[discontinue_date]',
          rules: [{
            type: 'empty',
            prompt: 'Please Enter Discontinue Date'
          }]
        }
      }
  })

  $('#confirmDiscontinueBenefitID').click(() => {
    let result = $('#discontinue_benefit_form').form('validate form')

    if (result) {
      let date = $('input[name="benefit[discontinue_date]"]').val()
      $('#main_dbdate').text(date)
      $('#main_confirmDiscontinueBenefitID').modal({closable: false}).modal('show')
    }
  })

  $('#confirmDiscontinueBenefit').click(() => {

    $('#discontinue_benefit_form').submit()
  })


  $('#NoDB').on('click', function(){
     $('#main_modalDiscontinuePeme').modal({autofocus: false, closable : false, observeChanges: true}).modal('show')

  })

 $('#benefitlogsModal').modal({
    closable  : false,
    onHide: function() {
        $('input[name="benefit[search]"]').val("");
        $('.row_logs').remove();
        $('p[role="append_benefit_logs"]').text(" ")
        showAllLogs(benefit_id)
     }
  })
  .modal('attach events', '#benefit_logs', 'show');

 $('p[class="log-date"]').each(function(){
    let date = $(this).html();
    $(this).html(moment(date).format("MMMM Do YYYY, h:mm a"));
  })

 $('div[id="log_message"]').each(function(){
    var $this = $(this);
    var t = $this.text();
    $this.html(t.replace('&lt','<').replace('&gt', '>'));
  })

  $('#btnSearchBenefitLogs').on('click', function(){

    let message = $('input[name="benefit[search]"]').val();

    if (message == "" || message == null)
      {
        $('.row_logs').remove();
        $('p[role="append_benefit_logs"]').text(" ")
        showAllLogs(benefit_id)
      }
      else
        {
          $('.row_logs').remove();
          $('p[role="append_benefit_logs"]').text(" ")
          $.ajax({
            url:`/benefits/${benefit_id}/${message}/logs`,
            type: 'GET',
            success: function(response){
              let obj = JSON.parse(response)
              $("#package_logs_table tbody").html('')
              if (jQuery.isEmptyObject(obj)) {
                let no_log =
                  `No Matching Logs Found!`
                $("#timeline").removeClass('feed timeline');
                $('p[role="append_benefit_logs"]').text(no_log)
              }
              else  {
                for (let benefit_logs of obj) {
                  let new_row =
                    `<div class="event row_logs"> \
                    <div class="label"> \
                    <i class="blue circle icon"></i> \
                    </div> \
                    <div class="content"> \
                    <div class="summary"> \
                    <a> \
                    <p class="log-date">${benefit_logs.inserted_at}</p>\
                    </a> \
                    </div> \
                    <div class="extra text" id="log_message"> \
                    ${benefit_logs.message}\
                    </div> \
                    </div> \
                    </div> \
                    </tr>`

                  $("#timeline").addClass('feed timeline')
                  $('div[class="ui feed timeline"]').append(new_row)
                }
              }
              $('p[class="log-date"]').each(function(){
                let date = $(this).html();
                $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
              })
            }
          })
        }
  })


////Delete Benefit/////

  $('#mainDeleteBenefitID').on('click', function(){
  let deletePeme = $('#benefit_id_delete').val()
  $('#b_id').text(deletePeme)
  $('#main_modalDeletePeme').modal({autofocus: false, closable: false, observeChanges: true}).modal('show')

  let currentDate = new Date()
  let tomorrowsDate = currentDate.setDate(currentDate.getDate() + 1)

  $('.delete').on('keypress', function (e) {
    var regex = new RegExp(/^[a-zA-Z0-9,. ]*$/);
    var str = String.fromCharCode(!e.charCode ? e.which : e.charCode);
    if (regex.test(str)) {
        return true;
    }

    e.preventDefault();
    return false;
  });


  $('#CancelDelete').on('click', function(){
    $('#delete_date_picker').val('')
    $('#delete_remarks').val('')
  })

  $('#deleteDate').calendar({
    type: 'date',
    minDate: new Date(tomorrowsDate),
    onChange: function (start_date, text, mode) {
      let start = new Date(start_date)
      let end_date = start.setDate(start.getDate() + 1)
      end_date = new Date(end_date)
      $('input[name="hidden-date"]').val(end_date)
      let start_date1 = start_date.setDate(start_date.getDate() -1)
      let new_end_date = moment(start_date1).add(1, 'year').calendar()
      new_end_date = moment(new_end_date).format("MM-DD-YYYY")
      $('input[name="account[end_date]"]').val(new_end_date)
      $('input[name="account[start_date]"]').val(moment(start_date.setDate(start_date.getDate() + 1)).format("MMM-DD-YYYY"))

      $('#account_end_date').calendar({
        type: 'date',
        minDate: new Date(end_date),
        formatter: {
          date: function (date, settings) {
            if (!date) return '';
            var month_names = ['Default', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
            var day = date.getDate() + '';
            if (day.length < 2) {
              day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
              month = month;
            }
            var year = date.getFullYear();
            return month_names[month] + '  ' + day + '  ' + year;
          }
        }
      })
    },
    formatter: {
        date: function (date, settings) {
            if (!date) return '';
            var month_names = ['Default', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
            var day = date.getDate() + '';
            if (day.length < 2) {
                day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
                month = month;
            }
            var year = date.getFullYear();
            if (year < date.getFullYear() || year > 9999){
              year.setFullYear(date.getFullYear);
              return month_names[month] + '-' + day + '-' + year;
            }
            else
              return month_names[month] + '  ' + day + '  ' + year;
        }
    }
  });
  })

  $('#delete_benefit_form').form({
      inline: true,
      fields: {
        'benefit[delete_date]': {
          identifier: 'benefit[delete_date]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Delete Date'
          }]
        }
      }
    })


$('#confirmDeleteBenefitID').click(() => {

    let result = $('#delete_benefit_form').form('validate form')
    if (result) {
    let date = $('input[name="benefit[delete_date]"]').val()
    $('#main_dbdeletedate').text(date)
    $('#main_modalDeletePemeConfirmation').modal('show')
    }
  })

  $('#confirmDeleteBenefit').click(() => {
    $('#delete_benefit_form').submit()
  })


  $('#NoDL').on('click', function(){
    // $('#main_modalDeletePeme').modal('show')
    $('#main_modalDeletePeme').modal({autofocus: false, closable: false, observeChanges: true}).modal('show')

  })

//// DISABLING JS ////

  $('#mainDisableBenefitID').on('click', function(){
  let benefit_value = $('#benefit_id_disabler').val()

  $('.disabled').on('keypress', function (e) {
    var regex = new RegExp(/^[a-zA-Z0-9,. ]*$/);
    var str = String.fromCharCode(!e.charCode ? e.which : e.charCode);
    if (regex.test(str)) {
        return true;
    }

    e.preventDefault();
    return false;
  });

  $('#b_id').text(benefit_value)
    $('#main_modalDisablingPeme').modal({autofocus: false, closable: false, observeChanges: true}).modal('show')
    let currentDate = new Date()
    let tomorrowsDate = currentDate.setDate(currentDate.getDate() + 1)
  $('#disabledDate').calendar({
    type: 'date',
    minDate: new Date(tomorrowsDate),
    onChange: function (start_date, text, mode) {
      let start = new Date(start_date)
      let end_date = start.setDate(start.getDate() + 1)
      end_date = new Date(end_date)
      $('input[name="hidden-date"]').val(end_date)
      let start_date1 = start_date.setDate(start_date.getDate() -1)
      let new_end_date = moment(start_date1).add(1, 'year').calendar()
      new_end_date = moment(new_end_date).format("MMM-DD-YYYY")
      $('input[name="account[end_date]"]').val(new_end_date)
      $('input[name="account[start_date]"]').val(moment(start_date.setDate(start_date.getDate() + 1)).format("MMM-DD-YYYY"))

      $('#account_end_date').calendar({
        type: 'date',
        minDate: new Date(end_date),
        formatter: {
          date: function (date, settings) {
            if (!date) return '';
            var month_names = ['Default', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
            var day = date.getDate() + '';
            if (day.length < 2) {
              day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
              month = month;
            }
            var year = date.getFullYear();
            return  month_names[month] + '  ' + day + '  ' + year;
          }
        }
      })
    },
    formatter: {
        date: function (date, settings) {
            if (!date) return '';
            var month_names = ['Default', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
            var day = date.getDate() + '';
            if (day.length < 2) {
                day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
                month = month;
            }
            var year = date.getFullYear();
            if (year < date.getFullYear() || year > 9999){
              year.setFullYear(date.getFullYear);
              return month_names[month] + '-' + day + '-' + year;
            }
            else
              return  month_names[month] + '  ' + day + '  ' + year;
        }
    }
  });
  })
  // open modal for yes/no benefit disabled
  // $('#confirmDisableBenefitID').click(function(e) {
  //     e.preventDefault()
  //     $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
  //     $('.disabledateFormPicker').removeClass('error')
  //   if ($('#disabled_date').val() != ''){
  //     $('#main_DisablingPemeConfirmation').modal({autofocus: false, closable: false}).modal('show')
  //   }
  //   else{
  //     $('.disabledateFormPicker').addClass('error')
  //     $('.disabledateFormPicker').append('<div class="ui basic red pointing prompt label transition visible">Please enter disabled date</div>')
  //   }
  // })

  // $('#disabled_date').change(function(){
  //     $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
  //     $('.disabledateFormPicker').removeClass('error')
  })

$('#confirmDisableBenefitID').click(() => {

    let result = $('#disabled_benefit_form').form('validate form')

    if (result) {
    let date = $('input[name="benefit[disabled_date]"]').val()
    $('#main_disabled_date').text(date)
    $('#main_DisablingPemeConfirmation').modal('show')
    }
  })

  $('#cancel_disabled_button').click(function() {
    $('#disabled_date').val('')
    $('#disabled_remarks').val('')
  })

  // submit yes/no benefit modal
  $('#confirmDisableBenefitID1').click(function(){
     $('#disabled_benefit_form').submit()
  })

  $('#no_keep_benefit_button').click(function(){
    $('#main_modalDisablingPeme').modal({autofocus: false, closable: false, observeChanges: true}).modal('show')
  })

  $('#disabled_benefit_form').form({
      inline: true,
      fields: {
        'benefit[disabled_date]': {
          identifier: 'benefit[disabled_date]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Disable date'
          }]
        }
      }
    })

function add_search(table){
  let id = table[0].getAttribute("id")
  let value = $(`#${id}_filter`).val()

  if(value != 1){
    $(`#${id}_filter`).addClass('ui left icon input')
    $(`#${id}_filter`).find('label').after('<i class="search icon"></i>')
    $(`#${id}_filter`).find('input[type="search"]').unwrap()
    $(`#${id}_filter`).find('input[type="search"]').attr("placeholder", `Search`)
    $(`#${id}_filter`).find('input[type="search"]').append(`</div>`)
    $(`#${id}_filter`).val(1)
  }
}

onmount('input[id="show_benefit_result"]', function(){
  let text = $('#show_benefit_result').val()
  let text1 = "Rider. "
  let merge_string = text1.concat(text)

  let split_string = text.split(",")[0]
  let web_benefits = "/web/benefits/"
  let view = "/view"
  let merge1 = web_benefits.concat(split_string)
  let merge2 = merge1.concat(view)

	$('.modal.complete')
		.modal({
			autofocus: false,
			closable: false,
			centered: false,
			observeChanges: true,
			selector: {
				deny: '.deny.button',
				approve: '.approve.button'
      },
      onShow: () => {
        $('#complete-description').text(merge_string)
      },
      onApprove: () => {
				window.location.replace("/web/benefits/create_new_rider")
			},
			onDeny: () => {
        window.location.replace(merge2)
			}
		})
		.modal('show')
})

