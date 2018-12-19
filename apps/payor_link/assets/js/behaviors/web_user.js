onmount('input[id="show_user_result"]', function(){
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
			onApprove: () => {
				window.location.replace("/web/users/new")
			},
			onDeny: () => {
				window.location.replace("/web/users")
			}
		})
		.modal('show')
});

onmount('div[id="newUser"]', function(){

  $.fn.form.settings.rules.mobileChecker = function(param) {
    let unmasked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmasked_value.length == 11) {
      return true
    } else {
      return false
    }
  }

  $.fn.form.settings.rules.checkExistingUsername = function(param) {
    let valid = true
    if (param != "") {
      $.ajax({
        async: false,
        url:`/web/check_existing_username?username=${param}`,
        type: 'GET',
        success: function(response){
          if (response.valid == true) {
            valid = true
          }  else {
            valid = false
          }
        }
      })
    } else {
      valid = true
    }
    return valid
  }

  $.fn.form.settings.rules.checkExistingMobile = function(param) {
    let current_mobile = $('#currentMobile').val()
    let valid = true
    if (param != "") {
      if (current_mobile == undefined) {
        $.ajax({
          async: false,
          url:`/web/check_existing_user_mobile?mobile=${param}`,
          type: 'GET',
          success: function(response){
            if (response.valid == true) {
              valid = true
            }  else {
              valid = false
            }
          }
        })
      } else {
        $.ajax({
          async: false,
          url:`/web/check_existing_user_mobile?mobile=${param}&current_mobile=${current_mobile}`,
          type: 'GET',
          success: function(response){
            if (response.valid == true) {
              valid = true
            }  else {
              valid = false
            }
          }
        })
      }
    } else {
      valid = true
    }
    return valid
  }

  $.fn.form.settings.rules.checkExistingPayroll = function(param) {
    let current_payroll_code = $('#currentPayroll').val()
    let company_id = $('#companyDropdown').val()
    let valid = true
    if (param != "") {
      if (current_payroll_code == undefined) {
        $.ajax({
          async: false,
          url:`/web/check_existing_user_payroll?payroll_code=${param}&company_id=${company_id}`,
          type: 'GET',
          success: function(response){
            if (response.valid == true) {
              valid = true
            }  else {
              valid = false
            }
          }
        })
      } else {
        $.ajax({
          async: false,
          url:`/web/check_existing_user_payroll?payroll_code=${param}&current_payroll_code=${current_payroll_code}&company_id=${company_id}`,
          type: 'GET',
          success: function(response){
            if (response.valid == true) {
              valid = true
            }  else {
              valid = false
            }
          }
        })
      }
    } else {
      valid = true
    }
    return valid
  }

  $.fn.form.settings.rules.checkExistingEmail = function(param) {
    let current_email = $('#currentEmail').val()
    let valid = true
    if (param != "") {
      if (current_email == undefined) {
        $.ajax({
          async: false,
          url:`/web/check_existing_user_email?email=${param}`,
          type: 'GET',
          success: function(response){
            if (response.valid == true) {
              valid = true
            }  else {
              valid = false
            }
          }
        })
      } else {
        $.ajax({
          async: false,
          url:`/web/check_existing_user_email?email=${param}&current_email=${current_email}`,
          type: 'GET',
          success: function(response){
            if (response.valid == true) {
              valid = true
            }  else {
              valid = false
            }
          }
        })
      }
    } else {
      valid = true
    }
    return valid
  }

  const csrf = $('input[name="_csrf_token"]').val()

  let role_application = $('input[name="role_application"]').val();
  let acu_schedule_permission = $('input[name="acu_schedule_permission"]').val()

  if(role_application == "ProviderLink" && acu_schedule_permission == "Full Access") {
    $('#acu_sched_notify').removeClass('hidden')
    $('.other_app').addClass('hidden')
    $('.provider_app').removeClass('hidden')

    $('#companyDropdown').dropdown('clear')
		$('.other_app')
		  .find('input')
  		.each(function () {
	  		$(this).val('')
			})

  	initializeFacilityDropdown()
	  $('#facility_dropdown').dropdown('show')

    initializeProviderLinkValidation()
  }
  else if(role_application == "ProviderLink" && acu_schedule_permission != "Full Access") {
    $('#acu_sched_notify').addClass('hidden')
    $('.other_app').addClass('hidden')
    $('.provider_app').removeClass('hidden')

    $('#companyDropdown').dropdown('clear')
		$('.other_app')
		  .find('input')
  		.each(function () {
	  		$(this).val('')
			})

  	initializeFacilityDropdown()
	  $('#facility_dropdown').dropdown('show')

    initializeProviderLinkValidation()
  }
  else {
    $('#acu_sched_notify').addClass('hidden')
    $('.other_app').removeClass('hidden')
    $('.provider_app').addClass('hidden')

    $('#facility_id').dropdown('clear')

    initializeNormalValidation()
  }

  $('#userFormSubmit').click(function() {

    let validate_form = $('#userForm').form('validate form')

    if(validate_form) {
      let valid = validateReportingTo()
      if (valid == false) {
        event.preventDefault()
      }
      else{
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
            $('#confirmation-header').text('Update User')
            $('#confirmation-description').text(`Are you sure you want to update user information?`)
            $('#confirmation-question').text('')
            $('.confirmation_deny').text('No, Keep User Information')
            $('.confirmation_approve').text('Yes, Update Information')
          },
          onApprove: () => {
            $('#userForm').submit()
          }
        })
        .modal('show')
      }
    }
  })

	$('body').on('click', '.remove-role', function() {
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
					$('#confirmation-header').text('Delete Role?')
					$('#confirmation-description').text(`Removing this role will permanently delete this from the table.`)
					$('#confirmation-question').text('Do you want to delete this role?')
				},
				onApprove: () => {
					$('#roleBody').html('')
					$('#roleID').val('')

					$('.other_app').removeClass('hidden')
					$('.provider_app').addClass('hidden')

					$('#acu_sched_notify').addClass('hidden')
					$('#facility_id').val('')
				}
			})
			.modal('show')
	})

	function initializeNormalValidation(){
		// Validation for PayorLink, AccountLink, MemberLink, RegistrationLink
		$('#userForm').form({
			inline: true,
			fields: {
				'user[username]': {
					identifier: 'user[username]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter Username'
						},
						{
							type   : 'minLength[8]',
							prompt : 'Username must be at least 8 characters'
						},
						{
							type   : 'checkExistingUsername[param]',
							prompt : 'Username already taken'
						},
						{
							type   : 'regExp[/^[A-Z0-9a-z._-]*$/]',
							prompt  : 'Special character allows dot(.), underscore(_) and hypen(-) only'
						}
					]
				},
				'user[email]': {
					identifier: 'user[email]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter Email Address'
						},
						{
							type: 'email',
							prompt: 'Please enter a valid Email Address'
						},
						{
							type   : 'checkExistingEmail[param]',
							prompt : 'Email already exists'
						}
					]
				},
				'user[mobile]': {
					identifier: 'user[mobile]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter Mobile Number'
						},
						{
							type: 'mobileChecker[param]',
							prompt: 'Mobile Number must be 11 digits'
						},
						{
							type   : 'checkExistingMobile[param]',
							prompt : 'Mobile Number already exist'
						}
					]
				},
				'user[first_name]': {
					identifier: 'user[first_name]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter First Name'
						}
					]
				},
				'user[last_name]': {
					identifier: 'user[last_name]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter Last Name'
						}
					]
				},
				'user[company_id]': {
					identifier: 'user[company_id]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter Company Name'
						}
					]
				},
				'user[payroll_code]': {
					identifier: 'user[payroll_code]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter Payroll Code'
						},
						{
							type   : 'checkExistingPayroll[param]',
							prompt : 'Payroll Code already exist'
						}
					]
				},
				'user[role_id]': {
					identifier: 'user[role_id]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please select a role'
						}
					]
				}
			},
			onSuccess: function(event, fields) {
				let valid = validateReportingTo()
				if (valid == false) {
					event.preventDefault()
				}
			}
		})
	}

	function initializeFacilityDropdown() {
		$('#facility_dropdown')
			.dropdown({
				apiSettings: {
					url: `/web/users/load_facilities`,
					cache: false
				},
				filterRemoteData: true,
				onShow: () => {
					if($('#current_facility_id').length > 0) {
						let facility_val = $('#current_facility_id').val()

						$('#facility_dropdown').dropdown('set selected', facility_val)
						setTimeout(() => {
							$('#facility_dropdown').dropdown('hide')
						}, 500)

						$('#current_facility_id').remove()
					}
				}
			})
	}

	function initializeProviderLinkValidation(){
		// Validation for ProviderLink
		$('#userForm').form({
			inline: true,
			fields: {
				'user[username]': {
					identifier: 'user[username]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter Username'
						},
						{
							type   : 'minLength[8]',
							prompt : 'Username must be at least 8 characters'
						},
						{
							type   : 'checkExistingUsername[param]',
							prompt : 'Username already taken'
						},
						{
							type   : 'regExp[/^[A-Z0-9a-z._-]*$/]',
							prompt  : 'Special character allows dot(.), underscore(_) and hypen(-) only'
						}
					]
				},
				'user[email]': {
					identifier: 'user[email]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter Email Address'
						},
						{
							type: 'email',
							prompt: 'Please enter a valid Email Address'
						},
						{
							type   : 'checkExistingEmail[param]',
							prompt : 'Email already exists'
						}
					]
				},
				'user[mobile]': {
					identifier: 'user[mobile]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter Mobile Number'
						},
						{
							type: 'mobileChecker[param]',
							prompt: 'Mobile Number must be 11 digits'
						},
						{
							type   : 'checkExistingMobile[param]',
							prompt : 'Mobile Number already exist'
						}
					]
				},
				'user[first_name]': {
					identifier: 'user[first_name]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter First Name'
						}
					]
				},
				'user[last_name]': {
					identifier: 'user[last_name]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter Last Name'
						}
					]
				},
				'user[facility_id]': {
					identifier: 'user[facility_id]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please enter a facility'
						}
					]
				},
				'user[role_id]': {
					identifier: 'user[role_id]',
					rules: [
						{
							type   : 'empty',
							prompt : 'Please select a role'
						}
					]
				}
			}
		})
	}

	let company_users = []

	$('.reporting-to-primary').keyup(function(){
		$(this).closest('.input').closest('.search').closest('.field').removeClass('error')
		$(this).closest('.input').closest('.search').closest('.field').find('.pointing.prompt').remove()
  })

	$('body').on('keyup', '.reporting-to-secondary',function() {
		$(this).closest('.input').closest('.search').closest('.field').removeClass('error')
		$(this).closest('.input').closest('.search').closest('.field').find('.pointing.prompt').remove()
	})

	// if(!$('#acu_sched_notify').hasClass("hidden")) {
	// 	$('.other_app').addClass('hidden')
	// 	$('.provider_app').removeClass('hidden')

	// 	$('#companyDropdown').dropdown('clear')
	// 	$('.other_app')
	// 		.find('input')
	// 		.each(function () {
	// 			$(this).val('')
	// 		})

	// 	initializeFacilityDropdown()
	// 	$('#facility_dropdown').dropdown('show')

	// 	initializeProviderLinkValidation()
	// } else {
	// 	initializeNormalValidation()
	// }

	function validateReportingTo(){
		let username_array = company_users
		let valid = true
    let valid_secondary = true
    let primary_array = []

    $('.reporting-to-primary').each(function(){
      if ($(this).val() != "") {
        primary_array.push($(this).val())
      }
    })

    $('.reporting-to-secondary').each(function(){
      if ($(this).val() != "") {
        primary_array.push($(this).val())
      }
    })

    function countInArray(array, what) {
      var count = 0
      for (var i = 0; i < array.length; i++) {
        if (array[i] === what) {
            count++
        }
      }
      return count
    }

    $('.reporting-to-primary').each(function(){
      let count = countInArray(primary_array, $(this).val())
      if ($(this).val() != "") {
        username_array = username_array.filter(user => user.username != $('#user_username').val())
        let user = username_array.find(user => user.username == $(this).val())
        if (user == undefined) {
          $(this).closest('.input').closest('.search').closest('.field').removeClass('error')
          $(this).closest('.input').closest('.search').closest('.field').find('.pointing.prompt').remove()
          $(this).closest('.input').closest('.search').closest('.field').addClass('error')
          $(this).closest('.input').closest('.search').closest('.field').append(`<div class="ui basic red pointing prompt label transition visible">Invalid</div>`)
          valid = false
        }
        else {
          if (count > 1) {
            $(this).closest('.input').closest('.search').closest('.field').removeClass('error')
            $(this).closest('.input').closest('.search').closest('.field').find('.pointing.prompt').remove()
            $(this).closest('.input').closest('.search').closest('.field').addClass('error')
            $(this).closest('.input').closest('.search').closest('.field').append(`<div class="ui basic red pointing prompt label transition visible">Existing username. Enter another.</div>`)
            valid = false
          }
          else {
            valid = true
          }
				}
			}
		})

    $('.reporting-to-secondary').each(function(){
			if ($(this).val() != "") {
        username_array = username_array.filter(user => user.username != $('#user_username').val())
        let user = username_array.find(user => user.username == $(this).val())
        if (user == undefined) {
          $(this).closest('.input').closest('.search').closest('.field').removeClass('error')
					$(this).closest('.input').closest('.search').closest('.field').addClass('error')
        	$(this).closest('.input').closest('.search').closest('.field').append(`<div class="ui basic red pointing prompt label transition visible">Invalid</div>`)
					valid_secondary = false
        }
        else {
          valid_secondary = true
        }
      }
    })
    if (valid && valid_secondary){
      return true
    } else{
      return false
    }
	}

	$('.ui.search')
  .search({
		searchFields: ['username'],
    source: company_users,
    maxResults: 5
  })

	if ($('select[name="user[company_id]"]').val() != "") {
    let company_id = $('#companyDropdown').val()
		$.ajax({
	    url:`/web/get_all_company_users?company_id=${company_id}`,
	    type: 'GET',
	    async: false,
	    success: function(response){
				//$('.txtbox-reporting-to').remove()
        company_users = response
				$('.ui.search')
				  .search({
    				searchFields: ['username'],
				    source: company_users,
				    maxResults: 5,
				    minCharacters: 2,
				    searchOnFocus: false
				  })
	    }
	  })
	}

	$('#companyDropdown').change(function(){
		let company_id = $(this).val()
		$.ajax({
	    url:`/web/get_all_company_users?company_id=${company_id}`,
	    type: 'GET',
	    async: false,
	    success: function(response){
				//$('.txtbox-reporting-to').remove()
	    	company_users = response
				$('.ui.search')
				  .search({
    				searchFields: ['username'],
				    source: company_users,
				    maxResults: 5,
				    minCharacters: 2,
				    searchOnFocus: false
				  })
	    }
	  })
  })

	let Inputmask = require('inputmask')
  let im = new Inputmask("0\\999-999-9999", {
    "clearIncomplete": false,
  })

	im.mask($('.mobile'))

  $('.add-role-modal')
		.modal({
			autofocus: false,
			observeChanges: false,
			selector: {
				deny: '.close.button',
				approve: '.approve.button'
			},
			onShow: () => {
				$('.add-role-modal')
					.find('input[type="checkbox"]')
					.prop('checked', false)

				if($('#roleID').val() != undefined) {
					$(`input[roleID="${ $('#roleID').val() }"]`).prop('checked', true)
				}
			},
			onApprove: () => {
				let dt = $('#modal_role_dt').DataTable()
				let rows = dt.rows({ 'search': 'applied' }).nodes()

				let checked_roles = $('input[class="select-role"]:checked', rows).length

				switch(checked_roles) {
					case 0:
						alertify.error('<i class="close icon"></i>Please select one role before submitting.')
						return false
					case 1:
						$('input[class="select-role"]:checked', rows).each(function() {
							let role_id = $(this).attr('roleID')
							let role_name = $(this).attr('rolename')
							let description = $(this).attr('description')
							let applications = $(this).attr('applications')
							let acu_sched_permission = $(this).attr('acu_sched_permission')
							let row = `
								<tr>
									<td>${role_name}</td>
									<td>${applications}</td>
									<td>${description}</td>
									<td class="table-icon--holder">
										<div class="ui icon top right floated pointing dropdown">
											<i class="primary medium ellipsis vertical icon"></i>
											<div class="left menu transition hidden">
												<div class="item remove-role">
													Remove
												</div>
											</div>
										</div>
									</td>
								</tr>
							`
							$('#roleBody').html(row)
							$('#roleID').val(role_id)
							$('#roleHeader').find('.prompt').remove()
							$('.dropdown').dropdown()

              if(applications == "ProviderLink") {
								(acu_sched_permission == "Full Access") ? $('#acu_sched_notify').removeClass('hidden') : $('#acu_sched_notify').addClass('hidden')
								$('#acu_sched_notify')
									.find('input')
									.prop('checked', false)

								$('.other_app').addClass('hidden')
								$('.provider_app').removeClass('hidden')

								$('#companyDropdown').dropdown('clear')
								$('.other_app')
									.find('input')
									.each(function() {
										$(this).val('')
									})

								initializeProviderLinkValidation()
								initializeFacilityDropdown()
							} else {
								$('#acu_sched_notify').addClass('hidden')
								$('.other_app').removeClass('hidden')
								$('.provider_app').addClass('hidden')

								$('#facility_id').dropdown('clear')

								initializeNormalValidation()
							}
						})
						break
					default:
						alertify.error('<i class="close icon"></i>Only one role is allowed.')
						return false
				}
			}
		})
		.modal('attach events', '#btnAddRole', 'show')

  $('.add-reporting-to').on('click', function(){
  	let text_box = `
  		<div class="field txtbox-reporting-to">
  			<br>
	  		<div class="ui search">
				  <div class="ui icon input">
					  <input type="text" class="prompt email reporting-to-secondary" name="user[reporting_to][]" placeholder="Enter lead name">
					  <i class="inverted circular green active minus link icon remove-reporting-to"></i>
				  </div>
				  <div class="results"></div>
				</div>
			</div>`
  	$('#reportToContainer').append(text_box)

		$('.ui.search')
		  .search({
				searchFields: ['username'],
		    source: company_users,
		    maxResults: 5,
				minCharacters: 2,
				searchOnFocus: false
		  })
  })

	$('body').on('click', '.remove-reporting-to', function() {
    $(this).closest('.txtbox-reporting-to').remove()
  })

	$('#deactivateBtn').on('click', function(){
		let user_id = $(this).attr('userID')
	  swal({
	    title: 'Deactivate User?',
	    text: 'Are you sure you want to deactivate user?',
	    type: 'question',
	    showCancelButton: true,
	    cancelButtonText: 'No, don’t deactivate',
	    confirmButtonText: 'Yes, deactivate',
	    cancelButtonClass: 'ui button',
	    confirmButtonClass: 'ui blue button',
      reverseButtons: true,
	    buttonsStyling: false
	  }).then(function () {

      $.ajax({
        url: `/web/users/${user_id}/update_status`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'put',
        data: {user: {action: "Deactivated"}},
        dataType: 'json',
        success: function(response){
        	window.location.href = '/web/users'
        },
        error: function(xhr, status, error) {
          alert('Error deactivating user')
        }
      })

	  }).catch(swal.noop)
  })

  $('#activateBtn').on('click', function(){
		let user_id = $(this).attr('userID')
	  swal({
	    title: 'Reactivate User?',
	    text: 'Are you sure you want to reactivate user?',
	    type: 'question',
	    showCancelButton: true,
	    cancelButtonText: 'No, don’t reactivate',
	    confirmButtonText: 'Yes, reactivate',
	    cancelButtonClass: 'ui button',
	    confirmButtonClass: 'ui blue button',
      reverseButtons: true,
	    buttonsStyling: false
	  }).then(function () {
      $.ajax({
        url: `/web/users/${user_id}/update_status`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'put',
        data: {user: {action: "Active"}},
        dataType: 'json',
        success: function(response){
        	window.location.href = '/web/users'
        },
        error: function(xhr, status, error) {
          alert('Error activating user')
        }
      })

	  }).catch(swal.noop)
	})

	$('.btn_discard').click(_ => {
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
					$('#confirmation-header').text('Discard User?')
					$('#confirmation-description').text(`This will discard all the information you have entered.`)
					$('#confirmation-question').text('Do you want to discard this user?')
				},
				onApprove: () => {
					window.location.replace("/web/users")
				}
			})
			.modal('show')
	})

	$('.btn_draft').click(_ => {
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
					$('#confirmation-header').text('Save as Draft?')
					$('#confirmation-description').text(`This will save all the information you have entered as draft.`)
					$('#confirmation-question').text('Do you want to save this user as draft?')
				},
				onApprove: () => {
					//window.location.replace("/web/users")
					alert('save as draft!')
				}
			})
			.modal('show')
	})
});

onmount('div[id="user_index_page"]', function () {
  $('#users_index').DataTable({
    "ajax": {
      "url": `/web/users/index/data`,
      "type": "get"
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true,
      "columnDefs": [
        {
          "targets": [ 0 ],
          data: function ( row, type, val, meta ) {
            return `<a href="/web/users/${row[0].split('|')[1]}">${row[0].split('|')[0]}</a>`;
          }
        },
        {
          "targets": [ 3 ],
          data: function ( row, type, val, meta ) {
            return `<p><i class="${row[3].split('|')[0]} circle icon"></i>${row[3].split('|')[1]}</p>`;
          }
        },
        {
          "targets": [ 1 ],
          data: function ( row, type, val, meta ) {
            return `${row[1].split('|')[0]} <br> ${row[1].split('|')[1]}`;
          }
        }
      ]
  })

})
