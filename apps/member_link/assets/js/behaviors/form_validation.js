onmount('div[name="AccountValidation"]', function(){
  $('#AccountForm').form({
    on: 'blur',
    inline: true,
    fields: {
      'user[old_password]': {
        identifier: 'user[old_password]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter old password'
        }]
      },
      'user[password]': {
        identifier: 'user[password]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter new password'
        },
        {
          type: 'regExp[/(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}/]',
          prompt: 'Password must be 8 to 20 characters long and should include at least 1 numeric character, special character and uppercase letter.'
        }]
      },
      'user[password_confirmation]': {
        identifier: 'user[password_confirmation]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter confirm new password'
        },
        {
          type: 'match[user[password]]',
          prompt: "Password doesn't match"
        }]
      },
    },
  });

});

onmount('div[name="ContactDetailsValidation"]', function(){
  let validMobilePrefix = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994","976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  $.fn.form.settings.rules.validateMobile = function(param) {

    if (param == '') {
      return true;
    } else {

      param = param.replace(/-/g, '');
      if (/^0[0-9]{10}$/.test(param)) {
        return validMobilePrefix.indexOf(param.substring(1,4)) == -1 ? false : true;
      } else {
        return false;
      }
    }
  }

  $('#ContactDetailsForm').form({
    on: 'blur',
    inline: true,
    fields: {
      'contact[email]': {
        identifier: 'contact[email]',
        rules: [{
          type: 'empty',
          prompt: "Please enter email address"
        },
        {
          type: 'regExp[/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/]',
          prompt: 'The email you have entered is invalid'
        }]
      },
      'contact[email_confirmation]': {
        identifier: 'contact[email_confirmation]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter confirm email address'
        },
        {
          type: 'match[contact[email]]',
          prompt: "Email address doesn't match"
        }]
      },
      'contact[mobile]': {
        identifier: 'contact[mobile]',
        rules: [{
          type: 'empty',
          prompt: "Please enter mobile number"
        },
        {
          type: 'validateMobile[param]',
          prompt: 'The Mobile number you have entered is invalid'
        }]
      },
      'contact[mobile_confirmation]': {
        identifier: 'contact[mobile_confirmation]',
        rules: [{
          type   : 'empty',
          prompt : 'Please enter confirm mobile number'
        },
        {
          type: 'match[contact[mobile]]',
          prompt: "Mobile number doesn't match"
        }]
      },
    }
  });

});

function validateUploadedImage(file){
      var imageType = ["image/png", "image/jpg", "image/jpeg"]

      if(jQuery.inArray(file.type, imageType) >= 0){

        if(file.size > 5000000){
          $('div[id="upload_photo"]').attr('class', 'twelve wide error field');
          $('p[id="desc_upload_photo"]').after("<div class='ui basic red pointing prompt label transition visible'>Maximum file size is 5MB</div>");
          return false; // false is required if you do don't want to let it submit
        } else {
          return true;
        }


      }else{
        $('div[id="upload_photo"]').attr('class', 'twelve wide error field');
        $('p[id="desc_upload_photo"]').after("<div class='ui basic red pointing prompt label transition visible'>Acceptable file types are jpg, jpeg and png</div>");
        return false; // false is required if you do don't want to let it submit
      }

}

onmount('div[name="ProfileValidation"]', function(){

  $('#ProfileForm').form({
    on: 'blur',
    inline: true,
    fields: {
      'member[photo]': {
        identifier: 'member[photo]',
        rules: [{
          type: 'empty',
          prompt: "Please select photo"
        }]
      }
    },
    onSuccess: function() {

      var input = document.getElementById('imageUpload');
      var file = input.files[0];
      var imageType = ["image/png", "image/jpg", "image/jpeg"]

      return validateUploadedImage(file);

    },
  });

});

onmount('div[name="RequestProfCorValidation"]', function(){

  $('input[name="profile_correction[first_name]"]').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[0-9``~<>^'{}[\]\\;':"/?!@#$%&*()_+=]/;

    if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
      return false;
    }else{
      if (($('input[name="profile_correction[first_name]"]').val().length + 1) <= 150) {
        $(this).on('focusout', function(evt){
          $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
        })
      } else {
        return false;
      }
    }
  });

  $('input[name="profile_correction[middle_name]"]').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[0-9``~<>^'{}[\]\\;':"/?!@#$%&*()_+=]/;

    if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
      return false;
    }else{
      if (($('input[name="profile_correction[middle_name]"]').val().length + 1) <= 150) {
        $(this).on('focusout', function(evt){
          $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
        })
      } else {
        return false;
      }
    }
  });

  $('input[name="profile_correction[last_name]"]').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[0-9``~<>^'{}[\]\\;':"/?!@#$%&*()_+=]/;

    if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
      return false;
    }else{
      if (($('input[name="profile_correction[last_name]"]').val().length + 1) <= 150) {
        $(this).on('focusout', function(evt){
          $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
        })
      } else {
        return false;
      }
    }
  });

  $('input[name="profile_correction[suffix]"]').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[0-9``~<>^'{}[\]\\;':"/?!@#$%&*()_+=]/;

    if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
      return false;
    }else{
      if (($('input[name="profile_correction[suffix]"]').val().length + 1) <= 10) {
        $(this).on('focusout', function(evt){
          $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
        })
      } else {
        return false;
      }
    }
  });

  function validate_atleastone(){
    var month = document.getElementById("profile_correction_month");

    if ($('input[name="profile_correction[first_name]"]').val() == '' &&
      $('input[name="profile_correction[middle_name]"]').val() == '' &&
      $('input[name="profile_correction[last_name]"]').val() == '' &&
      $('input[name="profile_correction[suffix]"]').val() == '' &&
      month.options[month.selectedIndex].value == '' &&
      $('input[name="profile_correction[birth_date][day]"]').val() == '' &&
      $('input[name="profile_correction[birth_date][year]"]').val() == '' &&
      !$('input[name="profile_correction[gender]"]').is(':checked')) {

      $('div[id="request_form"]').before("<div id='neg_msg' class='ui negative message'><i class='close icon'></i>One of these fields must be present: [Name, Birth Date, Gender]</div>");

      return false;
    } else {
      if ($('div[id="neg_msg"]').length >= 0) {
        $('div[id="neg_msg"]').remove();
      }
      return true;
    }
  }

  $.fn.form.settings.rules.validateName = function(param) {
    if ($('input[name="profile_correction[first_name]"]').val() == '' &&
        $('input[name="profile_correction[middle_name]"]').val() == '' &&
        $('input[name="profile_correction[last_name]"]').val() == '' &&
        $('input[name="profile_correction[suffix]"]').val() == '') {

      return true;
    } else {

      if (param == '') {
        return false;
      } else {
        return true;
      }

    }
  }

  $.fn.form.settings.rules.validateBirthDateFields = function(param) {

    var month = document.getElementById("profile_correction_month");
    var day = $('input[name="profile_correction[birth_date][day]"]').val();
    var year = $('input[name="profile_correction[birth_date][year]"]').val();

    if (month.options[month.selectedIndex].value == '' && day == '' && year == '') {
      return true;
    } else {

      if (param == '') {
        return false;
      } else {
        return true;
      }

    }

  }

  $.fn.form.settings.rules.validateBirthDate = function(param) {

    var month = document.getElementById("profile_correction_month");
    var day = $('input[name="profile_correction[birth_date][day]"]').val();
    var year = $('input[name="profile_correction[birth_date][year]"]').val();

    if (month.options[month.selectedIndex].value == '' && day == '' && year == '') {
      return true;
    } else {

      if (param == '') {
        return false;
      } else {
        return moment(year + '-' + month.options[month.selectedIndex].value + '-' + day).isValid();
      }

    }

  }

  $('#ReqProfCorForm').form({
    on: 'blur',
    inline: true,
    fields: {
      'profile_correction[first_name]': {
        identifier: 'profile_correction[first_name]',
        rules: [{
          type: 'validateName[param]',
          prompt: "Please enter First Name"
        },
        {
          type: 'regExp[/^[,.\\-ña-zÑA-Z\\s]{0,150}$/]',
          prompt: 'The First Name you have entered is invalid'
        }]
      },
      'profile_correction[last_name]': {
        identifier: 'profile_correction[last_name]',
        rules: [{
          type: 'validateName[param]',
          prompt: "Please enter Last Name"
        },
        {
          type: 'regExp[/^[,.\\-ña-zÑA-Z\\s]{0,150}$/]',
          prompt: 'The Last Name you have entered is invalid'
        }]
      },
      'profile_correction[middle_name]': {
        identifier: 'profile_correction[middle_name]',
        rules: [{
          type: 'regExp[/^[,.\\-ña-zÑA-Z\\s]{0,150}$/]',
          prompt: 'The Middle Name you have entered is invalid'
        }]
      },
      'profile_correction[suffix]': {
        identifier: 'profile_correction[suffix]',
        rules: [{
          type: 'regExp[/^[,.\\-ña-zÑA-Z\\s]{0,10}$/]',
          prompt: 'The Extension you have entered is invalid'
        }]
      },
      'profile_correction[id_card]': {
        identifier: 'profile_correction[id_card]',
        rules: [{
          type: 'empty',
          prompt: "Please select ID Card"
        }]
      },
      'profile_correction[birth_date][month]': {
        identifier: 'profile_correction[birth_date][month]',
        rules: [{
          type: 'validateBirthDateFields[param]',
          prompt: "Birth date must have month, day and year"
        },
        {
          type: 'validateBirthDate[param]',
          prompt: "Invalid birthdate"
        }]
      },
      'profile_correction[birth_date][day]': {
        identifier: 'profile_correction[birth_date][day]',
        rules: [{
          type: 'validateBirthDateFields[param]',
          prompt: "Birth date must have month, day and year"
        },
        {
          type: 'validateBirthDate[param]',
          prompt: "Invalid birthdate"
        }]
      },
      'profile_correction[birth_date][year]': {
        identifier: 'profile_correction[birth_date][year]',
        rules: [{
          type: 'validateBirthDateFields[param]',
          prompt: "Birth date must have month, day and year"
        },
        {
          type: 'validateBirthDate[param]',
          prompt: "Invalid birthdate"
        }]
      },
    },
    onSuccess: function() {

      var input = document.getElementById('imageUpload');
      var file = input.files[0];

      if (validateUploadedImage(file) && validate_atleastone()) {
        return true;
      } else {
        return false;
      }

    },
  });

});
