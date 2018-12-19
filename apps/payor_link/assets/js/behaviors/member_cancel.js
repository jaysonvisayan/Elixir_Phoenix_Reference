// Cancel Member
$('div[name="member_cancel"]').on('click', function() {

    $('input[type=date]').on('click', function(event) {
        event.preventDefault()
    })

    let hidden_cancel_date = $('#hidden_cancel_date').val()
    let hidden_cancel_reason = $('#hidden_cancel_reason').val()
    let hidden_cancel_remarks = $('#hidden_cancel_remarks').val()
    $('[role="edit_cancel_date"]').val(hidden_cancel_date)
    $('[role="edit_cancel_reason"]').val(hidden_cancel_reason)
    $('[role="edit_cancel_remarks"]').val(hidden_cancel_remarks)
    $('div[role="member_cancel"]').modal({
        closable: false,
        autofocus: false,
        observeChanges: true,
        onHide: function() {
            $('[role="cancel_date"]').val('')
            $('[role="cancel_reason"]').val('')
            $('[role="cancel_remarks"]').val('')
            $('[role="edit_cancel_date"]').val(hidden_cancel_date)
            $('[role="edit_cancel_reason"]').val(hidden_cancel_reason)
            $('[role="edit_cancel_remarks"]').val(hidden_cancel_remarks)
            $('#edit_cancel').attr("class", "actions")
            $('#update_cancel').attr("class", "hidden")
            $('[role="edit_cancel_date"]').attr("disabled", true)
            $('[role="edit_cancel_reason"]').attr("disabled", true)
            $('[role="edit_cancel_remarks"]').attr("disabled", true)
        }
    }).modal('show')

    var temp_minDate = ""
    var temp_maxDate = $('#member_expiry').val()

    let member_expiry = new Date($('#member_expiry').val())
    let member_effectivity = new Date($('#member_effectivity').val())
    let member_suspend = new Date($('div[name="member_cancel"]').attr('suspend_date'))
    let member_reactivate = new Date($('div[name="member_cancel"]').attr('reactivate_date'))
    let today = new Date()

    if ($('div[name="member_cancel"]').attr('suspend_date') == "") {
        var cancel_minDate = new Date()
        var dayOfMonth1 = cancel_minDate.getDate();
        cancel_minDate.setDate(dayOfMonth1 + 1);
    } else if ($('div[name="member_cancel"]').attr('reactivate_date') == "") {
        if (today > member_suspend) {
            var cancel_minDate = new Date()
            var dayOfMonth1 = cancel_minDate.getDate();
            cancel_minDate.setDate(dayOfMonth1 + 1);

        } else if (today < member_suspend) {
            temp_minDate = $('div[name="member_cancel"]').attr('suspend_date');
            var cancel_minDate = new Date(temp_minDate);
            var dayOfMonth1 = cancel_minDate.getDate();
            cancel_minDate.setDate(dayOfMonth1 + 1);

        }

    } else {

        if (today > member_reactivate) {
            var cancel_minDate = new Date()
            var dayOfMonth1 = cancel_minDate.getDate();
            cancel_minDate.setDate(dayOfMonth1 + 1);

        } else if (today < member_reactivate) {
            temp_minDate = $('div[name="member_cancel"]').attr('reactivate_date');
            var cancel_minDate = new Date(temp_minDate);
            var dayOfMonth1 = cancel_minDate.getDate();
            cancel_minDate.setDate(dayOfMonth1 + 1);

        }

    }
    var cancel_maxDate = new Date(temp_maxDate);
    var dayOfMonth2 = cancel_maxDate.getDate();
    cancel_maxDate.setDate(dayOfMonth2 - 1);

    $('#cancel_date_picker').calendar({
        type: 'date',
        minDate: cancel_minDate,
        maxDate: cancel_maxDate,
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
    });

});

$('#edit_cancel_member').on('click', function() {
    $('#edit_cancel').attr("class", "hidden")
    $('#update_cancel').attr("class", "actions")
    $('#cancel_date').removeAttr("disabled")
    $('#cancel_reason').removeAttr("disabled")
    $('#cancel_remarks').removeAttr("disabled")
})

// Submit button
$('#btn_cancel_member').on('click', function() {

    const member_id = $('#member_id').val()
    const member_effectivity = $('#member_effectivity').val()
    const member_expiry = $('#member_expiry').val()
    const member_status = $('#member_status').val()
    const member_cancel = $('#cancel_date').val()
    const member_reason = $('#cancel_reason').val()
    if ((member_cancel != "" || member_reason == "") || (member_cancel == "" || member_reason != "")) {
        $('#cancel').form({
            on: blur,
            inline: true,
            fields: {
                'member[cancel_date]': {
                    identifier: 'member[cancel_date]',
                    rules: [{
                        type: 'empty',
                        prompt: 'Please enter cancellation date'
                    }, ]
                },
                'member[cancel_reason]': {
                    identifier: 'member[cancel_reason]',
                    rules: [{
                        type: 'empty',
                        prompt: 'Please enter reason'
                    }, ]
                },
            }
        })
        $('#cancel').submit()
    } else {
        swal({
            title: 'Cancel Member',
            text: `Cancelling this member will temporarily remove all funtions on ${member_cancel}?`,
            type: 'question',
            showCancelButton: true,
            cancelButtonText: '<i class="remove icon"></i> No, keep member',
            confirmButtonText: '<i class="check icon"></i> Yes, cancel member',
            cancelButtonClass: 'ui negative button',
            confirmButtonClass: 'ui positive button',
            reverseButtons: true,
            buttonsStyling: false
        }).then(function() {
            $('#cancel').submit()
        })
    }
})
// End of Submit button


// Submit button
$('#cancel_cancel').on('click', function() {
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
        $('#cancel_date').val('')
        $('#cancel_reason').val('')
        $('#cancel_remarks').val('')
        $('#cancel').submit()
    })

})
// End of Submit button

// End of Cancel member