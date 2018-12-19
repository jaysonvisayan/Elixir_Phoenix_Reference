onmount('div[id="kycStep1"]', function(){

  $('input[name="kyc[mm_first_name]"]').on('keypress', function(e){
     preventNumAndSChar(e)
  })

  $('input[name="kyc[mm_middle_name]"]').on('keypress', function(e){
     preventNumAndSChar(e)
  })

  $('input[name="kyc[mm_last_name]"]').on('keypress', function(e){
     preventNumAndSChar(e)
  })

  function preventNumAndSChar(e){
    let theEvent = e || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /^[a-zA-Z-., ]$/;

    if( !regex.test(key) ) {
      theEvent.returnValue = false;
      if(theEvent.preventDefault) theEvent.preventDefault();
    }
  }

  // $('input[name="kyc[mm_first_name]"]').bind('paste', function(e){
  //    e.preventDefault()
  // })

  // $('input[name="kyc[mm_middle_name]"]').bind('paste', function(e){
  //    e.preventDefault()
  // })

  // $('input[name="kyc[mm_last_name]"]').bind('paste', function(e){
  //    e.preventDefault()
  // })

  $('#sourceOfFund').on('change', function(){

    // for clearing semantic errors
    $('#sof_container').removeClass("error");
    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });

    if($(this).val() == 'Others'){
      $('#sofOthers').attr("disabled", false)
    }
    else{
      $('#sofOthers').attr("disabled", true)
      $('#sofOthers').val("")
    }
    sourceOfFundValidation($(this).val())
  })
  sourceOfFundValidation($('#sourceOfFund').val())


  function sourceOfFundValidation(sofValue){
    if(sofValue == 'Others'){

      ////////////////////////////////// start of semantic form validation with kyc_others
      $('#step1_form')
      .form({
        inline : true,
        fields: {
          'kyc[country_of_birth]': {
            identifier: 'kyc[country_of_birth]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your country of birth.'
              }
            ]
          },
          'kyc[city_of_birth]': {
            identifier: 'kyc[city_of_birth]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your city of birth.'
              }
            ]
          },
          'kyc[citizenship]': {
            identifier: 'kyc[citizenship]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your citizenship.'
              }
            ]
          },
          'kyc[mm_first_name]': {
            identifier: 'kyc[mm_first_name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your mother\'s maiden first name.'
              }
              // {
              //   type: 'regExp',
              //   prompt: 'Please enter only valid characters, avoid special character and numbers',
              //   value: '^[a-zA-Z-.,]{2,150}$',
              // }

            ]
          },
          'kyc[mm_middle_name]': {
            identifier: 'kyc[mm_middle_name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your mother\'s maiden middle name.'
              }
              // {
              //   type: 'regExp',
              //   prompt: 'Please enter only valid characters, avoid special character and numbers',
              //   value: '^[a-zA-Z-.,]{2,150}$',
              // }

            ]
          },
          'kyc[mm_last_name]': {
            identifier: 'kyc[mm_last_name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your mother\'s maiden last name.'
              }
            ]
          },
          'kyc[educational_attainment]': {
            identifier: 'kyc[educational_attainment]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please select educational attainment.'
              }
            ]
          },
          'kyc[company_name]': {
            identifier: 'kyc[company_name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your company name.'
              },
              {
                type: 'regExp',
                prompt: 'Please enter only valid characters, avoid special character and numbers',
                value: '^[a-zA-Z-.() ]{2,150}$',
              }
            ]
          },
          'kyc[company_branch]': {
            identifier: 'kyc[company_branch]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your company branch.'
              },
              {
                type: 'regExp',
                prompt: 'Please enter only valid characters, avoid special character and numbers',
                value: '^[a-zA-Z-.() ]{2,150}$',
              }
            ]
          },

          'kyc[position_title]': {
            identifier: 'kyc[position_title]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your position.'
              }
            ]
          },
          'kyc[occupation]': {
            identifier: 'kyc[occupation]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your occupation.'
              }
            ]
          },
          'kyc[nature_of_work]': {
            identifier: 'kyc[nature_of_work]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your nature of work.'
              },
              {
                type: 'regExp',
                prompt: 'Please enter only valid characters, avoid special character and numbers',
                value: '^[a-zA-Z-.() ]{2,150}$',
              }
            ]
          },
          'kyc[others]': {
            identifier: 'kyc[others]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter other source of fund.'
              }
            ]
          }

        }
      })
      ///////////////////////////////// end of semantic form validation


    }
    else{


      ////////////////////////////////// start of semantic form validation w/o kyc_others
      $('#step1_form')
      .form({
        inline : true,
        fields: {
          'kyc[country_of_birth]': {
            identifier: 'kyc[country_of_birth]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your country of birth.'
              }
            ]
          },
          'kyc[city_of_birth]': {
            identifier: 'kyc[city_of_birth]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your city of birth.'
              },
              {
              type: 'regExp',
              prompt: 'Please enter only valid characters, avoid special character and numbers',
             value: '^[a-zA-Z-.() ]{2,150}$',
              }
             ]
          },
          'kyc[citizenship]': {
            identifier: 'kyc[citizenship]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your citizenship.'
              }
              // {
              //   type: 'regExp',
              //   prompt: 'Please enter only valid characters, avoid special character and numbers',
              //   value: '^[a-zA-Z-.() ]{2,150}$',
              // }
            ]
          },

          'kyc[mm_first_name]': {
            identifier: 'kyc[mm_first_name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your mother\'s maiden first name.'
              }
              // {
              //   type: 'regExp',
              //   prompt: 'Please enter only valid characters, avoid special character and numbers',
              //   value: '^[a-zA-Z-.,]{2,150}$',
              // }

            ]
          },
          'kyc[mm_middle_name]': {
            identifier: 'kyc[mm_middle_name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your mother\'s maiden middle name.'
              }
              // {
              //   type: 'regExp',
              //   prompt: 'Please enter only valid characters, avoid special character and numbers',
              //   value: '^[a-zA-Z-.,]{2,150}$',
              // }
            ]
          },
          'kyc[mm_last_name]': {
            identifier: 'kyc[mm_last_name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your mother\'s maiden last name.'
              },
              {
                type: 'regExp',
                prompt: 'Please enter only valid characters, avoid special character and numbers',
                value: '^[a-zA-Z-.,]{2,150}$',
              }

            ]
          },
          'kyc[educational_attainment]': {
            identifier: 'kyc[educational_attainment]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your educational attainment.'
              }
            ]
          },
          'kyc[company_name]': {
            identifier: 'kyc[company_name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your company name.'
              },
              {
              type: 'regExp',
              prompt: 'Please enter only valid characters, avoid special character and numbers',
              value: '^[a-zA-Z-.() ]{2,150}$',
              }
            ]
          },
          'kyc[company_branch]': {
            identifier: 'kyc[company_branch]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your company branch.'
              },
              {
                type: 'regExp',
                prompt: 'Please enter only valid characters, avoid special character and numbers',
                value: '^[a-zA-Z-.() ]{2,150}$',
              }
            ]
          },

          'kyc[position_title]': {
            identifier: 'kyc[position_title]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your position.'
              },
              {
                type: 'regExp',
                prompt: 'Please enter only valid characters, avoid special character and numbers',
                value: '^[a-zA-Z-.() ]{2,150}$',
              }
            ]
          },
          'kyc[occupation]': {
            identifier: 'kyc[occupation]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your occupation.'
              }
            ]
          },
          'kyc[nature_of_work]': {
            identifier: 'kyc[nature_of_work]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter your nature of work.'
              },
              {
              type: 'regExp',
              prompt: 'Please enter only valid characters, avoid special character and numbers',
              value: '^[a-zA-Z-.() ]{2,150}$',
              }
            ]
          }

        }
      })
      ///////////////////////////////// end of semantic form validation


    }
  }


})


onmount('div[id="kycStep2"]', function(){
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

    $.fn.form.settings.rules.validateResidentialLine = function(param) {

    if (param == '') {
      return true;
    } else {

      param = param.replace(/-/g, '');
      if (/^\d{7}$/.test(param)) {
        return true;
      } else {
        return false;
      }
    }
  }

  $.fn.form.settings.rules.validateZipCode = function(param) {

    if (param == '') {
      return true;
    } else {

      param = param.replace(/-/g, '');
      if (/^\d{4}$/.test(param)) {
        return true;
      } else {
        return false;
      }
    }
  }


  $('#step2_form')
  .form({
    on: 'blur',
    inline : true,
    fields: {
      'kyc[street_no]': {
        identifier: 'kyc[street_no]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter your street number.'
          }
        ]
      },
      'kyc[subd_dist_town]': {
        identifier: 'kyc[subd_dist_town]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter your subdivision / district / town.'
          }
        ]
      },
      'kyc[city]': {
        identifier: 'kyc[city]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter your city / province.'
          }
        ]
      },
      'kyc[zip_code]': {
        identifier: 'kyc[zip_code]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter your zipcode.'
          },
          {
            type: 'validateZipCode[param]',
            prompt: 'Please enter a valid zipcode'
          }
        ]
      },
      'kyc[residential_line]': {
        identifier: 'kyc[residential_line]',
        optional: true,
        rules: [
          // {
          //   type: 'validateResidentialLine[param]'
            // prompt: 'Please enter a valid residential line.'
          // }
        ]

      },
      'kyc[mobile1]': {
        identifier: 'kyc[mobile1]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter your mobile no.'
          }
          // {
          //   type: 'validateMobile[param]',
          //   prompt: 'Please enter a valid mobile no.'
          // }
        ]
      },
      'kyc[email1]': {
        identifier: 'kyc[email1]',
        // optional: true,
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter email address'
          },
          {
            type: 'email',
            prompt: 'Please enter valid email.'
          }
        ]
      },
      'kyc[email2]': {
        identifier: 'kyc[email2]',
        optional: true,
        rules: [
          {
            type: 'email',
            prompt: 'Please enter valid email.'
          }
        ]
      }
    }
  })
  $('.countries').dropdown('set selected',  "Philippines")
})

onmount('a[id="skipKYC"]', function(){
  $('#skipKYC').on('click', function(){
    let checker = false

    $('input[type="text"]').each(function(){
      if ($(this).val() != "" && $(this).hasClass('account-name') == false) {
        checker = true
      }
    })

    if (checker == false){
      window.location = '/'
    } else {
      swal({
        title: 'Entered information may not be saved.',
        text: 'Are you sure you want to continue?',
        showCancelButton: true,
        cancelButtonText: 'Cancel',
        confirmButtonText: 'Proceed',
        cancelButtonClass: 'ui button',
        confirmButtonClass: 'ui blue button',
        buttonsStyling: false,
        reverseButtons: true
      }).then(function () {
        window.location = '/'
      }).catch(swal.noop)
    }

  })
})

onmount('a[id="skipDeleteKYC"]', function(){
  const csrf = $('input[name="_csrf_token"]').val()
  const member_id = $('#kycID').val()
  $('#skipDeleteKYC').on('click', function(){
    let checker = false

    swal({
      title: 'Entered information may not be saved.',
      text: 'Are you sure you want to continue?',
      showCancelButton: true,
      cancelButtonText: 'Cancel',
      confirmButtonText: 'Proceed',
      cancelButtonClass: 'ui button',
      confirmButtonClass: 'ui blue button',
      buttonsStyling: false,
      reverseButtons: true
    }).then(function () {

      $.ajax({
        url:`/en/kyc/delete`,
        headers: {"X-CSRF-TOKEN": csrf},
        data: {id: member_id},
        type: 'POST',
        success: function(response){
          window.location = '/'
        },
        error: function(){
          alert("Erorr deleting KYC!")
        }
      })

    }).catch(swal.noop)

  })
})
