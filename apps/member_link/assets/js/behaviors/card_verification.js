onmount('div[name="cardVerification"]', function () {
  $('.ui.dropdown').dropdown();
  $('#submit').on('click', function(){
    $.fn.form.settings.rules.checkCardLength = function(param) {
      let arr = []
      $('input[name="user[card_number][]"]').each(function(){
        arr.push($(this).val())
      })
      let length = arr.join().replace(/,/g, "").length
      if(length == 16){
        return true
      }
      else{
        return false
      }
    }
    $.fn.form.settings.rules.checkBirthday = function(param) {
      if($('select[name="user[date]"]').val() == "" || $('select[name="user[month]"]').val() == "" || $('select[name="user[year]"]').val() == ""){
        return false
      }
      else{
        return true
      }
    }
    $.fn.form.settings.rules.checkBirthdayBlank = function(param) {
      if($('select[name="user[date]"]').val() == "" && $('select[name="user[month]"]').val() == "" && $('select[name="user[year]"]').val() == ""){
        return false
      }
      else{
        return true
      }
    }
    $('.ui.form')
    .form({
      inline: true,
      on: 'blur',
      fields: {
        'cardLength':{
          identifier : 'cardLength',
          rules : [
            {
              type : 'checkCardLength[param]',
              prompt : "Please input valid card number"
            }
          ]
        },
        'termsandconditions':{
          identifier : 'termsandconditions',
          rules : [
            {
              type : 'checked',
              prompt : "Please indicate that you accept the Terms and Conditions"
            }
          ]
        },
        'birthDateValidate':{
          identifier : 'birthDateValidate',
          rules :[
            {
              type : 'checkBirthdayBlank[param]',
              prompt : "Please enter date of birth"
            },
            {
              type : 'checkBirthday[param]',
              prompt : "Birthday is invalid"
            }
          ]
        }
      }
    })

  })
});

