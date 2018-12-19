onmount('.ui.checkbox', function(){
  $('.ui.checkbox').checkbox();
});

onmount('button[id="preventNext"]', function () {
  $('#preventNext').on('click', function(){
    let message = $(this).attr('message')
    swal({
      title: `${message}`,
      type: 'error',
      allowOutsideClick: true,
      confirmButtonText: 'OK',
      confirmButtonClass: 'ui button',
      buttonsStyling: false
    }).catch(swal.noop)
  });
});

onmount('#smart-health-container', function () {
  $('body').css('overflow', 'hidden')
})