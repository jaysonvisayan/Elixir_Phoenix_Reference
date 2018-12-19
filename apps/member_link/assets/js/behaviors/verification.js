onmount('div[id="verificationInput"]', function(){
 	var charLimit = 1;
 	$('input[class="verificationCode"]').keydown(function(e){
    var keyChar = [8, 9, 19, 20, 27, 33, 34, 35, 37, 38, 39, 40, 45, 46, 48, 144, 145,
      96, 97, 98, 99, 100, 101, 102, 103, 104, 105];

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
});

onmount('div[id="cardVerificationInput"]', function(){
 	var charLimit = 4;
 	$('input[class="cardVerification"]').keydown(function(e){
    var keyChar = [8, 9, 19, 20, 27, 33, 34, 35, 37, 38, 39, 40, 45, 46, 48, 144, 145,
      96, 97, 98, 99, 100, 101, 102, 103, 104, 105];

 		if (e.which == 8 && this.value.length == 0){
 			$(this).closest('div[class="field"]').prev().find('.cardVerification').focus();
 		}
    else if ($.inArray(e.which, keyChar) >= 0){
 			return true;
 		}
 		else if (this.value.length >= charLimit){
 			$(this).closest('div[class="field"]').next().find('.cardVerification').focus();
 			return false;
 		}
 		else if (e.shiftKey || e.which <= 48 || e.which >= 58){
 			return false;
 		}
 	}).keyup(function(){
 		if (this.value.length >= charLimit){
 			$(this).closest('div[class="field"]').next().find('.cardVerification').focus();
 			return false;
 		}
 	});
});

onmount('div[name="LoginVerifyCode"]', function(){
  $('#verifyButton').attr("disabled", true)
  $('input[type="text"]').keydown(function(e){
    var keyChar = [8, 9, 19, 20, 27, 33, 34, 35, 37, 38, 39, 40, 45, 46, 48, 144, 145,
      96, 97, 98, 99, 100, 101, 102, 103, 104, 105];
    if($.inArray(e.which, keyChar) >=0){
      return true;
    }
 		else if (e.shiftKey || e.which <= 48 || e.which >= 58){
 			return false;
 		}

  }).keyup(function(){
    if (this.value.length >= 4){
      $('#verifyButton').attr("disabled", false)
      return false;
    }
    else{
      $('#verifyButton').attr("disabled", true)
    }
  })
})
