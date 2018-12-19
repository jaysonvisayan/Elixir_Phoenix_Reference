onmount('div[id="product_coverage_step"]', function () {
  const check_facility = input => {
    let coverage = $(input).attr('coverage')
    let value = $(input).val().toLowerCase()

    if (value == 'true') {
      $(`#${coverage}_add_ex_lt_btn`).removeClass('disabled')
      $(`#${coverage}_add_ex_rs_btn`).removeClass('disabled')
      $(`#${coverage}_lt_tbl`).DataTable().clear().draw()
      $(`#${coverage}_rs_tbl`).DataTable().clear().draw()
    } else {
      $(`#${coverage}_add_ex_lt_btn`).addClass('disabled')
      $(`#${coverage}_add_ex_rs_btn`).addClass('disabled')
    }
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

  const get_selected_facilities = (coverage, type) => {
    let selected_ids = []

    $(`.selected_${coverage}_${type}_id`).each(function () {
      selected_ids.push($(this).text())
    })

    return selected_ids
  }

  const get_provider_access = provider_access => {
    return (provider_access == undefined) ? '' : provider_access
  }

  const initialize_lt_validation = () => {
    $('#limit-threshold-form').form({
      on: 'blur',
      inline: true,
      fields: {
        'limit-threshold-facility': {
          identifier: 'limit-threshold-facility',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a limit threshold facility.'
          }]
        },
        'limit-threshold-value': {
          identifier: 'limit-threshold-value',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a value.'
          }, {
            type: 'checkOuterLimit[param]',
            prompt: 'Inner limit is equal to outer limit.'
          }]
        }
      }
    })
  }

  const initialize_rs_validation_integer = () => {
    $('#risk-share-form').form({
      on: 'blur',
      inline: true,
      fields: {
        'risk-share-facility': {
          identifier: 'risk-share-facility',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a limit threshold facility.'
          }]
        },
        'risk-share': {
          identifier: 'risk-share',
          rules: [{
            type: 'empty',
            prompt: 'Please enter risk share.'
          }]
        },
        'risk-share-value': {
          identifier: 'risk-share-value',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a value.'
          }, {
            type   : 'integer[1..100]',
            prompt : 'Please enter a value between 1 to 100.'
          }]
        },
        'covered-after-risk-share': {
          identifier: 'covered-after-risk-share',
          rules: [{
            type: 'empty',
            prompt: 'Please enter covered after risk share value.'
          }, {
            type   : 'integer[1..100]',
            prompt : 'Please enter a covered value between 1 to 100.'
          }]
        }
      }
    })
  }

  const initialize_rs_validation_decimal = () => {
    $('#risk-share-form').form({
      on: 'blur',
      inline: true,
      fields: {
        'risk-share-facility': {
          identifier: 'risk-share-facility',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a limit threshold facility.'
          }]
        },
        'risk-share': {
          identifier: 'risk-share',
          rules: [{
            type: 'empty',
            prompt: 'Please enter risk share.'
          }]
        },
        'risk-share-value': {
          identifier: 'risk-share-value',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a value.'
          }, {
            type   : 'decimal',
            prompt : 'Please enter a valid decimal value.'
          }]
        },
        'covered-after-risk-share': {
          identifier: 'covered-after-risk-share',
          rules: [{
            type: 'empty',
            prompt: 'Please enter covered after risk share value.'
          }, {
            type   : 'integer[1..100]',
            prompt : 'Please enter a covered value between 1 to 100.'
          }]
        }
      }
    })
  }

  const submit_lt = () => {
    let result = $('#limit-threshold-form').form('validate form')
    if (result) {
      let coverage = $('input[name="limit-threshold-coverage"]').val()
      let facility_code = $('#select-lt-facility').dropdown('get value')
      let facility_name = $('#select-lt-facility').dropdown('get text')
      let dt = $(`#${coverage}_lt_tbl`).DataTable()
      let value = $('input[name="limit-threshold-value"]').val()
      $(`input[name="product[${coverage}][limit_threshold]"]`).prop('readonly', true)

      dt.row
        .add([
          `<span class="green">${facility_code}</span>`,
          `<strong>${facility_name}</strong>`,
          `<span class="lt_value">${value}</span>`,
          `<a href="#!" class="remove_lt"><i class="green trash icon"></i></a>
                  <span class="selected_${coverage}_lt_id hidden">${facility_code}</span>
                  <input type="hidden" name="product[${coverage}][lt_data][]" value="${facility_code}-${value}">`
        ])
        .draw()

      $('.remove_lt').unbind('click').click(function () {
        let row = $(this).closest('tr')
        dt.row(row).remove().draw()

        if(dt.rows().count() == 0) {
          $(`input[name="product[${coverage}][limit_threshold]"]`).prop('disabled', false)
        }
      })
    }

    return result
  }

  const submit_rs = () => {
    let result = $('#risk-share-form').form('validate form')

    if(result) {
      let coverage = $('input[name="risk-share-coverage"]').val()
      let facility_code = $('#select-rs-facility').dropdown('get value')
      let facility_name = $('#select-rs-facility').dropdown('get text')
      let risk_share = $('#select-rs').dropdown('get text')
      let dt = $(`#${coverage}_rs_tbl`).DataTable()
      let value = $('input[name="risk-share-value"]').val()
      let cars = $('input[name="covered-after-risk-share"]').val()
      let rs_data = `${risk_share}-${value}-${cars}`

      if(risk_share == "Copayment") {
        value = `${value} PHP`
      } else {
        value = `${value} %`
      }

      dt.row
        .add([
          `<span class="green">${facility_code}</span>`,
          `<strong>${facility_name}</strong>`,
          risk_share,
          value,
          `${cars} %`,
          `<a href="#!" class="remove_rs"><i class="green trash icon"></i></a>
           <span class="selected_${coverage}_rs_id hidden">${facility_code}</span
           <input type="hidden" name="product[${coverage}][rs_data][]" value="${facility_code}-${rs_data}">`
        ])
        .draw()

      $('.remove_rs').unbind('click').click(function () {
        let row = $(this).closest('tr')
        dt.row(row).remove().draw()
      })
    }

    return result
  }

  $.fn.form.settings.rules.checkOuterLimit = param => {
    let outer_limit = $('input[name="limit-threshold-outer-value"]').val()
    outer_limit = (outer_limit == undefined) ? 0 : outer_limit
    return outer_limit == param ? false : true
  }

  $('.modal-open-facilities').click(function () {
    let coverage = $(this).attr('coverage')
    let dt = $(`#${coverage}_fa_modal_tbl`)
    let provider_access = get_provider_access($(this).attr('providerAccess'))
    let type = $(`input[name="product[${coverage}][type]"]:checked`).val()
    let selected_fa_ids = get_selected_facilities(coverage, "fa")
    let fa_ids = selected_fa_ids.join(',')


    switch (type) {
      case 'All Affiliated Facilities':
        $(`#${coverage}_header`).text('Exclusion of Facilities')
        $(`#${coverage}_description`).text(
          'All the facilities are listed on the service. The facilities added will be excluded from the list.'
        )
        break
      case 'Specific Facilities':
        $(`#${coverage}_header`).text('Add Facilities')
        $(`#${coverage}_description`).text(
          'Add at least one or more facilities from the list.'
        )
        break
      default:
        $(`#${coverage}_header`).text('Add Facilities')
        $(`#${coverage}_description`).text(
          'Add at least one or more facilities from the list.'
        )
    }

    $(`.facilities.modal.${coverage}`)
      .modal({
        autofocus: false,
        closable: false,
        selector: {
          deny: '.cancel.button'
        }
      })
      .modal('show')

    dt.DataTable({
      destroy: true,
      pageLength: 5,
      bLengthChange: false,
      bFilter: true,
      ajax: {
        url: `/web/products/load_fa?ids=${fa_ids}&provider_access=${provider_access}`
      },
      deferRender: true,
      drawCallback: function (settings) {
        $('.facilities.modal')
          .modal({
            autofocus: false,
            closable: false,
            selector: {
              deny: '.cancel.button'
            }
          })
          .modal('refresh')
      }
    })
  })

  $('.fa_rb').on('change', function () {
    let form = $(this).closest('.coverage_form')
    form.find('#funding_arrangement_type').val('true')

    form.form('validate field', 'funding_arrangement_type')
  })

  $('.coverage_type_radio').on('change', function () {
    let coverage = $(this).attr('coverage')
    let value = $(this).find('input').val()
    let input = $(`input[name="${coverage}_is_valid_facility"]`)
    let dt_fa = $(`#${coverage}_fa_tbl`).DataTable()
    let dt_lt = $(`#${coverage}_lt_tbl`).DataTable()

    let fa_checker = (dt_fa.rows().count() > 0) ? true : false
    let lt_checker = (dt_lt.rows().count() > 0) ? true : false

    let form = $(this).parents('.coverage_form')
    form.find('#coverage_type').val('true')

    $(`#${coverage}_add_fa_btn`).removeClass('disabled')
    $('#confirmation-header').text('Change Facilities?')
    $('#confirmation-description').text('All the data entered about facility access and exempted facilities in limit threshold will be deleted.')
    $('#confirmation-question').text('Do you want to proceed?')

    if(value == "All Affiliated Facilities") {
      $(`#${coverage}_add_ex_lt_btn`).removeClass('disabled')
      $(`#${coverage}_add_ex_rs_btn`).removeClass('disabled')
      input.val('true')
    } else {
      input.val('')
      check_facility(input)
    }

    if(fa_checker) {
      form.form('validate field', 'fa_tbl')
      form.form('validate field', 'coverage_type')
    }

    if(fa_checker || lt_checker) {
      $('.modal.confirmation')
        .modal({
          autofocus: false,
          closable: false,
          selector: {
            deny: '.deny.button',
            approve: '.approve.button'
          },
          onShow: () => {
            $('.modal.confirmation')
              .find('.close.icon')
              .css('display', 'none')
          },
          onVisible: _ => {
            $('.modal.confirmation').modal('refresh')
          },
          onApprove: () => {
            dt_fa.clear().draw()
            dt_lt.clear().draw()
          },
          onDeny: () => {
            confirmation_fa(value, coverage)
          }
        })
        .modal('show')
    }
  })

  const confirmation_fa = (value, coverage) => {
    switch(value) {
      case "All Affiliated Facilities":
        $('input[value="Specific Facilities"]').prop('checked', true)
        break
      case "Specific Facilities":
        $('input[value="All Affiliated Facilities"]').prop('checked', true)
        $(`#${coverage}_add_ex_lt_btn`).removeClass('disabled')
        $(`#${coverage}_add_ex_rs_btn`).removeClass('disabled')
        break
    }
  }
      $('.remove_facility')
        .unbind('click')
        .click(function () {
          let row = $(this).parents('tr')
          let current_dt = $(this).parents('table').DataTable()

          $('.modal.confirmation')
          .modal({
            autofocus: false,
            closable: false,
            selector: {
              deny: '.deny.button',
              approve: '.approve.button'
            },
            onShow: () => {
              $('.modal.confirmation')
                .find('.close.icon')
                .css('display', 'none')

              $('#confirmation-header').text('Remove Facility?')
              $('#confirmation-description').text('Facility shall be removed from Facility Details and user shall be redirected to Facility Step if YES button is clicked.')
              $('#confirmation-question').text('Do you want to proceed?')
            },
            onVisible: _ => {
              $('.modal.confirmation').modal('refresh')
            },
            onApprove: () => {
              current_dt
                .row(row)
                .remove()
                .draw()

              let count = current_dt.rows().count()
              if (count == 0) {
                let input = $(`input[name="dentl_is_valid_facility"]`)
                input.val('')
                check_facility(input)
              }
            }
          })
          .modal('show')
        })


  $('.submit_fa').click(function () {
    let coverage = $(this).attr('coverage')
    let checked_facility = $(`#${coverage}_fa_modal_tbl`).find(
      'input[class="facility_chkbx"]:checked'
    )
    let input = $(`input[name="${coverage}_is_valid_facility"]`)

    if (checked_facility.length > 0) {
      let dt = $(`#${coverage}_fa_tbl`).DataTable()
      $(`#${coverage}_fa_modal_tbl`)
        .find('input[class="facility_chkbx"]:checked')
        .each(function () {
          dt.row
            .add([
              `<span class="green selected_facility_${coverage}_id">${$(this).attr('code')}</span>`,
              `<strong>${$(this).attr('facility_name')}</strong>`,
              `<span class="dim small">${$(this).attr('address')}</span>`,
              `<span class='small'>${$(this).attr('facility_type')}</span>`,
              `<span class='small'>${$(this).attr('category')}</span>`,
              `<span class='small'>${$(this).attr('region')}</span>`,
               `<a href="#!" class="remove_facility">Remove</a>
              <input type="hidden" name="product[${coverage}][facility_ids][]" value="${$(this).attr('facility_id')}">
              <span class="selected_${coverage}_fa_id hidden">${$(this).attr('facility_id')}</span>`
            ])
            .draw()
        })

      $(`.modal.facilities.${coverage}`).modal('hide')
      input.val('true')
      check_facility(input)

      $('.remove_facility')
        .unbind('click')
        .click(function () {
          let row = $(this).parents('tr')
          let current_dt = $(this).parents('table').DataTable()

          $('.modal.confirmation')
          .modal({
            autofocus: false,
            closable: false,
            selector: {
              deny: '.deny.button',
              approve: '.approve.button'
            },
            onShow: () => {
              $('.modal.confirmation')
                .find('.close.icon')
                .css('display', 'none')

              $('#confirmation-header').text('Remove Facility?')
              $('#confirmation-description').text('Facility shall be removed from Facility Details and user shall be redirected to Facility Step if YES button is clicked.')
              $('#confirmation-question').text('Do you want to proceed?')
            },
            onVisible: _ => {
              $('.modal.confirmation').modal('refresh')
            },
            onApprove: () => {
              current_dt
                .row(row)
                .remove()
                .draw()

              let count = current_dt.rows().count()
              if (count == 0) {
                let input = $(`input[name="${coverage}_is_valid_facility"]`)
                input.val('')
                check_facility(input)
              }
            }
          })
          .modal('show')
        })
    } else {
      alertify.error(
        '<i class="close icon"></i>Please select at least one facility before submitting.'
      )
    }
  })

  $('.modal-open-lt').click(function() {
    let coverage = $(this).attr('coverage')
    let outer_limit = $(`input[name="product[${coverage}][limit_threshold]"]`).val()
    let type = $(`input[name="product[${coverage}][type]"]:checked`).val()
    let selected_fa_ids = get_selected_facilities(coverage, "fa")
    let selected_lt_codes = get_selected_facilities(coverage, "lt")
    let provider_access = get_provider_access($(this).attr('providerAccess'))

    $('#limit-threshold-form').form('reset')
    $(`.modal.limit-threshold`)
      .modal({
        autofocus: false,
        closable: false,
        selector: {
          deny: '.cancel.button',
          approve: '.add.button'
        },
        onApprove: () => { return submit_lt() },
        onShow: () => {
          $('input[name="limit-threshold-outer-value"]').val(outer_limit)
          $('input[name="limit-threshold-coverage"]').val(coverage)

          $('#lt_dropdown').html(`
            <label class="label-title">Facility</label>
            <div class="ui fluid selection dropdown" id="select-lt-facility">
              <input type="hidden" name="limit-threshold-facility">
              <i class="dropdown icon"></i>
              <div class="default text">Select Facility</div>
              <div class="menu">
              </div>
            </div>
          `)

          initialize_lt_validation()

          $('#select-lt-facility').dropdown({
            apiSettings: {
              url: `/web/products/load_dropdown_facilities?type=${type}&facilities=${selected_fa_ids}&provider_access=${provider_access}&selected_lt_codes=${selected_lt_codes}`
            }
          })
        }
      })
      .modal('show')
  })

  $('.modal-open-rs').click(function() {
    let coverage = $(this).attr('coverage')
    let type = "All Affiliated Facilities"
    let fa_ids = []
    let selected_rs_codes = get_selected_facilities(coverage, "rs")
    let provider_access = get_provider_access($(this).attr('providerAccess'))

    $(`.modal.risk-share`)
      .modal({
        autofocus: false,
        closable: false,
        selector: {
          deny: '.cancel.button',
          approve: '.add.button'
        },
        onApprove: () => { return submit_rs() },
        onShow: () => {
          $('input[name="risk-share-coverage"]').val(coverage)
          $('#risk-share-form').form('clear')

          $('#rs_dropdown').html(`
            <label class="label-title">Facility</label>
            <div class="ui fluid selection dropdown" id="select-rs-facility">
              <input type="hidden" name="risk-share-facility">
              <i class="dropdown icon"></i>
              <div class="default text">Select Facility</div>
              <div class="menu">
              </div>
            </div>
          `)

          $('#select-rs-facility').dropdown({
            apiSettings: {
              url: `/web/products/load_dropdown_facilities?type=${type}&facilities=${fa_ids}&provider_access=${provider_access}&selected_lt_codes=${selected_rs_codes}`
            }
          })

          initialize_rs_validation_integer()
        }
      })
      .modal('show')

    $('#select-rs').dropdown({
      onChange: (value, text, $choice) => {
        if(value == "copayment") {
          $('#lbl-risk-share-value').text('PHP')
          initialize_rs_validation_decimal()
        } else if(value == "coinsurance") {
          $('#lbl-risk-share-value').text('%')
          initialize_rs_validation_integer()
        }
      }
    })
  })

  $('#select-rs').dropdown({
    onChange: (value, text, $choice) => {
      if(value == "copayment") {
        $('#lbl-risk-share-value').text('PHP')
        initialize_rs_validation_decimal()
      } else if(value == "coinsurance") {
        $('#lbl-risk-share-value').text('%')
        initialize_rs_validation_integer()
      }
    }
  })

  $('.coverage_form').form({
    on: 'blur',
    inline: true,
    fields: {
      // limit_threshold: {
      //   identifier: 'limit_threshold',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter a limit threshold facility.'
      //   }]
      // },
      // af_rs: {
      //   identifier: 'af_rs',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter a risk share.'
      //   }]
      // },
      // af_value: {
      //   identifier: 'af_value',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter a risk share value.'
      //   }]
      // },
      // af_cars: {
      //   identifier: 'af_cars',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter coverage after risk share value.'
      //   }]
      // },
      // naf_rs: {
      //   identifier: 'naf_rs',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter a risk share.'
      //   }]
      // },
      // naf_value: {
      //   identifier: 'naf_value',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter a risk share value.'
      //   }]
      // },
      // naf_cars: {
      //   identifier: 'naf_cars',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter coverage after risk share value.'
      //   }]
      // },
      // naf_reimbursable: {
      //   identifier: 'naf_reimbursable',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter reimbursable value.'
      //   }]
      // },
      coverage_type: {
        identifier: 'coverage_type',
        rules: [{
          type: 'empty',
          prompt: 'Please enter coverage type.'
        }]
      },
      fa_tbl: {
        identifier: 'fa_tbl',
        rules: [{
          type: 'empty',
          prompt: 'Please enter atleast one facility.'
        }]
      },
      funding_arrangement_type: {
        identifier: 'funding_arrangement_type',
        rules: [{
          type: 'empty',
          prompt: 'Please enter funding arrangement type.'
        }]
      }
    }
  })

  $('.btn_submit').click(function () {
    let validation_result = $('.coverage_form').form('validate form')

    if (Array.isArray(validation_result)) {
      if (jQuery.inArray(false, validation_result) == -1) {
        $('#product_coverage_form').submit()
      }
      else {
        alertify.error('Please fill-up all missing fields')
      }
    } else {
      if (validation_result) {
        $('#product_coverage_form').submit()
      }
    }
  })

  $('.risk_share_type').on('change', function () {
    let value = $(this).dropdown('get value')
    let coverage = $(this).find('select').attr('coverage')
    $(`#${coverage}_rs_value`).prop('readonly', false)

    switch(value) {
      case "Copay":
        maskDecimal.mask(`#${coverage}_rs_value`)
        $(`#${coverage}_rs_value_sign`).text("PHP")
        break
      case "CoInsurance":
        maskPercentage.mask(`#${coverage}_rs_value`)
        $(`#${coverage}_rs_value_sign`).text("%")
        break
      default:
        maskPercentage.mask(`#${coverage}_rs_value`)
        $(`#${coverage}_rs_value_sign`).text("%")
        break
    }
  })

  $('.ui.modal.sf')
    .modal({
      autofocus: false,
      closable: false,
      selector: {
        deny: '.cancel.button',
        approve: '.add.button'
      }
    })
    .modal('attach events', '.modal-open-rsf')

  $('.ui.modal.af')
    .modal({
      autofocus: false,
      closable: false,
      selector: {
        deny: '.cancel.button',
        approve: '.add.button'
      }
    })
    .modal('attach events', '.modal-open-raf')
})
