onmount('div[name="LoginValidation"]', function() {

    $("#eye").click(function() {
        var input = $('#password_text');
        if (input.attr("type") == "password") {
            input.attr("type", "text");
        } else {
            input.attr("type", "password");
        }
    });

    $('#username_text').on('keyup', function() {
      if ($(this).find('input').val() != "") {
        $('#username').removeClass('error')
        $('#username').find('.red').remove()
      }
    })

    $('#password_text').on('keypress', function(e) {
        if ($(this).find('input').val() != "") {
            $('#password').removeClass('error')
            $('#password').find('.red').remove()
        }
        var character = e.keyCode ? e.keyCode : e.which;
        var sftKey = e.shiftKey ? e.shiftKey : ((character == 16) ? true : false);
        // Is caps lock on?
        var isCapsLock = (((character >= 65 && character <= 90) && !sftKey) || ((character >= 97 && character <= 122) && sftKey));
        // Display warning and set css
        if (isCapsLock == true) {
            $('#password').addClass('error')
            $('#password').append(`<div class="ui red left pointing label transition visible" style="-webkit-box-shadow: 0 0 10px red;box-shadow: 0 0 10px red">WARNING: Caps Lock is on</div>`)
        }
    })

    $('#payroll_code_text').on('keyup', function() {
        if ($(this).find('input').val() != "") {
            $('#payroll_code').removeClass('error')
            $('#payroll_code').find('.red').remove()
        }
    })

    $('form#login_form').on('submit', function(e) {
        const username = $('input[name="session[username]"]').val()
        const password = $('input[name="session[password]"]').val()
        const payroll_code = $('input[name="session[payroll_code]"]').val()
        if (username == "") {
            $('#username').removeClass('error')
            $('#username').find('.red').remove()
            $('#username').addClass('error')
            $('#username').append(`<div class="ui red left pointing label transition visible" style="-webkit-box-shadow: 0 0 10px red;box-shadow: 0 0 10px red">Please enter username</div>`)
            e.preventDefault()
        }
        if (password == "") {
            $('#password').removeClass('error')
            $('#password').find('.red').remove()
            $('#password').addClass('error')
            $('#password').append(`<div class="ui red left pointing label transition visible" style="-webkit-box-shadow: 0 0 10px red;box-shadow: 0 0 10px red">Please enter password</div>`)
            e.preventDefault()
        }
        if (payroll_code == "") {
            $('#payroll_code').removeClass('error')
            $('#payroll_code').find('.red').remove()
            $('#payroll_code').addClass('error')
            $('#payroll_code').append(`<div class="ui red left pointing label transition visible" style="-webkit-box-shadow: 0 0 10px red;box-shadow: 0 0 10px red">Please enter payroll code</div>`)
            e.preventDefault()
        }
        if ($("#g-recaptcha-response").val() == "") {
            $('#append').html('<br /><div class="ui red left pointing label transition visible" style="-webkit-box-shadow: 0 0 10px red;box-shadow: 0 0 10px red">Please enter reCAPTCHA</div>')
            e.preventDefault()
        }
    });
});

function remove_error() {
    $('#username').removeClass('error')
    $('#password').removeClass('error')
    $('#payroll_code').removeClass('error')
    $('#username').find('.red').remove()
    $('#password').find('.red').remove()
    $('#payroll_code').find('.red').remove()
}