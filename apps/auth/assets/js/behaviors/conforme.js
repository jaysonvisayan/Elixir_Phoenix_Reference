onmount('input[id="chk_member_conforme"]', function () {
  $('a[id="lnk_member_conforme"]').on('click', function(){
    $('div[id="member_conforme"]').modal('show');
  });

  $('a[id="btn-accept-consent"]').on('click', function(){
    if ($('input[id="chk_member_conforme"]').is(':checked')) {
      $('#message_consent').hide();
      $('#message_consent').html('');
      return true;
    } else {
      $('#message_consent').show();
      $('#message_consent').html('Please indicate that you have read and agree to the terms and conditions stated in the MEMBER CONFORME.');
      return false;
    }
  });
})
