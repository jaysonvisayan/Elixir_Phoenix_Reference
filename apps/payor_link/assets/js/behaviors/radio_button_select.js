onmount('div[role="clickable-segment"]', function(){
  $(this).css("cursor", "pointer")

  $(this).on('click', function(){
    $(this).find('input[type="radio"]').prop("checked", true)
  })
})
