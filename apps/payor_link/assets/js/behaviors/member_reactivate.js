// Reactivate Member
$('div[name="member_reactivate"]').on('click', function() {

    let hidden_reactivate_date = $('#hidden_reactivate_date').val()
    let hidden_reactivate_reason = $('#hidden_reactivate_reason').val()
    let hidden_reactivate_remarks = $('#hidden_reactivate_remarks').val()
    $('[role="edit_reactivate_date"]').val(hidden_reactivate_date)
    $('[role="edit_reactivate_reason"]').val(hidden_reactivate_reason)
    $('[role="edit_reactivate_remarks"]').val(hidden_reactivate_remarks)
    $('div[role="member_reactivate"]').modal({
        closable: false,
        autofocus: false,
        observeChanges: true,
        onHide: function() {
            $('[role="reactivate_date"]').val('')
            $('[role="reactivate_reason"]').val('')
            $('[role="reactivate_remarks"]').val('')
            $('[role="edit_reactivate_date"]').val(hidden_reactivate_date)
            $('[role="edit_reactivate_reason"]').val(hidden_reactivate_reason)
            $('[role="edit_reactivate_remarks"]').val(hidden_reactivate_remarks)
            $('#edit_reactivate').attr("class", "actions")
            $('#update_reactivate').attr("class", "hidden")
            $('[role="edit_reactivate_date"]').attr("disabled", true)
            $('[role="edit_reactivate_reason"]').attr("disabled", true)
            $('[role="edit_reactivate_remarks"]').attr("disabled", true)
        }
    }).modal('show')

    var reactivate_minDate = new Date();
    var dayOfMonth = reactivate_minDate.getDate();
    reactivate_minDate.setDate(dayOfMonth + 1);
    var temp_maxDate = "";

    if ($(this).attr('cancel_date') == "") {
        temp_maxDate = $('#member_expiry').val()
    } else {
        temp_maxDate = $(this).attr('cancel_date');
    }

    // previous day before the CANCEL DATE or ENDDATE
    var reactivate_maxDate = new Date(temp_maxDate);
    var dayOfMonth = reactivate_maxDate.getDate();
    reactivate_maxDate.setDate(dayOfMonth - 1);

    $('#reactivate_date_picker').calendar({
        type: 'date',
        minDate: reactivate_minDate,
        maxDate: reactivate_maxDate,
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

$('#edit_reactivate_member').on('click', function() {
    $('#edit_reactivate').attr("class", "hidden")
    $('#update_reactivate').attr("class", "actions")
    $('#reactivate_date').removeAttr("disabled")
    $('#reactivate_reason').removeAttr("disabled")
    $('#reactivate_remarks').removeAttr("disabled")
})


// Submit button
$('#btn_reactivate_member').on('click', function() {

    const member_id = $('#member_id').val()
    const member_effectivity = $('#member_effectivity').val()
    const member_expiry = $('#member_expiry').val()
    const member_status = $('#member_status').val()
    const member_reactivate = $('#reactivate_date').val()
    const member_reason = $('#reactivate_reason').val()
    if ((member_reactivate != "" || member_reason == "") || (member_reactivate == "" || member_reason != "")) {
        $('#reactivate').form({
            on: blur,
            inline: true,
            fields: {
                'member[reactivate_date]': {
                    identifier: 'member[reactivate_date]',
                    rules: [{
                        type: 'empty',
                        prompt: 'Please enter reactivation date'
                    }, ]
                },
                'member[reactivate_reason]': {
                    identifier: 'member[reactivate_reason]',
                    rules: [{
                        type: 'empty',
                        prompt: 'Please enter reason'
                    }, ]
                },
            }
        })
        $('#reactivate').submit()
    } else {
        $('#reactivate').submit()

    }
})
// End of Submit button


// Submit button
$('#cancel_reactivate').on('click', function() {
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
        $('#reactivate_date').val('')
        $('#reactivate_reason').val('')
        $('#reactivate_remarks').val('')
        $('#reactivate').submit()
    })

})
// End of Submit button

// End of Reactivate Member