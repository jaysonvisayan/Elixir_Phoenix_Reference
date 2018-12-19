onmount('form[id="emergencyContactForm"]', function (){


  let validMobileNos = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994","976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];
  $.fn.form.settings.rules.checkMobilePrefix = function(param) {
    return validMobileNos.indexOf(param.substring(1,4)) == -1 ? false : true;
  }

  $('#emergencyContactForm')
  .form({
    inline: true,
    fields: {
      account_code: {
        identifier: 'member[ecp_email]',
        optional: true,
        rules: [
	        {
	          type: 'email',
	          prompt: 'Please enter a valid Email'
	        }
        ]
      },
      phone1: {
        identifier: 'member[ecp_phone]',
        optional: true,
        rules: [
          {
            type  : 'checkMobilePrefix[param]',
            prompt: 'Mobile prefix is invalid.'
          },
          {
            type   : 'exactLength[11]',
            prompt : 'Phone Number must be {ruleValue} digits'
          }
        ]
      },
      phone2: {
        identifier: 'member[ecp_phone2]',
        optional: true,
        rules: [
          {
            type  : 'checkMobilePrefix[param]',
            prompt: 'Mobile prefix is invalid.'
          },
          {
            type   : 'exactLength[11]',
            prompt : 'Additional Phone Number must be {ruleValue} digits'
          }
        ]
      }
    }
  })

})


