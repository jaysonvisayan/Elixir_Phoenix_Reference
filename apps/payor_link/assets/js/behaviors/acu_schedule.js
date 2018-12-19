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

    // $('#select_acu_member').on('change', function() {
    //   var table = $('#acu_schedule_table').DataTable()
    //   var rows = table.rows({ 'search': 'applied' }).nodes();
    //   if ($(this).is(':checked')) {
    //     $('input[type="checkbox"]', rows).each(function() {
    //       var value = $(this).val()

    //       if (this.checked) {
    //         valArray.push(value)
    //       } else {
    //         var index = valArray.indexOf(value);

    //         if (index >= 0) {
    //           valArray.splice(index, 1)
    //         }
    //         valArray.push(value)
    //       }
    //       $(this).prop('checked', true)
    //     })

    //   } else {
    //     valArray.length = 0
    //     $('input[type="checkbox"]', rows).each(function() {
    //       $(this).prop('checked', false)
    //     })
    //   }
    //   $('.member_main').val(valArray)
    // })

    $('#select_acu_member').on('change', function() {
        var table = $('#acu_schedule_tablea').DataTable()
        var rows = table.rows({
            'search': 'applied'
        }).nodes();

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

onmount('div[id="acu_mobile"]', function() {
  $('#acu_schedule_table').DataTable({
    aoColumns: [
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      { sType: 'date' },
      null,
    ],
    order: [[9, 'desc' ]]
  })

})

onmount('div[id="acu_schedule_form"]', function() {
    $('#overlay2').css("display", "none");
    // $('select[name="acu_schedule[account_code]"]').dropdown('clear')
    // $('select[name="acu_schedule[account_code]"]').dropdown()
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
                            var monthNames = [
                              "Jan", "Feb", "Mar",
                              "Apr", "May", "Jun", "Jul",
                              "Aug", "Sep", "Oct",
                              "Nov", "Dec"
                            ];
                            var day = date.getDate();
                            var monthIndex = date.getMonth();
                            var year = date.getFullYear();
                            return monthNames[monthIndex] + ' ' + day + ', ' + year;
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
                            var monthNames = [
                              "Jan", "Feb", "Mar",
                              "Apr", "May", "Jun", "Jul",
                              "Aug", "Sep", "Oct",
                              "Nov", "Dec"
                            ];
                            var day = date.getDate();
                            var monthIndex = date.getMonth();
                            var year = date.getFullYear();
                            return monthNames[monthIndex] + ' ' + day + ', ' + year;
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
            minDate: hello
        })
      } else {
        $('#acu_time_to').calendar({
            ampm: false,
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
                headers: {
                    "X-CSRF-TOKEN": csrf
                },
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
            })

        }
    })

    const request = (params, facility_id, product_code, account_code) => {
        let csrf = $('input[name="_csrf_token"]').val()
        $.ajax({
            url: `/acu_schedules/get_active/members`,
            headers: {
                "X-CSRF-TOKEN": csrf
            },
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

    $.fn.form.settings.rules.checkGuaranteedAmount = function(param) {
        if (parseInt(param) == 0) {
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

    $('#acu_schedule_guaranteed_amount').on('input', function() {
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
                'acu_schedule[guaranteed_amount]': {
                    identifier: 'acu_schedule[guaranteed_amount]',
                    rules: [{
                            type: 'empty',
                            prompt: 'Please enter number of guaranteed amount'
                        },
                        {
                            type: 'checkGuaranteedAmount[param]',
                            prompt: 'Guaranteed amount should be greater than 0'
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
                        prompt: 'Please select atleast one member type'
                    }]
                }
            },
            onSuccess: function(event) {
                $('#overlay2').css("display", "block");
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
})

onmount('div[id="acu_schedule_edit_form"]', function() {
    let acu_schedule_id = $('input[name="asm[as_id]"]').val()
    ajax_datatable_form(acu_schedule_id)
    $('#overlay2').css("display", "none");
    const get_account_products = (account_code, product_code) => {
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
            headers: {
                "X-CSRF-TOKEN": csrf
            },
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
                var monthNames = [
                  "Jan", "Feb", "Mar",
                  "Apr", "May", "Jun", "Jul",
                  "Aug", "Sep", "Oct",
                  "Nov", "Dec"
                ];
                var day = date.getDate();
                var monthIndex = date.getMonth();
                var year = date.getFullYear();
                return monthNames[monthIndex] + ' ' + day + ', ' + year;
            }
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
                var monthNames = [
                  "Jan", "Feb", "Mar",
                  "Apr", "May", "Jun", "Jul",
                  "Aug", "Sep", "Oct",
                  "Nov", "Dec"
                ];
                var day = date.getDate();
                var monthIndex = date.getMonth();
                var year = date.getFullYear();
                return monthNames[monthIndex] + ' ' + day + ', ' + year;
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
            minDate: hello
        })
      } else {
        $('#acu_time_to').calendar({
            ampm: false,
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
            minDate: hello
        })
      } else {
        $('#acu_time_to').calendar({
            ampm: false,
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

    // let acu_schedule_id = $('#cancel_acu_schedule_edit').attr('acu_schedule_id')
    //   $('#acu_mobile_edit_form').submit(function(event){
    //   if($('input[name="product_codes"]').val() == [] ||
    //     $('input[type="text"]').val() == "" ||
    //     $('input[name="acu_schedule[time_from]"]').val() == "" ||
    //     $('input[name="acu_schedule[time_to]"]').val() == "" ||
    //     $('input[name]')
    // )
    //   var req =
    //   $.ajax({
    //     url: $('#acu_mobile_edit_form').attr('action'),
    //     type: 'POST',
    //     data : $('#acu_mobile_edit_form').serialize(),
    //       beforeSend: function()
    //       {
    //         $('#overlay2').css("display", "block");
    //       },
    //       complete: function()
    //       {
    //         $('#overlay2').css("display", "none");
    //       }
    //   });
    //   req.done(function (data){
    //       console.log('form submitted.');
    //       window.location.href = `/acu_schedules/${acu_schedule_id}/edit`
    //   })
    //   event.preventDefault();
    //  });

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
                          var monthNames = [
                            "Jan", "Feb", "Mar",
                            "Apr", "May", "Jun", "Jul",
                            "Aug", "Sep", "Oct",
                            "Nov", "Dec"
                          ];
                          var day = date.getDate();
                          var monthIndex = date.getMonth();
                          var year = date.getFullYear();
                          return monthNames[monthIndex] + ' ' + day + ', ' + year;
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
                    formatter: {
                        date: function(date, settings) {
                          var monthNames = [
                            "Jan", "Feb", "Mar",
                            "Apr", "May", "Jun", "Jul",
                            "Aug", "Sep", "Oct",
                            "Nov", "Dec"
                          ];
                          var day = date.getDate();
                          var monthIndex = date.getMonth();
                          var year = date.getFullYear();
                          return monthNames[monthIndex] + ' ' + day + ', ' + year;
                        }
                    }
                })

                $('#acu_time_from').calendar({
                    ampm: false,
                    type: 'time'
                })

                $('#acu_time_to').calendar({
                    ampm: false,
                    type: 'time'
                })
            }
        })

      // $('#acu_date_from').calendar("set date", new Date(edit_date_from))
      // $('#acu_date_to').calendar("set date", edit_date_to)
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

    // if($('#acu_schedule_account_code').dropdown('get value') == ""){
    //   $('#acu_schedule_product_code').dropdown()
    //   $('div[class="ui search selection dropdown multiple"]').addClass('disabled')
    //   $('div[class="ui search selection dropdown facility"]').addClass('disabled')
    //   $('.acu_schedule_member_type').attr('disabled', true)
    //   $('input[type="text"]').attr('disabled', true)
    // }

    $('#acu_schedule_account_code').on('change', function() {
        // if($('#acu_schedule_account_code').dropdown('get value') == ""){
        //   $('#acu_schedule_product_code').dropdown()
        //   $('div[class="ui search selection dropdown multiple"]').addClass('disabled')
        //   $('#acu_schedule_facility_id').dropdown()
        //   $('div[class="ui search selection dropdown facility"]').addClass('disabled')
        //   $('.acu_schedule_member_type').attr('disabled', true)
        //   $('input[type="text"]').attr('disabled', true)
        //   $('input[type="text"]').val('')
        //   $('input[type="number"]').val('')
        // }else{
        //   $('#acu_schedule_product_code').dropdown()
        //   $('div[class="ui search selection dropdown multiple disabled"]').removeClass('disabled')
        //   $('#acu_schedule_facility_id').dropdown()
        //   $('#acu_schedule_facility_id').dropdown("clear")
        //   $('div[class="ui search selection dropdown facility"]').addClass('disabled')
        //   $('input[id="acu_schedule_member_type"]').prop('checked', false)
        //   $('input[type="text"]').removeAttr('disabled')
        //   $('input[name="acu_schedule[no_of_guaranteed]"]').attr('disabled', true)
        //   $('input[type="text"]').val('')
        //   $('input[type="text"]').prop('disabled', true)
        //   $('input[type="number"]').val('')
        // }

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
            $('input[type="text"]').attr('disabled', true)
            $('input[type="text"]').val('')
        } else {
            $('#acu_schedule_facility_id').dropdown()
            $('div[class="ui search selection dropdown facility disabled"]').removeClass('disabled')
            let csrf = $('input[name="_csrf_token"]').val()

            $.ajax({
                url: `/acu_schedules/get_acu/facilities`,
                headers: {
                    "X-CSRF-TOKEN": csrf
                },
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
                    $('input[type="text"]').val('')
                    $('input[type="number"]').val('')

                }
            })

        }
    })

    const request = (params, facility_id, product_code, account_code) => {
        let csrf = $('input[name="_csrf_token"]').val()

        $.ajax({
            url: `/acu_schedules/get_active/members`,
            headers: {
                "X-CSRF-TOKEN": csrf
            },
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
            $('input[type="text"]').attr('disabled', true)
            $('input[type="text"]').val('')
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

    $.fn.form.settings.rules.checkGuaranteedAmount = function(param) {
        if (parseInt(param) == 0) {
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

    $('#acu_schedule_guaranteed_amount').on('input', function() {
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
                'acu_schedule[guaranteed_amount]': {
                    identifier: 'acu_schedule[guaranteed_amount]',
                    rules: [{
                            type: 'empty',
                            prompt: 'Please enter number of guaranteed amount'
                        },
                        {
                            type: 'checkGuaranteedAmount[param]',
                            prompt: 'Guaranteed amount should be greater than 0'
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
                        prompt: 'Please select atleast one member type'
                    }]
                }
            },
            onSuccess: function() {
                $('#overlay2').css("display", "block");
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


function ajax_datatable_form(acu_schedule_id){
  let table = $('#as_members_table').find('table[role="datatable"]')
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
            response.acu_schedule_member[i].package,
            `<a class="clickable-row" href="#" asm_id="${response.acu_schedule_member[i].id}" id="asm_update_status"><i class="red trash icon"></i></a>`
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
                response.acu_schedule_member[i].package,
                `<a class="clickable-row" href="#" asm_id="${response.acu_schedule_member[i].id}" id="asm_update_status"><i class="red trash icon"></i></a>`
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
              response.acu_schedule_member[i].package,
              `<a class="clickable-row" href="#" asm_id="${response.acu_schedule_member[i].id}" id="asm_update_status"><i class="red trash icon"></i></a>`
            ]).draw(false);
          }
        }
      })
    }
  });
}

})

onmount('div[id="add_asm"]', function() {
  let acu_schedule_id = $('#as_id').val()
  if (acu_schedule_id == '')
  {
    acu_schedule_id = '517db87e-6639-4b3d-928a-c6e63d104eeb'
  }
  else
  {
    acu_schedule_id = acu_schedule_id
  }

  const csrf = $('input[name="_csrf_token"]').val();
  $('#acu_schedule_table').DataTable({
    "ajax": {
      "url": `/acu_schedules/${acu_schedule_id}/datatable/load/removed_members`,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "processing": true,
    "serverSide": true,
    "deferRender": true,
    "ordering": false,
    "lengthMenu": [[10, 50, 100, 500, 1000], [10, 50, 100, 500, 1000]],
    "aoColumnDefs": [{
        'bSortable': false,
        'aTargets': [0]
    }],
    "drawCallback": () => {
        let main_ids = $('div[id="add_asm"]').find('input[name="asm[asm_ids]"]')
        $('#acu_schedule_table_length').find('.item').on('click', function(e){
            main_ids.val("")
            $('#checkAllacu').prop("checked", false)
        })
      $('.paginate_button').on('click', function(e){
        main_ids.val("")
        $('#checkAllacu').prop("checked", false)
      })
    }
  });
    // ajax_datatable(acu_schedule_id)

    $('#asm_form').find('table[role="datatable"]')
    .on( 'page.dt',   function () {
      // $('input:checkbox').prop('checked', false)
      $('#checkAllacu').prop('checked', false)
      // $('.member_main').val('')
     } )
    .dataTable({
    lengthMenu: [[10, 50, 100, 500], [10, 50, 100, 500]],
    aoColumnDefs: [{
            'bSortable': false,
            'aTargets': [0]
        }],
    // dom:
    //   "<'ui grid'"+
    //     "<'row'"+
    //   "<'eight wide column'l>"+
    //   "<'right aligned eight wide column'f>"+
    //   ">"+
    //   "<'row dt-table'"+
    //   "<'sixteen wide column'tr>"+
    //   ">"+
    //   "<'row'"+
    //   "<'seven wide column'i>"+
    //   "<'right aligned nine wide column'p>"+
    //   ">"+
    //   ">",
    // renderer: 'semanticUI',
    // pagingType: "full_numbers",
    // scrollX: true,
    // language: {
    //   emptyTable:     "No Records Found!",
    //   zeroRecords:    "No Records Found!",
    //   search:         "Search",
    //   paginate: {
    //     first: "<i class='angle single left icon'></i> First",
    //     previous: "<i class='angle double left icon'></i> Previous",
    //     next: "Next <i class='angle double right icon'></i>",
    //     last: "Last <i class='angle single right icon'></i>"
    //   }
    // }
  });

  $('#show_add_asm').on('click', function() {
    $('div[id="add_asm"]').modal({
        autofocus: false,
        observeChanges: true
    }).modal("show")

    $('div[id="add_asm"]').on('mouseenter', function(){
    $('input:checkbox.selection').on('change', function() {
      let main_ids = $('div[id="add_asm"]').find('input[name="asm[asm_ids]"]')
      let valArray =[]
      if(main_ids.val().length == 0){
          valArray = [];
        }
        else{
          valArray = main_ids.val().split(',')
        }
        var value = $(this).val()

        if (this.checked) {
            valArray.push(value)
            main_ids.val(valArray)
        } else {
            var index = valArray.indexOf(value)
            if (index >= 0) {
                valArray.splice(index, 1)
            }
            main_ids.val(valArray)
        }
    })

      // $('div[id="add_asm"]').find('#checkAllacu').on('change', function() {
      //     var valArray = [];
      //     if ($(this).is(':checked')) {
      //         $('#acu_schedule_table tbody input[type="checkbox"]').each(function() {
      //             var value = $(this).val();
      //             valArray.push(value);
      //             $(this).prop('checked', this.checked)
      //             $('#asm_submit_button').removeClass('disabled')
      //         })
      //     } else {
      //         $('div[id="add_asm"]').find('input[id="acu_sched_id"]').each(function() {
      //             $(this).prop('checked', this.checked)
      //             $('#asm_submit_button').addClass('disabled')
      //         })
      //     }
      //     $('div[id="add_asm"]').find('input[name="asm[asm_ids]"]').val(valArray)
      // })

  function onlyUnique(value, index, self) {
      return self.indexOf(value) === index;
  }

  $('div[id="add_asm"]').find('#checkAllacu').on('change', function() {
        let main_ids = $('div[id="add_asm"]').find('input[name="asm[asm_ids]"]')
        // var valArray = []
        // var valArray = valArray.push(main_ids.val())
        var valArray = [];
        if(main_ids.val().length == 0){
          valArray = [];
        }
        else{
          valArray = main_ids.val().split(',')
        }
        if ($(this).is(':checked')) {
              $('#acu_schedule_table tbody input[type="checkbox"]').each(function() {
                var value = $(this).val();
                valArray.push(value);
                $(this).prop('checked', true)
              })
          } else {
              $('#acu_schedule_table tbody input[type="checkbox"]').each(function() {
                var value = $(this).val();
                var index = valArray.indexOf(value)
                if (index >= 0) {
                    valArray.splice(index, 1)
                }
                $(this).prop('checked', false)
              })
        }

        var unique = valArray.filter( onlyUnique )
        main_ids.val(unique)
    });

      $('#asm_submit_button').on('click', function(){
          $(this).addClass('disabled')
      })
    })
    $('#asm_form')
     .form({
         inline: true,
         on: 'blur',
         onSuccess: function(event) {
           $('#overlay3').css("display", "block");
         }
      })
  })
})


// onmount('button[id="acu_schedule_package_submit"]', function() {
//     $('button[id="acu_schedule_package_submit"]').on('click', function() {
//         $(this).addClass('disabled')
//     })
// })

// Start of edit package rate

  var im = new Inputmask("decimal", {
      min: 0,
      allowMinus: false,
      radixPoint: ".",
      groupSeparator: ",",
      digits: 2,
      autoGroup: true,
      rightAlign: false,
      oncleared: function() {
          if ($(this).attr('asp_rate') == '') {
              self.value('');
          }
      }
  });

  let am = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  })
  im.mask($('input[role="mask-decimal"]'));
  am.mask($('span[role="mask-decimal"]'));

  let original_package_rate
  $('td[role="edit"]').on("mouseenter", function() {
    let this_td = $(this)
    let id = $(this).attr("asp_id")
    let orig_rate  = $(this).attr("orig_rate")
    let value = $(`td[id="${id}"]`).html()

    $(this).find('span[role="edit-package-rate"]').click(function() {
      $(`td[id="${id}"]`).find('span').hide()
      $(`td[id="${id}"]`).find('input').removeClass("hide")
      this_td.find('span[role="approved-rate"]').removeClass("hide")
      this_td.find('span[role="disapproved-rate"]').removeClass("hide")
      $(this).hide()
    })

    $(this).find('span[role="approved-rate"]').click(function() {
      let this_approved = $(this)
      const csrf = $('input[name="_csrf_token"]').val();
      let edited_rate = $(`input[id="${id}"]`).val()

      $('.ajs-message.ajs-error.ajs-visible').remove()
      if  (edited_rate == "") {
        alertify.error('<i class="close icon"></i>Please enter package rate')
      } else if  (edited_rate == 0) {
        alertify.error('<i class="close icon"></i>Package rate must be greater than 0')
      } else if (parseInt(orig_rate) == parseInt(edited_rate.split(",").join(""))) {
        $.ajax({
            url: `/acu_schedules/${id}/update_package_rate/${edited_rate}`,
            headers: {
                "X-CSRF-TOKEN": csrf
            },
            type: 'post',
            success: function(response) {
              let data = JSON.parse(response)
              if (data.response == true) {
                $(`td[id="${id}"]`).find("span").html(edited_rate)
                $(`td[id="${id}"]`).find("input").addClass("hide")
                $(`td[id="${id}"]`).find('span').show()
                this_td.find('span[role="edit-package-rate"]').show()
                this_td.find('span[role="disapproved-rate"]').addClass("hide")
                this_td.next().find('#orig-rate-display').addClass("hide")
                this_approved.addClass("hide")
              } else {
                $('.ajs-message.ajs-error.ajs-visible').remove()
                alertify.error('<i class="close icon"></i>${data.response}')
              }
            },
            error: function(response) {
              console.log('Error updating package rate')
            }
        })
      } else {
        let rate  = edited_rate.split(",").join("")
        $.ajax({ url: `/acu_schedules/${id}/update_package_rate/${rate}`,
            headers: {
                "X-CSRF-TOKEN": csrf
            },
            type: 'post',
            success: function(response) {
              let data = JSON.parse(response)
              if (data.response == true) {
                $(`td[id="${id}"]`).find("span").html(edited_rate)
                $(`td[id="${id}"]`).find("input").addClass("hide")
                $(`td[id="${id}"]`).find('span').show()
                this_td.find('span[role="edit-package-rate"]').show()
                this_td.find('span[role="disapproved-rate"]').addClass("hide")
                this_td.next().find('#orig-rate-display').removeClass("hide")
                this_approved.addClass("hide")
              } else {
                $('.ajs-message.ajs-error.ajs-visible').remove()
                alertify.error(`<i class="close icon"></i>${data.response}`)
              }
            },
            error: function(response) {
              alert('Error updating package rate')
            }
        })
      }
    })

    $(this).find('span[role="disapproved-rate"]').click(function() {
      let orig_val = $(`td[id="${id}"]`).find("span").html()
      $(`td[id="${id}"]`).find("input").addClass("hide")
      $(`td[id="${id}"]`).find("input").val(orig_val)
      $(`td[id="${id}"]`).find('span').show()
      this_td.find('span[role="edit-package-rate"]').show()
      this_td.find('span[role="approved-rate"]').addClass("hide")
      $(this).addClass("hide")
    })
  })

  // end


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
  // alert("yeah")
  if (result) {
    $('#acu_package_form_submit').submit()
  }
})
})

// function ajax_datatable(acu_schedule_id){
//   let table = $('#asm_form').find('table[role="datatable"]')
//     .on( 'page.dt',   function () {
//       $('input:checkbox').prop('checked', false)
//       $('#checkAllacu').prop('checked', false)
//       $('.member_main').val('')
//      } )
//     .dataTable({
//     lengthMenu: [[10, 25, 50, -1], [10, 25, 50, "All"]],
//     dom:
//       "<'ui grid'"+
//         "<'row'"+
//       "<'eight wide column'l>"+
//       "<'right aligned eight wide column'f>"+
//       ">"+
//       "<'row dt-table'"+
//       "<'sixteen wide column'tr>"+
//       ">"+
//       "<'row'"+
//       "<'seven wide column'i>"+
//       "<'right aligned nine wide column'p>"+
//       ">"+
//       ">",
//     renderer: 'semanticUI',
//     pagingType: "full_numbers",
//     scrollX: true,
//     language: {
//       emptyTable:     "No Records Found!",
//       zeroRecords:    "No Matching Records Found!",
//       search:         "Search",
//       paginate: {
//         first: "<i class='angle single left icon'></i> First",
//         previous: "<i class='angle double left icon'></i> Previous",
//         next: "Next <i class='angle double right icon'></i>",
//         last: "Last <i class='angle single right icon'></i>"
//       }
//     }
//   });
//   $('#asm_form').find('input[type="search"]').unbind('on').on('keyup', function(){
//     if($(this).val().length >= 2){
//       $.ajax({
//       url:`/acu_schedules/load/datatable`,
//       type: 'get',
//       data: {params: { "search" : $(this).val().trim(), "offset" : 0, "acu_schedule_id" : acu_schedule_id}},
//       dataType: 'json',
//       beforeSend: function()
//         {
//           $('#overlay3').css("display", "block");
//         },
//       complete: function()
//       {
//         $('#overlay3').css("display", "none");
//       },
//       success: function(response){
//         table.fnClearTable();
//         let dataSet = []
//         for (let i=0;i<response.acu_schedule_member.length;i++){
//           table.fnAddData([
//             `<input id="acu_sched_id" type="checkbox" value="${response.acu_schedule_member[i].id}">`,
//             response.acu_schedule_member[i].card_no,
//             response.acu_schedule_member[i].full_name,
//             response.acu_schedule_member[i].gender,
//             response.acu_schedule_member[i].birthdate,
//             response.acu_schedule_member[i].age,
//             response.acu_schedule_member[i].package
//           ])
//           }
//         }
//       })
//     }
//   })
//   $('#asm_form').find('.dataTables_length').find('.ui.dropdown').on('change', function(){
//     if ($(this).find('.text').text() == 100){
//       let info = table.page.info();
//       if (info.pages - info.page == 1){
//         let search = $('.dataTables_filter input').val();
//         const csrf2 = $('input[name="_csrf_token"]').val();
//         $.ajax({
//           url:`/acu_schedules/load/datatable`,
//           headers: {"X-CSRF-TOKEN": csrf2},
//           type: 'get',
//           data: {params: { "search" : search.trim(), "offset" : info.recordsTotal, "acu_schedule_id" : acu_schedule_id}},
//           dataType: 'json',
//           beforeSend: function()
//           {
//             $('#overlay3').css("display", "block");
//           },
//           complete: function()
//           {
//             $('#overlay3').css("display", "none");
//           },
//           success: function(response){
//             let dataSet = []
//             for (let i=0;i<response.acu_schedule_member.length;i++){
//               table.fnAddData([
//                 `<input id="acu_sched_id" type="checkbox" value="${response.acu_schedule_member[i].id}">`,
//                 response.acu_schedule_member[i].card_no,
//                 response.acu_schedule_member[i].full_name,
//                 response.acu_schedule_member[i].gender,
//                 response.acu_schedule_member[i].birthdate,
//                 response.acu_schedule_member[i].age,
//                 response.acu_schedule_member[i].package
//               ])
//             }
//           }
//         })
//       }
//     }
//   })
//   let info
//   table.on('page', function () {
//     info = table.page.info();
//     // console.log(info)
//     if (info.pages - info.page == 1){
//       let search = $('.dataTables_filter input').val();
//       const csrf2 = $('input[name="_csrf_token"]').val();
//       $.ajax({
//         url:`/acu_schedules/load/datatable`,
//         headers: {"X-CSRF-TOKEN": csrf2},
//         type: 'get',
//         data: {params: { "search" : search.trim(), "offset" : info.recordsTotal, "acu_schedule_id" : acu_schedule_id}},
//         dataType: 'json',
//         beforeSend: function()
//         {
//           $('#overlay3').css("display", "block");
//         },
//         complete: function()
//         {
//           $('#overlay3').css("display", "none");
//         },
//         success: function(response){
//           let dataSet = []
//           for (let i=0;i<response.acu_schedule_member.length;i++){
//             table.fnAddData([
//               `<input id="acu_sched_id" type="checkbox" value="${response.acu_schedule_member[i].id}">`,
//               response.acu_schedule_member[i].card_no,
//               response.acu_schedule_member[i].full_name,
//               response.acu_schedule_member[i].gender,
//               response.acu_schedule_member[i].birthdate,
//               response.acu_schedule_member[i].age,
//               response.acu_schedule_member[i].package
//             ])
//           }
//         }
//       })
//     }
//   });
// }

onmount('div[role="show"]', function(){
  console.log(123)
  let acu_schedule_id = $('input[name="asm[as_id]"]').val()
  console.log(acu_schedule_id)
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
          console.log(response)
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

onmount('div[id="as_members_tbl"]', function(){
    let acu_schedule_id = $('input[name="asm[as_id]"]').val()

    const csrf = $('input[name="_csrf_token"]').val();
    $('#acu_schedule_tbl').DataTable({
      "ajax": {
        "url": `/acu_schedules/${acu_schedule_id}/datatable/load/members`,
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

    $('#show_acu_schedule_tbl').DataTable({
        "ajax": {
          "url": `/acu_schedules/${acu_schedule_id}/datatable/load/members/show`,
          "headers": { "X-CSRF-TOKEN": csrf },
          "type": "get"
        },
          "processing": true,
           "serverSide": true,
        "deferRender": true
      });
})
