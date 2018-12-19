onmount('.ui .grid', function(){
  $('p[role="validate"]').hide();
  $('p[error="select"]').hide();
  $('p[error="number"]').hide();

  $('.person.name').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[a-zA-Z,. -]/;

    if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key) == false){
      return false;
    }else{
      $(this).on('focusout', function(evt){
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  })

  $('.product.name').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[a-zA-Z0-9:() -]/;

    if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key) == false){
      return false;
    }else{
      if($(this).val().length >= $(this).attr("maxlength")){
        $(this).next('p[role="validate"]').hide();
        $(this).on('keyup', function(evt){
          if(evt.keyCode == 8){
            $(this).next('p[role="validate"]').show();
          }
        })
        return false;
      } else {
        $(this).on('focusout', function(evt){
          $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
        })
      }
    }
  })

  $('.alphanumeric').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[a-zA-Z,0-9. -]/;

    if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key) == false){
      return false;
    }else{
      $(this).on('focusout', function(evt){
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  })

  $('input[type="text"]').on('keypress', function(evt){
    if($(this).hasClass('email') == false) {
      if($(this).val().length <= 1 && evt.keyCode == 32){
        return false;
      }else{
        $(this).on('focusout', function(evt){
          $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
        })
      }
    }
  })

  $('input[id="contact"]').on('focusout', function(){
    $(this).each(function(){
      if ($(this).val().length >= $(this).attr("minlength")) {
        $(this).next('p[role="validate"]').hide();
      }
    })
  });

   number_input()
   email_input()

   $('a').on('click', function(){
     number_input()
   })

   $('button[id="modal_contact"]').on('click', function(e){
     $('div[role="add"]').find('select[id="select"]').each(function(){
       if ($(this).val() == "") {
         $('p[error="select"]').show();
         e.preventDefault();
         return false;
       }else{
         $('p[error="select"]').hide();
       }
     })
     $('div[role="add"]').find('input[id="contact"]').each(function(){
       if($(this).prop('disabled') == false) {
         if ($(this).val().length < $(this).attr("minlength")) {
           $('p[error="number"]').show();
           e.preventDefault();
           return false;
         }else{
           $('p[error="number"]').hide();
         }
       }
     });
   })

   $('button[id="edit_modal_contact"]').on('click', function(e){
     $('div[role="edit"]').find('select[id="select"]').each(function(){
       if ($(this).val() == "") {
         $('p[error="select"]').show();
         e.preventDefault();
         return false;
       }else{
         $('p[error="select"]').hide();
       }
     })
     $('div[role="edit"]').find('input[id="contact"]').each(function(){
       if ($(this).val().length < $(this).attr("minlength")) {
         $('p[error="number"]').show();
         e.preventDefault();
         return false;
       }else{
         $('p[error="number"]').hide();
       }
     });
   })

})

const email_input = () => {
  $('.email-address').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[``~<>^'{}[\]\\;':"/?!#$%&*()+=]|\,/;

    if( regex.test(key) ) {
      theEvent.returnValue = false;
      if(theEvent.preventDefault) theEvent.preventDefault();
    }
  })
}

const number_input = () => {
  $('input[type="number"]').attr("min", 0)
  $('input[type="number"]').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[a-zA-Z``~<>^'{}[\]\\;':",./>?!@#$%&*()_+=-]|\./;
    let min = $(this).attr("minlength")

    if( regex.test(key) || key == "e") {
      theEvent.returnValue = false;
      if(theEvent.preventDefault) theEvent.preventDefault();
    }else{
      if($(this).val().length >= $(this).attr("maxlength")){
          $(this).next('p[role="validate"]').hide();
          $(this).on('keyup', function(evt){
            if(evt.keyCode == 8){
              $(this).next('p[role="validate"]').show();
            }
          })
          return false;
      }else if( min > $(this).val().length){
        $(this).next('p[role="validate"]').show();
        $(this).on('focusout', function(evt){
          $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
        })
      }
      else{
        $(this).next('p[role="validate"]').hide();
        $(this).on('focusout', function(evt){
          $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
        })
      }
    }
  })
}

onmount('#benefit_limits', function(){
  $('input[type="text"]').on('keypress', function(evt){
    if($(this).val().length <= 1 && evt.keyCode == 32){
      return false;
    }else{
      $(this).on('focusout', function(evt){
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }

  })

  number_input()

});
