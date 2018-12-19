// Suspend Member
$('div[name="member_suspend"]').on('click', function() {

    $('input[type=date]').on('click', function(event) {
        event.preventDefault()
    })

    let hidden_suspend_date = $('#hidden_suspend_date').val()
    let hidden_suspend_reason = $('#hidden_suspend_reason').val()
    let hidden_suspend_remarks = $('#hidden_suspend_remarks').val()
    $('[role="edit_suspend_date"]').val(hidden_suspend_date)
    $('[role="edit_suspend_reason"]').val(hidden_suspend_reason)
    $('[role="edit_suspend_remarks"]').val(hidden_suspend_remarks)
    $('div[role="member_suspend"]').modal({
        closable: false,
        autofocus: false,
        observeChanges: true,
        onHide: function() {
            $('[role="suspend_date"]').val('')
            $('[role="suspend_reason"]').val('')
            $('[role="suspend_remarks"]').val('')
            $('[role="edit_suspend_date"]').val(hidden_suspend_date)
            $('[role="edit_suspend_reason"]').val(hidden_suspend_reason)
            $('[role="edit_suspend_remarks"]').val(hidden_suspend_remarks)
            $('#edit_suspend').attr("class", "actions")
            $('#update_suspend').attr("class", "hidden")
            $('[role="edit_suspend_date"]').attr("disabled", true)
            $('[role="edit_suspend_reason"]').attr("disabled", true)
            $('[role="edit_suspend_remarks"]').attr("disabled", true)
        }
    }).modal('show')

    var suspend_minDate = new Date()
    var dayOfMonth = suspend_minDate.getDate()
    suspend_minDate.setDate(dayOfMonth + 1)
    var temp_maxDate = ""


    if ($(this).attr('cancel_date') == "") {
        temp_maxDate = $('#member_expiry').val()
    } else {
        temp_maxDate = $(this).attr('cancel_date')
    }

    // previous day before the CANCEL DATE or ENDDATE
    var suspend_maxDate = new Date(temp_maxDate)
    var dayOfMonth = suspend_maxDate.getDate()
    suspend_maxDate.setDate(dayOfMonth - 1)

    $('#suspend_date_picker').calendar({
        type: 'date',
        minDate: suspend_minDate,
        maxDate: suspend_maxDate,
        formatter: {
            date: function(date, settings) {
                if (!date) return ''
                var day = date.getDate() + ''
                if (day.length < 2) {
                    day = '0' + day
                }
                var month = (date.getMonth() + 1) + ''
                if (month.length < 2) {
                    month = '0' + month
                }
                var year = date.getFullYear()
                return year + '-' + month + '-' + day
            }
        }
    })

})
$('#edit_suspend').on('click', function() {
    $('#edit_suspend').attr("class", "hidden")
    $('#update_suspend').attr("class", "actions")
    $('#suspend_date').removeAttr("disabled")
    $('#suspend_reason').removeAttr("disabled")
    $('#suspend_remarks').removeAttr("disabled")
})


// Submit button
$('#btn_suspend_member').on('click', function() {
    const member_id = $('#member_id').val()
    const member_effectivity = $('#member_effectivity').val()
    const member_expiry = $('#member_expiry').val()
    const member_status = $('#member_status').val()
    const member_suspend = $('#suspend_date').val()
    const member_reason = $('#suspend_reason').val()
    if ((member_suspend != "" || member_reason == "") || (member_suspend == "" || member_reason != "")) {
        $('#suspend').form({
            on: blur,
            inline: true,
            fields: {
                'member[suspend_date]': {
                    identifier: 'member[suspend_date]',
                    rules: [{
                        type: 'empty',
                        prompt: 'Please enter suspension date'
                    }, ]
                },
                'member[suspend_reason]': {
                    identifier: 'member[suspend_reason]',
                    rules: [{
                        type: 'empty',
                        prompt: 'Please enter reason'
                    }, ]
                },
            }
        })
        $('#suspend').submit()
    } else {
        swal({
            title: 'Suspend Member',
            text: `Suspending this member will temporarily remove all funtions on ${member_suspend}?`,
            type: 'question',
            showCancelButton: true,
            cancelButtonText: '<i class="remove icon"></i> No, keep member',
            confirmButtonText: '<i class="check icon"></i> Yes, suspend member',
            cancelButtonClass: 'ui negative button',
            confirmButtonClass: 'ui positive button',
            reverseButtons: true,
            buttonsStyling: false
        }).then(function() {
            $('#suspend').submit()
        })
    }
})
// End of Submit button

$('#btn_edit_suspend_member').on('click', function() {
    const member_id = $('#member_id').val()
    const member_effectivity = $('#member_effectivity').val()
    const member_expiry = $('#member_expiry').val()
    const member_status = $('#member_status').val()
    const member_suspend = $('#suspend_date').val()
    console.log(member_suspend)
    const member_reason = $('#suspend_reason').val()
    if ((member_suspend != "" || member_reason == "") || (member_suspend == "" || member_reason != "")) {
        $('#suspend').form({
            on: blur,
            inline: true,
            fields: {
                'member[suspend_date]': {
                    identifier: 'member[suspend_date]',
                    rules: [{
                        type: 'empty',
                        prompt: 'Please enter suspension date'
                    }, ]
                },
                'member[suspend_reason]': {
                    identifier: 'member[suspend_reason]',
                    rules: [{
                        type: 'empty',
                        prompt: 'Please enter reason'
                    }, ]
                },
            }
        })
        $('#suspend').submit()
    } else {
        $('#suspend').submit()
    }
})
// End of Submit button


$('#cancel_suspend').on('click', function() {
    swal({
        title: 'Are you sure you want to retract movement?',
        type: 'question',
        showCancelButton: true,
        cancelButtonText: '<i class="remove icon"></i> No, dont retract movement',
        confirmButtonText: '<i class="check icon"></i> Yes, retract movement',
        cancelButtonClass: 'ui negative button',
        confirmButtonClass: 'ui positive button',
        reverseButtons: true,
        buttonsStyling: false
    }).then(function() {
        $('#suspend_date').val('')
        $('#suspend_reason').val('')
        $('#suspend_remarks').val('')
        $('#suspend').submit()
    })

})

// End of Suspend Member