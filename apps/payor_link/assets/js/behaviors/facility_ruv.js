onmount('div[id="ruv_index"]', function() {

    $('#add_ruv').on('click', function() {

        var min_date = $('#hidden_date').val()

        $('#ruv_modal').modal({
            closable: false,
            onShow: function() {
                var min_date = $('#hidden_date').val(new Date())
                $('#code_description').change(function() {
                    var id = $('#code_description').val()
                    $.ajax({
                        url: `/ruvs/${id}/get`,
                        type: 'GET',
                        success: function(response) {
                            min_date = new Date(response.effectivity_date)
                            var dayOfMonth1 = min_date.getDate()
                            min_date.setDate(dayOfMonth1 + 1)

                            var today = new Date()
                            var get_day = today.getDate();
                            today.setDate(get_day + 1);

                            var minimum = ""
                            if(today > min_date){
                                minimum = today
                            }
                            else if(today < min_date){
                                minimum = min_date
                            }
                            $('#ruv_effectivity_date').calendar({
                                type: 'date',
                                minDate: minimum,
                                formatter: {
                                    date: function(date, settings) {
                                        if (!date) return '';
                                        var day = ("0" + date.getDate()).slice(-2);
                                        var month = ("0" + (date.getMonth() + 1)).slice(-2);
                                        var year = date.getFullYear();
                                        return day + '/' + month + '/' + year;
                                    }
                                }
                            })
                        }

                    })
                    $('#effectivity_date').val('')
                })
            },
            onDeny: function() {
                //
            },
            onApprove: function() {
                //

            }
        }).modal('show');
    })

    $('#ruv_submit').on('click', function() {

        // const effectivity_date = $('#effectivity_date').val()
        const code_description = $('#code_description').val()
        if (code_description == "") {
            $('#addruv').form({
                on: blur,
                inline: true,
                fields: {
                    'facility_ruv[ruv_id]': {
                        identifier: 'facility_ruv[ruv_id]',
                        rules: [{
                            type: 'empty',
                            prompt: 'Please select RUV'
                        }, ]
                    },
                    // 'facility_ruv[effectivity_date]': {
                    //     identifier: 'facility_ruv[effectivity_date]',
                    //     rules: [{
                    //         type: 'empty',
                    //         prompt: 'Please enter effectivity_date'
                    //     }, ]
                    // },
                }
            })
            $('#addruv').submit()
        } else {
            $('#addruv').submit()
        }
    })

})

onmount('div[id="main_file_upladed_ruv"]', function() {
    $('#file_upload').on('change', function(event) {
        let csvfile = event.target.files[0];
        if (csvfile.size >= 1048576) {
            $(this).val('')
            alert_error_size()
        }

    })

    function alert_error_size() {
        alertify.error('File maximum size reached (maximum size: 1mb).<i id="notification_error" class="close icon"></i>');
        alertify.defaults = {
            notifier: {
                delay: 8,
                position: 'top-right',
                closeButton: false
            }
        };
    }

})
