onmount('div[name="Login"]', function () {
  $('#password').on('keyup', function(){
    if($(this).find('input').val() != ""){
     $('#password').removeClass('error')
     $('div[id="message"]').remove()
    }
  });

  $('form[id="sign_in"]').on('submit', function(e){
    const username = $('input[name="session[username]"]').val()
    const password = $('input[name="session[password]"]').val()
    $('div[id="message"]').remove()

   if(username == "" && password == ""){
      $('p[role="append"]').append('<div id="message" class="ui negative message userpass">Please enter your username and password</div>')
      $('#username').addClass('error')
      $('#password').addClass('error')

      $('#username').on('keyup', function(){
        if($(this).find('input').val() != ""){
          $('#username').removeClass('error')

          if($('#passsword').val() == ""){
            $('.userpass').remove()
          }else{
            $('div[id="message"]').remove()
            $('p[role="append"]').append('<div id="message" class="ui negative message pass">Please enter your password</div>')
          }
        }
      })
      e.preventDefault()
    }else if(username == ""){
      $('p[role="append"]').append('<div id="message" class="ui negative message user">Please enter your username</div>')
      $('#username').addClass('error')
      e.preventDefault()
    }else if(password == ""){
      $('p[role="append"]').append('<div id="message" class="ui negative message pass">Please enter your password</div>')
      $('#password').addClass('error')
      e.preventDefault()
    }
  });
});

onmount('div[name="LoginVerifyCode"]', function () {
  $(document).ready(function () {
    var counter = 60;
    var id = setInterval(function() {
     counter--;
     if(counter > 0) {
       var msg = 'You can send a new code after ' + counter + ' seconds';
       $('#notice').text(msg);
     } else {
       $('#notice').hide()
       $('#new_code').show();
       clearInterval(id);
     }
    }, 1000)
  });

  let test = $('input[name="user[verification_code][]"]').val();

  $('input[name="user[verification_code][]"]').each(function(){
    if($(this).val() == ""){
      $('button[type="submit"]').prop('disabled', true);
    }
    else{
      $('button[type="submit"]').prop('disabled', false);
    }
  });

  $('input[name="user[verification_code][]"]').on('keyup', function(){
    $('input[name="user[verification_code][]"]').each(function(){
      if($(this).val() == ""){
        $('button[type="submit"]').prop('disabled', true);
      }
      else{
        $('button[type="submit"]').prop('disabled', false);
      }
    });
  });
});
