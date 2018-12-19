onmount('div[id="kyc-step-3"]', function(){
  $('button[id="finish"]').on('click', function(){
    $('#kyc-step3').form({
      on:'blur',
      inline: true,
      fields: {
        // 'kyc[tin]': {
        //   identifier: 'kyc[tin]',
        //   rules: [{
        //     type  : 'checkTINlength[param]'
        //     // prompt: 'Tin No. should be 12 digits'
        //   },

        //   ]
        // },
        // 'kyc[sss_number]': {
        //   identifier: 'kyc[sss_number]',
        //   rules: [{
        //     type  : 'NineDigits[param]'
        //     // prompt: 'SSS No. should be 9 digits'
        //   }]
        // },
        // 'kyc[unified_id_number]': {
        //   identifier: 'kyc[unified_id_number]',
        //   rules: [{
        //     type  : 'NineDigits[param]',
        //     prompt: 'Unified ID No. should be 9 digits'
        //   }]
        // },
        'kyc[id_card]': {
          identifier: 'kyc[id_card]',
          rules: [{
            type  : 'empty',
            prompt: 'Please select Identification Card'
          },]
        },
        'kyc[front_side]': {
          identifier: 'kyc_front_side',
          rules: [{
            type  : 'empty',
            prompt: 'Please Upload Front Side'
          },
          {
            type : 'checkFrontSize[param]',
            prompt: 'Maximum file size is 5MB'
          },
          {
            type : 'checkFrontType[param]',
            prompt: 'Acceptable file types are jpg, jpeg and png.'
          }]
        },
        'kyc[back_side]': {
          identifier: 'kyc_back_side',
          rules: [{
            type  : 'empty',
            prompt: 'Please Upload Back Side'
          },
          {
            type : 'checkBackSize[param]',
            prompt: 'Maximum file size is 5MB'
          },
          {
            type : 'checkBackType[param]',
            prompt: 'Acceptable file types are jpg, jpeg and png.'
          }]
        },
        'kyc[cir_form]': {
          identifier: 'kyc_cir_form',
          rules: [{
            type  : 'empty',
            prompt: 'Please Upload CIR Form'
          },
          {
            type : 'checkCirSize[param]',
            prompt: 'Maximum file size is 5MB'
          }]
        },
        'kyc[terms_form]': {
          identifier: 'kyc_terms_form',
          rules: [{
            type  : 'empty',
            prompt: 'Please Upload Terms and Conditions Form'
          },
          {
            type : 'checkTermsSize[param]',
            prompt: 'Maximum file size is 5MB'
          }]
        },
      }
    })
  })

  let extensionLists  = ['jpg', 'jpeg', 'png'];

  $.fn.form.settings.rules.checkTINlength= function(param) {
    if (param.replace(/_/g, "").length == 0){
      return true
    }else if (param.replace(/_/g, "").length < 15){
    return false
    }else{
      return true
    }
  }

  $.fn.form.settings.rules.clearTin= function(param){

  }

  $.fn.form.settings.rules.NineDigits= function(param) {
    if (param.replace(/_/g, "").length == 0){
      return true
    }else if(param.replace(/_/g, "").length < 11){
    return false
    } else{
      return true
    }
  }

  $.fn.form.settings.rules.checkFrontType= function(param) {
    let file = $('input[name="kyc[front_side]"]')
    if(file[0].files[0] == undefined) {
      if(file.attr("value") == undefined || file.attr("value") == ""){
        return false
      } else{
        return true
      }
    }else{
      return extensionLists.indexOf(file.val().split('.').pop()) > -1? true: false
    }
  }

  $.fn.form.settings.rules.checkBackType= function(param) {
    let file = $('input[name="kyc[back_side]"]')
    if(file[0].files[0] == undefined) {
      if(file.attr("value") == undefined || file.attr("value") == ""){
        return false
      } else{
        return true
      }
    }else{
      return extensionLists.indexOf(file.val().split('.').pop()) > -1? true: false
    }
  }

  $.fn.form.settings.rules.checkFrontSize= function(param){
    let file = $('input[name="kyc[front_side]"]')
    if(file[0].files[0] == undefined) {
      if(file.attr("value") == undefined || file.attr("value") == ""){
        return false
      } else{
        return true
      }
    }else{
      return file[0].files[0].size <= 1024 * 1024 * 5? true : false
    }
  }

  $.fn.form.settings.rules.checkBackSize= function(param) {
    let file = $('input[name="kyc[back_side]"]')
    if(file[0].files[0] == undefined) {
      if(file.attr("value") == undefined || file.attr("value") == ""){
        return false
      } else{
        return true
      }
    }else{
      return file[0].files[0].size <= 1024 * 1024 * 5? true : false
    }
  }

  $.fn.form.settings.rules.checkCirSize= function(param) {
    let file = $('input[name="kyc[cir_form]"]')
    if(file[0].files[0] == undefined) {
      if(file.attr("value") == undefined || file.attr("value") == ""){
        return false
      } else{
        return true
      }
    }else{
      return file[0].files[0].size <= 1024 * 1024 * 5? true : false
    }
  }

  $.fn.form.settings.rules.checkTermsSize= function(param) {
    let file = $('input[name="kyc[terms_form]"]')
    if(file[0].files[0] == undefined) {
      if(file.attr("value") == undefined || file.attr("value") == ""){
        return false
      } else{
        return true
      }
    }else{
      return file[0].files[0].size <= 1024 * 1024 * 5? true : false
    }
  }
})
