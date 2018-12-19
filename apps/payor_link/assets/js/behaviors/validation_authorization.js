onmount('div[id="member_card"]', function(){
  $('#member_card').form({
    on: blur,
    inline: true,
    fields: {
      'authorization[card_number]': {
        identifier: 'authorization[card_number]',
        rules: [{
          type  : 'empty',
          prompt: 'Please enter Card Number'
        },
        {
          type   : 'minLength[16]',
          prompt : 'This field must be at least {ruleValue} digits'
        }]
      },
      'authorization[cvv_number]': {
        identifier: 'authorization[cvv_number]',
        rules: [{
          type  : 'empty',
          prompt: 'Please enter CVV Number'
        },
        {
          type   : 'minLength[3]',
          prompt : 'This field must be at least {ruleValue} digits'
        }]
      },
    }
  })
})

onmount('div[id="member_info"]', function(){

  $('input[name="authorization[full_name]"]').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[0-9``~<>^'{}[\]\\;':"/?!@#$%&*()_+=]/;

    if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
      return false;
    }else{
      $(this).on('focusout', function(evt){
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  })

  $('#member_info').form({
    on: blur,
    inline: true,
    fields: {
      'authorization[birthdate]': {
        identifier: 'authorization[birthdate]',
        rules: [{
          type  : 'empty',
          prompt: 'Please enter Birth Date'
        }]
      },
      'authorization[full_name]': {
        identifier: 'authorization[full_name]',
        rules: [{
          type  : 'empty',
          prompt: 'Please enter Full Name'
        }]
      },
    }
  })
})
