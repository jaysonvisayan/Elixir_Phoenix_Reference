onmount('div[id="accountVerification"]', function() {
  let attempts = $('#attemptsChecker').attr('attempts')
  if(attempts == 3) {
    $('#attemptsChecker').empty()
    $('#attemptsChecker').append(
      "Your account is locked please reset your password!"
    )
  }
})
