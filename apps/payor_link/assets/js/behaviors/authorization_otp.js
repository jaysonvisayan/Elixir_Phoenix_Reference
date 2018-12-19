    onmount('div[id="show_consult"]', function() {
        $('#print_button').on('click', function() {
            $('#print_modal')
                .modal({
                    closable: false,
                    autofocus: false,
                    observeChanges: true
                })
                .modal('show')
        })

    // $('#skip_cvv').on('click', function() {
    //     $('#cvv_error').html("")
    //     $('#cvv_error').removeClass('ui red basic label left pointing')
    //     $('#cvv_field').removeClass('error')
    //     $('#cvv').val('')
    //     $('#cvv_consult_modal')
    //         .modal({
    //             transition: 'fade right'
    //         }).modal('hide').modal('hide dimmer');
    // })

    // $('#skip_otp').on('click', function() {
    //     $('#otp_error').html("")
    //     $('#otp_error').removeClass('ui red basic label left pointing')
    //     $('#otp_field').removeClass('error')
    //     $('#otp').val('')
    //     $('#otp_consult_modal')
    //         .modal({
    //             transition: 'fade right'
    //         }).modal('hide').modal('hide dimmer');
    // })

        let id = $('#authorization_id').val()
        $('#otp_original_button').on('click', function() {
            $('#copy').val('original')
            $('#print_modal')
                .modal({
                    transition: 'fade right'
                }).modal('close');
            $.ajax({
                url: `/authorizations/${id}/send_otp`,
                type: 'get',
                success: function(response) {
                    console.log("OTP Sent!")
                }
            })
            $('#otp_consult_modal').attr('class', 'ui tiny modal');
            $('#otp_consult_modal')
                .modal({
                    closable: false,
                    autofocus: false,
                    observeChanges: true,
                    transition: 'fade right'
                })
                .modal('show')
            var sec = $('#timer span').text()
            var timer = setInterval(function() {
               $('#timer span').text(--sec);
               if (sec == 0) {
                  $('#timer').fadeOut('fast');
                  $('#send_otp').removeAttr('style')
                  clearInterval(timer);
               }
            }, 1000);
        })

        $('#otp_duplicate_button').on('click', function() {
            $('#copy').val('duplicate')
            $('#print_modal')
                .modal({
                    transition: 'fade right'
                }).modal('close');
            $.ajax({
                url: `/authorizations/${id}/send_otp`,
                type: 'get',
                success: function(response) {
                    console.log("OTP Sent!")
                }
            })
            $('#otp_consult_modal').attr('class', 'ui tiny modal');
            $('#otp_consult_modal')
                .modal({
                    closable: false,
                    autofocus: false,
                    observeChanges: true,
                    transition: 'fade right'
                })
                .modal('show')

            var sec = $('#timer span').text()
            var timer = setInterval(function() {
               $('#timer span').text(--sec);
               if (sec == 0) {
                  $('#timer').fadeOut('fast');
                  $('#send_otp').removeAttr('style')
                  clearInterval(timer);
               }
            }, 1000);
        })

        $('#otp').keypress(function(evt) {
            evt = (evt) ? evt : window.event;
            var charCode = (evt.which) ? evt.which : evt.keyCode;
            $('#otp_error').html("")
            $('#otp_error').removeClass('ui red basic label left pointing')
            $('#otp_field').removeClass('error')
            if (charCode == 8 || charCode == 37) {
                return true;
            } else if (charCode == 46) {
                return false;
            } else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
                return false;
            }
            return true;
        });

        $('#otp_submit_button').on('click', function() {
            let otp = $('#otp').val()
            let copy = $('#copy').val()
             if (otp.length == 0) {
                $('#otp_error').html("")
                $('#otp_error').removeClass('ui red basic label left pointing')
                $('#otp_field').removeClass('error')
                $('#otp_error').append(' Please enter 4-digit PIN Code ')
                $('#otp_error').addClass('ui red basic label left pointing')
                $('#otp_field').addClass('error')
            } else if (otp.length != 4) {
                $('#otp_error').html("")
                $('#otp_error').removeClass('ui red basic label left pointing')
                $('#otp_field').removeClass('error')
                $('#otp_error').append(' Error authenticating PIN Code ')
                $('#otp_error').addClass('ui red basic label left pointing')
                $('#otp_field').addClass('error')
            } else {
                $.ajax({
                    url: `/authorizations/${id}/${otp}/${copy}/validate_otp`,
                    type: 'get',
                    success: function(response) {
                        if (response.message == "Invalid OTP") {
                            $('#otp_error').html("")
                            $('#otp_error').removeClass('ui red basic label left pointing')
                            $('#otp_field').removeClass('error')
                            $('#otp_error').append(' Error authenticating PIN Code ')
                            $('#otp_error').addClass('ui red basic label left pointing')
                            $('#otp_field').addClass('error')
                        } else if (response.message == "OTP already expired") {
                            $('#otp_error').html("")
                            $('#otp_error').removeClass('ui red basic label left pointing')
                            $('#otp_field').removeClass('error')
                            $('#otp_error').append(' The 4-Digit PIN Code that you have entered is already expired ')
                            $('#otp_error').addClass('ui red basic label left pointing')
                            $('#otp_field').addClass('error')
                        } else if (response.message == "Original Copy") {
                            $('#otp_error').html("")
                            $('#otp_error').removeClass('ui red basic label left pointing')
                            $('#otp_field').removeClass('error')
                            window.open(`/authorizations/${id}/${copy}/print_authorization`, '_blank')
                        } else if (response.message == "Duplicate Copy") {
                            $('#otp_error').html("")
                            $('#otp_error').removeClass('ui red basic label left pointing')
                            $('#otp_field').removeClass('error')
                            window.open(`/authorizations/${id}/${copy}/print_authorization`, '_blank')
                        } else {
                            console.log(response.message)
                        }
                    }
                })
            }

        })


        // $('#cvv_submit_button').on('click', function() {
        //     let cvv = $('#cvv').val()
        //     if (cvv.length == 0) {
        //         $('#cvv_error').html("")
        //         $('#cvv_error').removeClass('ui red basic label left pointing')
        //         $('#cvv_field').removeClass('error')
        //         $('#cvv_error').append(' Please enter CVV ')
        //         $('#cvv_error').addClass('ui red basic label left pointing')
        //         $('#cvv_field').addClass('error')
        //     } else if (cvv.length != 3 || 0) {
        //         $('#cvv_error').html("")
        //         $('#cvv_error').removeClass('ui red basic label left pointing')
        //         $('#cvv_field').removeClass('error')
        //         $('#cvv_error').append(' Please enter 3-digit CVV ')
        //         $('#cvv_error').addClass('ui red basic label left pointing')
        //         $('#cvv_field').addClass('error')
        //     } else {
        //         $.ajax({
        //             url: `/authorizations/${id}/${cvv}/validate_cvv`,
        //             type: 'get',
        //             success: function(response) {
        //                 if (response.message == "Invalid CVV") {
        //                     $('#cvv_error').html("")
        //                     $('#cvv_error').removeClass('ui red basic label left pointing')
        //                     $('#cvv_field').removeClass('error')
        //                     $('#cvv_error').append(' Error authenticating CVV ')
        //                     $('#cvv_error').addClass('ui red basic label left pointing')
        //                     $('#cvv_field').addClass('error')
        //                 } else if (response.message == "Successful") {
        //                     $('#cvv_error').html("")
        //                     $('#cvv_error').removeClass('ui red basic label left pointing')
        //                     $('#cvv_field').removeClass('error')
        //                     window.location.href = `/authorizations/${id}/auth_verified`;
        //                 } else {
        //                     console.log(response.message)
        //                 }
        //             }
        //         })
        //     }

        // })

        // $('#enter_otp').on('click', function() {
        //     $('#cvv_consult_modal')
        //         .modal({
        //             transition: 'fade right'
        //         }).modal('close');
        //     $('#cvv_error').html("")
        //     $('#cvv_error').removeClass('ui red basic label left pointing')
        //     $('#cvv_field').removeClass('error')
        //     $('#cvv').val('')
        //     $('#otp_consult_modal').attr('class', 'ui tiny modal');
        //     $('#otp_consult_modal').modal({
        //         transition: 'fade right'
        //     }).modal('show');
        //     $.ajax({
        //         url: `/authorizations/${id}/send_otp`,
        //         type: 'get',
        //         success: function(response) {
        //             console.log("OTP Sent!")
        //         }
        //     })

        // })

        // $('#enter_cvv').on('click', function() {
        //     $('#otp_consult_modal')
        //         .modal({
        //             transition: 'fade right'
        //         }).modal('close');
        //     $('#otp_error').html("")
        //     $('#otp_error').removeClass('ui red basic label left pointing')
        //     $('#otp_field').removeClass('error')
        //     $('#otp').val('')
        //     $('#cvv_consult_modal').attr('class', 'ui tiny modal');
        //     $('#cvv_consult_modal').modal({
        //         transition: 'fade right'
        //     }).modal('show');;

        // })

        $('#send_otp').on('click', function() {
            $.ajax({
                url: `/authorizations/${id}/send_otp`,
                type: 'get',
                success: function(response) {
                    console.log("OTP Sent!")
                }
            })
            $('#timer span').text('60')
            $('#send_otp').attr('style', 'pointer-events: none;cursor: default;text-decoration:none;color:black')
            $('#timer').removeAttr('style')
            var sec = $('#timer span').text()
            var timer = setInterval(function() {
               $('#timer span').text(--sec);
               if (sec == 0) {
                  $('#timer').hide()
                  clearInterval(timer);
               }
            }, 1000);
        })
        // $('#cvv').keypress(function(evt) {
        //     evt = (evt) ? evt : window.event;
        //     var charCode = (evt.which) ? evt.which : evt.keyCode;
        //     $('#cvv_error').html("")
        //     $('#cvv_error').removeClass('ui red basic label left pointing')
        //     $('#cvv_field').removeClass('error')
        //     if (charCode == 8 || charCode == 37) {
        //         return true;
        //     } else if (charCode == 46) {
        //         return false;
        //     } else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
        //         return false;
        //     }
        //     return true;
        // });

})
