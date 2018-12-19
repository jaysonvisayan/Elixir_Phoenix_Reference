onmount('div[id="verificationInput"]', function(){
 	var charLimit = 1;
 	$('input[class="verificationCode"]').keydown(function(e){
    var keyChar = [8, 9, 19, 20, 27, 33, 34, 35, 37, 38, 39, 40, 45, 46, 48, 54, 96, 97, 98,
                  99, 100, 101, 102, 103, 104, 105, 144, 145];

 		if (e.which == 8 && this.value.length == 0){
 			$(this).closest('div[class="field"]').prev().find('.verificationCode').focus();
 		}
 		else if ($.inArray(e.which, keyChar) >= 0){
 			return true;
 		}
 		else if (this.value.length >= charLimit){
 			$(this).closest('div[class="field"]').next().find('.verificationCode').focus();
 			return false;
 		}
 		else if (e.shiftKey || e.which <= 48 || e.which >= 58){
 			return false;
 		}
 	}).keyup(function(){
 		if (this.value.length >= charLimit){
 			$(this).closest('div[class="field"]').next().find('.verificationCode').focus();
 			return false;
 		}
 	});

  $('form#verify_form').on('submit', function(e) {
    if ($("#g-recaptcha-response").val() == "") {
      $('#append').html('<br /><div class="ui negative tiny message"><i class="close icon"></i>Please verify that you are not a robot.</div>')
      e.preventDefault()
    }
  })

});
