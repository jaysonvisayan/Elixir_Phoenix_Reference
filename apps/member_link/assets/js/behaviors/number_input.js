onmount('.ui .grid', function(){
  const number_input = () => {
    $('input[type="number"]').on('keypress', function(evt){
      let theEvent = evt || window.event;
      let key = theEvent.keyCode || theEvent.which;
      key = String.fromCharCode( key );
      let regex = /[a-zA-Z``~<>^'{}[\]\\;':",./?!@#$%&*()_+=-]|\./;
      let min = $(this).attr("minlength")

      if( regex.test(key) ) {
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
  number_input()
})
