onmount('.ui.checkbox', function(){
  $('.ui.checkbox').checkbox();
});

onmount('button[id="preventNext"]', function () {
  $('#preventNext').on('click', function(){
    let message = $(this).attr('message')
    alertify.error(`<i class="close icon"></i><p>${message}</p>`);
  });
});

onmount('.person.name', function () {
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
});
