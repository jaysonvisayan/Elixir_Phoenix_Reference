onmount('div[id="product_exclusions"]', function () {


  $('.genex.modal').modal({autofocus: false}).modal('attach events', '.button.genex', 'show');
  var valArrayGen = [];

  $(".input_genex").each(function () {
    var value = $(this).val();

    if(this.checked) {
      valArrayGen.push(value);
    } else {
      var index = valArrayGen.indexOf(value);

      if (index >= 0) {
        valArrayGen.splice( index, 1)
      }
    }
    $('input[name="product[gen_exclusion_ids_main]"]').val(valArrayGen);
  });

  $(".input_genex").on('change', function () {
    var value = $(this).val();

    if(this.checked) {
      valArrayGen.push(value);
    } else {
      var index = valArrayGen.indexOf(value);

      if (index >= 0) {
        valArrayGen.splice( index, 1)
      }
    }
    $('input[name="product[gen_exclusion_ids_main]"]').val(valArrayGen);
  });

  $("#select_genex").on('change', function(){
    let value = $(this).val()
    let gen_array = [];

    if(value == 'false'){
      $('.input_genex').each(function () {
        $(this).prop('checked', true);
        gen_array.push($(this).val());
      });
      $(this).val('true');
    } else {
      $('.input_genex').each(function () {
        $(this).prop('checked', false);
      });
      $(this).val('false');
    }
    valArrayGen = gen_array
    $('input[name="product[gen_exclusion_ids_main]"]').val(gen_array);
  });

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

  $("#select_pre_ex").on('change', function(){
    let value = $(this).val()
    let pre_ex_array = [];

    if(value == 'false'){
      $('.input_pre_ex').each(function () {
        $(this).prop('checked', true);
        pre_ex_array.push($(this).val());
      });
      $(this).val('true');
    } else {
      $('.input_pre_ex').each(function () {
        $(this).prop('checked', false);
      });
      $(this).val('false');
    }
    valArray = pre_ex_array
    $('input[name="product[pre_existing_ids_main]"]').val(pre_ex_array);
  });

  $('.pre-existing.modal').modal({autofocus: false}).modal('attach events', '.button.pre-existing', 'show');
  var valArray = [];

  $(".input_pre_ex").each(function () {
    var value = $(this).val();

    if(this.checked) {
      valArray.push(value);
    } else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('input[name="product[pre_existing_ids_main]"]').val(valArray);
  });

  $(".input_pre_ex").on('change', function () {
    var value = $(this).val();

    if(this.checked) {
      valArray.push(value);
    } else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('input[name="product[pre_existing_ids_main]"]').val(valArray);
  });

  //  $('.view.modal').modal('attach events', '.button.view', 'show').modal({
  //    observeChanges: true
  //  })
  //
  //
  //  $('.view_m_exclusion').on('click', function(){
  //    let exclusion_id = $(this).attr('exclusionID')
  //    let product_exclusion_id = $(this).attr('productExclusionID')
  //    let product_id = $(this).attr('productID')
  //    let csrf = $('input[name="_csrf_token"]').val();
  //    let array = [];
  //
  //    $('#view_m').modal({observeChanges: true}).modal('show');
  //
  //    $.ajax({
  //      url:`/products/${exclusion_id}/get_exclusion`,
  //      headers: {"X-CSRF-TOKEN": csrf},
  //      type: 'get',
  //      success: function(response){
  //        let obj = JSON.parse(response)
  //        let exclusion_diseases = obj.exclusion_diseases
  //        let exclusion_procedures = obj.exclusion_procedures
  //        let exclusion_durations = obj.exclusion_durations
  //
  //        $('#exclusion_name').text(obj.name)
  //        $('#product_exclusion_id').val(product_exclusion_id)
  //        $('#product_id').val(product_id)
  //
  //        // populating General Exclusion tbl
  //        if(obj.coverage == "Exclusion"){
  //          $('#parsed-duration-title').hide()
  //          $('#parsed-duration').hide()
  //          $('#procedure_tbl').show()
  //          $('h4#label').show()
  //          $('#disease_tbl tbody').html('')
  //          for (let exclusion_disease of exclusion_diseases) {
  //            let new_row = `<tr> \
  //              <td>${exclusion_disease.disease.code}</td> \
  //              <td>${exclusion_disease.disease.description}</td> \
  //              </tr>`
  //            $('#disease_tbl tbody').append(new_row)
  //          }
  //
  //          $('#procedure_tbl tbody').html('')
  //          for (let exclusion_procedure of exclusion_procedures) {
  //            let new_row = `<tr> \
  //              <td>${exclusion_procedure.procedure.code}</td> \
  //              <td>${exclusion_procedure.procedure.description}</td> \
  //              </tr>`
  //            $('#procedure_tbl tbody').append(new_row)
  //          }
  //        }
  //        else{
  //
  //          let convertToMoment = (date) => {
  //            return moment(date, "YYYY-MM-DD")
  //          }
  //
  //          let parseDuration = (diff) => {
  //            let duration = moment.duration(diff)
  //            let result = ""
  //
  //            if(duration.years() > 0){
  //              result = `${duration.years()} years ${duration.months()} months ${duration.days()} days`
  //            }else if(duration.months() > 0){
  //              result = `${duration.months()} months ${duration.days()} days`
  //            }else{
  //              result = `${duration.days()} days`
  //            }
  //            return result
  //          }
  //
  //          let from = convertToMoment(obj.duration_from)
  //          let to = convertToMoment(obj.duration_to)
  //          let diff = to.diff(from)
  //          /*let uuuuuuresult = parseDuration(diff)
  //
  //          $('#parsed-duration > h4').show()
  //          $('#parsed-duration > h4').text("Duration: " + result)*/
  //          $('#parsed-duration-title').show()
  //          $('#parsed-duration').show()
  //
  //          $('#parsed-duration').html('')
  //          for (let exclusion_duration of exclusion_durations) {
  //            let new_row = `${exclusion_duration.disease_type}: ${exclusion_duration.duration} months <br />`
  //            $('#parsed-duration').append(new_row)
  //          }
  //
  //          $('#disease_tbl tbody').html('')
  //          for (let exclusion_disease of exclusion_diseases) {
  //            let new_row = `<tr> \
  //              <td>${exclusion_disease.disease.code}</td> \
  //              <td>${exclusion_disease.disease.description}</td> \
  //              </tr>`
  //            $('#disease_tbl tbody').append(new_row)
  //          }
  //          $('#procedure_tbl').hide()
  //          $('h4#label').hide()
  //        }
  //
  //      } // success_respose end
  //
  //    }); // ajax end
  //
  //  }); // onclick end

  // Deleting Product exclusion in step
  $('.deleting_product_exclusion').on('click', function(){
    let product_exclusion_id = $(this).attr('productExclusionID');
    let product_id = $(this).attr('productID');
    $('#confirmation_exclusion').modal('show')


    $('#confirmation_submit_exclusion').on('click', function(){

      let csrf = $('input[name="_csrf_token"]').val();

      $.ajax({
        url:`/products/${product_id}/product_exclusion/${product_exclusion_id}`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'DELETE',
        success: function(response){
          let obj = JSON.parse(response)
          window.location.replace("/products/" + product_id  + "/setup?step=2");
        }
      });

    })
  })

  $('#step4_next').click(function(){
    let product_id = $(this).attr('productID');
    let genex_cards = $('#genex_validation').text();
    let pre_cards = $('#pre_validation').text();

    if(genex_cards.indexOf('Exclusion Code') > -1) {
      if(pre_cards.indexOf('Exclusion Code') > -1){
        window.location.replace('/products/' + product_id + '/setup?step=4')
      } else {
        $('#optionValidation').removeClass('hidden');
      }
    } else {
      $('#optionValidation').removeClass('hidden');
    }
  });

  // Deleting Product exclusion in edit
  $('.deleting_product_exclusion_edit').on('click', function(){
    let product_id = $(this).attr('productID');
    let product_exclusion_id = $(this).attr('productExclusionID');
    $('#confirmation_exclusion_edit').modal('show')

    $('#confirmation_submit_exclusion_edit').on('click', function(){

      let csrf = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/products/${product_id}/product_exclusion/${product_exclusion_id}`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'DELETE',
        success: function(response){
          let obj = JSON.parse(response)
          window.location.replace("/products/" + product_id  + "/edit?tab=exclusion");
        }
      });

    })
  })

  $('#genex_search').keyup(function(){
    let current_search = $(this).val().toLowerCase();

    $('.g_card').each(function(){
      $(this).show();
    });

    $('.g_card').each(function(){
      let val = $(this).text().toLowerCase();
      if(val.indexOf(current_search) == -1) {
        $(this).hide();
      }
    });
  });

  $('#pre_search').keyup(function(){
    let current_search = $(this).val().toLowerCase();

    $('.p_card').each(function(){
      $(this).show();
    });

    $('.p_card').each(function(){
      let val = $(this).text().toLowerCase();
      if(val.indexOf(current_search) == -1) {
        $(this).hide();
      }
    });
  });

  $('#nxtBtnStep2').on('click', function(){
    let p_id = $(this).attr('productID')
    let nxtStep = $(this).attr('nxt_step')
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${p_id}/next_btn/${nxtStep}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'GET',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.replace('/products/' + p_id + '/setup?step=' + nxtStep)
      }
    });
  })

  var textbox = '#limit_amount';
  var hidden = '#hidden_limit_amount';
  $(textbox).keyup(function (e) {
  var num = $(textbox).val();
    var comma = /,/g;
    num = num.replace(comma,'');
    $(hidden).val(num);
    var numCommas = addCommas(num);
    $(textbox).val(numCommas);
  });
    $(textbox).keypress(function(e){
     $('div[id="edit_pec_modal').find('.error').removeClass('error').find('.prompt').remove();
   })
  $(textbox).keypress(function(e){
     if (this.value.length == 0 && e.which == 48 ){
        return false;
     }
     else if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) {
        return false;
     }
  });
function addCommas(nStr) {
  nStr += '';
  var comma = /,/g;
  nStr = nStr.replace(comma,'');
  let x = nStr.split('.');
  let x1 = x[0];
  let x2 = x.length > 1 ? '.' + x[1] : '';
  var rgx = /(\d+)(\d{3})/;
  while (rgx.test(x1)) {
    x1 = x1.replace(rgx, '$1' + ',' + '$2');
  }
  return x1 + x2;
}

$('.edit_pec_limit').on('click', function(){
  let exclusion_id = $(this).attr('exclusion_id')
  let limit_type = $(this).attr('limit_type')
  let limit_percentage = $(this).attr('limit_percentage')
  let limit_peso = $(this).attr('limit_peso')
  let limit_session = $(this).attr('limit_session')
  let to_string = addCommas(limit_peso)
  $('input[name="product_exclusion[exclusion_id]"]').val(exclusion_id)
  if(limit_type=="Peso"){
    $('select[name="product_exclusion[limit_type]"]').dropdown('set value', "Peso")
    $('select[name="product_exclusion[limit_type]"]').dropdown('set text', "Peso")
    $('#limit_amount').val(to_string)
    $('#hidden_limit_amount').val(limit_peso)
  }
  else if(limit_type=="Percentage"){
    $('select[name="product_exclusion[limit_type]"]').dropdown('set value', "Percentage")
    $('select[name="product_exclusion[limit_type]"]').dropdown('set text', "Percentage")
    $('#limit_amount').val(limit_percentage)
    $('#hidden_limit_amount').val(limit_percentage)
  }
  else if(limit_type=="Sessions"){
    $('select[name="product_exclusion[limit_type]"]').dropdown('set value', "Sessions")
    $('select[name="product_exclusion[limit_type]"]').dropdown('set text', "Sessions")
    $('#limit_amount').val(limit_session)
    $('#hidden_limit_amount').val(limit_session)
  }
  if(limit_type=="Peso"){
    $('#limit_icon').html("PHP")
  }
  else if(limit_type=="Percentage"){
    $('#limit_icon').html("%")
  }
  else if(limit_type=="Sessions"){
    $('#limit_icon').html("Session/s")
  }

  $('select[name="product_exclusion[limit_type]"]').on('change', function () {
  $('#limit_amount').val('')
  $('#hidden_limit_amount').val('')
  $('div[id="edit_pec_modal').find('.error').removeClass('error').find('.prompt').remove();
  if($(this).val() == "Peso"){
    $('#limit_icon').html("PHP")
    $('#limit_amount').val(to_string)
    $('#hidden_limit_amount').val(limit_peso)
  }
  else if($(this).val() == "Percentage"){
    $('#limit_icon').html("%")
    $('#limit_amount').val(limit_percentage)
    $('#hidden_limit_amount').val(limit_percentage)
  }
  else if($(this).val() == "Sessions"){
    $('#limit_icon').html("Session/s")
    $('#limit_amount').val(limit_session)
    $('#hidden_limit_amount').val(limit_session)
  }
  })
  $('#edit_pec_modal').modal({autofocus: false}).modal('show');

})

$('#edit_pec_submit').on('click', function(){
  let limit_type = $('select[name="product_exclusion[limit_type]"]').val()
  if(limit_type=="Peso"){
    $('#edit_pec_form').form({
      inline: true,
      on: 'blur',
      fields: {
        'product_exclusion[limit_type]': {
         identifier: 'product_exclusion[limit_type]',
          rules: [
          {
            type: 'empty',
            prompt: 'Please select Limit Type'
          }
          ]
        },
        'product_exclusion[amount]': {
          identifier: 'product_exclusion[amount]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter PEC Limit Amount!'
          },
          {
            type: 'integer[1..100000]',
            prompt: 'Maximum PEC limit amount is up to Php 100,000.00 only.'
          }]
        }
      }
    });
    $('#edit_pec_form').submit()
  }
  else if(limit_type=="Percentage"){
    $('#edit_pec_form').form({
      inline: true,
      on: 'blur',
      fields: {
        'product_exclusion[limit_type]': {
         identifier: 'product_exclusion[limit_type]',
          rules: [
          {
            type: 'empty',
            prompt: 'Please select Limit Type'
          }
          ]
        },
        'product_exclusion[amount]': {
          identifier: 'product_exclusion[amount]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter PEC Limit Amount!'
          },
          {
            type: 'integer[1..100]',
            prompt: 'Maximum PEC limit amount is up to 100% only.'
          }]
        }
      }
    });
    $('#edit_pec_form').submit()
  }
  else if(limit_type=="Sessions"){
    $('#edit_pec_form').form({
      inline: true,
      on: 'blur',
      fields: {
        'product_exclusion[limit_type]': {
         identifier: 'product_exclusion[limit_type]',
          rules: [
          {
            type: 'empty',
            prompt: 'Please select Limit Type'
          }
          ]
        },
        'product_exclusion[amount]': {
          identifier: 'product_exclusion[amount]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter PEC Limit Amount!'
          },
          {
            type: 'integer[1..100]',
            prompt: 'Maximum PEC limit amount is up to 100 Sessions only.'
          }]
        }
      }
    });
    $('#edit_pec_form').submit()
  }
})

});
