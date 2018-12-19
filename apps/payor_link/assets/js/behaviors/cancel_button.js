onmount('div[id="cancel_button"]', function () {
  $(this).modal('attach events', '#test', 'show');
});

onmount('div[id="modal_cancel"]', function () {
  $(this).modal('attach events', '#cancel_button', 'show');

  $('div[role="delete-draft"]').on('click', function(){
     $('#delete-draft').submit()
  })
});
