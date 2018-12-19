onmount('div[id="delete_member"]', function() {

  var valArray = []
  $('input:checkbox.selection').on('change', function() {
    var value = $(this).val()

    if (this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value)
      if (index >= 0) {
          valArray.splice(index, 1)
      }
    }

    $('.member_main').val(valArray)

    if ($('.member_main').val() == "") {
      $('#delete_member').addClass('disabled')
    } else {
      $('#delete_member').removeClass('disabled')
    }

    $('.member_main').val(valArray)

    $('#selected_members').html(valArray.length)
  })

  if ($('.member_main').val() == "") {
    $('#delete_member').addClass('disabled')
  } else {
    $('#delete_member').removeClass('disabled')
  }

  $('#select_acu_member').on('change', function() {
    var table = $('#acu_schedule_tablea').DataTable()
    var rows = table.rows({'search': 'applied'}).nodes();

    if ($(this).is(':checked')) {
      $('.selection', rows).each(function() {
        var value = $(this).val()

        if (this.checked) {
          valArray.push(value)
        } else {
          var index = valArray.indexOf(value);
          if (index >= 0) {
            valArray.splice(index, 1)
          }
          valArray.push(value)
        }

        $(this).prop('checked', true)
      })
    } else {
      valArray.length = 0
      $('.selection', rows).each(function() {
        $(this).prop('checked', false)
      })
    }

    $('.member_main').val(valArray)

    if ($('.member_main').val() == "") {
      $('#delete_member').addClass('disabled')
    } else {
      $('#delete_member').removeClass('disabled')
    }

    $('#selected_members').html(valArray.length)
  })

  $('#delete_member').on('click', function() {
    $('#delete_member_form').form('submit')
  })

})

onmount('div[id="new_acu_mobile"]', function() {
  $('#new_acu_schedule_table').DataTable({
    order: []
  })
})

onmount('div[id="new_acu_schedule_form"]', function() {
  $('.discard_acu_schedule').click(function(){
    swal({
      title: 'Delete schedule?',
      text: 'Deleting this schedule will permanently remove this schedule from the system.',
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Schedule',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Schedule',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      showCloseButton: true,
      allowOutsideClick: false
    }).then(function() {
      window.location.href = `/web/acu_schedules`
    }).catch(swal.noop)
  })

 var im = new Inputmask("decimal", {

    min: 0,
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('#acu_schedule_guaranteed_amount'));

  $('#overlay2').css("display", "none");
  $('select[name="acu_schedule[product_code][]"]').dropdown('clear')
  $('select[name="acu_schedule[product_code][]"]').dropdown()
  $('input[id="acu_schedule_member_type"]').prop('checked', false)
  $('select[name="acu_schedule[facility_id]"]').dropdown('clear')
  $('select[name="acu_schedule[facility_id]"]').dropdown()
  $('input[name="acu_schedule[date_from]"]').val("")
  $('input[name="acu_schedule[date_to]"]').val("")
  $('input[name="acu_schedule[no_of_members_val]"]').val("")
  $('input[name="acu_schedule[no_of_guaranteed]"]').val("")

  $('select[name="acu_schedule[account_code]"]').on('change', function() {
    let csrf = $('input[name="_csrf_token"]').val()
    let account_code = $(this).val()

    $.ajax({
      url: `/acu_schedules/get_account_date/${account_code}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response) {

        let end_date = new Date(response.end_date)

        $('#acu_date_from').calendar({
          type: 'date',
          ampm: false,
          minDate: new Date(),
          maxDate: end_date,
          monthFirst: false,
          onChange: function(date, text, mode) {
            date = new Date(date)
            $('#acu_date_to').calendar("set date", date)
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

        $('input[name="acu_schedule[date_from]"]').on('input', function() {
          if ($(this).val() == "") {
            $('input[name="acu_schedule[date_to]"]').prop('disabled', true)
          }
        })

        $('#acu_date_to').calendar({
          type: 'date',
          ampm: false,
          startCalendar: $('#acu_date_from'),
          maxDate: end_date,
          monthFirst: false,
          onChange: function(date, text, mode) {
            $('input[name="acu_schedule[time_from]"]').prop('disabled', false)
            $('input[name="acu_schedule[time_from]"]').val("")
            $('input[name="acu_schedule[time_to]"]').val("")
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

        $('input[name="acu_schedule[date_to]"]').on('input', function() {
          if ($(this).val() == "") {
            $('input[name="acu_schedule[time_from]"]').prop('disabled', true)
            $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
            $('input[name="acu_schedule[time_from]"]').val("")
            $('input[name="acu_schedule[time_to]"]').val("")
          } else {
            $('input[name="acu_schedule[time_from]"]').prop('disabled', false)
          }
        })

        $('#acu_time_from').calendar({
          ampm: false,
          disableMinute: true,
          type: 'time',
          onChange: function(date, text, mode) {
            $('input[name="acu_schedule[time_to]"]').prop('disabled', false)
            //$('#acu_time_to').calendar("set date", date)
            validateTimeTo(date)
          }
        })

        $('input[name="acu_schedule[time_from]"]').on('input', function() {
          if ($('input[name="acu_schedule[time_from]"]').val() == "") {
            $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
            $('input[name="acu_schedule[time_to]"]').val("")
          } else {
            $('input[name="acu_schedule[time_to]"]').prop('disabled', false)
          }
        })
      }
    })
  })

  function validateTimeTo(date) {
    let hello = new Date(date)
    hello.setTime(hello.getTime() + (1*60*60*1000))
    let date_from = $('input[name="acu_schedule[date_from]"]').val()
    let date_to = $('input[name="acu_schedule[date_to]"]').val()
    if (date_from == date_to) {
      $('#acu_time_to').calendar({
        ampm: false,
        type: 'time',
        disableMinute: true,
        minDate: hello
      })
    } else {
      $('#acu_time_to').calendar({
        ampm: false,
        disableMinute: true,
        type: 'time'
      })
    }
  }

    $('#cancel_acu_schedule').on('click', function() {
      swal({
        title: 'Cancel Schedule?',
        text: 'Canceling this schedule will permanently remove it from the system.',
        type: 'warning',
        showCancelButton: true,
        confirmButtonText: '<i class="check icon"></i> Yes, Delete Schedule',
        cancelButtonText: '<i class="remove icon"></i> No, Keep Schedule',
        confirmButtonClass: 'ui button',
        cancelButtonClass: 'ui button',
        buttonsStyling: false,
        reverseButtons: true,
        showCloseButton: true,
        allowOutsideClick: false
      }).then(function() {
        window.location.href = `/acu_schedules`
      }).catch(swal.noop)
    })

    if ($('#acu_schedule_account_code').val() == "") {
      $('#acu_schedule_product_code').dropdown()
      $('div[class="ui search selection dropdown multiple"]').addClass('disabled')
      $('div[class="ui search selection dropdown facility"]').addClass('disabled')
      $('.acu_schedule_member_type').attr('disabled', true)
      $('input[type="text"]').attr('disabled', true)
    }

    $('#acu_schedule_account_code').on('change', function() {
      if ($('#acu_schedule_account_code').val() == "") {
        $('#acu_schedule_product_code').dropdown()
        $('#acu_schedule_product_code').dropdown("clear")
        $('div[class="ui search selection dropdown multiple"]').addClass('disabled')
        $('#acu_schedule_facility_id').dropdown()
        $('#acu_schedule_facility_id').dropdown("clear")
        $('div[class="ui search selection dropdown facility"]').addClass('disabled')
        $('.acu_schedule_member_type').attr('disabled', true)
        $('input[type="text"]').val("")
        $('input[type="text"]').attr('disabled', true)
        $('input[type="number"]').val("")
        $('input[type="number"]').attr('disabled', true)
        $('div[class="ui calendar"]').addClass('disabled')
      } else {
        $('#acu_schedule_product_code').dropdown()
        $('#acu_schedule_product_code').dropdown("clear")
        $('div[class="ui search selection dropdown multiple disabled"]').removeClass('disabled')
        $('#acu_schedule_facility_id').dropdown()
        $('#acu_schedule_facility_id').dropdown("clear")
        $('div[class="ui search selection dropdown facility"]').addClass('disabled')
        $('input[name="acu_schedule[no_of_members_val]"]').removeAttr('disabled')
        $('input[name="acu_schedule[no_of_guaranteed]"]').attr('disabled', true)
        $('input[type="text"]').val("")
        $('input[type="text"]').attr('disabled', true)
        $('input[type="number"]').val("")
        $('input[type="number"]').attr('disabled', true)
        $('div[class="ui calendar"]').addClass('disabled')
      }

      let csrf = $('input[name="_csrf_token"]').val()
      let account_code = $(this).val()

      $.ajax({
        url: `/acu_schedules/get_acu_products/${account_code}`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        success: function(response) {
          const data = JSON.parse(response)
          let product_codes = []
          product_codes.length = 0
          $('#acu_schedule_product_code').html('')
          $('#acu_schedule_product_code').dropdown('clear')
          $('#acu_schedule_product_code').append('<option value="">Select Plan Code</option>')
          for (let code of data) {
            product_codes.push(code)
            $('#acu_schedule_product_code').append(`<option value="${code}">${code}</option>`)
          }
          $('#acu_schedule_product_code').dropdown()
        }
      })
    })

    $('#acu_schedule_product_code').on('change', function() {
      let product_code = $(this).val()
      let account_code = $('#acu_schedule_account_code').val()
      $('#number_of_members').attr('accountCode', account_code)
      $('#number_of_members').attr('productCode', product_code)
      $('#acu_schedule_facility_id').html('')
      $('#acu_schedule_facility_id').dropdown('clear')
      $('input[id="acu_schedule_member_type"]').prop('checked', false)
      $('#acu_schedule_number_of_members_val').val('')

      if ($(this).val().length == 0) {
        $('#acu_schedule_facility_id').dropdown()
        $('#acu_schedule_facility_id').dropdown("clear")
        $('div[class="ui search selection dropdown facility"]').addClass('disabled')
        $('input[type="checkbox"]').attr('disabled', true)
        $('input[name="acu_schedule[no_of_guaranteed]"]').attr('disabled', true)
        $('input[type="number"]').attr('disabled', true)
      } else {
        $('#acu_schedule_facility_id').dropdown()
        $('div[class="ui search selection dropdown facility disabled"]').removeClass('disabled')
        let csrf = $('input[name="_csrf_token"]').val()

        $.ajax({
          url: `/acu_schedules/get_acu/facilities`,
          headers: {"X-CSRF-TOKEN": csrf},
          type: 'get',
          data: {
            params: {
              "product_code": product_code
            }
          },
          success: function(response) {
            const facilities = JSON.parse(response)
            $('#acu_schedule_facility_id').html('')
            $('#acu_schedule_facility_id').dropdown('clear')
            $('#acu_schedule_facility_id').append(`<option value="">Select Facility</option>`)
            for (let facility of facilities) {
              $('#acu_schedule_facility_id').append(`<option value="${facility.facility_id}">${facility.facility_code} | ${facility.facility_name}</option>`)
            }
            $('#acu_schedule_facility_id').dropdown()
          }
        })

        $('#acu_schedule_facility_id').on('change', function() {
          if ($('#acu_schedule_facility_id').dropdown('get value') == null) {
            $('input[id="acu_schedule_member_type"]').prop('checked', false)
            $('#acu_schedule_number_of_members_val').val('')
          } else {
            $('input[type="checkbox"]').removeAttr('disabled')
            $('input[id="acu_schedule_member_type"]').prop('checked', false)
            $('#acu_schedule_number_of_members_val').val('')
          }
          $('#acu_schedule_guaranteed_amount').prop('disabled', false)
          $('input[name="acu_schedule[date_from]"]').prop('disabled', false)
          $('input[name="acu_schedule[date_to]"]').prop('disabled', false)
        })
      }
    })

    const request = (params, facility_id, product_code, account_code) => {
      let csrf = $('input[name="_csrf_token"]').val()
      $.ajax({
        url: `/web/acu_schedules/get_active/members`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        data: {
          params: {
            "facility_id": facility_id,
            "member_type": params,
            "product_code": $('#acu_schedule_product_code').val(),
            "account_code": account_code
          }
        },
        success: function(response) {
          const data = JSON.parse(response)
          $('#acu_schedule_number_of_members_val').val('')
          $('#acu_schedule_number_of_members_val').val(data)
          if ($('#acu_schedule_number_of_members_val').val != "" || parseInt($('#acu_schedule_number_of_members_val').val() != 0)) {
            $('#acu_schedule_no_of_guaranteed').attr('disabled', false)
          } else {
            $('#acu_schedule_no_of_guaranteed').attr('disabled', true)
          }
        }
      })
    }

    $('input[id="acu_schedule_member_type"]').on('change', function() {
      let product_code = $('#acu_schedule_product_code').val()
      let facility_id = $('#acu_schedule_facility_id').val()
      let principal = $('input[name="acu_schedule[principal]"]').prop('checked')
      let dependent = $('input[name="acu_schedule[dependent]"]').prop('checked')
      let account_code = $('#acu_schedule_account_code').val()

      if (principal == true && dependent == false) {
        $('input[type="number"]').removeAttr('disabled')
        request(["Principal"], facility_id, product_code, account_code)
      } else if (principal == false && dependent == true) {
        $('input[type="number"]').removeAttr('disabled')
        request(["Dependent"], facility_id, product_code, account_code)
      } else if (principal == true && dependent == true) {
        $('input[type="number"]').removeAttr('disabled')
        request(["Principal", "Dependent"], facility_id, product_code, account_code)
      } else {
        $('input[name="acu_schedule[no_of_guaranteed]"]').attr('disabled', true)
        $('input[type="number"]').attr('disabled', true)
        request([""], facility_id, product_code, account_code)
      }
    })

    $.fn.form.settings.rules.checkMemberValidate = function(param) {
      if (parseInt($('#acu_schedule_number_of_members_val').val()) < parseInt(param) || parseInt(param) == 0) {
        return false
      } else {
        return true
      }
    }

    $.fn.form.settings.rules.checkNumberOfMembers = function(param) {
      if (parseInt($('#acu_schedule_number_of_members_val').val()) <= 0) {
        return false
      } else {
        return true
      }
    }

  $('#acu_schedule_no_of_guaranteed').on('input', function() {
      if ($('#acu_schedule_no_of_guaranteed').val() == "") {
        $('input[name="acu_schedule[date_from]"]').prop('disabled', true)
        $('input[name="acu_schedule[date_to]"]').prop('disabled', true)
        $('input[name="acu_schedule[time_from]"]').prop('disabled', true)
        $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
        $('input[name="acu_schedule[date_from]"]').val('')
        $('input[name="acu_schedule[date_to]"]').val('')
        $('input[name="acu_schedule[time_from]"]').val('')
        $('input[name="acu_schedule[time_to]"]').val('')
      } else {
        $('input[name="acu_schedule[date_from]"]').prop('disabled', false)
        $('input[name="acu_schedule[date_to]"]').prop('disabled', false)
      }
    })

  $('#acu_schedule_date_to').on('input', function() {
    if ($('#acu_schedule_date_to').val() == "") {
      $('input[name="acu_schedule[time_from]"]').prop('disabled', true)
      $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
      $('input[name="acu_schedule[time_from]"]').val('')
      $('input[name="acu_schedule[time_to]"]').val('')
    } else {
      $('input[name="acu_schedule[time_from]"]').prop('disabled', false)
    }
  })

  $('#acu_mobile_form')
    .form({
      inline: true,
      on: 'blur',
      fields: {
        'acu_schedule[account_code]': {
          identifier: 'acu_schedule[account_code]',
          rules: [{
            type: 'empty',
            prompt: 'Please select Account Code'
          }]
        },
        'acu_schedule[product_code][]': {
          identifier: 'acu_schedule[product_code][]',
          rules: [{
            type: 'empty',
            prompt: 'Please select at least one(1) Plan'
          }]
        },
        'acu_schedule[facility_id]': {
          identifier: 'acu_schedule[facility_id]',
          rules: [{
            type: 'empty',
            prompt: 'Please select facility'
          }]
        },
        'acu_schedule[number_of_members_val]': {
          identifier: 'acu_schedule[number_of_members_val]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter number of members'
          },
          {
            type: 'checkNumberOfMembers[param]',
            prompt: 'Number of Members must not be less than or equal to zero'
          }
          ]
        },
        'acu_schedule[no_of_guaranteed]': {
          identifier: 'acu_schedule[no_of_guaranteed]',
          rules: [{
              type: 'empty',
              prompt: 'Please enter number of guaranteed members'
            },
            {
              type: 'checkMemberValidate[param]',
              prompt: 'No. of guaranteed heads cannot be more than the Members that will avail ACU.'
            }
          ]
        },
        'acu_schedule[date_from]': {
          identifier: 'acu_schedule[date_from]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter date from'
          }]
        },
        'acu_schedule[date_to]': {
          identifier: 'acu_schedule[date_to]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter date to'
          }]
        },
        'acu_schedule[time_from]': {
          identifier: 'acu_schedule[time_from]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter time from'
          }]
        },
        'acu_schedule[time_to]': {
          identifier: 'acu_schedule[time_to]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter time to'
          }]
        },
        'member_type': {
          identifier: 'acu_schedule_member_type',
          rules: [{
            type: 'checked',
            prompt: 'Please select at least one member type'
          }]
        },
        'acu_schedule["guaranteed_amount"]': {
          identifier: 'acu_schedule_guaranteed_amount',
          rules: [{
            type: 'empty',
            prompt: 'Please enter guaranteed amount'
          }]
        }
      },
      onSuccess: function(event) {
        $('#acu_submit').addClass('disabled')
        $('.acu_schedule_save_as_draft').addClass('disabled')
        $('#overlay2').css("display", "block");
      }
    })

  $('a[id="show_acu_schedule"]').on('click', function() {
    let csrf = $('input[name="_csrf_token"]').val()
    let acu_schedule_id = $(this).attr("acuID")

    $.ajax({
      url: `/acu_schedules/${acu_schedule_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response) {
        let product_codes = []
        for (let product of response.products) {
          product_codes.push(product.code)
        }
        let facilities = []
        facilities.push(response.facility_id)
        $('div[role="view_acu_modal"]').modal({
          closable: false,
          autofocus: false,
          observeChanges: true,
          onShow: function() {
            $('select[name="view_acu_schedule[account_code]"]').dropdown()
            $('select[name="view_acu_schedule[account_code]"]').dropdown('clear')
            $('select[name="view_acu_schedule[account_code]"]').dropdown('set text', `${response.account_code} | ${response.account_name}`)

            $('select[name="view_acu_schedule[product_code][]"]').dropdown()
            $('select[name="view_acu_schedule[product_code][]"]').dropdown('clear')
            for (let product of product_codes) {
                $('select[name="view_acu_schedule[product_code][]"]').append(`<option value="${product}">${product}</option>`)
            }
            $('select[name="view_acu_schedule[product_code][]"]').dropdown()

            setTimeout(function() {
                $('select[name="view_acu_schedule[product_code][]"]').dropdown('set selected', product_codes)
            }, 1)

            $('select[name="view_acu_schedule[facility_id]').dropdown()
            $('select[name="view_acu_schedule[facility_id]').dropdown('clear')
            $('select[name="view_acu_schedule[facility_id]"]').dropdown('set text', `${response.facility.code} | ${response.facility.name}`)
            $('input[name="view_acu_schedule[no_of_members]"]').val(`${response.no_of_members}`)
            $('input[name="view_acu_schedule[no_of_guaranteed]"]').val(`${response.no_of_guaranteed}`)
            $('input[name="view_acu_schedule[date_from]"]').val(`${response.date_from}`)
            $('input[name="view_acu_schedule[date_to]"]').val(`${response.date_to}`)
            $('input[name="view_acu_schedule[principal]"]').attr('disabled', true)
            $('input[name="view_acu_schedule[dependent]"]').attr('disabled', true)

            $('input[name="view_acu_schedule[principal]"]').prop('checked', false)
            $('input[name="view_acu_schedule[dependent]"]').prop('checked', false)

            if (response.member_type == "Principal") {
                $('input[name="view_acu_schedule[principal]"]').prop('checked', 'checked')
            } else if (response.member_type == "Dependent") {
                $('input[name="view_acu_schedule[dependent]"]').prop('checked', 'checked')
            } else if (response.member_type == "Principal and Dependent") {
                $('input[name="view_acu_schedule[dependent]"]').prop('checked', 'checked')
                $('input[name="view_acu_schedule[principal]"]').prop('checked', 'checked')
            }
          }
        }).modal('show')
      }
    })
  })

  $('.acu_schedule_save_as_draft').click(function(){
    $('#save_as_draft').val('true')
    $('#acu_mobile_form').submit()
  })
})

onmount('div[id="new_acu_schedule_edit_form"]', function() {
  $('.discard_acu_schedule').click(function(){
    swal({
      title: 'Delete schedule?',
      text: 'Deleting this schedule will permanently remove this schedule from the system.',
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Schedule',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Schedule',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      showCloseButton: true,
      allowOutsideClick: false
    }).then(function() {
      window.location.href = `/web/acu_schedules/${$('#acu_schedule_id').val()}/discard`
    }).catch(swal.noop)
  })

  $('.valid_timezoned').each(function(){
    let val = $(this).val()
    $(this).val(moment(val).format("MMMM DD, YYYY hh:mm A"));
  })

  var im = new Inputmask("decimal", {
    min: 0,
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });

  im.mask($('#acu_schedule_guaranteed_amount'));
  let acu_schedule_id = $('input[name="asm[as_id]"]').val()
  // ajax_datatable_form(acu_schedule_id)
  $('#overlay2').css("display", "none");

  const get_account_products = (account_code, product_code) => {
    let csrf = $('input[name="_csrf_token"]').val()
    $.ajax({
      url: `/acu_schedules/get_acu_products/${account_code}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response) {
        const data = JSON.parse(response)
        let product_codes = []
        product_codes.length = 0
        $('#acu_schedule_product_code').html('')
        $('#acu_schedule_product_code').dropdown('clear')
        $('#acu_schedule_product_code').append('<option value="">Select Plan Code</option>')
        for (let code of data) {
            product_codes.push(code)
            if (product_code.includes(code)) {
                $('#acu_schedule_product_code').append(`<option selected="selected" value="${code}">${code}</option>`)
            } else {
                $('#acu_schedule_product_code').append(`<option value="${code}">${code}</option>`)
            }
        }
        $('#acu_schedule_product_code').dropdown()
      }
    })
  }

  const get_product_facilities = (product_codes, facility_id) => {
    let csrf = $('input[name="_csrf_token"]').val()
    $.ajax({
      url: `/acu_schedules/get_acu/facilities`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      data: {
        params: {
          "product_code": product_codes
        }
      },
      success: function(response) {
        const facilities = JSON.parse(response)
        $('#acu_schedule_facility_id').html('')
        $('#acu_schedule_facility_id').dropdown('clear')
        $('#acu_schedule_facility_id').append(`<option value="">Select Facility</option>`)
        for (let facility of facilities) {
          if (facility_id == facility.facility_id) {
            $('#acu_schedule_facility_id').append(`<option selected="selected" value="${facility.facility_id}">${facility.facility_code} | ${facility.facility_name}</option>`)
          } else {
            $('#acu_schedule_facility_id').append(`<option value="${facility.facility_id}">${facility.facility_code} | ${facility.facility_name}</option>`)
          }
        }
        $('#acu_schedule_facility_id').dropdown()
      }
    })
  }

  let account_code = $('select[name="acu_schedule[account_code]"]').val()
  let product_codes = $('input[name="product_codes"]').val()
  let facility_id = $('input[name="facility_id"]').val()
  product_codes = JSON.parse(product_codes)

  get_account_products(account_code, product_codes)
  get_product_facilities(product_codes, facility_id)

  $('#cancel_acu_schedule_edit').on('click', function() {
    let acu_schedule_id = $(this).attr('acu_schedule_id')
    swal({
      title: 'Cancel Schedule?',
      text: 'Canceling this schedule will permanently remove it from the system.',
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Schedule',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Schedule',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      showCloseButton: true,
      allowOutsideClick: false
    }).then(function() {
      window.location.href = `/acu_schedules/${acu_schedule_id}/delete_acu_schedule`
    }).catch(swal.noop)
  })

  if ($(this).attr("role") == "edit") {
    $('input[name="acu_schedule[date_from]"]').prop('disabled', false)
    $('input[name="acu_schedule[time_from]"]').prop('disabled', false)
    $('input[name="acu_schedule[date_to]"]').prop('disabled', false)
    $('input[name="acu_schedule[time_to]"]').prop('disabled', false)
  }

  let end_date = $('input[name="account_end_date"]').val()
  let edit_date_from = $('input[name="acu_schedule[date_from]"]').val()
  let edit_date_to = $('input[name="acu_schedule[date_to]"]').val()
  let edit_time_from = $('input[name="acu_schedule[time_from]"]').val()
  let edit_time_to = $('input[name="acu_schedule[time_to]"]').val()
  end_date = new Date(end_date)

    $('#acu_date_from').calendar({
      type: 'date',
      ampm: false,
      minDate: new Date(),
      maxDate: end_date,
      monthFirst: false,
      onChange: function(date, text, mode) {
        date = new Date(date)
        $('#acu_date_to').calendar("set date", date)
        $('input[name="acu_schedule[time_from]"]').val("")
        $('input[name="acu_schedule[time_to]"]').val("")
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

    $('input[name="acu_schedule[date_from]"]').on('input', function() {
      if ($(this).val() == "") {
        $('input[name="acu_schedule[date_to]"]').prop('disabled', true)
      }
    })

    $('#acu_date_to').calendar({
      type: 'date',
      ampm: false,
      startCalendar: $('#acu_date_from'),
      maxDate: end_date,
      monthFirst: false,
      onChange: function(date, text, mode) {
        $('input[name="acu_schedule[time_from]"]').prop('disabled', false)
        $('input[name="acu_schedule[time_from]"]').val("")
        $('input[name="acu_schedule[time_to]"]').val("")
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

    $('#acu_date_from').calendar("set date", new Date(edit_date_from))
    $('#acu_date_to').calendar("set date", new Date(edit_date_to))
    $('#acu_time_from').calendar("set date", edit_time_from)
    $('#acu_time_to').calendar("set date", edit_time_to)

    $('input[name="acu_schedule[date_to]"]').on('input', function() {
      if ($(this).val() == "") {
        $('input[name="acu_schedule[time_from]"]').prop('disabled', true)
        $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
        $('input[name="acu_schedule[time_from]"]').val("")
        $('input[name="acu_schedule[time_to]"]').val("")
      } else {
        $('input[name="acu_schedule[time_from]"]').prop('disabled', false)
        $('input[name="acu_schedule[time_to]"]').prop('disabled', false)
      }
    })

    $('#acu_time_from').calendar({
      ampm: false,
      disableMinute: true,
      type: 'time',
      onChange: function(date, text, mode) {
        $('input[name="acu_schedule[time_to]"]').prop('disabled', false)
        //$('#acu_time_to').calendar("set date", date)
        validateTimeTo(date)
      }
    })

    // $('#acu_time_to').calendar({
    //     ampm: false,
    //     type: 'time',
    //     startCalendar: $('#acu_time_from')
    // })

    function validateTimeTo(date) {
      let hello = new Date(date)
      hello.setTime(hello.getTime() + (1*60*60*1000))
      let date_from = $('input[name="acu_schedule[date_from]"]').val()
      let date_to = $('input[name="acu_schedule[date_to]"]').val()
      if (date_from == date_to) {
        $('#acu_time_to').calendar({
          ampm: false,
          type: 'time',
          disableMinute: true,
          minDate: hello
        })
      } else {
        $('#acu_time_to').calendar({
          ampm: false,
          disableMinute: true,
          type: 'time'
        })
      }
    }

    function validateTimeToOnLoad() {
      let current = $('input[name="acu_schedule[time_from]"]').val()
      let hello = new Date()
      hello.setHours(current.slice(0, 1))
      hello.setMinutes(current.slice(2,4))
      hello.setTime(hello.getTime() + (1*60*60*1000))
      let date_from = $('input[name="acu_schedule[date_from]"]').val()
      let date_to = $('input[name="acu_schedule[date_to]"]').val()
      if (date_from == date_to) {
        $('#acu_time_to').calendar({
          ampm: false,
          type: 'time',
          disableMinute: true,
          minDate: hello
        })
      } else {
        $('#acu_time_to').calendar({
          ampm: false,
          disableMinute: true,
          type: 'time'
        })
      }
    }

    validateTimeToOnLoad()

    $('input[name="acu_schedule[time_from]"]').on('input', function() {
      if ($('input[name="acu_schedule[time_from]"]').val() == "") {
        $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
      } else {
        $('input[name="acu_schedule[time_to]"]').prop('disabled', false)
      }
    })

    if ($('input[name="product_codes"]').val() == [] && $('div[id="acu_schedule_edit_form"]').attr('role') != 'show') {
      $('#acu_schedule_facility_id').dropdown()
      $('#acu_schedule_facility_id').dropdown('clear')
      $('div[class="ui search selection dropdown facility"]').addClass('disabled')
      $('input[id="acu_schedule_member_type"]').attr('disabled', true)
      $('input[id="acu_schedule_member_type"]').prop('checked', false)
      $('input[name="acu_schedule[no_of_guaranteed]"]').attr('disabled', true)
      $('input[type="number"]').attr('disabled', true)
      $('input[type="number"]').val('')
      $('input[type="text"]').attr('disabled', true)
      $('input[type="text"]').val('')
    }

    $('select[name="acu_schedule[account_code]"]').on('change', function() {
      $('input[name="acu_schedule[date_from]"]').attr('disabled', true)
      $('input[name="acu_schedule[date_to]"]').attr('disabled', true)
      let csrf = $('input[name="_csrf_token"]').val()
      let account_code = $('select[name="acu_schedule[account_code]"]').val()

      $.ajax({
        url: `/acu_schedules/get_account_date/${account_code}`,
        headers: {
            "X-CSRF-TOKEN": csrf
        },
        type: 'get',
        success: function(response) {

          let end_date = new Date(response.end_date)

          $('#acu_date_from').calendar({
            type: 'date',
            ampm: false,
            minDate: new Date(),
            maxDate: end_date,
            monthFirst: false,
            onChange: function(date, text, mode) {
              date = new Date(date)
              $('#acu_date_to').calendar("set date", date)
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

          $('input[name="acu_schedule[date_from]"]').on('input', function() {
            if ($(this).val() == "") {
              $('input[name="acu_schedule[date_to]"]').prop('disabled', true)
            }
          })

          $('#acu_date_to').calendar({
            type: 'date',
            ampm: false,
            startCalendar: $('#acu_date_from'),
            maxDate: end_date,
            monthFirst: false,
            onChange: function(date, text, mode) {
              $('input[name="acu_schedule[time_from]"]').prop('disabled', false)
              $('input[name="acu_schedule[time_from]"]').val("")
              $('input[name="acu_schedule[time_to]"]').val("")
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

          $('input[name="acu_schedule[date_to]"]').on('input', function() {
            if ($(this).val() == "") {
              $('input[name="acu_schedule[time_from]"]').prop('disabled', true)
              $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
              $('input[name="acu_schedule[time_from]"]').val("")
              $('input[name="acu_schedule[time_to]"]').val("")
            } else {
              $('input[name="acu_schedule[time_from]"]').prop('disabled', false)
            }
          })

          $('#acu_time_from').calendar({
            ampm: false,
            disableMinute: true,
            type: 'time',
            onChange: function(date, text, mode) {
              $('input[name="acu_schedule[time_to]"]').prop('disabled', false)
              validateTimeTo(date)
            }
          })

          $('input[name="acu_schedule[time_from]"]').on('input', function() {
            if ($('input[name="acu_schedule[time_from]"]').val() == "") {
              $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
              $('input[name="acu_schedule[time_to]"]').val("")
            } else {
              $('input[name="acu_schedule[time_to]"]').prop('disabled', false)
            }
          })

          $('#acu_time_to').calendar({
            ampm: false,
            disableMinute: true,
            type: 'time'
          })
        }
      })
    })

    $('#cancel_acu_schedule').on('click', function() {
      swal({
        title: 'Cancel Schedule?',
        text: 'Canceling this schedule will permanently remove it from the system.',
        type: 'warning',
        showCancelButton: true,
        confirmButtonText: '<i class="check icon"></i> Yes, Delete Schedule',
        cancelButtonText: '<i class="remove icon"></i> No, Keep Schedule',
        confirmButtonClass: 'ui button',
        cancelButtonClass: 'ui button',
        buttonsStyling: false,
        reverseButtons: true,
        showCloseButton: true,
        allowOutsideClick: false
      }).then(function() {
        window.location.href = `/acu_schedules`
      }).catch(swal.noop)
    })

    $('#acu_schedule_account_code').on('change', function() {
      let account_code = $(this).val()
      let csrf = $('input[name="_csrf_token"]').val()
      $.ajax({
        url: `/acu_schedules/get_acu_products/${account_code}`,
        headers: {
            "X-CSRF-TOKEN": csrf
        },
        type: 'get',
        success: function(response) {
          const data = JSON.parse(response)
          let product_codes = []
          product_codes.length = 0
          $('#acu_schedule_product_code').html('')
          $('#acu_schedule_product_code').dropdown('clear')
          $('#acu_schedule_product_code').append('<option value="">Select Plan Code</option>')
          for (let code of data) {
              product_codes.push(code)
              $('#acu_schedule_product_code').append(`<option value="${code}">${code}</option>`)
          }
          $('#acu_schedule_product_code').dropdown()
          $('#acu_schedule_product_code').dropdown("clear")
          $('div[class="ui search selection dropdown multiple disabled"]').removeClass('disabled')
          $('#acu_schedule_facility_id').dropdown()
          $('#acu_schedule_facility_id').dropdown("clear")
          $('div[class="ui search selection dropdown facility"]').addClass('disabled')
          $('input[name="acu_schedule[no_of_members_val]"]').removeAttr('disabled')
          $('input[name="acu_schedule[no_of_guaranteed]"]').attr('disabled', true)
          $('.acu_schedule_member_type').attr('disabled', true)
          $('input[type="text"]').val("")
          $('input[type="text"]').attr('disabled', true)
          $('input[type="number"]').val("")
          $('input[type="number"]').attr('disabled', true)
          $('div[class="ui calendar"]').addClass('disabled')
        }
      })
    })

    $('#acu_schedule_product_code').on('change', function() {
      let product_code = $(this).val()
      let account_code = $('#acu_schedule_account_code').val()
      $('#number_of_members').attr('accountCode', account_code)
      $('#number_of_members').attr('productCode', product_code)
      $('#acu_schedule_facility_id').html('')
      $('#acu_schedule_facility_id').dropdown('clear')
      $('input[id="acu_schedule_member_type"]').prop('checked', false)
      $('#acu_schedule_number_of_members_val').val('')

      if ($(this).val().length == 0) {
        $('#acu_schedule_facility_id').dropdown()
        $('div[class="ui search selection dropdown facility"]').addClass('disabled')
        $('input[id="acu_schedule_member_type"]').attr('disabled', true)
        $('input[id="acu_schedule_member_type"]').prop('checked', false)
        $('input[name="acu_schedule[no_of_guaranteed]"]').attr('disabled', true)
        $('input[type="number"]').attr('disabled', true)
        $('input[type="number"]').val('')
        // $('input[type="text"]').attr('disabled', true)
        // $('input[type="text"]').val('')
      } else {
        $('#acu_schedule_facility_id').dropdown()
        $('div[class="ui search selection dropdown facility disabled"]').removeClass('disabled')
        let csrf = $('input[name="_csrf_token"]').val()

        $.ajax({
          url: `/acu_schedules/get_acu/facilities`,
          headers: {"X-CSRF-TOKEN": csrf},
          type: 'get',
          data: {
            params: {
              "product_code": product_code
            }
          },
          success: function(response) {
            const facilities = JSON.parse(response)
            $('#acu_schedule_facility_id').html('')
            $('#acu_schedule_facility_id').dropdown('clear')
            $('#acu_schedule_facility_id').append(`<option value="">Select Facility</option>`)
            for (let facility of facilities) {
              $('#acu_schedule_facility_id').append(`<option value="${facility.facility_id}">${facility.facility_code} | ${facility.facility_name}</option>`)
            }
            $('#acu_schedule_facility_id').dropdown()
          }
        })

        $('#acu_schedule_facility_id').on('change', function() {
          if ($('#acu_schedule_facility_id').dropdown('get value') == null) {
            $('input[id="acu_schedule_member_type"]').prop('checked', false)
            $('#acu_schedule_number_of_members_val').val('')
          } else {
            $('input[type="checkbox"]').removeAttr('disabled')
            $('input[id="acu_schedule_member_type"]').prop('checked', false)
            $('#acu_schedule_number_of_members_val').val('')
          }
          $('#acu_schedule_guaranteed_amount').prop('disabled', false)
          $('input[name="acu_schedule[date_from]"]').prop('disabled', false)
          $('input[name="acu_schedule[date_to]"]').prop('disabled', false)
        })
      }
    })

    $('#acu_schedule_facility_id').on('change', function() {
      if ($('#acu_schedule_facility_id').dropdown('get value') == null) {
      } else {
        $('input[type="checkbox"]').removeAttr('disabled')
        $('input[id="acu_schedule_member_type"]').prop('checked', false)
        $('#acu_schedule_number_of_members_val').val('')
        $('input[type="text"]').val('')
        $('input[type="number"]').val('')
      }
    })

    const request = (params, facility_id, product_code, account_code) => {
      let csrf = $('input[name="_csrf_token"]').val()

      $.ajax({
        url: `/web/acu_schedules/get_active/members`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        data: {
          params: {
            "facility_id": facility_id,
            "member_type": params,
            "product_code": $('#acu_schedule_product_code').val(),
            "account_code": $('select[name="acu_schedule[account_code]"]').val()
          }
        },
        success: function(response) {
          const data = JSON.parse(response)
          $('#acu_schedule_number_of_members_val').val('')
          $('#acu_schedule_number_of_members_val').val(data)
          if ($('#acu_schedule_number_of_members_val').val != "" || parseInt($('#acu_schedule_number_of_members_val').val() != 0)) {
            $('#acu_schedule_no_of_guaranteed').attr('disabled', false)
          } else {
            $('#acu_schedule_no_of_guaranteed').attr('disabled', true)
          }
        }
      })
    }

    $('input[id="acu_schedule_member_type"]').on('change', function() {
      let product_code = $('#acu_schedule_product_code').val()
      let facility_id = $('#acu_schedule_facility_id').val()
      let principal = $('input[name="acu_schedule[principal]"]').prop('checked')
      let dependent = $('input[name="acu_schedule[dependent]"]').prop('checked')
      let account_code = $('select[name="acu_schedule[account_code]"]').val()

      if (principal == true && dependent == false) {
        $('input[type="number"]').removeAttr('disabled')
        request(["Principal"], facility_id, product_code, account_code)
      } else if (principal == false && dependent == true) {
        $('input[type="number"]').removeAttr('disabled')
        request(["Dependent"], facility_id, product_code, account_code)
      } else if (principal == true && dependent == true) {
        $('input[type="number"]').removeAttr('disabled')
        request(["Principal", "Dependent"], facility_id, product_code, account_code)
      } else {
        $('input[type="number"]').attr('disabled', true)
        $('input[type="number"]').val('')
        $('#acu_schedule_no_of_guaranteed').val('')
        $('#acu_schedule_no_of_guaranteed').prop('disabled', true)
        // $('input[type="text"]').attr('disabled', true)
        // $('input[type="text"]').val('')
        request([""], facility_id, product_code, account_code)
      }
    })


    $.fn.form.settings.rules.checkMemberValidate = function(param) {
      if (parseInt($('#acu_schedule_number_of_members_val').val()) < parseInt(param) || parseInt(param) == 0) {
        return false
      } else {
        return true
      }
    }

    $.fn.form.settings.rules.checkNumberOfMembers = function(param) {
      if (parseInt($('#acu_schedule_number_of_members_val').val()) <= 0) {
        return false
      } else {
        return true
      }
    }

    $('#acu_schedule_number_of_members_val').on('input', function() {
      if ($('#acu_schedule_number_of_members_val').val() == "") {
        $('input[name="acu_schedule[date_from]"]').prop('disabled', true)
        $('input[name="acu_schedule[date_to]"]').prop('disabled', true)
        $('input[name="acu_schedule[date_from]"]').val('')
        $('input[name="acu_schedule[date_to]"]').val('')
        $('input[name="acu_schedule[time_from]"]').prop('disabled', true)
        $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
        $('input[name="acu_schedule[time_from]"]').val('')
        $('input[name="acu_schedule[time_to]"]').val('')
      } else {
        $('input[name="acu_schedule[date_from]"]').prop('disabled', false)
        $('input[name="acu_schedule[date_to]"]').prop('disabled', false)
      }
    })

    $('#acu_schedule_no_of_guaranteed').on('input', function() {
      if ($('#acu_schedule_no_of_guaranteed').val() == "") {
        $('input[name="acu_schedule[date_from]"]').prop('disabled', true)
        $('input[name="acu_schedule[date_to]"]').prop('disabled', true)
        $('input[name="acu_schedule[date_from]"]').val('')
        $('input[name="acu_schedule[date_to]"]').val('')
        $('input[name="acu_schedule[time_from]"]').prop('disabled', true)
        $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
        $('input[name="acu_schedule[time_from]"]').val('')
        $('input[name="acu_schedule[time_to]"]').val('')
      } else {
        $('input[name="acu_schedule[date_from]"]').prop('disabled', false)
        $('input[name="acu_schedule[date_to]"]').prop('disabled', false)
      }
    })

    $('input[name="acu_schedule[date_from]"]').on('input', function() {
      if ($(this).val() == "") {
        $('input[name="acu_schedule[time_from]"]').prop('disabled', true)
        $('input[name="acu_schedule[time_to]"]').prop('disabled', true)
        $('input[name="acu_schedule[time_from]"]').val("")
        $('input[name="acu_schedule[time_to]"]').val("")
      } else {
        $('input[name="acu_schedule[time_from]"]').prop('disabled', false)
      }
    })

    $('a[id="show_acu_schedule"]').on('click', function() {
      let csrf = $('input[name="_csrf_token"]').val()
      let acu_schedule_id = $(this).attr("acuID")

        $.ajax({
            url: `/acu_schedules/${acu_schedule_id}`,
            headers: {
                "X-CSRF-TOKEN": csrf
            },
            type: 'get',
            success: function(response) {
                let product_codes = []
                for (let product of response.products) {
                    product_codes.push(product.code)
                }
                let facilities = []
                facilities.push(response.facility_id)
                $('div[role="view_acu_modal"]').modal({
                    closable: false,
                    autofocus: false,
                    observeChanges: true,
                    onShow: function() {
                        $('select[name="view_acu_schedule[account_code]"]').dropdown()
                        $('select[name="view_acu_schedule[account_code]"]').dropdown('clear')
                        $('select[name="view_acu_schedule[account_code]"]').dropdown('set text', `${response.account_code} | ${response.account_name}`)

                        $('select[name="view_acu_schedule[product_code][]"]').dropdown()
                        $('select[name="view_acu_schedule[product_code][]"]').dropdown('clear')
                        for (let product of product_codes) {
                            $('select[name="view_acu_schedule[product_code][]"]').append(`<option value="${product}">${product}</option>`)
                        }
                        $('select[name="view_acu_schedule[product_code][]"]').dropdown()

                        setTimeout(function() {
                            $('select[name="view_acu_schedule[product_code][]"]').dropdown('set selected', product_codes)
                        }, 1)

                        $('select[name="view_acu_schedule[facility_id]').dropdown()
                        $('select[name="view_acu_schedule[facility_id]').dropdown('clear')
                        $('select[name="view_acu_schedule[facility_id]"]').dropdown('set text', `${response.facility.code} | ${response.facility.name}`)
                        $('input[name="view_acu_schedule[no_of_members]"]').val(`${response.no_of_members}`)
                        $('input[name="view_acu_schedule[no_of_guaranteed]"]').val(`${response.no_of_guaranteed}`)
                        $('input[name="view_acu_schedule[date_from]"]').val(`${response.date_from}`)
                        $('input[name="view_acu_schedule[date_to]"]').val(`${response.date_to}`)
                        $('input[name="view_acu_schedule[principal]"]').attr('disabled', true)
                        $('input[name="view_acu_schedule[dependent]"]').attr('disabled', true)

                        $('input[name="view_acu_schedule[principal]"]').prop('checked', false)
                        $('input[name="view_acu_schedule[dependent]"]').prop('checked', false)

                        if (response.member_type == "Principal") {
                            $('input[name="view_acu_schedule[principal]"]').prop('checked', 'checked')
                        } else if (response.member_type == "Dependent") {
                            $('input[name="view_acu_schedule[dependent]"]').prop('checked', 'checked')
                        } else if (response.member_type == "Principal and Dependent") {
                            $('input[name="view_acu_schedule[dependent]"]').prop('checked', 'checked')
                            $('input[name="view_acu_schedule[principal]"]').prop('checked', 'checked')
                        }

                    }
                }).modal('show')

            }
        })
    })

$('.open_modal_package_new').click(function(){
  let original_package_rate
      $('#acu_package_code').text($(this).attr('asp_code'))
      $('#acu_package_description').text($(this).attr('asp_description'))
      $('#acu_package_rate_display').text(`${$(this).attr('asp_rate')} php`)
      $('#acu_package_id').val($(this).attr('asp_id'))
      original_package_rate = $(this).attr('original_package_rate')
      let package_rate = $(this).attr('asp_rate')
      $('#new_view_modal_package').modal({
          closable: false,
          autofocus: false,
          observeChanges: true,
          onHide: function(){
            $('#dropdown_adjustment').dropdown('clear')
            $('#acu_package_adjustment_rate').val('')
            $('#new_view_modal_package').find('.field').find('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
            $('#new_view_modal_package').find('.field').removeClass('error')
        }
      }).modal('show')

      var im = new Inputmask("decimal", {
          min: 0,
          allowMinus: false,
          radixPoint: ".",
          groupSeparator: ",",
          digits: 2,
          min: 1,
          autoGroup: true,
          rightAlign: false,
          oncleared: function() {
              if ($(this).attr('asp_rate') == '') {
                  self.value('');
              }
          }
      });
      im.mask($('#acu_package_adjustment'));

  $('#dropdown_adjustment').change(function(){
    if ($(this).val() == "Deduct"){
      var im = new Inputmask("decimal", {
          min: 0,
          allowMinus: false,
          radixPoint: ".",
          groupSeparator: ",",
          digits: 2,
          min: 1,
          autoGroup: true,
          rightAlign: false,
          oncleared: function() {
              if ($(this).attr('asp_rate') == '') {
                  self.value('');
              }
          }
      });
      im.mask($('#acu_package_adjustment'));
    }else{
      var im = new Inputmask("decimal", {
          min: 0,
          allowMinus: false,
          radixPoint: ".",
          groupSeparator: ",",
          digits: 2,
          min: 1,
          autoGroup: true,
          rightAlign: false,
          oncleared: function() {
              if ($(this).attr('asp_rate') == '') {
                  self.value('');
              }
          }
      });
      im.mask($('#acu_package_adjustment'));
    }
  })

    $.fn.form.settings.rules.CheckPakageRate = function(param) {
    if (parseInt(param) >= 1){
      return true
    }else{
      return false
    }
    }
    $.fn.form.settings.rules.CheckPakageRate1 = function(param) {
      if ($('#dropdown_adjustment').dropdown('get value') == "Deduct"){
        if (package_rate - parseInt(param.replace(",","")) >= 1){
          return true
        }else{
          return false
        }
      }else{
        return true
      }
    }

  $('#acu_package_form')
      .form({
          inline: true,
          on: 'blur',
          fields: {
              'acu_schedule_package[adjustment_type]': {
                  identifier: 'acu_schedule_package[adjustment_type]',
                  rules: [{
                      type: 'empty',
                      prompt: 'Please select adjustment.'
                  }]
              },
              'acu_schedule_package[adjutsment_rate]': {
                  identifier: 'acu_schedule_package[adjustment_rate]',
                  rules: [{
                      type: 'empty',
                      prompt: 'Please enter amount.'
                      },
                      {
                      type: 'CheckPakageRate[param]',
                      prompt: 'Please enter valid amount'
                      },
                      {
                      type: 'CheckPakageRate1[param]',
                      prompt: 'Entered amount must be less than the current package rate.'
                  }]
              }
          }
      })
  })

$('#acu_schedule_package_submit_modal').click((e) => {
e.preventDefault()
swal({
  title: 'Are you sure you want to add ACU Schedule?',
  type: 'warning',
  showCancelButton: true,
  cancelButtonText: 'No',
  confirmButtonColor: '#3085d6',
  cancelButtonColor: '#d33',
  confirmButtonText: 'Yes'
}).then((result) => {
  if (result) {
    $('#acu_package_form_submit').submit()
  }
})
})
  $('.view_adjusted_package_rate').click(function(){
      $('#acu_package_code_display').text($(this).attr('asp_code'))
      $('#acu_package_description_display').text($(this).attr('asp_description'))
      $('#view_acu_package_rate_display').text(`${$(this).attr('original_package_rate')} php`)
      $('#adjusted_amount_display').text(`${$(this).attr('adjusted_amount')} php`)
    $('#adjusted_package_rate_modal').modal({
      closable: false,
      autofocus: false,
      observeChanges: true
    }).modal('show')
  })

  $('#new_submit_acu_schedule').click(function(){
    if ($('input[name="acu_schedule[no_of_selected_members]"]').val() != "0") {
    swal({
      title: 'Finalize ACU Schedule',
      text: "Are you sure you want to submit this ACU schedule?",
      type: 'question',
      showCancelButton: true,
      confirmButtonText: 'Yes',
      cancelButtonText: 'No',
      cancelButtonClass: 'ui button',
      confirmButtonClass: 'ui blue button',
      buttonsStyling: false
      }).then(function () {
        $('#new_submit_acu_schedule_member').submit()
    })
    }else{
      $('.ajs-message.ajs-error.ajs-visible').remove()
      alertify.error('</i>Please add at least one member<i id="notification_error" class="close icon">');
      alertify.defaults = {
        notifier:{
          delay:5,
          position:'top-right',
          closeButton: false
        }
      };
    }
  })
  // submit onselect package
  $('#new_select_package_submit').click(function(){
    let data_array = []
    let table = $('#acu_schedule_select_package_table').DataTable();
    let rows = table.rows({ 'search': 'applied' }).nodes();
    $('input[name="acu_schedule[selected_package][]"]').remove()
    $('.selected_package', rows).each(function(){
      data_array.push($(this).dropdown('get value'))
      $('#new_select_package_form').append(
        $('<input>')
        .attr('type', 'hidden')
        .attr('name', 'acu_schedule[selected_package][]')
        .val($(this).dropdown('get value'))
      );
    })
    if ($.inArray("", data_array) != -1){
      $('.ajs-message.ajs-error.ajs-visible').remove()
      alertify.error('</i>Please select package<i id="notification_error" class="close icon">');
      alertify.defaults = {
        notifier:{
          delay:5,
          position:'top-right',
          closeButton: false
        }
      };
    }
    else{
      $('#new_select_package_form').submit()
    }
  })

  $('.acu_schedule_save_as_draft').click(function(){
    $('#save_as_draft').val('true')
    $('#acu_mobile_edit_form').submit()
  })
})

onmount('div[id="new_add_asm"]', function() {
  $('#new_show_add_asm').on('click', function() {
    $('div[id="new_add_asm"]').modal('setting', {
      autofocus: false,
      observeChanges: true,
      centered: true,
      onHide: function(){
        let table = $('#acu_schedule_member_table').DataTable();
        rows_selected.length = 0;
        table.ajax.reload();
      }
    }).modal("show")
  })

  let acu_schedule_id = $('#as_id').val()
  const csrf2 = $('input[name="_csrf_token"]').val()
  let rows_selected = [];
  let data_2 = []

  let table = $('#new_add_asm').find('#acu_schedule_member_table').DataTable({
    "ajax": {
      "url": `/web/acu_schedules/${acu_schedule_id}/datatable/load/removed_members`,
      "headers": { "X-CSRF-TOKEN": csrf2 },
      "type": "get"
    },
    "processing": true,
    "serverSide": true,
    "ordering": false,
    "lengthMenu": [[10, 50, 100, 500, 1000], [10, 50, 100, 500, 1000]],
    "drawCallback": () => {

    },
    'columnDefs': [{
      'targets': 0,
      'searchable': false,
      'orderable': false,
      'width': '1%',
      'className': 'dt-body-center',
      "renderer": 'semanticUI',
      "pagingType": "full_numbers",
      'render': function (data, type, full, meta){
        return '<input type="checkbox" style="width:20px; height:20px">';
      }
    }],
    'order': [[1, 'asc']],
    'rowCallback': function(row, data, dataIndex){
      // Get row ID
      var rowId = data[0];

      // If row ID is in the list of selected row IDs
      if($.inArray(rowId, rows_selected) !== -1){
        $(row).find('input[type="checkbox"]').prop('checked', true);
        $(row).addClass('selected');

      }
    }
  });

  $('#acu_schedule_member_table tbody').on('click', 'input[type="checkbox"]', function(e){
    var $row = $(this).closest('tr');

    // Get row data
    var data = table.row($row).data();

    // Get row ID
    var rowId = data[0];

    // Determine whether row ID is in the list of selected row IDs
    var index = $.inArray(rowId, rows_selected);

    // If checkbox is checked and row ID is not in list of selected row IDs
    if(this.checked && index === -1){
      rows_selected.push(rowId);
      data_2.push(data);

      // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
    } else if (!this.checked && index !== -1){
      rows_selected.splice(index, 1);
      data_2.splice(index, 1);
    }

    if(this.checked){
      $row.addClass('selected');
    } else {
      $row.removeClass('selected');
    }

    updateDataTableSelectAllCtrl(table);

    e.stopPropagation();
  });

  $('#acu_schedule_member_table').on('click', 'tbody td, thead th:first-child', function(e){
    $(this).parent().find('input[type="checkbox"]').trigger('click');
  });

  $('thead input[name="select_all"]', table.table().container()).on('click', function(e){
    if(this.checked){
      $('#acu_schedule_member_table tbody input[type="checkbox"]:not(:checked)').trigger('click');
    } else {
      $('#acu_schedule_member_table tbody input[type="checkbox"]:checked').trigger('click');
    }

    e.stopPropagation();
  });

  table.on('draw', function(){
    updateDataTableSelectAllCtrl(table);
  });

  function updateDataTableSelectAllCtrl(table) {
    var $table             = table.table().node();
    var $chkbox_all        = $('tbody input[type="checkbox"]', $table);
    var $chkbox_checked    = $('tbody input[type="checkbox"]:checked', $table);
    var chkbox_select_all  = $('thead input[name="select_all"]', $table).get(0);

    if($chkbox_checked.length === 0){
      chkbox_select_all.checked = false;
      if('indeterminate' in chkbox_select_all){
        chkbox_select_all.indeterminate = false;
      }

    } else if ($chkbox_checked.length === $chkbox_all.length){
      chkbox_select_all.checked = true;
      if('indeterminate' in chkbox_select_all){
        chkbox_select_all.indeterminate = false;
      }

    } else {
      chkbox_select_all.checked = true;
      if('indeterminate' in chkbox_select_all){
        chkbox_select_all.indeterminate = true;
      }
    }
  }

  $('#asm_submit_button').on('click', function(){
    let asm_ids_container = []
    let asm_details = data_2
    if (asm_details.length < 1){
      $('.ajs-message.ajs-error.ajs-visible').remove()
      alertify.error('</i>Please select at least one member<i id="notification_error" class="close icon">');
      alertify.defaults = {
        notifier:{
          delay:5,
          position:'top-right',
          closeButton: false
        }
      }
    }
    else{
      $(this).addClass('disabled')


      asm_details.map(function(value){
        asm_ids_container.push(value[0])
      })

      $('div[id="new_select_package_modal"]').find('input[name="asm[asm_ids]"]').val(asm_ids_container)
      let DataSet = []

      let result_v2 = asm_details.map(function(value){
        // console.log(value)
        return {id: value[0], card_no: value[1], fullname: value[2], package_code: value[6]}
      })

      for (let i=0; i<result_v2.length; i++){
        for (let a=0; a<result_v2.length; a++){
          if (result_v2[i].id == result_v2[a].id && i != a){
            result_v2.splice(a, 1);
          }
        }
      }

      for (let asm of result_v2){
        if (asm.package_code.split(', ').length > 1){
          let card_no = asm.card_no
          let fullname = asm.fullname
          let DataArray = []
          let package_dropdown = ``
          for (let p_code of asm.package_code.split(', ')){
            package_dropdown += `<div class="item" data-value="${asm.id}, ${p_code}">${p_code}</div>`
          }
          let package_data =
            `<div class="field">
          <div class="ui fluid dropdown selected_package">
          <input type="hidden" name="acu_schedule[selected_package][]">
          <i class="dropdown icon"></i>
          <div class="default text">Select Package</div>
          <div class="menu">
          ${package_dropdown}
          </div>
          </div>
          </div>`
          DataArray.push(card_no)
          DataArray.push(fullname)
          DataArray.push(package_data)
          DataSet.push(DataArray)
        }
      }
      $('#acu_schedule_select_package_table').DataTable({
        destroy: true,
        data: DataSet,
        columns: [
          { title: "Card No" },
          { title: "Full Name" },
          { title: "Package Code" }
        ]
      });

      let data_array_test = []
      let table_test = $('#acu_schedule_select_package_table').DataTable();
      let rows_test = table_test.rows({ 'search': 'applied' }).nodes();
      $('.selected_package', rows_test).each(function(){
        $(this).dropdown('get value')
      })

      $('.selected_package').dropdown()
      if (DataSet.length > 0){
        $('div[id="new_add_asm"]').modal('hide')
        $('#new_select_package_modal').modal({
          closable: false,
          autofocus: false,
          observeChanges: true,
          onHide: function(){
            swal({
              title: 'Member/s cannot be added.',
              html: `Package was not selected`,
              type: 'warning',
              width: '500px',
              confirmButtonText: '<i class="check icon"></i> Ok',
              confirmButtonClass: 'ui button',
              buttonsStyling: false,
              reverseButtons: true,
              allowOutsideClick: false
            }).then(function() {
              let result_v2 = asm_details.map(function(value){
                return {id: value[0], card_no: value[1], fullname: value[2], package_code: value[6]}
              })
              let single_package_result = []
              for (let asm of result_v2){
                if (asm.package_code.split(', ').length == 1){
                  single_package_result.push([asm.id,asm.card_no,asm.fullname,asm.package_code].join('||'))
                }
              }
              $('div[id="new_select_package_modal"]').find('input[name="asm[asm_ids]"]').val(single_package_result)
              if (single_package_result.length != 0){
                $('#new_select_package_form').submit()
              }
              else{
                /// to clear checked checkbox when the selection of multiple package has been close
                asm_details.length = 0;
                $('#asm_submit_button').removeClass('disabled')
                let table = $('#acu_schedule_member_table').DataTable();
                rows_selected.length = 0;
                table.ajax.reload();
              }

            }).catch(swal.noop)
          }
        }).modal('show')
      }
      else{
        let result_v2 = asm_details.map(function(value){
          return {id: value[0], card_no: value[1], fullname: value[2], package_code: value[6]}
        })
        let single_package_result = []
        for (let asm of result_v2){
          if (asm.package_code.split(', ').length == 1){
            single_package_result.push([asm.id,asm.card_no,asm.fullname,asm.package_code].join('||'))
          }
        }
        $('div[id="new_add_asm"]').find('input[name="asm[asm_ids]"]').val(single_package_result)
        if (single_package_result.length != 0){
          $('#new_add_asm').find('#asm_form').submit()
        }
      }
    }
  })



})

onmount('div[role="show"]', function(){
  let acu_schedule_id = $('input[name="asm[as_id]"]').val()
  let table = $('#as_members_table_show').find('table[role="datatable"]')
    .DataTable({
    lengthMenu: [[10, 25, 50, -1], [10, 25, 50, "All"]],
    dom:
      "<'ui grid'"+
        "<'row'"+
      "<'eight wide column'l>"+
      "<'right aligned eight wide column'f>"+
      ">"+
      "<'row dt-table'"+
      "<'sixteen wide column'tr>"+
      ">"+
      "<'row'"+
      "<'seven wide column'i>"+
      "<'right aligned nine wide column'p>"+
      ">"+
      ">",
    renderer: 'semanticUI',
    pagingType: "full_numbers",
    scrollX: true,
    language: {
      emptyTable:     "No Records Found!",
      zeroRecords:    "No Matching Records Found!",
      search:         "Search",
      paginate: {
        first: "<i class='angle single left icon'></i> First",
        previous: "<i class='angle double left icon'></i> Previous",
        next: "Next <i class='angle double right icon'></i>",
        last: "Last <i class='angle single right icon'></i>"
      }
    }
  });
  $('#acu_schedule_tablea').find('input[type="search"]').unbind('on').on('keyup', function(){
    if($(this).val().length >= 2){
      $.ajax({
      url:`/acu_schedules/load/datatable/grid`,
      type: 'get',
      data: {params: { "search" : $(this).val().trim(), "offset" : 0, "acu_schedule_id" : acu_schedule_id}},
      dataType: 'json',
      success: function(response){
        table.clear()
        let dataSet = []
        for (let i=0;i<response.acu_schedule_member.length;i++){
          table.row.add([
            response.acu_schedule_member[i].card_no,
            response.acu_schedule_member[i].full_name,
            response.acu_schedule_member[i].gender,
            response.acu_schedule_member[i].birthdate,
            response.acu_schedule_member[i].age,
            response.acu_schedule_member[i].package
          ]).draw();
          }
        }
      })
    }
  })
  $('#acu_schedule_tablea').find('.dataTables_length').find('.ui.dropdown').on('change', function(){
    if ($(this).find('.text').text() == 100){
      let info = table.page.info();
      if (info.pages - info.page == 1){
        let search = $('.dataTables_filter input').val();
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/acu_schedules/load/datatable/grid`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {params: { "search" : search.trim(), "offset" : info.recordsTotal, "acu_schedule_id" : acu_schedule_id}},
          dataType: 'json',
          success: function(response){
            let dataSet = []
            for (let i=0;i<response.acu_schedule_member.length;i++){
              table.row.add([
                response.acu_schedule_member[i].card_no,
                response.acu_schedule_member[i].full_name,
                response.acu_schedule_member[i].gender,
                response.acu_schedule_member[i].birthdate,
                response.acu_schedule_member[i].age,
                response.acu_schedule_member[i].package
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
    if (info.pages - info.page == 1){
      let search = $('.dataTables_filter input').val();
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/acu_schedules/load/datatable/grid`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {params: { "search" : search.trim(), "offset" : info.recordsTotal, "acu_schedule_id" : acu_schedule_id}},
        dataType: 'json',
        success: function(response){
          let dataSet = []
          for (let i=0;i<response.acu_schedule_member.length;i++){
            table.row.add([
              response.acu_schedule_member[i].card_no,
              response.acu_schedule_member[i].full_name,
              response.acu_schedule_member[i].gender,
              response.acu_schedule_member[i].birthdate,
              response.acu_schedule_member[i].age,
              response.acu_schedule_member[i].package
            ]).draw(false);
          }
        }
      })
    }
  });

})

onmount('form[id="acu_mobile_edit_form"]', function(){

    let acu_schedule_id = $('input[name="asm[as_id]"]').val()
    const csrf = $('input[name="_csrf_token"]').val();

    $('#new_as_members_tbl').find('#acu_schedule_table').DataTable({
      "ajax": {
        "url": `/web/acu_schedules/${acu_schedule_id}/datatable/load/members`,
        "headers": { "X-CSRF-TOKEN": csrf },
        "type": "get"
      },
        "processing": true,
         "serverSide": true,
      "deferRender": true,
      "drawCallback": () => {

        $('.asm_update_status').on('click', function(e){
            let asm_id = $(this).attr("asm_id")
            $('input[name="asm[asm_id]"]').val(asm_id)
            swal({
                title: 'Remove member?',
                text: '',
                type: 'question',
                showCancelButton: true,
                confirmButtonText: '<i class="check icon"></i> Yes, remove member',
                cancelButtonText: '<i class="remove icon"></i> No, keep member',
                confirmButtonClass: 'ui positive button',
                cancelButtonClass: 'ui negative button',
                buttonsStyling: false,
                reverseButtons: true,
                allowOutsideClick: false
            }).then(function() {
                $('#remove_member').submit()
            })
        })
      }
    });

  $('#new_as_members_tbl').find('#acu_schedule_tablea').DataTable({
    "ajax": {
      "url": `/web/acu_schedules/${acu_schedule_id}/datatable/load/members/show`,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "processing": true,
    "serverSide": true,
    "deferRender": true,
    // "columnDefs": [
    //   {
    //     "targets": [ 0 ],
    //     data: function ( row, type, val, meta ) {
    //       console.log(row)
    //       return `<a href="/web/members/${row[0].split('|')[0]}">${row[0].split('|')[1]}</a>`;
    //     }
    //   }
    // ]
  })

  $('.discard_acu_schedule').click(function(){
    swal({
      title: 'Delete schedule?',
      text: 'Deleting this schedule will permanently remove this schedule from the system.',
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Schedule',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Schedule',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      showCloseButton: true,
      allowOutsideClick: false
    }).then(function() {
      window.location.href = `/web/acu_schedules/${$('#acu_schedule_id').val()}/discard`
    }).catch(swal.noop)
  })

  $('#new_submit_acu_schedule').click(function(){
    if ($('input[name="acu_schedule[no_of_selected_members]"]').val() != "0") {
      swal({
        title: 'Finalize ACU Schedule',
        text: "Are you sure you want to submit this ACU schedule?",
        type: 'question',
        showCancelButton: true,
        confirmButtonText: 'Yes',
        cancelButtonText: 'No',
        cancelButtonClass: 'ui button',
        confirmButtonClass: 'ui blue button',
        buttonsStyling: false
        }).then(function () {
          $('#new_submit_acu_schedule_member').submit()
      })
    }else{
      $('.ajs-message.ajs-error.ajs-visible').remove()
      alertify.error('</i>Please add at least one member<i id="notification_error" class="close icon">');
      alertify.defaults = {
        notifier:{
          delay:5,
          position:'top-right',
          closeButton: false
        }
      }
    }
  })

  $('#export_button').on('click', function(){
    let value = $('#acus_id').val()
    // let created_date = ${val}
    let created_date = new Date($('#date_time').val())
    // let a = created_date.toLocaleString()
    var hours = created_date.getHours();
    var minutes = "0" + created_date.getMinutes();
    var seconds = "0" + created_date.getSeconds();
    var formattedTime = hours + ':' + minutes.substr(-2) + ':' + seconds.substr(-2);
    value = `{"id": "${value}", "datetime": "${created_date}"}`

    window.location.assign(`/acu_schedules/export/${value}`)
  })

$('#acu_submit').on('click', function(){
  $('#acu_mobile_edit_form')
    .form({
      inline: true,
      on: 'blur',
      fields: {
        'acu_schedule[account_code]': {
          identifier: 'acu_schedule[account_code]',
          rules: [{
            type: 'empty',
            prompt: 'Please select Account Code'
          }]
        },
        'acu_schedule[product_code][]': {
          identifier: 'acu_schedule[product_code][]',
          rules: [{
            type: 'empty',
            prompt: 'Please select at least one(1) Plan'
          }]
        },
        'acu_schedule[facility_id]': {
          identifier: 'acu_schedule[facility_id]',
          rules: [{
            type: 'empty',
            prompt: 'Please select facility'
          }]
        },
        'acu_schedule[number_of_members_val]': {
          identifier: 'acu_schedule[number_of_members_val]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter number of members'
          },
          {
            type: 'checkNumberOfMembers[param]',
            prompt: 'Number of Members must not be less than or equal to zero'
          }
          ]
        },
        'acu_schedule[no_of_guaranteed]': {
          identifier: 'acu_schedule[no_of_guaranteed]',
          rules: [{
              type: 'empty',
              prompt: 'Please enter number of guaranteed members'
            },
            {
              type: 'checkMemberValidate[param]',
              prompt: 'No. of guaranteed heads cannot be more than the Members that will avail ACU.'
            }
          ]
        },
        'acu_schedule[date_from]': {
          identifier: 'acu_schedule[date_from]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter date from'
          }]
        },
        'acu_schedule[date_to]': {
          identifier: 'acu_schedule[date_to]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter date to'
          }]
        },
        'acu_schedule[time_from]': {
          identifier: 'acu_schedule[time_from]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter time from'
          }]
        },
        'acu_schedule[time_to]': {
          identifier: 'acu_schedule[time_to]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter time to'
          }]
        },
        'member_type': {
          identifier: 'acu_schedule_member_type',
          rules: [{
            type: 'checked',
            prompt: 'Please select at least one member type'
          }]
        },
        'acu_schedule["guaranteed_amount"]': {
          identifier: 'acu_schedule_guaranteed_amount',
          rules: [{
            type: 'empty',
            prompt: 'Please enter guaranteed amount'
          }]
        }
      },
      onSuccess: function(event) {
        $('#acu_submit').addClass('disabled')
        $('.acu_schedule_save_as_draft').addClass('disabled')
        $('#overlay2').css("display", "block");
      }
    })
  $('#acu_mobile_edit_form').submit()
})

})
