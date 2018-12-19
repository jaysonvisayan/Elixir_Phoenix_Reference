onmount('div[id="product_benefit_step"]', function () {

  $('.modal-open-main').click(function () {
    //$('.ui.rtp-modal').modal('show');
    $('.ui.modal:not(.ui.send-rtp-modal)').modal('show');
  });

  $('.modal-open-main').click(function () {
    //$('.ui.rtp-modal').modal('show');
    $('.ui.modal:not(.ui.send-rtp-modal)').modal('show');
  });

  $('.send-rtp-modal')
    .modal('attach events', '.button.send-rtp');

  $('.benefit.modal')
    .modal('attach events', '.modal-open-benefit');
  $('.packages.modal')
    .modal('attach events', '.modal-open-package');
  $('.complete.modal')
    .modal('attach events', '.modal-open-complete');
  $('.facilities.modal')
    .modal('attach events', '.modal-open-facilities');

  $('.procedure.modal')
    .modal('attach events', '.modal-open-procedure');

  $('.limit.modal')
    .modal('attach events', '.modal-open-limit');

})

onmount('div[id="product_header_btn"]', function () {

  $('#btnDiscard').click(function () {

    let id = $(this).attr('productID');
    $('#delete_product').val(id);

    $('.modal.discard').modal({
        autofocus: false,
        closable: false,
        observeChanges: true,
        selector: {
          deny: '.deny.button',
          approve: '.approve.button'
        },
        onShow: () => {
          $('#discard-header').text('Delete Plan?')
          $('#discard-description').text(`Deleting this product will permanently remove it from the system.`)
          $('#discard-question').text('Are you sure you want to discard this plan?')
        },
        onApprove: () => {
          let id = $('#delete_product').val();

          let csrf2 = $('input[name="_csrf_token"]').val();
          $.ajax({
            url: `/web/products/${id}/delete_all`,
            headers: {
              "X-CSRF-TOKEN": csrf2
            },
            type: 'delete',
            success: function (response) {
              let obj = JSON.parse(response)
              window.location.replace('/web/products')
            }
          })
        }
      })
      .modal('show')
  })

  $('#btnDraft').click(function () {
    let result_code = $('#dental_form').form('validate field', 'product[code]')
    let result_coverage = $('#dental_form').form('validate field', 'product[name]')
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
            of creation of this product which can be continued later.`)
          $('#confirmation-question').text('Do you want to save this as draft?')
        },
        onApprove: () => {
          $('input[name="product[is_draft]"]').val("true")
          $('#product_coverage_form').submit()
          // window.location.replace('/web/products') }
         }
      })
      .modal('show')
  })

})

onmount('div[id="dental_product_header_btn"]', function () {

  $('#dental_btnDiscard').click(function () {

    let id = $(this).attr('productID');
    $('#delete_product').val(id);

    $('.modal.discard').modal({
        autofocus: false,
        closable: false,
        observeChanges: true,
        selector: {
          deny: '.deny.button',
          approve: '.approve.button'
        },
        onShow: () => {
          $('#discard-header').text('Delete Plan?')
          $('#discard-description').text(`Deleting this product will permanently remove it from the system.`)
          $('#discard-question').text('Are you sure you want to discard this plan?')
        },
        onApprove: () => {
          let id = $('#delete_product').val();

          let csrf2 = $('input[name="_csrf_token"]').val();
          $.ajax({
            url: `/web/products/${id}/delete_all`,
            headers: {
              "X-CSRF-TOKEN": csrf2
            },
            type: 'delete',
            success: function (response) {
              let obj = JSON.parse(response)
              window.location.replace('/web/products')
            }
          })
        }
      })
      .modal('show')
  })

  $('#dental_btnDraft').click(function () {

    let validate_mprincipal = $('#dental_condition_form').form('validate field', 'product[nem_principal]')
    let validate_mdependents = $('#dental_condition_form').form('validate field', 'product[nem_dependent]')
    let validate_pded = $('#dental_condition_form').form('validate field', 'product[mded_principal]')
    let validate_mded = $('#dental_condition_form').form('validate field', 'product[mded_dependent]')
    let validate_pminage = $('#dental_condition_form').form('validate field', 'product[principal_min_age]')
    let validate_pmaxage = $('#dental_condition_form').form('validate field', 'product[principal_max_age]')
    let validate_aminage = $('#dental_condition_form').form('validate field', 'product[adult_dependent_min_age]')
    let validate_amaxage = $('#dental_condition_form').form('validate field', 'product[adult_dependent_max_age]')
    let validate_mminage = $('#dental_condition_form').form('validate field', 'product[minor_dependent_min_age]')
    let validate_mmaxage = $('#dental_condition_form').form('validate field', 'product[minor_dependent_max_age]')
    let validate_ominage = $('#dental_condition_form').form('validate field', 'product[overage_dependent_min_age]')
    let validate_omaxage = $('#dental_condition_form').form('validate field', 'product[overage_dependent_max_age]')
    let validate_lfacilitated = $('#dental_condition_form').form('validate field', 'product[loa_facilitated]')
    let validate_reimbursement = $('#dental_condition_form').form('validate field', 'product[reimbursement]')
    let validate_lvalidity = $('#dental_condition_form').form('validate field', 'product[loa_validity]')
    let validate_shandling = $('#dental_condition_form').form('validate field', 'product[special_handling_type]')
    let validate_dfarrangement = $('#dental_condition_form').form('validate field', 'product[dental_funding_arrangement]')
    let validate_type_of_payment = $('#dental_condition_form').form('validate field', 'product[type_of_payment_type]')

    if (validate_mprincipal &&
      validate_mdependents &&
      validate_pded &&
      validate_mded &&
      validate_pminage &&
      validate_pmaxage &&
      validate_aminage &&
      validate_amaxage &&
      validate_mminage &&
      validate_mmaxage &&
      validate_ominage &&
      validate_omaxage &&
      validate_lfacilitated &&
      validate_reimbursement &&
      validate_lvalidity &&
      validate_shandling &&
      validate_dfarrangement &&
      validate_type_of_payment
    ) {

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
            of creation of this product which can be continued later.`)
            $('#confirmation-question').text('Do you want to save this as draft?')

            $('#dental_condition_form')
              .form({
                'product[nem_principal]': {
                  identifier: 'product[nem_principal]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter no. of Eligible principals'
                  }]
                },
                'product[nem_dependent]': {
                  identifier: 'product[nem_dependent]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter no. of Eligible dependents'
                  }]
                },
                'product[mded_principal]': {
                  identifier: 'product[mded_principal]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter a Default Effective Date for Principal'
                  }]
                },
                'product[mded_dependent]': {
                  identifier: 'product[mded_dependent]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter a Default Effective Date for Dependents'
                  }]
                },
                'product[principal_min_age]': {
                  identifier: 'product[principal_min_age]',
                  rules: [{
                      type: 'empty',
                      prompt: 'Please enter Principal Min Age.'
                    },
                    {
                      type: 'checkPrincipalMinMaxAge[param]',
                      prompt: `Principal min age must not be greater than or equal max age`

                    }
                  ]
                },
                'product[principal_max_age]': {
                  identifier: 'product[principal_max_age]',
                  rules: [{
                      type: 'empty',
                      prompt: 'Please enter Principal Max Age.'
                    },
                    {
                      type: 'checkPrincipalMinMaxAge[param]',
                      prompt: `Principal min age must not be greater than or equal max age`

                    }
                  ]
                },
                'product[adult_dependent_min_age]': {
                  identifier: 'product[adult_dependent_min_age]',
                  rules: [{
                      type: 'empty',
                      prompt: 'Please enter Parent Spouse Min Age.'
                    },
                    {
                      type: 'checkParentSpouseMinMaxAge[param]',
                      prompt: `Parent Spouse min age must not be greater than or equal max age`

                    }
                  ]
                },
                'product[adult_dependent_max_age]': {
                  identifier: 'product[adult_dependent_max_age]',
                  rules: [{
                      type: 'empty',
                      prompt: 'Please enter Parent Spouse Max Age.'
                    },
                    {
                      type: 'checkParentSpouseMinMaxAge[param]',
                      prompt: `Parent Spouse min age must not be greater than or equal max age`

                    }
                  ]
                },
                'product[minor_dependent_min_age]': {
                  identifier: 'product[minor_dependent_min_age]',
                  rules: [{
                      type: 'empty',
                      prompt: 'Please enter Child and Sibling Min Age.'
                    },
                    {
                      type: 'checkChildSiblingMinMaxAge[param]',
                      prompt: `Child and Sibling min age must not be greater than or equal max age`

                    }
                  ]
                },
                'product[minor_dependent_max_age]': {
                  identifier: 'product[minor_dependent_max_age]',
                  rules: [{
                      type: 'empty',
                      prompt: 'Please enter Child and Sibling Max Age.'
                    },
                    {
                      type: 'checkChildSiblingMinMaxAge[param]',
                      prompt: `Child and Sibling min age must not be greater than or equal max age`

                    }
                  ]
                },
                'product[overage_dependent_min_age]': {
                  identifier: 'product[overage_dependent_min_age]',
                  rules: [{
                      type: 'empty',
                      prompt: 'Please enter Overage Min Age.'
                    },
                    {
                      type: 'checkOverageMinMaxAge[param]',
                      prompt: `Overage min age must not be greater than or equal max age`

                    }
                  ]
                },
                'product[overage_dependent_max_age]': {
                  identifier: 'product[overage_dependent_max_age]',
                  rules: [{
                      type: 'empty',
                      prompt: 'Please enter Overage Max Age.'
                    },
                    {
                      type: 'checkOverageMinMaxAge[param]',
                      prompt: `Overage min age must not be greater than or equal max age`

                    }
                  ]
                },
                'product[loa_facilitated]': {
                  identifier: 'product[loa_facilitated]',
                  rules: [{
                    type: 'checkModeOfAvailment2[param]',
                    prompt: `Please Check at least one or two Mode of Availment`

                  }]
                },
                'product[reimbursement]': {
                  identifier: 'product[reimbursement]',
                  rules: [{
                    type: 'checkModeOfAvailment2[param]',
                    prompt: `Please Check at least one or two Mode of Availment`

                  }]
                },
                'product[loa_validity]': {
                  identifier: 'product[loa_validity]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Enter LOA validity'
                  }]
                },
                'product[special_handling_type]': {
                  identifier: 'product[special_handling_type]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Select special handling'
                  }]
                },
                'product[dental_funding_arrangement]': {
                  identifier: 'product[dental_funding_arrangement]',
                  rules: [{
                    type: 'checked',
                    prompt: 'Select funding arrangement'
                  }]
                },
                'product[type_of_payment_type]': {
                  identifier: 'product[type_of_payment_type]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Select type of payment'
                  }]
                },
              })
          },
          onApprove: () => {
            let input = document.getElementById('product_capitation_fee')
            let unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#product_capitation_fee').val(unmasked)
            $('input[name="product[is_draft]"]').val('true')
            $('#dental_condition_form').submit()
            // window.location.replace('/web/products')
            return false
          },
          onDeny: () => {
            $('input[name="product[is_draft]"]').val('false')
          }
        })
        .modal('show')
    }
  })

})

onmount('div[id="product_index_page"]', function () {

  $('.modal-open-main').click(function () {
    //$('.ui.rtp-modal').modal('show');
    $('.ui.modal:not(.ui.send-rtp-modal)').modal('show');

    //onload
    if ($('#selection_regular:checked').val() ? true : false) {
      $("#append_product_base").removeClass("hidden")
      $('input[name="params[product_base]"]').attr('disabled', false)
    }

    $('#select_regular').on("click", function (e) {
      $("#append_product_base").removeClass("hidden")
      $('input[name="params[product_base]"]').attr('disabled', false)
    })
    $('#select_peme').on("click", function (e) {
      $("#append_product_base").addClass("hidden")
      $('input[name="params[product_base]"]').attr('disabled', true)
    })



    $('#choose_product_form').form({

      inline: true,
      fields: {
        'params[product_base]': {
          identifier: 'params[product_base]',
          rules: [{
            type: 'checked',
            prompt: 'Please enter a product base.'
          }]
        }
      }

    })

    $('.toggle_btn_modal').click(function () {
      $('.selection-button').removeClass('active_modal')
      $('.toggle_ico').removeClass('white')
      $('.toggle_ico').addClass('dark')

      $(this).find('.selection-button').addClass('active_modal')
      $(this).find('.toggle_ico').addClass('white')
      $(this).find('.toggle_ico').removeClass('dark')

      let option = $(this).find('.option').attr('value')
      $('#params_product_category').val(option)

      if (option == "Regular Plan") {
        $("#append_product_base").removeClass('hidden')
      } else {
        $("#append_product_base").addClass('hidden')
      }
    })

  });

  const csrf = $('input[name="_csrf_token"]').val();
  $('#product_table').DataTable({
    "ajax": {
      "url": "/web/products/index/data",
      "headers": {
        "X-CSRF-TOKEN": csrf
      },
      "type": "get"
    },
    "ajax": $.fn.dataTable.dt_timeout(
      `/web/products/index/data`,
      csrf
    ),
    "processing": true,
    "serverSide": true,
    "deferRender": true,
    "order": [[ 5, "desc" ]]
  });
})

onmount('div[id="new_product_show"]', function () {
  $('#logsModal').modal('attach events', '#logs', 'show')

  $('p[class="log-date"]').each(function () {
    let date = $(this).html();
    $(this).html(moment(date).format("MMM D, YYYY"));
  })

  history.pushState(null, null, location.href);
  window.onpopstate = function () {
    // history.go(1); // to disable back button
    location.replace("/web/products"); // back to index page
  };

    var im = new Inputmask("decimal", {
      radixPoint: ".",
      groupSeparator: ",",
      digits: 2,
      autoGroup: true,
      // prefix: '₱ ',
      rightAlign: false,
      oncleared: function () { self.Value(''); }
    });
    im.mask($('.capitationFee'))
    im.mask($('.limit_amount'))

})

onmount('div[id="main_step1_general_peme"]', function () {
  $('input[name="product[name]"]').on('keypress', function (evt) {
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode(key);
    let regex = /[``~<>^'{}[\]\\;,'"/?!@#$%&*_+=|:]/;

    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
      return false;
    } else {
      $(this).on('focusout', function (evt) {
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  })

  $('input[name="product[description]"]').on('keypress', function (evt) {
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode(key);
    let regex = /[``~<>^'{}[\]\\;,'"/?!@#$%&*_+=|:]/;

    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
      return false;
    } else {
      $(this).on('focusout', function (evt) {
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  })


  $('#main_general_form')

    .form({
      inline: true,
      fields: {

        'product[name]': {
          identifier: 'product[name]',
          rules: [{
              type: 'empty',
              prompt: 'Please enter a name.'
            },
            // {
            //   type: 'checkProductNames[param]',
            //   prompt: 'Product Name has already been taken.'
            // }
            {
              type: 'maxLength[150]',
              prompt: 'Plan Name cannot exceed 150 characters'
            }
          ]
        },
        'product[description]': {
          identifier: 'product[description]',
          rules: [{
              type: 'empty',
              prompt: 'Please enter a description.'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Plan Description cannot exceed 150 characters'
            }
          ]
        },

        'product[type]': {
          identifier: 'product[type]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a type.'
          }]
        },

        'product[member_type][]': {
          identifier: 'product[member_type][]',
          rules: [{
            type: 'checked',
            prompt: 'Please select atleast one member type.'
          }]
        },

        'product[standard_product]': {
          identifier: 'product[standard_product]',
          rules: [{
            type: 'checked',
            prompt: 'Please enter a product classification.'
          }]
        },

      }
    })
})


onmount('div[id="main_step1_general_dental"]', function () {
  $('input[name="product[code]"]').on('keypress', function (evt) {
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode(key);
    let regex = /[``~<>^'{}[\]\\;,'"/?!@#$%&*+=|:()]/;

    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
      return false;
    } else {
      $(this).on('focusout', function (evt) {
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  })
})

onmount('div[id="main_new_general_dental"]', function () {
  $('input[name="product[code]"]').on('keypress', function (evt) {
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode(key);
    let regex = /[``~<>^'{}[\]\\;,'"/?!@#$%&*+=|:()]/;

    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
      return false;
    } else {
      $(this).on('focusout', function (evt) {
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  })
})



onmount('div[id="main_step1_general"]', function () {

  // default
  $('#main_general_form')
    .form({
      inline: true,
      on: 'blur',
      fields: {
        'product[name]': {
          identifier: 'product[name]',
          rules: [{
              type: 'empty',
              prompt: 'Please enter a name.'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Plan Name cannot exceed 150 characters'
            }
          ]
        },
        'product[description]': {
          identifier: 'product[description]',
          rules: [{
              type: 'empty',
              prompt: 'Please enter a description.'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Plan Description cannot exceed 150 characters'
            }
          ]
        },
        'product[type]': {
          identifier: 'product[type]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a type.'
          }]
        },
        'product[limit_amount]': {
          identifier: 'product[limit_amount]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a limit amount.'
          }]
        },
        'product[limit_applicability]': {
          identifier: 'product[limit_applicability]',
          rules: [{
            type: 'checked',
            prompt: 'Please enter a limit applicability.'
          }]
        },
        'product[limit_type]': {
          identifier: 'product[limit_type]',
          rules: [{
            type: 'checked',
            prompt: 'Please enter a limit type.'
          }]
        },
        'product[phic_status]': {
          identifier: 'product[phic_status]',
          rules: [{
            type: 'checked',
            prompt: 'Please enter a PHIC status.'
          }]
        },
        'product[standard_product]': {
          identifier: 'product[standard_product]',
          rules: [{
            type: 'checked',
            prompt: 'Please enter a product classification.'
          }]
        },
        'product[member_type][]': {
          identifier: 'product[member_type][]',
          rules: [{
            type: 'checked',
            prompt: 'Please select atleast one member type.'
          }]
        }
        // 'product[product_base]': {
        //   identifier: 'product[product_base]',
        //   rules: [
        //     {
        //       type: 'checked',
        //       prompt: 'Please enter a product base.'
        //     }
        //   ]
        // }
      },
      onSuccess: function (event, fields) {
        var input = document.getElementById('product_limit_amt');
        var unmasked = input.inputmask.unmaskedvalue()
        input.inputmask.remove()
        $('#product_limit_amt').val(unmasked)
      }
    })


  $('#delete_draft').click(function () {
    let id = $(this).attr('productID');
    $('#dp_product_id').val(id);

    $('#delete_product_confirmation').modal('show');
  });

  $('#dp_cancel').click(function () {
    $('#delete_product_confirmation').modal('hide');
  });

  $('#dp_submit').click(function () {
    let id = $('#dp_product_id').val();

    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url: `/products/${id}/delete_all`,
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      type: 'delete',
      success: function (response) {
        let obj = JSON.parse(response)
        window.location.replace('/products')
      }
    });
  });


  $('input[name="product[code]"]').on('keypress', function (evt) {
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode(key);
    let regex = /[``~<>^'{}[\]\\;,'"/?!@#$%&*+=|:()]/;

    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
      return false;
    } else {
      $(this).on('focusout', function (evt) {
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  })

  // $('input[name="product[name]"]').on('keypress', function (evt) {
  //   let theEvent = evt || window.event;
  //   let key = theEvent.keyCode || theEvent.which;
  //   key = String.fromCharCode(key);
  //   let regex = /[``~<>^'{}[\]\\;,'"/?!@#$%&*_+=|:]/;

  //   if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
  //     return false;
  //   } else {
  //     $(this).on('focusout', function (evt) {
  //       $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
  //     })
  //   }
  // })

  // $('input[name="product[description]"]').on('keypress', function (evt) {
  //   let theEvent = evt || window.event;
  //   let key = theEvent.keyCode || theEvent.which;
  //   key = String.fromCharCode(key);
  //   let regex = /[``~<>^'{}[\]\\;,'"/?!@#$%&*_+=|:]/;

  //   if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
  //     return false;
  //   } else {
  //     $(this).on('focusout', function (evt) {
  //       $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
  //     })
  //   }
  // })

  $.fn.form.settings.rules.checkProductLimit = function (param) {
    let highest = $('#product_benefit_highest').val()
    //c
    // let submitted = param.split(',.').join('')
    // console.log("submitted: " + submitted)
    // console.log("highestpb: " + highest)
    let submitted = param.split(',').join('')
    if (highest == "") {
      if (parseFloat(submitted) >= parseFloat(0)) {
        return true
      } else {
        return false
      }
    } else {

      if (parseFloat(submitted) >= parseFloat(highest)) {
        return true
      } else {
        return false
      }

    }
  }

  $.fn.form.settings.rules.checkSharedLimitAmount = function (param) {
    let pla = $('#product_limit_amt').val().split(',').join('')
    let submitted = param.split(',').join('')

    if (parseFloat(pla) >= parseFloat(submitted)) {
      return true
    } else {
      return false
    }

  }


  /////////////////////////// start: limit applicability and product base validation

  $('#product_limit_amt').on("keyup", function (e) {
    let pla = $(this).val()
    $('#slaTxtBox').val(pla)
  });

  // if the limit applicability has been set first
  $('input[name="product[limit_applicability]"]').change(function () {
    let val = $(this).val()

    if (val == "Principal") {

      ////alert(val)
      $('#slaContainer').addClass('hidden')
      $('input[name="product[shared_limit_amount]"]').prop('disabled', true)

      validateBenefitBased()
    } else if (val == "Share with Dependents") {
      let pla = $('#product_limit_amt').val()
      if (pla.length > 0) {
        $('#slaContainer').removeClass('hidden')
        $('input[name="product[shared_limit_amount]"]').prop('disabled', false)
        $('#slaTxtBox').val(pla)
        validateBenefitBasedwithSLA()
      } else if (pla.length == 0) {
        //alert('Fill up first the limit amount before selecting Share with Dependents')
        $('#swd').prop('checked', false)
        $('#swd').closest('div').removeClass('checked')
      }
    }

  })

  let csrf = $('input[name="_csrf_token"]').val();
  let product_name = $('input[name="product[name]"]').val()
  let highest2 = $('#product_benefit_highest').val()

  // onload set
  if ($('.swd:checked').val() ? true : false) {
    validateBenefitBasedwithSLA()
  } else if ($('.laprincipal:checked').val() ? true : false) {
    validateBenefitBased()
  }

  ///////////////////
  function validateBenefitBased() {
    $('.field.error').removeClass("error");
    $('.error').removeClass("error");

    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function () {
      $(this).remove();
    });
    $('#main_general_form')
      .form({
        inline: true,
        fields: {
          'product[name]': {
            identifier: 'product[name]',
            rules: [{
                type: 'empty',
                prompt: 'Please enter a name.'
              },
              // {
              //   type: 'checkProductNames[param]',
              //   prompt: 'Product Name has already been taken.'
              // }
              {
                type: 'maxLength[150]',
                prompt: 'Plan Name cannot exceed 150 characters'
              }
            ]
          },
          'product[description]': {
            identifier: 'product[description]',
            rules: [{
                type: 'empty',
                prompt: 'Please enter a description.'
              },
              {
                type: 'maxLength[150]',
                prompt: 'Plan Description cannot exceed 150 characters'
              }
            ]
          },
          'product[type]': {
            identifier: 'product[type]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter a type.'
            }]
          },
          'product[limit_amount]': {
            identifier: 'product[limit_amount]',
            rules: [{
                type: 'empty',
                prompt: 'Please enter a limit amount.'
              },
              {
                type: 'checkProductLimit[param]',
                prompt: `Plan Limit must be equal or greater than each benefit\'s limit, the highest benefit was amounting ${highest2}. Plan cannot be saved.`
              }
            ]
          },
          'product[limit_applicability]': {
            identifier: 'product[limit_applicability]',
            rules: [{
              type: 'checked',
              prompt: 'Please enter a limit applicability.'
            }]
          },
          'product[limit_type]': {
            identifier: 'product[limit_type]',
            rules: [{
              type: 'checked',
              prompt: 'Please enter a limit type.'
            }]
          },
          'product[phic_status]': {
            identifier: 'product[phic_status]',
            rules: [{
              type: 'checked',
              prompt: 'Please enter a PHIC status.'
            }]
          },
          'product[standard_product]': {
            identifier: 'product[standard_product]',
            rules: [{
              type: 'checked',
              prompt: 'Please enter a product classification.'
            }]
          },
          'product[member_type][]': {
            identifier: 'product[member_type][]',
            rules: [{
              type: 'checked',
              prompt: 'Please select atleast one member type.'
            }]
          }
        },
        onSuccess: function (event, fields) {
          var input = document.getElementById('product_limit_amt');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          $('#product_limit_amt').val(unmasked)
        }
      })
  }


  function validateBenefitBasedwithSLA() {
    $('.field.error').removeClass("error");
    $('.error').removeClass("error");

    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function () {
      $(this).remove();
    });
    $('#main_general_form')
      .form({
        inline: true,
        fields: {
          'product[name]': {
            identifier: 'product[name]',
            rules: [{
                type: 'empty',
                prompt: 'Please enter a name. haha'
              },
              {
                type: 'maxLength[150]',
                prompt: 'Plan Name cannot exceed 150 characters'
              }
            ]
          },
          'product[description]': {
            identifier: 'product[description]',
            rules: [{
                type: 'empty',
                prompt: 'Please enter a description. haha'
              },
              {
                type: 'maxLength[150]',
                prompt: 'Plan Description cannot exceed 150 characters'
              }
            ]
          },
          'product[type]': {
            identifier: 'product[type]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter a type.'
            }]
          },
          'product[limit_amount]': {
            identifier: 'product[limit_amount]',
            rules: [{
                type: 'empty',
                prompt: 'Please enter a limit amount.'
              },
              {
                type: 'checkProductLimit[param]',
                prompt: `Plan Limit must be equal or greater than each benefit\'s limit, the highest benefit was amounting ${highest2}. Plan cannot be saved.`
              }
            ]
          },
          'product[limit_applicability]': {
            identifier: 'product[limit_applicability]',
            rules: [{
              type: 'checked',
              prompt: 'Please enter a limit applicability.'
            }]
          },
          'product[shared_limit_amount]': {
            identifier: 'product[shared_limit_amount]',
            rules: [{
                type: 'empty',
                prompt: 'Please enter a shared limit amount.'
              },
              {
                type: 'checkSharedLimitAmount[param]',
                prompt: `Shared Limit Amount must be less than or equal to Limit Amount.`
              }
            ]
          },
          'product[limit_type]': {
            identifier: 'product[limit_type]',
            rules: [{
              type: 'checked',
              prompt: 'Please enter a limit type.'
            }]
          },
          'product[phic_status]': {
            identifier: 'product[phic_status]',
            rules: [{
              type: 'checked',
              prompt: 'Please enter a PHIC status.'
            }]
          },
          'product[standard_product]': {
            identifier: 'product[standard_product]',
            rules: [{
              type: 'checked',
              prompt: 'Please enter a product classification.'
            }]
          },
          'product[member_type][]': {
            identifier: 'product[member_type][]',
            rules: [{
              type: 'checked',
              prompt: 'Please select atleast one member type.'
            }]
          }
        },
        onSuccess: function (event, fields) {
          var input = document.getElementById('product_limit_amt');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          $('#product_limit_amt').val(unmasked)

          var input = document.getElementById('slaTxtBox');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          $('#slaTxtBox').val(unmasked)
        }
      })
  }

  //////////////////


  /////////////////////////// end: limit applicability and product base validation

  function checkGeneral() {
    let counter = 0;
    $('.checker').each(function () {
      let field = $(this).attr('field');
      let value = $(this).val();
      switch (field) {
        case "name":
        case "description":
        case "type":
        case "limit_amount":
          let new_val = $('input[name="' + field + '"]').val()
          if (value != new_val) {
            counter++;
            ////alert(value + "   " + new_val)
          }
          break;
        case "limit_applicability":
          let new_val_la = "";
          if ($('#individual').checked) {
            new_val_la = "Individual"
          } else {
            new_val_la = "Share with Family"
          }
          if (value != new_val_la) {
            counter++;
          }
          break;
        case "limit_type":
          let new_val_lt = "";
          if ($('#abl').checked) {
            new_val_lt = "ABL"
          } else {
            new_val_lt = "MBL"
          }
          if (value != new_val_lt) {
            counter++;
          }
          break;
        case "phic_status":
          let new_val_ps = "";
          if ($('#rtftest').checked) {
            new_val_ps = "Required to File"
          } else {
            new_val_ps = "Optional to File"
          }
          if (value != new_val_ps) {
            counter++;
          }
          break;
        case "standard_product":
          let new_val_sp = "";
          if ($('#rtftest').checked) {
            new_val_sp = "Yes"
          } else {
            new_val_sp = "No"
          }
          if (value != new_val_sp) {
            counter++;
          }
          break;
        default:
          break
      }
    });
    if (counter > 0) {
      return false
    } else {
      return true
    }
  }

  $('.discard_changes_g').click(function () {
    let url = $(this).attr('redirect_link');
    let val = checkGeneral();

    if (val == false) {
      $('#g_confirmation').modal('show');
      $('#g_confirmation_link').val(url);
    }
  });

  $('#confirmation_submit_g').click(function () {
    let url = $('#g_confirmation_link').val();
    window.location.replace(url);
  });

  var im = new Inputmask("decimal", {
    allowMinus: false,
    min: 0,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false
  });
  im.mask($('#product_limit_amt'))
  im.mask($('#slaTxtBox'))




  // for changing of step title in product/new
  $('div.ui.radio.checkbox.pbase').on('click', function () {
    let radio_selected = $(this).find('input:radio').val();
    if (radio_selected == 'Exclusion-based') {
      $('.cov-ben').find('.title').text('Coverage')
    } else if (radio_selected == 'Benefit-based') {
      $('.cov-ben').find('.title').text('Benefit')
    } else {
      $('.cov-ben').find('.title').text('Coverage/Benefit')
    }
  })

  // for change of tab title in product/edit?tab=general
  $('div.ui.radio.checkbox.pbase').on('click', function () {
    let radio_selected = $(this).find('input:radio').val();
    if (radio_selected == 'Exclusion-based') {
      $('#cov-ben-edittab').text('Coverage')
    } else if (radio_selected == 'Benefit-based') {
      $('#cov-ben-edittab').text('Benefit')
    } else {
      $('#cov-ben-edittab').text('Coverage/Benefit')
    }
  })

  /////////////////////////////// product base is now excluded to general step1 asof 06132018
  // for opening of modal product_base with populating modal span
  // $('.eb').on('change', function(){
  //   if(this.checked){
  //     if( $(this).attr('role') == 'Benefit-based' ) {
  //       $('.notChecked').text('Exclusion-based')
  //       $('.radioChecked').text('Benefit-based')
  //       $('#product_base_confirmation').modal('show');
  //     }
  //   }
  // })

  // $('.bb').on('change', function(){
  //   if(this.checked){
  //     if( $(this).attr('role') == 'Exclusion-based' ) {
  //       $('.notChecked').text('Benefit-based')
  //       $('.radioChecked').text('Exclusion-based')
  //       $('#product_base_confirmation').modal('show');
  //     }
  //   }
  // })
  /////////////////////////////// product base is now excluded to general step1 asof 06132018

});

onmount('div[id="step6_risk_share"]', function () {
  $('#delete_draft').click(function () {
    let id = $(this).attr('productID');
    $('#dp_product_id').val(id);

    $('#delete_product_confirmation').modal('show');
  });

  $('#dp_cancel').click(function () {
    $('#delete_product_confirmation').modal('hide');
  });

  $('#dp_submit').click(function () {
    let id = $('#dp_product_id').val();

    let csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url: `/products/${id}/delete_all`,
      headers: {
        "X-CSRF-TOKEN": csrf2
      },
      type: 'delete',
      success: function (response) {
        let obj = JSON.parse(response)
        window.location.replace('/products')
      }
    });
  });
});

onmount('div[id="step7_summary"]', function () {
  $('#delete_draft').click(function () {
    let id = $(this).attr('productID');
    $('#dp_product_id').val(id);

    $('#delete_product_confirmation').modal('show');
  });

  $('#dp_cancel').click(function () {
    $('#delete_product_confirmation').modal('hide');
  });

  $('#dp_submit').click(function () {
    let id = $('#dp_product_id').val();

    let csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url: `/products/${id}/delete_all`,
      headers: {
        "X-CSRF-TOKEN": csrf2
      },
      type: 'delete',
      success: function (response) {
        let obj = JSON.parse(response)
        window.location.replace('/products')
      }
    });
  });
  let im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () {
      self.Value('');
    }
  })
  im.mask($('#limit_amount'));
  im.mask($('#smp_limit'));
});

onmount('div[id="showProduct"]', function () {
  let im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () {
      self.Value('');
    }
  })
  im.mask($('#limit_amount'));
  im.mask($('#smp_limit'));
})
onmount('div[id="showSummary"]', function () {
  let im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () {
      self.Value('');
    }
  })
  im.mask($('#limit_amount'));
})
onmount('div[id="product_index_page"]', function () {
  let table = $('table[role="datatable"]').DataTable({
    dom: "<'ui grid'" +
      "<'row'" +
      "<'eight wide column'l>" +
      "<'right aligned eight wide column'f>" +
      ">" +
      "<'row dt-table'" +
      "<'sixteen wide column'tr>" +
      ">" +
      "<'row'" +
      "<'six wide column'i>" +
      "<'right aligned ten wide column'p>" +
      ">" +
      ">",
    renderer: 'semanticUI',
    pagingType: "full_numbers",
    language: {
      emptyTable: "No Records Found!",
      zeroRecords: "No Records Found!",
      search: "Search",
      paginate: {
        first: "<i class='angle single left icon'></i> First",
        previous: "<i class='angle double left icon'></i> Previous",
        next: "Next <i class='angle double right icon'></i>",
        last: "Last <i class='angle single right icon'></i>"
      }
    }
  });
  $('input[type="search"]').unbind('on').on('keyup', function () {
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url: `/products/load_datatable`,
      headers: {
        "X-CSRF-TOKEN": csrf2
      },
      type: 'get',
      data: {
        params: {
          "search_value": $(this).val().trim(),
          "offset": 0
        }
      },
      dataType: 'json',
      success: function (response) {
        table.clear()
        let dataSet = []
        for (let i = 0; i < response.product.length; i++) {
          table.row.add([
            check_product_step(response.product[i]),
            check_product_name(response.product[i].name, response.product[i].description, "name"),
            check_product_name(response.product[i].name, response.product[i].description, "description"),
            response.product[i].classification,
            response.product[i].created_by,
            response.product[i].date_created,
            response.product[i].updated_by,
            response.product[i].date_updated
          ]).draw();
        }
      }
    })
  })
  $('.dataTables_length').find('.ui.dropdown').on('change', function () {
    if ($(this).find('.text').text() == 100) {
      let info = table.page.info();
      if (info.pages - info.page == 1) {
        let search_value = $('.dataTables_filter input').val();
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url: `/products/load_datatable`,
          headers: {
            "X-CSRF-TOKEN": csrf2
          },
          type: 'get',
          data: {
            params: {
              "search_value": search_value.trim(),
              "offset": info.recordsTotal
            }
          },
          dataType: 'json',
          success: function (response) {
            let dataSet = []
            for (let i = 0; i < response.product.length; i++) {
              table.row.add([
                check_product_step(response.product[i]),
                check_product_name(response.product[i].name, response.product[i].description, "name"),
                check_product_name(response.product[i].name, response.product[i].description, "description"),
                response.product[i].classification,
                response.product[i].created_by,
                response.product[i].date_created,
                response.product[i].updated_by,
                response.product[i].date_updated
              ]).draw(false);
            }
          }
        })
      }
    }
  })
  let info
  table.on('page', function () {
    info = table.page.info();
    if (info.pages - info.page == 1) {
      let search_value = $('.dataTables_filter input').val();
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url: `/products/load_datatable`,
        headers: {
          "X-CSRF-TOKEN": csrf2
        },
        type: 'get',
        data: {
          params: {
            "search_value": search_value.trim(),
            "offset": info.recordsTotal
          }
        },
        dataType: 'json',
        success: function (response) {
          let dataSet = []
          for (let i = 0; i < response.product.length; i++) {
            table.row.add([
              check_product_step(response.product[i]),
              check_product_name(response.product[i].name, response.product[i].description, "name"),
              check_product_name(response.product[i].name, response.product[i].description, "description"),
              response.product[i].classification,
              response.product[i].created_by,
              response.product[i].date_created,
              response.product[i].updated_by,
              response.product[i].date_updated
            ]).draw(false);
          }
        }
      })
    }
  });

  function check_product_step(product) {
    if (product.step == "8") {
      if (product.facility_access == true) {
        return `<a href="/products/${product.id}/revert_step/4">${product.code} (Draft/Step 4)</a>`
      } else {
        return `<a href="/web/products/${product.id}">${product.code}</a>`
      }
    } else {
      return `<a href="/products/${product.id}/setup?step=${product.step}">${product.code} (Draft)</a>`
    }
  }

  function check_product_name(name, description, type) {
    if (name == null) {
      return "(Copy / Draft)"
    } else {
      if (type == "name") {
        return name
      } else {
        return description
      }
    }
  }

})
