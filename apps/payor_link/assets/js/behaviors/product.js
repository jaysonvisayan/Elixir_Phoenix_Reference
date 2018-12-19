onmount('div[id="step1_general"]', function () {

  $('#delete_draft').click(function(){
    let id = $(this).attr('productID');
    $('#dp_product_id').val(id);

    $('#delete_product_confirmation').modal('show');
  });

  $('#dp_cancel').click(function(){
    $('#delete_product_confirmation').modal('hide');
  });

  $('#dp_submit').click(function(){
    let id = $('#dp_product_id').val();

    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${id}/delete_all`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.replace('/products')
      }
    });
  });


  /////////////////////////// start: limit applicability and product base validation

  $('#product_limit_amt').on("keyup", function(e){
    let pla = $(this).val()
    //console.log(pla)
    $('#slaTxtBox').val(pla)
  });

  // if the limit applicability has been set first
  $('input[name="product[limit_applicability]"]').change(function(){
    let val = $(this).val()

    if(val == "Principal"){
      ////alert(val)
      $('#slaContainer').addClass('hidden')
      $('input[name="product[shared_limit_amount]"]').prop('disabled', true)

      ////console.log( $('.eb:checked').val()?true:false )
      ////console.log( $('.bb:checked').val()?true:false )

      if( $('.eb:checked').val()?true:false ){
        ////alert('onclick limit applicability'+ 1)
        validateExclusionBased()
      }
      else if( $('.bb:checked').val()?true:false ){
        ////alert('onclick limit_applicability' + 2)
        validateBenefitBased()
      }
      else{
        validateBenefitBasedwithSLA()
      }

    }
    else if (val == "Share with Dependents"){
      let pla = $('#product_limit_amt').val()
      if (pla.length > 0){
        $('#slaContainer').removeClass('hidden')
        $('input[name="product[shared_limit_amount]"]').prop('disabled', false)
        $('#slaTxtBox').val(pla)
      }
      else if(pla.length == 0){
        //alert('Fill up first the limit amount before selecting Share with Dependents')
        $('#swd').prop('checked', false)
        $('#swd').closest('div').removeClass('checked')
      }

      if( $('.eb:checked').val()?true:false ){
         //alert("eb:checked.val()?true:false")
        ////alert('onclick limit_applicability' + 3)
        validateExclusionBasedwithSLA()
      }

      else if( $('.bb:checked').val()?true:false ){
        ////alert('onclick limit_applicability' + 4)
        validateBenefitBasedwithSLA()
      }
      else{
        validateBenefitBasedwithSLA()
      }

    }

    function validateBenefitBased() {
        $('.field.error').removeClass("error");
        $('.error').removeClass("error");

        $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
          $(this).remove();
        });
        $('#general_form')
        .form({
          inline : true,
          fields: {
            'product[name]': {
              identifier: 'product[name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a name.'
                }
              ]
            },
            'product[description]': {
              identifier: 'product[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a description.'
                }
              ]
            },
            'product[type]': {
              identifier: 'product[type]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a plan type.'
                }
              ]
            },
            'product[limit_amount]': {
              identifier: 'product[limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a limit amount.'
                },
                {
                  type: 'checkProductLimit[param]',
                  prompt: `Plan Limit must be equal or greater than each benefit\'s limit, the highest benefit was amounting ${highest2}. Plan cannot be saved.`
                }
              ]
            },
            'product[limit_applicability]': {
              identifier: 'product[limit_applicability]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit applicability.'
                }
              ]
            },
            'product[limit_type]': {
              identifier: 'product[limit_type]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit type.'
                }
              ]
            },
            'product[phic_status]': {
              identifier: 'product[phic_status]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a PHIC status.'
                }
              ]
            },
            'product[standard_product]': {
              identifier: 'product[standard_product]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan classification.'
                }
              ]
            },
            'product[member_type][]': {
              identifier: 'product[member_type][]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please select atleast one member type.'
                }
              ]
            },
            'product[product_base]': {
              identifier: 'product[product_base]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan base.'
                }
              ]
            }
          },
          onSuccess: function(event, fields){
            var input = document.getElementById('product_limit_amt');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#product_limit_amt').val(unmasked)
          }
        })
      }


      function validateBenefitBasedwithSLA() {
        $('.field.error').removeClass("error");
        $('.error').removeClass("error");

        $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
          $(this).remove();
        });
        $('#general_form')
        .form({
          inline : true,
          fields: {
            'product[name]': {
              identifier: 'product[name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a name.'
                }
              ]
            },
            'product[description]': {
              identifier: 'product[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a description.'
                }
              ]
            },
            'product[type]': {
              identifier: 'product[type]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a plan type.'
                }
              ]
            },
            'product[limit_amount]': {
              identifier: 'product[limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a limit amount.'
                },
                {
                  type: 'checkProductLimit[param]',
                  prompt: `Plan Limit must be equal or greater than each benefit\'s limit, the highest benefit was amounting ${highest2}. Plan cannot be saved.`
                }
              ]
            },
            'product[limit_applicability]': {
              identifier: 'product[limit_applicability]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit applicability.'
                }
              ]
            },
            'product[shared_limit_amount]': {
              identifier: 'product[shared_limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a shared limit amount.'
                },
                {
                  type: 'checkSharedLimitAmount[param]',
                  prompt: `Shared Limit Amount must be less than or equal to Limit Amount.`
                }
              ]
            },
            'product[limit_type]': {
              identifier: 'product[limit_type]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit type.'
                }
              ]
            },
            'product[phic_status]': {
              identifier: 'product[phic_status]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a PHIC status.'
                }
              ]
            },
            'product[standard_product]': {
              identifier: 'product[standard_product]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan classification.'
                }
              ]
            },
            'product[member_type][]': {
              identifier: 'product[member_type][]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please select atleast one member type.'
                }
              ]
            },
            'product[product_base]': {
              identifier: 'product[product_base]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan base.'
                }
              ]
            }
          },
          onSuccess: function(event, fields){
            var input = document.getElementById('product_limit_amt');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#product_limit_amt').val(unmasked)

            var input = document.getElementById('slaTxtBox');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#slaTxtBox').val(unmasked)
          }
        })
      }

      function validateExclusionBased(){
        $('.field.error').removeClass("error");
        $('.error').removeClass("error");

        $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
          $(this).remove();
        });
        $('#general_form')
        .form({
          inline : true,
          fields: {
            'product[name]': {
              identifier: 'product[name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a name.'
                }
              ]
            },
            'product[description]': {
              identifier: 'product[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a description.'
                }
              ]
            },
            'product[type]': {
              identifier: 'product[type]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a plan type.'
                }
              ]
            },
            'product[limit_amount]': {
              identifier: 'product[limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a limit amount.'
                }
              ]
            },
            'product[limit_applicability]': {
              identifier: 'product[limit_applicability]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit applicability.'
                }
              ]
            },
            'product[limit_type]': {
              identifier: 'product[limit_type]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit type.'
                }
              ]
            },
            'product[phic_status]': {
              identifier: 'product[phic_status]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a PHIC status.'
                }
              ]
            },
            'product[standard_product]': {
              identifier: 'product[standard_product]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan classification.'
                }
              ]
            },
            'product[member_type][]': {
              identifier: 'product[member_type][]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please select atleast one member type.'
                }
              ]
            },
            'product[product_base]': {
              identifier: 'product[product_base]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan base.'
                }
              ]
            }
          },
          onSuccess: function(event, fields){
            var input = document.getElementById('product_limit_amt');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#product_limit_amt').val(unmasked)
          }
        })
      }


      function validateExclusionBasedwithSLA(){
        $('.field.error').removeClass("error");
        $('.error').removeClass("error");

        $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
          $(this).remove();
        });
        $('#general_form')
        .form({
          inline : true,
          fields: {
            'product[name]': {
              identifier: 'product[name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a name.'
                }
              ]
            },
            'product[description]': {
              identifier: 'product[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a description.'
                }
              ]
            },
            'product[type]': {
              identifier: 'product[type]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a plan type.'
                }
              ]
            },
            'product[limit_amount]': {
              identifier: 'product[limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a limit amount.'
                }
              ]
            },
            'product[limit_applicability]': {
              identifier: 'product[limit_applicability]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit applicability.'
                }
              ]
            },
            'product[shared_limit_amount]': {
              identifier: 'product[shared_limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a shared limit amount.'
                },
                {
                  type: 'checkSharedLimitAmount[param]',
                  prompt: `Shared Limit Amount must be less than or equal to Limit Amount.`
                }
              ]
            },
            'product[limit_type]': {
              identifier: 'product[limit_type]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit type.'
                }
              ]
            },
            'product[phic_status]': {
              identifier: 'product[phic_status]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a PHIC status.'
                }
              ]
            },
            'product[standard_product]': {
              identifier: 'product[standard_product]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan classification.'
                }
              ]
            },
            'product[member_type][]': {
              identifier: 'product[member_type][]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please select atleast one member type.'
                }
              ]
            },
            'product[product_base]': {
              identifier: 'product[product_base]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan base.'
                }
              ]
            }
          },
          onSuccess: function(event, fields){
            var input = document.getElementById('product_limit_amt');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#product_limit_amt').val(unmasked)

            var input = document.getElementById('slaTxtBox');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#slaTxtBox').val(unmasked)
          }
        })
      }

  })

  let csrf = $('input[name="_csrf_token"]').val();
  let highest2 = $('#product_benefit_highest').val()




      $.fn.form.settings.rules.checkProductLimit = function(param) {
        let highest = $('#product_benefit_highest').val()
        let submitted = param.split(',').join('')
        ////console.log("submitted: " + submitted)
        ////console.log("highestpb: " + highest)
        if (highest == ""){
          if (parseFloat(submitted) >= parseFloat(0)){
            return true
          }
          else{
            return false
          }
        }
        else {

          if (parseFloat(submitted) >= parseFloat(highest)){
            return true
          }
          else{
            return false
          }

        }
      }

      $.fn.form.settings.rules.checkSharedLimitAmount = function(param) {
        let pla = $('#product_limit_amt').val().split(',').join('')
        let submitted = param.split(',').join('')
        //console.log(pla)
        //console.log(submitted)
        if (parseFloat(pla) >= parseFloat(submitted)){
          return true
        }
        else{
          return false
        }

      }

       // onload set
      if( $('.eb:checked').val()?true:false && $('.swd:checked').val()?true:false ){
         ////alert('onload' + 1)
        validateExclusionBasedwithSLA()
      }
      else if( $('.eb:checked').val()?true:false && $('.laprincipal:checked').val()?true:false ){
        ////alert('onload'+ 2)
        validateExclusionBased()
      }
      else if( $('.bb:checked').val()?true:false && $('.swd:checked').val()?true:false ){
        ////alert('onload' + 3)
        validateBenefitBasedwithSLA()
      }
      else if( $('.bb:checked').val()?true:false && $('.laprincipal:checked').val()?true:false ){
        ////alert('onload' + 4)
        validateBenefitBased()
      }


       // if the product_base condition has been set first
      $('.eb').on('change', function(){
         ////console.log( $('.swd:checked').val()?true:false )
         ////console.log(this.checked)
        if(this.checked && $('.swd:checked').val()?true:false ){
          ////alert("Exclusion-based and swd")
          if( $(this).attr('role') == 'Benefit-based' ) {
             ////alert("Exclusion-based and swd")
            $('.notChecked').text('Exclusion-based')
            $('.radioChecked').text('Benefit-based')
            validateExclusionBasedwithSLA()
            $('#product_base_confirmation').modal('show');
          }
        }

        else if(this.checked && $('.laprincipal:checked').val()?true:false ){
          ////alert("Exclusion-based and principal")
          if( $(this).attr('role') == 'Benefit-based' ) {
            ////alert("Exclusion-based and principal")
            $('.notChecked').text('Exclusion-based')
            $('.radioChecked').text('Benefit-based')
            validateExclusionBased()
            $('#product_base_confirmation').modal('show');
          }
        }

      })

      // for confirmation of "No Keep + (Exclusion-based or Benefit-based)"
      // and it will retain the current radiochecked on that product_base
      $('#confirmation_cancel_b').click(function(){
        let value = $('.radioChecked').text()
        if(value == "Exclusion-basedExclusion-based"){
          document.getElementsByClassName('eb')[0].checked = true
          let radio_selected = $('.pbase.edit').find('input:radio:checked').val();
          if(radio_selected == 'Exclusion-based'){
            $('.cov-ben').find('.title').text('Coverage')
            validateExclusionBased()
            $('#cov-ben-edittab').text('Coverage')
          }
          else if(radio_selected == 'Benefit-based'){
            $('.cov-ben').find('.title').text('Benefit')
            validateBenefitBased()
            $('#cov-ben-edittab').text('Benefit')
          }
        }
        else if(value == "Benefit-basedBenefit-based"){
          document.getElementsByClassName('bb')[0].checked = true
          let radio_selected = $('.pbase.edit').find('input:radio:checked').val();
          if(radio_selected == 'Exclusion-based'){
            $('.cov-ben').find('.title').text('Coverage')
            validateExclusionBased()
            $('#cov-ben-edittab').text('Coverage')
          }
          else if(radio_selected == 'Benefit-based'){
            $('.cov-ben').find('.title').text('Benefit')
            validateBenefitBased()
            $('#cov-ben-edittab').text('Benefit')
          }
        }
      })

      $('.bb').on('change', function(){
        ////alert(2)
        if(this.checked && $('.swd:checked').val()?true:false ){
          ////alert("Benefit-based and swd")
          if( $(this).attr('role') == 'Exclusion-based' ) {
            ////alert("Benefit-based and swd")
            $('.notChecked').text('Benefit-based')
            $('.radioChecked').text('Exclusion-based')
            validateBenefitBasedwithSLA()
            $('#product_base_confirmation').modal('show');
          }
        }
        else if(this.checked && $('.laprincipal:checked').val()?true:false ){
          ////alert("Benefit-based and principal")
          if( $(this).attr('role') == 'Exclusion-based' ) {
             ////alert("Benefit-based and principal")
            $('.notChecked').text('Benefit-based')
            $('.radioChecked').text('Exclusion-based')
            validateBenefitBased()
            $('#product_base_confirmation').modal('show');
          }
        }
      })

      function validateBenefitBased() {
        $('.field.error').removeClass("error");
        $('.error').removeClass("error");

        $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
          $(this).remove();
        });
        $('#general_form')
        .form({
          inline : true,
          fields: {
            'product[name]': {
              identifier: 'product[name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a name.'
                }
              ]
            },
            'product[description]': {
              identifier: 'product[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a description.'
                }
              ]
            },
            'product[type]': {
              identifier: 'product[type]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a plan type.'
                }
              ]
            },
            'product[limit_amount]': {
              identifier: 'product[limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a limit amount.'
                },
                {
                  type: 'checkProductLimit[param]',
                  prompt: `Plan Limit must be equal or greater than each benefit\'s limit, the highest benefit was amounting ${highest2}. Plan cannot be saved.`
                }
              ]
            },
            'product[limit_applicability]': {
              identifier: 'product[limit_applicability]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit applicability.'
                }
              ]
            },
            'product[limit_type]': {
              identifier: 'product[limit_type]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit type.'
                }
              ]
            },
            'product[phic_status]': {
              identifier: 'product[phic_status]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a PHIC status.'
                }
              ]
            },
            'product[standard_product]': {
              identifier: 'product[standard_product]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan classification.'
                }
              ]
            },
            'product[member_type][]': {
              identifier: 'product[member_type][]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please select atleast one member type.'
                }
              ]
            },
            'product[product_base]': {
              identifier: 'product[product_base]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan base.'
                }
              ]
            }
          },
          onSuccess: function(event, fields){
            var input = document.getElementById('product_limit_amt');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#product_limit_amt').val(unmasked)
          }
        })
      }

      function validateBenefitBasedwithSLA() {
        $('.field.error').removeClass("error");
        $('.error').removeClass("error");

        $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
          $(this).remove();
        });
        $('#general_form')
        .form({
          inline : true,
          fields: {
            'product[name]': {
              identifier: 'product[name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a name.'
                }
              ]
            },
            'product[description]': {
              identifier: 'product[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a description.'
                }
              ]
            },
            'product[type]': {
              identifier: 'product[type]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a plan type.'
                }
              ]
            },
            'product[limit_amount]': {
              identifier: 'product[limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a limit amount.'
                },
                {
                  type: 'checkProductLimit[param]',
                  prompt: `Plan Limit must be equal or greater than each benefit\'s limit, the highest benefit was amounting ${highest2}. Plan cannot be saved.`
                }
              ]
            },
            'product[limit_applicability]': {
              identifier: 'product[limit_applicability]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit applicability.'
                }
              ]
            },
            'product[shared_limit_amount]': {
              identifier: 'product[shared_limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a shared limit amount.'
                },
                {
                  type: 'checkSharedLimitAmount[param]',
                  prompt: `Shared Limit Amount must be less than or equal to Limit Amount.`
                }
              ]
            },
            'product[limit_type]': {
              identifier: 'product[limit_type]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit type.'
                }
              ]
            },
            'product[phic_status]': {
              identifier: 'product[phic_status]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a PHIC status.'
                }
              ]
            },
            'product[standard_product]': {
              identifier: 'product[standard_product]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan classification.'
                }
              ]
            },
            'product[member_type][]': {
              identifier: 'product[member_type][]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please select atleast one member type.'
                }
              ]
            },
            'product[product_base]': {
              identifier: 'product[product_base]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan base.'
                }
              ]
            }
          },
          onSuccess: function(event, fields){
            var input = document.getElementById('product_limit_amt');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#product_limit_amt').val(unmasked)

            var input = document.getElementById('slaTxtBox');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#slaTxtBox').val(unmasked)
          }
        })
      }

      function validateExclusionBased(){
        $('.field.error').removeClass("error");
        $('.error').removeClass("error");

        $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
          $(this).remove();
        });
        $('#general_form')
        .form({
          inline : true,
          fields: {
            'product[name]': {
              identifier: 'product[name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a name.'
                }
              ]
            },
            'product[description]': {
              identifier: 'product[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a description.'
                }
              ]
            },
            'product[type]': {
              identifier: 'product[type]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a plan type.'
                }
              ]
            },
            'product[limit_amount]': {
              identifier: 'product[limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a limit amount.'
                }
              ]
            },
            'product[limit_applicability]': {
              identifier: 'product[limit_applicability]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit applicability.'
                }
              ]
            },
            'product[limit_type]': {
              identifier: 'product[limit_type]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit type.'
                }
              ]
            },
            'product[phic_status]': {
              identifier: 'product[phic_status]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a PHIC status.'
                }
              ]
            },
            'product[standard_product]': {
              identifier: 'product[standard_product]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan classification.'
                }
              ]
            },
            'product[member_type][]': {
              identifier: 'product[member_type][]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please select atleast one member type.'
                }
              ]
            },
            'product[product_base]': {
              identifier: 'product[product_base]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan base.'
                }
              ]
            }
          },
          onSuccess: function(event, fields){
            var input = document.getElementById('product_limit_amt');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#product_limit_amt').val(unmasked)
          }
        })
      }

      function validateExclusionBasedwithSLA(){
        $('.field.error').removeClass("error");
        $('.error').removeClass("error");

        $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
          $(this).remove();
        });
        $('#general_form')
        .form({
          inline : true,
          fields: {
            'product[name]': {
              identifier: 'product[name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a name.'
                }
              ]
            },
            'product[description]': {
              identifier: 'product[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a description.'
                }
              ]
            },
            'product[type]': {
              identifier: 'product[type]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a plan type.'
                }
              ]
            },
            'product[limit_amount]': {
              identifier: 'product[limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a limit amount.'
                }
              ]
            },
            'product[limit_applicability]': {
              identifier: 'product[limit_applicability]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit applicability.'
                }
              ]
            },
            'product[shared_limit_amount]': {
              identifier: 'product[shared_limit_amount]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter a shared limit amount.'
                },
                {
                  type: 'checkSharedLimitAmount[param]',
                  prompt: `Shared Limit Amount must be less than or equal to Limit Amount.`
                }
              ]
            },
            'product[limit_type]': {
              identifier: 'product[limit_type]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a limit type.'
                }
              ]
            },
            'product[phic_status]': {
              identifier: 'product[phic_status]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a PHIC status.'
                }
              ]
            },
            'product[standard_product]': {
              identifier: 'product[standard_product]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan classification.'
                }
              ]
            },
            'product[member_type][]': {
              identifier: 'product[member_type][]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please select atleast one member type.'
                }
              ]
            },
            'product[product_base]': {
              identifier: 'product[product_base]',
              rules: [
                {
                  type: 'checked',
                  prompt: 'Please enter a plan base.'
                }
              ]
            }
          },
          onSuccess: function(event, fields){
            var input = document.getElementById('product_limit_amt');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#product_limit_amt').val(unmasked)

            var input = document.getElementById('slaTxtBox');
            var unmasked = input.inputmask.unmaskedvalue()
            input.inputmask.remove()
            $('#slaTxtBox').val(unmasked)
          }
        })
      }


  /////////////////////////// end: limit applicability and product base validation


  function checkGeneral(){
    let counter = 0;
    $('.checker').each(function(){
      let field = $(this).attr('field');
      let value = $(this).val();
      switch(field){
        case "name":
        case "description":
        case "type":
        case "limit_amount":
          let new_val = $('input[name="' + field + '"]').val()
          if(value != new_val){
            counter++;
            ////alert(value + "   " + new_val)
          }
          break;
        case "limit_applicability":
          let new_val_la = "";
          if($('#individual').checked){
            new_val_la = "Individual"
          } else {
            new_val_la = "Share with Family"
          }
          if(value != new_val_la){
            counter++;
            ////alert(2)
          }
          break;
        case "limit_type":
          let new_val_lt = "";
          if($('#abl').checked){
            new_val_lt = "ABL"
          } else {
            new_val_lt = "MBL"
          }
          if(value != new_val_lt){
            counter++;
            ////alert(3)
          }
          break;
        case "phic_status":
          let new_val_ps = "";
          if($('#rtftest').checked){
            new_val_ps = "Required to File"
          } else {
            new_val_ps = "Optional to File"
          }
          if(value != new_val_ps){
            counter++;
            ////alert(4)
          }
          break;
        case "standard_product":
          let new_val_sp = "";
          if($('#rtftest').checked){
            new_val_sp = "Yes"
          } else {
            new_val_sp = "No"
          }
          if(value != new_val_sp){
            counter++;
            ////alert(5)
          }
          break;
        default:
          break
      }
    });
    if(counter > 0){
      return false
    } else {
      return true
    }
  }

  $('.discard_changes_g').click(function(){
    let url = $(this).attr('redirect_link');
    let val = checkGeneral();

    if(val == false){
      $('#g_confirmation').modal('show');
      $('#g_confirmation_link').val(url);
    }
  });

  $('#confirmation_submit_g').click(function(){
    let url = $('#g_confirmation_link').val();
    window.location.replace(url);
  });

  var im = new Inputmask("decimal", {
    allowMinus:false,
    min: 1,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false
  });
  im.mask($('#product_limit_amt'))
  im.mask($('#slaTxtBox'))



  // for changing of step title in product/new
  $('div.ui.radio.checkbox.pbase').on('click', function(){
    let radio_selected = $(this).find('input:radio').val();
    if(radio_selected == 'Exclusion-based'){
      $('.cov-ben').find('.title').text('Coverage')
    }
    else if(radio_selected == 'Benefit-based'){
      $('.cov-ben').find('.title').text('Benefit')
    }
    else{
      $('.cov-ben').find('.title').text('Coverage/Benefit')
    }
  })

  // for change of tab title in product/edit?tab=general
  $('div.ui.radio.checkbox.pbase').on('click', function(){
    let radio_selected = $(this).find('input:radio').val();
    if(radio_selected == 'Exclusion-based'){
      $('#cov-ben-edittab').text('Coverage')
    }
    else if(radio_selected == 'Benefit-based'){
      $('#cov-ben-edittab').text('Benefit')
    }
    else{
      $('#cov-ben-edittab').text('Coverage/Benefit')
    }
  })

  // for opening of modal product_base with populating modal span
  $('.eb').on('change', function(){
    if(this.checked){
      if( $(this).attr('role') == 'Benefit-based' ) {
        $('.notChecked').text('Exclusion-based')
        $('.radioChecked').text('Benefit-based')
        $('#product_base_confirmation').modal('show');
      }
    }
  })

  $('.bb').on('change', function(){
    if(this.checked){
      if( $(this).attr('role') == 'Exclusion-based' ) {
        $('.notChecked').text('Benefit-based')
        $('.radioChecked').text('Exclusion-based')
        $('#product_base_confirmation').modal('show');
      }
    }
  })



});

$('#general_form')
  .form({
    inline : true,
    on     : 'blur',
    fields: {
      'product[name]': {
        identifier: 'product[name]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter Plan name.'
          }
        ]
      },
      'product[description]': {
        identifier: 'product[description]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter Plan description.'
          }
        ]
      },
      'product[type]': {
        identifier: 'product[type]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please select Plan type.'
          }
        ]
      },
      'product[limit_amount]': {
        identifier: 'product[limit_amount]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter a limit amount.'
          }
        ]
      },
      'product[limit_applicability]': {
        identifier: 'product[limit_applicability]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please enter a limit applicability.'
          }
        ]
      },
      'product[limit_type]': {
        identifier: 'product[limit_type]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please enter a limit type.'
          }
        ]
      },
      'product[phic_status]': {
        identifier: 'product[phic_status]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please enter a PHIC status.'
          }
        ]
      },
      'product[standard_product]': {
        identifier: 'product[standard_product]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please select  Plan classification.'
          }
        ]
      },
      'product[member_type][]': {
        identifier: 'product[member_type][]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please select atleast one member type.'
          }
        ]
      },
      'product[product_base]': {
        identifier: 'product[product_base]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please enter a plan base.'
          }
        ]
      }
    },
    onSuccess: function(event, fields){
      var input = document.getElementById('product_limit_amt');
      var unmasked = input.inputmask.unmaskedvalue()
      input.inputmask.remove()
      $('#product_limit_amt').val(unmasked)

      var input = document.getElementById('slaTxtBox');
      var unmasked = input.inputmask.unmaskedvalue()
      input.inputmask.remove()
      $('#slaTxtBox').val(unmasked)
    }
  })




onmount('div[id="step6_risk_share"]', function () {
  $('#delete_draft').click(function(){
    let id = $(this).attr('productID');
    $('#dp_product_id').val(id);

    $('#delete_product_confirmation').modal('show');
  });

  $('#dp_cancel').click(function(){
    $('#delete_product_confirmation').modal('hide');
  });

  $('#dp_submit').click(function(){
    let id = $('#dp_product_id').val();

    let csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${id}/delete_all`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.replace('/products')
      }
    });
  });
});

onmount('div[id="step7_summary"]', function () {
  $('#delete_draft').click(function(){
    let id = $(this).attr('productID');
    $('#dp_product_id').val(id);

    $('#delete_product_confirmation').modal('show');
  });

  $('#dp_cancel').click(function(){
    $('#delete_product_confirmation').modal('hide');
  });

  $('#dp_submit').click(function(){
     let id = $('#dp_product_id').val();

    let csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${id}/delete_all`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.replace('/products')
      }
    });
  });
  let im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  })
  im.mask($('#limit_amount'));
  im.mask($('#smp_limit'));
});

onmount('div[id="showProduct"]', function () {
  let im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  })
  im.mask($('#limit_amount'));
  im.mask($('#smp_limit'));
})
onmount('div[id="showSummary"]', function () {
  let im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  })
  im.mask($('#limit_amount'));
})
onmount('div[id="product_index"]', function(){
  let table = $('table[role="datatable"]').DataTable({
    dom:
      "<'ui grid'"+
      "<'row'"+
      "<'eight wide column'l>"+
      "<'right aligned eight wide column'f>"+
      ">"+
      "<'row dt-table'"+
      "<'sixteen wide column'tr>"+
      ">"+
      "<'row'"+
      "<'seven wide column'i>"+
      "<'right aligned nine wide column'p>"+
      ">"+
      ">",
    renderer: 'semanticUI',
    pagingType: "full_numbers",
    language: {
      emptyTable:     "No Records Found!",
      zeroRecords:    "No Records Found!",
      search:         "Search",
      paginate: {
        first: "<i class='angle single left icon'></i> First",
        previous: "<i class='angle double left icon'></i> Previous",
        next: "Next <i class='angle double right icon'></i>",
        last: "Last <i class='angle single right icon'></i>"
      }
    }
  });
  $('input[type="search"]').unbind('on').on('keyup', function(){
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/load_datatable`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      data: {params: { "search_value" : $(this).val().trim(), "offset" : 0}},
      dataType: 'json',
      success: function(response){
        console.log(response)
        table.clear()
        let dataSet = []
        for (let i=0;i<response.product.length;i++){
          table.row.add( [
            check_product_step(response.product[i]),
            check_product_name(response.product[i].name, response.product[i].description, "name"),
            check_product_name(response.product[i].name, response.product[i].description, "description"),
            response.product[i].classification,
            response.product[i].created_by,
            response.product[i].date_created,
            response.product[i].updated_by,
            response.product[i].date_updated
          ] ).draw();
        }
      }
    })
  })
  $('.dataTables_length').find('.ui.dropdown').on('change', function(){
    if ($(this).find('.text').text() == 100){
      let info = table.page.info();
      if (info.pages - info.page == 1){
        let search_value = $('.dataTables_filter input').val();
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/products/load_datatable`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {params: { "search_value" : search_value.trim(), "offset" : info.recordsTotal}},
          dataType: 'json',
          success: function(response){
            let dataSet = []
            for (let i=0;i<response.product.length;i++){
              table.row.add( [
                check_product_step(response.product[i]),
                check_product_name(response.product[i].name, response.product[i].description, "name"),
                check_product_name(response.product[i].name, response.product[i].description, "description"),
                response.product[i].classification,
                response.product[i].created_by,
                response.product[i].date_created,
                response.product[i].updated_by,
                response.product[i].date_updated
              ] ).draw( false );
            }
          }
        })
      }
    }
  })
  let info
  table.on('page', function () {
    info = table.page.info();
    if (info.pages - info.page == 1){
      let search_value = $('.dataTables_filter input').val();
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/products/load_datatable`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {params: { "search_value" : search_value.trim(), "offset" : info.recordsTotal}},
        dataType: 'json',
        success: function(response){
          let dataSet = []
          for (let i=0;i<response.product.length;i++){
            table.row.add( [
              check_product_step(response.product[i]),
              check_product_name(response.product[i].name, response.product[i].description, "name"),
              check_product_name(response.product[i].name, response.product[i].description, "description"),
              response.product[i].classification,
              response.product[i].created_by,
              response.product[i].date_created,
              response.product[i].updated_by,
              response.product[i].date_updated
            ] ).draw( false );
          }
        }
      })
    }
  });

  function check_product_step(product){
    if (product.step == "8"){
      if (product.facility_access == true){
        return `<a href="/products/${product.id}/revert_step/4">${product.code} (Draft/Step 4)</a>`
      }else{
        return `<a href="/products/${product.id}">${product.code}</a>`
      }
    }else{
      return `<a href="/products/${product.id}/setup?step=${product.step}">${product.code} (Draft)</a>`
    }
  }

  function check_product_name(name,description,type){
    if (name == null){
      return "(Copy / Draft)"
    }else{
      if (type == "name"){
        return name
      }else{
        return description
      }
    }
  }

});

onmount('div[id="new_product_show"]', function () {
  $('#delete_dental').click(function(){
    let id = $(this).attr('productID');
    $('#dp_product_id').val(id);

    $('#delete_product_confirmation').modal('show');
  });

  $('#dp_cancel').click(function(){
    $('#delete_product_confirmation').modal('hide');
  });

  $('#dp_submit').click(function(){
    let id = $('#dp_product_id').val();
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${id}/delete_all`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.replace('/web/products')
      }
    });
  });
});

onmount('#cancel_submit', function () {
  let data = $('#tbl-data').val();
  if (!data){
    $('#cancel-btn').css("color","currentColor");
    $('#cancel-btn').css("cursor","not-allowed");
    $('#cancel-btn').css("text-decoration","not-none");
    $('#cancel-btn').css("opacity","0.7");
    $('#cancel-btn').css("pointer-events","none");
  }
});
