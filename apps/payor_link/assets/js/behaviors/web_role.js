onmount('div[name="main_role_form"]', function () {
  if ($('.auth-permission').is(':checked')) {
    $('.coverage-amount-table').css('display', 'table')
  }
  else {
    $('.coverage-amount-table')
      .css('display', 'none')
      .find('input')
      .val(0)
  }

  $('.authorization-row').on('click', function() {
    if ($('.auth-permission').is(':checked')) {
      $('.coverage-amount-table').css('display', 'table')
      $('#approval_limit').css('display', '')
    }
    else {
      $('.coverage-amount-table')
        .css('display', 'none')
      $('#approval_limit')
        .css('display', 'none')
        .find('input')
        .val(0)
    }
  })

  if ($('.user-full-access').is(':checked')) {
    $('.create-user-by').css('display', 'block')
      let full_access = $('.create-user-by').find('input').val()
      $('input[name="role[hidden_create_full_access]"]').val(full_access)
  }
  else {
    $('.create-user-by').css('display', 'none')
    $('.radio-access').prop('checked', false)
    $('input[name="role[hidden_create_full_access]"]').val('')
  }

  $('.approval-label')
    .css('display', 'none')

  if ($('.readonly').is(':checked') || $('.notallowed').is(':checked')) {
    $('#cutOffDateContainer').css({"display": "none"});
    $('#upload_days').css({"display": "none"});
    $('#role_no_of_days').val('')
    $('input[name="role[cut_off_dates][]"]').val('')
    $('#role_no_of_days').val(99)
    $('input[name="role[cut_off_dates][]"]').val(99)
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

  const maskDates = new Inputmask("numeric", {
    allowMinus:false,
    rightAlign: false
  })

  maskDates.mask($('#role_no_of_days'))
  maskDates.mask($('input[name="role[cut_off_dates][]"]'))

  $('.approval-limit-amount').each(function(){
    maskDecimal.mask($(this))
  })
  // maskDecimal.mask($('#role_approval_limit_amount'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][Cancer]"]'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][Dental]"]'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][Emergency]"]'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][Inpatient]"]'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][Maternity]"]'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][Medicine]"]'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][OP Consult]"]'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][OP Laboratory]"]'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][Optical]"]'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][PEME]"]'))
  // maskDecimal.mask($('input[name="role[approval_limit_amount][RUV]"]'))


  $('.select-application').on('change', function(){
    if($('select#role_application_id option:selected').text() == "PayorLink"){
      $('.member-permitted').css('display', 'block')
      $('.disease-readonly').attr('checked', true)
      $('.disease-not-allowed').attr('checked', false)
      $('.disease-readonly').attr('disabled', false)
      $('.disease-readonly').addClass('disabled')
    }
    else{
      $('.member-permitted').css('display', 'none')
      $('.member-permitted').attr('checked', false)
      $('.disease-not-allowed').attr('checked', true)
      $('.disease-readonly').attr('checked', false)
      $('.disease-readonly').attr('disabled', true)
      $('.disease-readonly').addClass('disabled')
    }
  })


  let csrf = $('input[name="_csrf_token"]').val();
  let roleName = $('input[type="text"][name="role[name]"]').val()

  $.ajax({
    url:`/web/roles/load/role_name`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let data = JSON.parse(response);

      let array = $.map(data, function(value, index) {
        return [value.name.toLowerCase()];
      });

      $.fn.form.settings.rules.checkRole = function(param) {
        return array.indexOf(param.toLowerCase()) == -1 ? true : false;
      }
      array.splice($.inArray(roleName.toLowerCase(), array),1)
      $.fn.form.settings.rules.checkEditRole = function(param) {
        let hiddenRole = $('.hidden-role-name').val().toLowerCase()
          console.log(hiddenRole)
        // console.log($.inArray(param.toLowerCase(), array))
        // console.log(array)
        // console.log(param.toLowerCase() == hiddenRole)
       // return array.indexOf(param.toLowerCase()) == -1 && hiddenRole == param.toLowerCase() ? true : false;
        return $.inArray(param.toLowerCase(), array) == -1 ? true : false;
      }

      $.fn.form.settings.rules.checkLimitAmount = function(param) {
        return param != "" ? true : false
      }

      $('#formBasicRole').form({
        on: blur,
        inline: true,
        fields: {
          'role[name]': {
            identifier: 'role[name]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Role Title'
            },
            {
              type   : 'checkRole[param]',
              prompt : 'Name already exists!'
            }
            ]
          },
          'role[application_ids][]': {
            identifier: 'role[application_ids][]',
            rules: [{
              type  : 'empty',
              prompt: 'Please select atleast one application'
            }
            ]
          },
          'role[description]': {
            identifier: 'role[description]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Role Description'
            }
            ]
          },
          'role[no_of_days]': {
            identifier: 'role[no_of_days]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter number of days'
            }
            ]
          }
        },
        onInvalid: _ => {
          $('.div_limit_amount').each(function() {
            $(this)
              .find('.ui.pointing.red.label')
              .text("Please enter a Limit Amount")
          })
        }
      });
      $('.txt_limit_amount').each(function() {
        let input_name = $(this).attr('name')
        $('#formBasicRole')
          .form(
            'add rule',
            input_name,
            'checkLimitAmount[param]'
          )
      })

      $('#formEditRole').form({
        on: blur,
        inline: true,
        fields: {
          'role[name]': {
            identifier: 'role[name]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Role Title'
            },
            {
              type   : 'checkEditRole[param]',
              prompt : 'Name already exists!'
            }
            ]
          },
          'role[application_ids][]': {
            identifier: 'role[application_ids][]',
            rules: [{
              type  : 'empty',
              prompt: 'Please select atleast one application'
            }
            ]
          },
          'role[description]': {
            identifier: 'role[description]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Role Description'
            }
            ]
          },
          'role[no_of_days]': {
            identifier: 'role[no_of_days]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter number of days'
            }
            ]
          },
          'role[cut_off_dates][]': {
            identifier: 'role[cut_off_dates][]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter Cut-Off Date'
            }
            ]
          }
        },
        onInvalid: _ => {
          $('.div_limit_edit_amount').each(function() {
            $(this)
              .find('.ui.pointing.red.label')
              .text("Please enter a Limit Amount")
          })
        }
      });
      $('.txt_limit_edit_amount').each(function() {
        let input_name = $(this).attr('name')
        $('#formEditRole')
          .form(
            'add rule',
            input_name,
            'checkLimitAmount[param]'
          )
      })
    }
  })

  $('.open-table').click(function() {
    $('.coverage-amount-table').css('display', 'table').find('input').val('')
    $('.approval-label').css('display', 'block')
  })

  $('.close-table').click(function() {
    $.each( $('.div_limit_amount') , function() {
      $(this).removeClass("error")

      $(this)
        .find('.ui.red.pointing.label.transition')
        .remove()
    })

    $('.coverage-amount-table')
      .css('display', 'none')
      .find('input')
      .val(0)
    $('.approval-label').css('display', 'none')

  })

  $('.close-table').click(function() {
    $.each( $('.div_limit_edit_amount') , function() {
      $(this).removeClass("error")

      $(this)
        .find('.ui.red.pointing.label.transition')
        .remove()
    })

    $('.coverage-amount-table')
      .css('display', 'none')
      .find('input')
      .val(0)
    $('.approval-label').css('display', 'none')

  })

  $('.user-full-access').click(function() {
    $('.create-user-by').css('display', 'block')
  })
    $('.create-user-by').click(function() {
      let full_access = $(this).find('input').val()
      $('input[name="role[hidden_create_full_access]"]').val(full_access)
    })

  $('.user-not-allowed').click(function() {
    $('.create-user-by')
        .css('display', 'none')
        .prop('disabled', true)
    $('input[name="role[hidden_create_full_access]"]').val('')
  })

  const check_cutoff_dates = _ => {
    let input_full_access_val = $('input[name="role[user_access_permissions]"][value="manage_user_access"]').is(":checked")

    if(input_full_access_val) {
    let values = []
    $('.reporting-cutoff').each(function() {
      values.push(
        $(this).val()
      )
    })

    $('.reporting-cutoff').each(function() {
      let current_value = $(this).val()

      values.splice($.inArray(current_value, values), 1)

      let is_included = $.inArray(
        current_value,
        values
      )

      if(current_value == "") {
        if($(this).hasClass('reporting-to-primary')) {
          $('#formBasicRole').form(
            'add prompt',
            $(this).attr('name'),
            'Please enter Cut-Off Date.'
          )
        } else {
          $(this)
            .closest('.field')
            .addClass('error')
            .find('.error-msg')
            .html(
              '<div class="ui basic red pointing prompt label transition visible">This is a required field.</div>'
            )
            .fadeIn('fast')
        }
      } else {
        if(is_included > -1) {
          if($(this).hasClass('reporting-to-primary')) {
            $('#formBasicRole').form(
              'add prompt',
              $(this).attr('name'),
              'Number has been duplicated!'
            )
          } else {
            $(this)
              .closest('.field')
              .addClass('error')
              .find('.error-msg')
              .html(
                '<div class="ui basic red pointing prompt label transition visible">Number has been duplicated!</div>'
              )
              .fadeIn('fast')
          }
        } else {
          if($(this).hasClass('reporting-to-primary')) {
            $('#formBasicRole').form(
              'remove prompt',
              $(this).attr('name'),
              'Number has been duplicated!'
            )
          } else {
            $(this)
              .closest('.field')
              .removeClass('error')
              .find('.error-msg')
              .html(
                ''
              )
              .fadeOut('fast')
          }
        }
      }

      if(current_value == "") {
        if($(this).hasClass('reporting-to-primary')) {
          $('#formEditRole').form(
            'add prompt',
            $(this).attr('name'),
            'Please enter Cut-Off Date.'
          )
        } else {
          $(this)
            .closest('.field')
            .addClass('error')
            .find('.error-msg')
            .html(
              '<div class="ui basic red pointing prompt label transition visible">This is a required field.</div>'
            )
            .fadeIn('fast')
        }
      } else {
        if(is_included > -1) {
          if($(this).hasClass('reporting-to-primary')) {
            $('#formEditRole').form(
              'add prompt',
              $(this).attr('name'),
              'Number has been duplicated!'
            )
          } else {
            $(this)
              .closest('.field')
              .addClass('error')
              .find('.error-msg')
              .html(
                '<div class="ui basic red pointing prompt label transition visible">Number has been duplicated!</div>'
              )
              .fadeIn('fast')
          }
        } else {
          if($(this).hasClass('reporting-to-primary')) {
            $('#formEditRole').form(
              'remove prompt',
              $(this).attr('name'),
              'Number has been duplicated!'
            )
          } else {
            $(this)
              .closest('.field')
              .removeClass('error')
              .find('.error-msg')
              .html(
                ''
              )
              .fadeOut('fast')
          }
        }
      }

      values.push(current_value)
    })
    } else {
      $('.reporting-cutoff').each(function() {
        let container = $(this).closest('.field')
        container.removeClass("error")

        container
          .find('.ui.basic.red.pointing.prompt.label.transition.visible')
          .remove()
      })

      $('#upload_days')
          .find('.ui.basic.red.pointing.prompt.label.transition.visible')
          .remove()
    }
  }

  $(document).on('keyup', '.reporting-cutoff', function() {
    check_cutoff_dates()
  })

  $('#formBasicRole').submit( _ => {
    check_cutoff_dates()
    check_user_access()
    return $('.ui.red.pointing.label.transition').length == 0 ? true : false
  })

  const remove_user_access_error = _ => {
    $('.create-user-by').each(function() {
      $(this)
        .find('.ui.basic.red.pointing.prompt.label.transition.visible')
        .remove()

      $(this)
        .closest('.field')
        .removeClass('error')
    })
  }

  const check_user_access = _ => {
    remove_user_access_error()
    if( $('input[name="role[users_permissions]"][value="manage_users"]').is(':checked')  ) {
      let val_array = []
      $('.create-user-by').each(function() {
        $(this)
          .find('.ui.basic.red.pointing.prompt.label.transition.visible')
          .remove()
        let input = $(this).find('input')
        let is_valid = input.is(':checked')

        if(!is_valid) {
          $(this)
            .closest('.field')
            .addClass('error')
            .find('.create-user-by')
            .append('<div class="ui basic red pointing prompt label transition visible">Please Select One</div>')
        }

        val_array.push (
          is_valid
        )
      })
      if(val_array.includes(true)) {
        remove_user_access_error()
      }
    }
  }

  $('#formEditRole').submit( _ => {
    check_cutoff_dates()
    check_user_access_edit()
    return $('.ui.red.pointing.label.transition').length == 0 ? true : false
  })

  const remove_user_error = _ => {
    $('.create-user-by').each(function() {
      $(this)
        .find('.ui.basic.red.pointing.prompt.label.transition.visible')
        .remove()

      $(this)
        .closest('.field')
        .removeClass('error')
    })
  }

  const check_user_access_edit = _ => {
    remove_user_error()
    if( $('input[name="role[users_permissions]"][value="manage_users"]').is(':checked')  ) {
      let val_array = []
      $('.create-user-by').each(function() {
        $(this)
          .find('.ui.basic.red.pointing.prompt.label.transition.visible')
          .remove()
        let input = $(this).find('input')
        let is_valid = input.is(':checked')

        if(!is_valid) {
          $(this)
            .closest('.field')
            .addClass('error')
            .find('.create-user-by')
            .append('<div class="ui basic red pointing prompt label transition visible">Please choose Application</div>')
        }

        val_array.push (
          is_valid
        )
      })
      if(val_array.includes(true)) {
        remove_user_error()
      }
    }
  }

  $('.add-cut-off-date').on('click', function(){
  	let text_box = `
  		<div class="field txtbox-cut-off">
  			<br>
	  		<div class="ui search">
				  <div class="ui icon input">
					  <input type="text" maxlength="2" class="prompt email reporting-to-secondary reporting-cutoff" name="role[cut_off_dates][]">
					  <i class="inverted circular green active minus link icon remove-cut-off-date"></i>
				  </div>
				  <div class="results"></div>
				</div>
        <div class="error-msg hidden"></div>
			</div>`
    $('#cutOffDateContainer').append(text_box)
  })

	$('body').on('click', '.remove-cut-off-date', function() {
    $(this).closest('.txtbox-cut-off').remove()
  })

  $('#draft_button').click(function() {
      $('.modal_role_confirmation')
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
            of creation of this role which can be continued later.`)
          $('#confirmation-question').text('Do you want to save this as draft?')

          $('input[name="role[is_draft]"]').val('true')
        },
        onApprove: () => {
          $('#formBasicRole').submit()
          return false
        },
        onDeny: () => {
          $('input[name="role[is_draft]"]').val('')
        }
      })
      .modal('show')
  })

  $('#draft_button2').click(function() {
      $('.modal_role_confirmation')
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
            of creation of this role which can be continued later.`)
          $('#confirmation-question').text('Do you want to save this as draft?')

          $('input[name="role[is_draft]"]').val('true')
        },
        onApprove: () => {
          $('#formEditRole').submit()
          return false
        },
        onDeny: () => {
          $('input[name="role[is_draft]"]').val('')
        }
      })
      .modal('show')
  })
});

  onmount('div[class="clicker"]', function () {
    $('.clicker').click(function() {
      $(this)
        .find('input')
        .prop('checked', true)
    })
  })

  onmount('div[class="clicker readonly-user-access"]', function() {
      $('#cutOffDateContainer').css({"display": "none"});
    let upload_days = $('#upload_sample').val()
     if(upload_days == "checked") {
      $('#upload_days').css({"display": "block"});
      $('#cutOffDateContainer').css({"display": "block"});
      } else {
      $('#upload_days').css({"display": "none"});
      $('#cutOffDateContainer').css({"display": "none"});
    }

    $('.readonly-user-access').click(function(){
      $('#cutOffDateContainer').css({"display": "none"});
      $('#upload_days').css({"display": "none"});
      $('#cutOffDateContainer').prop('disabled', true);
      $('#upload_days').prop('disabled', true);
      $('#role_no_of_days').val('')
      $('input[name="role[cut_off_dates][]"]').val('')
      $('#role_no_of_days').val(99)
      $('input[name="role[cut_off_dates][]"]').val(99)
    })
    $('.not-allowed-user-access').click(function(){
      $('#cutOffDateContainer').css('display', 'none');
      $('#upload_days').css('display', 'none');
      $('#cutOffDateContainer').prop('disabled', true);
      $('#upload_days').prop('disabled', true);
      $('#role_no_of_days').val('')
      $('input[name="role[cut_off_dates][]"]').val('2')
      $('#role_no_of_days').val(99)
      $('input[name="role[cut_off_dates][]"]').val(99)
    })
    $('.full-access-user-access').click(function(){
      let cut_off = $('.hidden-cut-off-date').val()
      $('#role_no_of_days').val(cut_off)
      $('input[name="role[cut_off_dates][]"]').val(cut_off)
      $('#cutOffDateContainer').css({"display": "block"});
      $('#upload_days').css({"display": "block"});
    })
  })

  onmount('.select-application', function() {
    $('.a').css('display', 'none')
    $('.disease-readonly').prop('checked', true)
          $('.disease-readonly').prop('checked', true)
      $( ".select-application" )
        .closest('.ui.dropdown')
        .dropdown({
          onChange: (value, text, $choice) => {
            if(text == "ProviderLink") {
            // show form
              $('.a').css('display', '')
              $('.b').css('display', 'none')
              $('.b').prop('disabled', '')
            } else {
            // hide form
              $('.a').css('display', 'none')
              $('.b').css('display', '')
              $('.disease-readonly').prop('checked', true)
            }
          }
      })
  })

  onmount('.select-web-application', function() {
      let starting_value = $( ".select-web-application" ).dropdown('get text')
          $('.a').css('display', 'none')
            if(starting_value == "ProviderLink") {
            // show form
              $('.a').css('display', '')
              $('.b').css('display', 'none')
              $('.b').prop('disabled', '')
            } else {
            // hide form
              $('.a').css('display', 'none')
              $('.b').css('display', '')
              $('.disease-readonly').prop('checked', true)
            }
  })

  onmount('#show_swal_role', function () {
    swal({
      icon: "success",
      title: 'Role Successfully Created!',
      text: 'Do you want to create another role?',
      type: 'success',
      allowOutsideClick: true,
      showCancelButton: true,
      confirmButton: true,
      confirmButtonText: 'Yes',
      cancelButtonText: 'No',
      confirmButtonClass: 'ui primary green button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false
    }).then(function (value) {
        if (value == true) {
            window.location.href = '/web/roles/new'
      } else {
            window.location.href = '/web/roles'
      }
    })
  })

  onmount('.cancel_button_role', function () {
  $('.cancel_button_role').click(function() {
  swal({
    title: 'Are you sure you want to discard this role?',
    text: "Deleting this draft will permanently remove this from the system.",
    type: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Yes, Discard Role',
    cancelButtonText: 'No, Keep Role',
    confirmButtonClass: 'ui red button',
    cancelButtonClass: 'ui button',
    buttonsStyling: false
  }).then(function(result) {
      if (result == true) {
            $('#delete-draft-role').submit()
      } else {
            window.location.href = '/web/roles/new'
        }
      })
    })
  })

  $('#role_cancel_button').click(function() {
  swal({
    title: 'Are you sure you want to discard this role?',
    text: "Deleting this draft will permanently remove this from the system.",
    type: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Yes, Discard Role',
    cancelButtonText: 'No, Keep Role',
    confirmButtonClass: 'ui red button',
    cancelButtonClass: 'ui button',
    buttonsStyling: false
  }).then(function(result) {
      if (result == true) {
            window.location.href = '/web/roles'
      } else {
            window.location.href = '/web/roles/new'
        }
      })
    })

  // onmount('.cancel_button_role', function () {
  // $('.cancel_button_role').click(function() {
  // swal({
  //   title: 'Are you sure you want to discard this role?',
  //   text: "Deleting this draft will permanently remove this from the system.",
  //   type: 'warning',
  //   showCancelButton: true,
  //   confirmButtonText: 'Yes, Discard Role',
  //   cancelButtonText: 'No, Keep Role',
  //   confirmButtonClass: 'ui red button',
  //   cancelButtonClass: 'ui button',
  //   buttonsStyling: false
  // }).then(function(result) {
  //     if (result == true) {
  //           window.location.href = '/web/roles'
  //     } else {
  //           window.location.href = '/web/roles/new'
  //       }
  //     })
  //   })
  // })

  onmount('#show_swal_update', function () {
  $('#show_swal_update').click(function() {
  swal({
    title: 'Are you sure you want to update role information?',
    type: 'warning',
    showCancelButton: true,
    confirmButtonText: ' Yes, Update Role',
    cancelButtonText: 'No, Keep Role Information',
    confirmButtonClass: 'ui primary green button',
    cancelButtonClass: 'ui button',
    buttonsStyling: false
  }).then(function(result) {
      if (result == true) {
          $('#formEditRole').submit()
        }
      })
    })
  })

  onmount('.web-role-show', function (){
    if($('.create-user-header').attr('createUser') == ""){
      $('.create-user-header').css({"display": "none"})
      $('.create-user-data').css({"display": "none"})
    }
    else {
      $('.create-user-header').css({"display": "block"})
      $('.create-user-data').css({"display": "block"})
    }
  })

  onmount('.web-role-show', function (){
    if($('.create-user-header').attr('createUser') == ""){
      $('.create-user-header').css({"display": "none"})
      $('.create-user-data').css({"display": "none"})
    }
    else {
      $('.create-user-header').css({"display": "block"})
      $('.create-user-data').css({"display": "block"})
    }
  })
//   onmount('.admin-role', function () {
//     $('.user-full-access').on('click', function () {
//       $('.web-role-show').css({"display", "block"})

//     else {
//       $('.web-role-show').prop({"disabled", true})
//     }
//   })

