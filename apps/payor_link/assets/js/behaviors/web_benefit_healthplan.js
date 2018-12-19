onmount('div[id="benefit_healthplan"]', function () {
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
  //$('.complete.modal').modal('attach events', '.modal-open-complete');
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

  const initializeBenefitCodeRule = _ => {
    $.fn.form.settings.rules.checkBenefitCode = function(param) {
      return bc_array.indexOf(param) == -1 ? true : false
    }
  }

  const initializeDeleteDiagnosis = _ => {
    $('.remove_diagnosis').on('click', function() {
      let row = $(this).closest('tr')
      let dt = $('#tbl_diagnosis').DataTable();
      dt.row(row)
        .remove()
        .draw()
      let dt_count = $('#tbl_diagnosis').DataTable().row().count()
      check_row_diagnosis(dt_count)
    })
  }

  const check_row_diagnosis = dt_count => {
    if (dt_count == 0) {
     $('input[name="is_valid_diagnosis"]').val(false)
    } else {
     $('input[name="is_valid_diagnosis"]').val(true)

     return true
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

        load_normal(response)
        $('#benefit_form_dim').dimmer('hide')
      },
      error: (xhr, ajaxOptions, thrownError) => {
        window.location.replace('/sign_out_error_dt')
      }
    })
  }

  const load_normal = response => {
    $('#benefit_code2').val(response.code)
    benefit_limits = response.limits
    load_coverage_data(response)
    load_package_data(response)
    load_diagnosis_data(response)
    load_procedure_data(response)
    if(response.type == "Policy"){
    $('#bc_policy').attr('checked', true)
    }else{
    $('#bc_availment').attr('checked', true)
    $('#hide_availment_fields').show();
    $('input[name="benefit[benefit_policy]"]').val("Availment")
    $('input[name="benefit[type]"]').val("Availment")

    let benefit_coverage = $("#coverages_dropdown").find('div[class="text"]').text()
      if(AddedText == "OP Consult") {
        hide_package_procedure()
      }

      $('#coverages_dropdown').dropdown('hide')
    }
  }

  const load_coverage_data = response => {
    $.each(response.coverages, function(index, value) {
      $('#loaded_coverage_id').append(`<input type="hidden" class="current_coverage_id" value="${value.id}">`)
    })
    $('#coverages_dropdown').dropdown('show')
  }

  const load_package_data = response => {
    $('#select-packages').dropdown('show')
    $.each(response.packages, function(index, value) {
      $('#loaded_package_id').append(`<input type="hidden" class="current_package_id" value="${value.id}">`)
    })
  }

  const load_diagnosis_data = response => {
    let dt = $('#tbl_diagnosis').DataTable();
    $.each(response.diagnosis, function(index, value) {
      dt.row.add([
        `<span class="green selected_diagnosis_id">${value.code}</span>`,
        `<strong>${value.name}</strong><br><small class="thin dim">${value.description}</small>`,
        `${value.type}`,
        `<a href="#!" class="remove_diagnosis"><i class="green trash icon"></i></a><input type="hidden" name="benefit[diagnosis_ids][]" value="${value.id}">`
      ]).draw(false)

  })

    let dt_count = $('#tbl_diagnosis').DataTable().row().count()

  // $('input[name="is_valid_diagnosis"]').val('true')
    initializeDeleteDiagnosis(dt_count)
    check_row_diagnosis(dt_count)
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

  $('form input').keydown(function (e) {
      if (e.keyCode == 13) {
          e.preventDefault();
          return false;
      }
  })
  const initializeBenefitValidations = _ => {
    $('#hp_form').form({
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
      }
    })
  }

  const initializeDraftValidation = _ => {
    $('#hp_form').form({
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
        'benefit[coverage_ids]': {
          identifier: 'benefit[coverage_ids]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a coverage.'
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
        observeChanges: true
      })
      .modal('attach events', '.modal-open-limit');
  }

  const tbl_limit = $('#tbl_limit').DataTable()
  let active_limit_row
  const initializeEditLimit = _ => {
    $('input[name="benefit[limits][]"]').val()

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

        if (name == "Dental") {
          $('div[role="general"]').hide()
        } else {
          $('div[role="dental"]').hide()
        }

        $('#limit_form').form('clear')
        $('input[name="limit_coverage"]').val(name)

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

  const addLimitRow = (id, coverage_name) => {

    if( $('input[name="benefit_id"]').val() != undefined && benefit_limits != undefined ) {
      if(benefit_limits == ""){
      tbl_limit.row.add([
        `<span class="name" id="limit_${coverage_name}">${coverage_name}</span>`,
        `<span class="type">-</span>`,
        `<span class="amount">-</span>`,
        `<span class="class">-</span>`,
        `
        <span class="button">
          <a href="#!" class="mini modal-open-limit add_limit ui primary basic button">Add Limit</a>
          <input type="hidden" name="benefit[limits][]" value="${id}">
        </span>
        `
      ]).draw()
      } else{
      $('#coverage_name').val(coverage_name)

      $('input[name="benefit[limits][]"]').val()

      $('input[name="benefit[coverages][]"]').val()
      $('input[name="benefit[type][]"]').val()
      $('input[name="benefit[amount][]"]').val()
      $('input[name="benefit[classification][]"]').val()

      $('input[name="is_valid_limit"]').val("true")
      $('input[name="is_valid_procedure"]').val("true")
     }
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
        </span>
        `
      ]).draw()
    }

    initializeLimitModal()

    $('.add_limit').click(function() {
      let row = $(this).closest('tr')
      let name = row.find('.name').text()
      let record = $(this).closest('td').find('input')
      active_limit_row = row

      if ( name == "Dental") {
        $('div[role="general"]').hide()
      } else {
        $('div[role="dental"]').hide()
      }

      $('#limit_form').form('clear')
      $('input[name="limit_coverage"]').val(name)
      $('input[name="limit_id"]').val(record.val())
      $('#limit_amount_field').addClass('disabled')
      $('#submit_limit_form').text("Add Limit")
    })
  }

  let coverage_value = [];
  const checkOPConsult = () => {
    let indicator = $('#coverages_dropdown').find('a:contains("OP Consult")')
    if(indicator.length > 0){
      alertify.error('<i class="close icon"></i>You cannot add more coverages if OP Consult is selected.')
      hide_package_procedure()

      return false
    }
    if(coverage_value.length > 0){
      let consult_element = $('#coverages_dropdown').find('div[class="item"]:contains("OP Consult")')
      consult_element.addClass('disabled')
    } else {
      let consult_element = $('#coverages_dropdown').find('div[class="item disabled"]:contains("OP Consult")')
      consult_element.removeClass('disabled')
    }

    show_package_procedure()
    return true
  }

  const show_package_procedure = () => {
    $('#package_procedure_fields').removeClass('hidden')

    $('#hp_form').form({
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
            prompt: 'Please select atleast one diagnosis'
          }]
        },
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

  const hide_package_procedure_v2 = () => {
    $('#package_procedure_fields').addClass('hidden')
    $('#select-packages')
      .dropdown('clear')
    $('#tbl_package')
      .DataTable()
      .clear()
      .draw()
  }

  const hide_package_procedure = () => {
    $('#package_procedure_fields').addClass('hidden')
    $('#select-packages')
      .dropdown('clear')
    $('#tbl_package')
      .DataTable()
      .clear()
      .draw()
    $('#hp_form').form({
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
            prompt: 'Please select atleast one diagnosis'
          }]
        }
      }
    })
  }

  //NEW BENEFIT POLICY
  $('#bc_policy').change(function(){
    // removed =
    $('#hide_availment_fields').hide();
    $('input[name="benefit[benefit_policy]"]').val("Policy")
    $('input[name="benefit[type]"]').val("Policy")
    policy_form_validation()
    $('.prompt').remove()
    $('#package_procedure_fields').find('div[class="field error"]').removeClass('error')
    $('#acu-select-packages').find('div[class="field error"]').removeClass('error')
    $('#hp_form').removeClass("success error warning");
    $('#hp_form').removeClass("ui basic red pointing prompt label transition visible");
  })

  let AddedValue = $('input[name="benefit[coverage_ids]"]').val()
  let AddedText = "-";

  $('#coverages_dropdown').dropdown({
    apiSettings: {
      url: `/web/benefits/load_coverages?type=health_plan`,
      cache: false
    },
    onShow: () => {
      let current_coverage_div = $('#loaded_coverage_id')
      let coverages_dd = []
      if(current_coverage_div.length > 0) {
        $('.current_coverage_id').each(function() {
          coverages_dd.push(
            $(this).val()
          )
        })

        $('#coverages_dropdown').dropdown(
          'set selected',
          coverages_dd
        )

        current_coverage_div.remove()
        $('#coverages_dropdown').addClass('disabled')
        return false
      }

      let result = checkOPConsult()
      return result
    },
    onAdd: (addedValue, addedText, $addedChoice) => {
     let benefit_policy = $('input[name="benefit[benefit_policy]"]').val()
     if(benefit_policy == "Policy") {
       policy_form_validation()
       $('.prompt').remove()
       $('#package_procedure_fields').find('div[class="field error"]').removeClass('error')
       $('#hp_form').removeClass("success error warning");
       AddedValue = addedValue
       AddedText = addedText
      addLimitRow(addedValue, addedText)
      coverage_value.push(addedText)

      if(addedText == "OP Consult") {
        hide_package_procedure_v2()
      }

      $('#coverages_dropdown').dropdown('hide')

     }else{
       AddedValue = addedValue
       AddedText = addedText
      addLimitRow(addedValue, addedText)
      coverage_value.push(addedText)

      if(addedText == "OP Consult") {
        hide_package_procedure()
      }

      $('#coverages_dropdown').dropdown('hide')
     }
    },
    onRemove: (removedValue, removedText, $removedChoice) => {
      let indicator = `span[id="limit_${removedText}"]`
      let row = $(indicator).closest('tr')

      coverage_value.pop(removedText)

      tbl_limit
        .row(row)
        .remove()
        .draw()

      let is_opc_selected = $('#coverages_dropdown').find('a:contains("OP Consult")')
      if(is_opc_selected < 0) {
        checkOPConsult()
      } else {
        show_package_procedure()
      }
      $('#coverages_dropdown').dropdown('hide')
    }
  })

  //FOR CATEGORY RADIO BUTTON
  $('#bc_availment').change(function(){
    initializeBenefitValidations()
    $('#hide_availment_fields').show();
    $('input[name="benefit[benefit_policy]"]').val("Availment")
    $('input[name="benefit[type]"]').val("Availment")

    let benefit_coverage = $("#coverages_dropdown").find('div[class="text"]').text()
      if(AddedText == "OP Consult") {
        hide_package_procedure()
      }

      $('#coverages_dropdown').dropdown('hide')

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
        $('div[id="limit_amount_label"]').text('Tooths')
        $('input[name="limit_type"]').val(addedValue)
      }

      if(addedValue == "Quadrant") {
        maskNumeric.mask('input[name="limit_amount"]')
        $('div[id="limit_amount_label"]').text('Quadrants')
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

  const policy_form_validation = () => {
    $('#hp_form').form({
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

  $('#cancel_limit_form').click(() => {
    $('.limit.modal').modal('hide')
  })

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
        case "Quadrant":
          amount_label = "Quadrant"
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

  initializeBenefitValidations()

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

    load_diagnosis_table(diagnosis_ids)
  }

  $('#btn_add_diagnosis').click(function () {
    initializeDiagnosisTbl()
  })

  const load_diagnosis_table = diagnosis_ids => {
    let type = $('#diagnosis_type_dropdown').dropdown('get value')
    $('#tbl_add_diagnosis').DataTable({
      "destroy": true,
      "pageLength": 5,
      "bLengthChange": false,
      "bFilter": true,
      "columnDefs": [
        {
          "orderable": false,
          "targets": 0
        }
      ],
      "ajax": $.fn.dataTable.dt_timeout(
        `/web/benefits/load_diagnosis?diagnosis_ids=${diagnosis_ids}&type=${type}&is_all_selected=${ $('#diagnosis_select_all').is(":checked") }`,
        csrf
      ),
      "deferRender": true,
      "drawCallback": function (settings) {
        $('#diagnosis_type_dropdown')
          .dropdown('hide')
          .dropdown({
            onChange: (value, text, $choice) => {
              load_diagnosis_table(diagnosis_ids)
            }
          })
      },
      "serverSide": true,
      "deferRender": true,
      "language": {
        "emptyTable": "No Records Found!",
        "zeroRecords": "No results found"
      }
    })
  }

  $('#btn_cancel_diagnosis').click(function() {
    $('.modal.diagnosis').modal('hide');
  })

  $('#btn_submit_diagnosis').click(function() {
    let is_all_selected = $('#diagnosis_select_all').is(":checked")

    let checked_diagnosis = $('input[class="diagnosis_chkbx"]:checked')
    if(checked_diagnosis.length > 0) {
      let submit_btn = $(this)
      submit_btn.html('<span class="ui active tiny centered inline loader"></span>')
      if (is_all_selected) {
        let selected_diagnosis_ids = []

        $('.selected_diagnosis_id').each(function() {
          selected_diagnosis_ids.push($(this).text())
        })

        let diagnosis_ids = selected_diagnosis_ids.join(",")
        let type = $('#diagnosis_type_dropdown').dropdown('get value')
        $('#tbl_diagnosis').DataTable({
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
        let dt = $('#tbl_diagnosis').DataTable();
        $('input[class="diagnosis_chkbx"]:checked').each(function() {
          dt.row.add([
            `<span class="green selected_diagnosis_id">${$(this).attr('code')}</span>`,
            `<strong>${$(this).attr('diagnosis_name')}</strong><br><small class="thin dim">${$(this).attr('description')}</small>`,
            `${$(this).attr('diagnosis_type')}`,
            `<a href="#!" class="remove_diagnosis"><i class="green trash icon"></i></a><input type="hidden" name="benefit[diagnosis_ids][]" value="${$(this).attr('diagnosis_id')}">`
          ]).draw(false)
        })
        submit_btn.html('Add')
        $('.modal.diagnosis').modal('hide');
      }

      // $('input[name="is_valid_diagnosis"]').val("true")

      let dt_count = $('#tbl_diagnosis').DataTable().row().count()
      initializeDeleteDiagnosis(dt_count)
      check_row_diagnosis(dt_count)

      // $(document).on('click', '.remove_diagnosis', function() {
      //   let row = $(this).closest('tr')
      //   let dt = $('#tbl_diagnosis').DataTable();
      //   dt.row(row)
      //     .remove()
      //     .draw()
      // })
    } else {
      alertify.error('<i class="close icon"></i>Please select at least one diagnosis.')
    }
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

  const tbl_package = $('#tbl_package').DataTable()
  $('#select-packages').dropdown({
    apiSettings: {
      url: `/web/benefits/load_packages`,
      cache: false
    },
    filterRemoteData: true,
    onShow: () => {
      let current_package_div = $('#loaded_package_id')
      if (current_package_div.length > 0) {
        let coverage_dd = []
        $('.current_package_id').each(function () {
          coverage_dd.push($(this).val())
        })

        $('#select-packages').dropdown(
          'set selected',
          coverage_dd
        )

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
                `<span class="selected_procedure_id hidden">${value.pp_id}</span>`
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

  $('#btn_add_procedure').click(function () {
    let selected_procedure_ids = []

    $('.selected_procedure_id').each(function() {
      selected_procedure_ids.push($(this).text())
    })

    let procedure_ids = selected_procedure_ids.join(",")

    $('.modal.procedure')
      .modal({
        autofocus: false,
        centered: false,
        observeChanges: true
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

  $('#btnDiscard').click(function () {
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
            window.location.href = `/web/benefits/delete_benefit/${$('input[name="benefit_id"]').val()}`
          } else {
            window.location.href = `/web/benefits`
          }
          return false
        }
      })
      .modal('show')
  })

  $('#btnDraft').click(function() {
    let result_code = $('#hp_form').form('validate field', 'benefit[code]')
    let result_coverage = $('#hp_form').form('validate field', 'benefit[coverage_ids]')

    if(result_code && result_coverage) {
      $('.modal.confirmation')
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
          $('#confirmation-header').text('Save as Draft')
          $('#confirmation-description').text(`Saving as draft allows the halt
            of creation of this benefit which can be continued later.`)
          $('#confirmation-question').text('Do you want to save this as draft?')

          $('input[name="benefit[is_draft]"]').val('true')
          initializeDraftValidation()
        },
        onApprove: () => {
          $('#hp_form').submit()
          return false
        },
        onDeny: () => {
          $('input[name="benefit[is_draft]"]').val('')

          let indicator = $('#coverages_dropdown').find('a:contains("OP Consult")')
          if (indicator.length > 0) {
            hide_package_procedure()
          } else {
            initializeBenefitValidations()
          }
        }
      })
      .modal('show')
    }
  })
  ///moved const to top
})
