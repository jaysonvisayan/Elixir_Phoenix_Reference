onmount('div[id="open_pb_modal"]', function () {
  $('.modal').modal({autofocus: false}).modal('attach events', '.add.button', 'show');

  $('a[name="edit_modal_benefit_limit"]').on('click', function(){
    let product_benefit_limit_id = $(this).attr('productBenefitLimitID')
    let product_id = $(this).attr('productID')
    let product_benefit_id = $(this).attr('productBenfitID')
    let csrf = $('input[name="_csrf_token"]').val();
    let array = [];

    $.ajax({
      url:`/products/${product_benefit_limit_id}/get_product_benefit_limit`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        // console.log(response)
        let obj = JSON.parse(response)
        let selector = 'div[role="edit"]';
        let string = obj.coverages;
        array = string.split(", ");
        // $(selector).find('#V').val(obj.limit_classification);
        $('input[name="product[limit_classification]"]').each(function(){
          if($(this).val() == obj.limit_classification) {
            let container = $(this).closest('div')
            container.checkbox('check')
          }
        })

        $('#product_coverage').dropdown('remove selected', array[15])
        $('#product_coverage').dropdown('set selected', array)

        $(selector).find('#limit_type_onchange').val(obj.limit_type).change()
        if (obj.limit_type == "Plan Limit Percentage"){
          $(selector).find('#amt_value').val(obj.limit_percentage);
        }
        else if (obj.limit_type == "Peso"){
          $(selector).find('#amt_value').val(obj.limit_amount);
          $(selector).find('#original_amount').val(obj.limit_amount);
        }
        else if (obj.limit_type == "Sessions"){
          $(selector).find('#amt_value').val(obj.limit_session);
        }
        $(selector).find('#pblID').val(obj.id);
        $(selector).find('#pbID').val(product_benefit_id);

        if (array.indexOf("ACU") != -1 && obj.limit_type == "Peso") {
          $('.ui.dropdown.selection').addClass("disabled")
        }
      }
    });
  });

  $('a[name="edit_modal_benefit_limit"]').on('click', function(){
  let product_id = $(this).attr('productID')
  let csrf = $('input[name="_csrf_token"]').val();

  let array = [];

    $.ajax({
      url:`/products/${product_id}/get_product_struct`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        // console.log(response + 'haha')
        let obj = JSON.parse(response)
        let selector = 'div[role="edit"]';
        // console.log(obj.limit_amount + 'haha2')

        $(selector).find('#product_limit_amount').val(obj.limit_amount);
      }
    });
    $('#btn-cancel-limit').on('click', function() {
      $('.modal.benefit').modal('hide');
    })

  });


  // masking for Benefit limits ///////////////////////////////////////////////

  // for product benefit limit index value
  var im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('.pb_index_amt_value'));


  // for dropdown onchange of product benefit limit modal
  $('#limit_type_onchange').on('change', function(e){

    if (this.value == "Plan Limit Percentage"){
      var im = new Inputmask("numeric", {
        min: 1,
        max: 100,
        rightAlign: false,
        allowMinus: false,
      });
      im.mask($('#amt_value'));
    }

    // for masking amount with comma: => 1,000,000.00
    else if (this.value == "Peso"){
      var im = new Inputmask("decimal", {
        radixPoint: ".",
        groupSeparator: ",",
        digits: 2,
        autoGroup: true,
        //prefix: '₱ ',
        rightAlign: false,
        allowMinus: false,
        oncleared: function () { self.Value(''); }
      });
      im.mask($('#amt_value'));
    }

    else if (this.value == "Sessions"){
      var im = new Inputmask("numeric", {
        min: 1,
        max: 100,
        rightAlign: false,
        allowMinus: false,
      });
      im.mask($('#amt_value'));
    }

  });


  // Validation for empty inputs

  $.fn.form.settings.rules.validAmount = function(param) {
    var product_limit_amount = $('#product_limit_amount').val();
    var total_pbl_amount = $('#total_product_benefit_limit').val();
    var submitted_amount = $('#amt_value').val().split(',').join('');
    var original_amount = $('#original_amount').val()
    var subtracted = total_pbl_amount - original_amount
    var final_result = Number(subtracted) + Number(submitted_amount);

    // console.log("Plan Limit amount:" + product_limit_amount)
    // console.log("total pbl amount: " + total_pbl_amount )
    // console.log("original amount: " + original_amount)
    // console.log("subtracted: " + subtracted)
    // console.log("submitted: "+ submitted_amount)
    // console.log("final_result:" + final_result)
    // alert(final_result)

    if (final_result > product_limit_amount){
      return false;
    }
    else {
      return true;
    }
  }

  $('#limit_modal_form')
  .form({
    inline: true,
    fields: {
        amount: {
          identifier: 'amount',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Amount'
            },
            {
              type: 'validAmount[param]',
              prompt: 'Submitted amount has been exceeded the Plan Limit amount'
            }
          ]
        }
    },
    onSuccess: function(event, fields){
      var input = document.getElementById('amt_value');
      var haha = input.inputmask.unmaskedvalue()
      input.inputmask.remove()
      var test = $('#amt_value').val(haha)
    }
  })

});
