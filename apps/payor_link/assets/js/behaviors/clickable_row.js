onmount('.clickable-row', function () {
  const el = $(this)
  el.on('click', function(e) {
    window.document.location = $(this).attr("href");
  })

  $('a[id="asm_update_status"]').on('click', function(e){
    let asm_id = $(this).attr("asm_id")
    $('input[name="asm[asm_id]"]').val(asm_id)
    swal({
      title: 'Remove member?',
      text: '',
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, remove member',
      cancelButtonText: '<i class="remove icon"></i> No, keep member',
      confirmButtonClass: 'ui positive button',
      cancelButtonClass: 'ui negative button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false
    }).then(function() {
      $('#remove_member').submit()
    })
  })

  $('div[role="retract"]').on('click', function(e){
    swal({
      title: 'Are you sure you want to retract movement?',
      text: '',
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, retract movement',
      cancelButtonText: '<i class="remove icon"></i> No, dont retract movement',
      confirmButtonClass: 'ui positive button',
      cancelButtonClass: 'ui negative button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false
    }).then(function() {
      $('#retract').submit()
    })
  })

  $('div[role="delete-product"]').on('click', function(){
    let product = $(this)
    swal({
      title: 'Remove plan?',
      text: '',
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Remove Plan',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Plan',
      confirmButtonClass: 'ui positive button',
      cancelButtonClass: 'ui negative button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false

    }).then(function() {
      product.find('#account_product').submit()
    })
  })

  $('div[role="cancel-renewal"]').on('click', function(){
    swal({
      title: 'Cancel Renewal?',
      text: 'Canceling renewal this account will permanently remove edit function.',
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Cancel Renewal',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Renewal',
      confirmButtonClass: 'ui positive button',
      cancelButtonClass: 'ui negative button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false

    }).then(function() {
      $('#form-cancel').submit()
    })
  })

  $('div[role="activate-account"]').on('click', function(){
    swal({
      title: 'Activate?',
      text: 'You may no longer edit this renewal after activation.',
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Activate Renewal',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Renewal',
      confirmButtonClass: 'ui positive button',
      cancelButtonClass: 'ui negative button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false

    }).then(function() {
      $('#form-activate').submit()
    })
  })

  $('div[role="renew-account"]').on('click', function(){
    swal({
      title: 'Renew Account?',
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Renew Account',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Account',
      confirmButtonClass: 'ui positive button',
      cancelButtonClass: 'ui negative button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false

    }).then(function() {
      $('#form-renew').submit()
    })
  })
});

onmount('.new.tab', function(){
  const el = $(this)
  el.on('click', function(e) {
    let url = $(this).attr("href");
    window.open(url, '_blank');
  })
})

onmount('.close-modal', function(){
  $('#close_modal').hide()

  const el = $(this)
  el.on('click', function(e) {
    $('#close_modal').click()
  })
})
