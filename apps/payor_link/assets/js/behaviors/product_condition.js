onmount('div[id="product_condition"]', function () {

  function ageEligibilityChecker(){
    let ae_error_counter = 0
    $('.grand_parent_element').each(function(){
      let min_age = $(this).find('.min_holder').find('.age').val()
      let max_age = $(this).find('.max_holder').find('.age').val()
      let min_holder = $(this).find('.min_holder')
      let max_holder = $(this).find('.max_holder')
      let equal_error = $(this).find('.max_holder').find('.equal_equal_validation_message')
      let greater_than_error = $(this).find('.max_holder').find('.greater_than_validation_message')
      let pls_complete_error = $(this).find('.max_holder').find('.pls_complete_validation_message')


      var parsed_minage = parseInt(min_age)
      var parsed_maxage = parseInt(max_age)

      if(parsed_minage > parsed_maxage){
        min_holder.addClass('error')
        max_holder.addClass('error')
        equal_error.addClass('hidden')
        greater_than_error.removeClass('hidden')
        pls_complete_error.addClass('hidden')
        ae_error_counter = ae_error_counter + 1
      }
      else if(parsed_minage == parsed_maxage){
        min_holder.addClass('error')
        max_holder.addClass('error')
        equal_error.removeClass('hidden')
        greater_than_error.addClass('hidden')
        pls_complete_error.addClass('hidden')
        ae_error_counter = ae_error_counter + 1
      }
      else if (isNaN(parsed_minage) == true || isNaN(parsed_maxage) == true){
        min_holder.addClass('error')
        max_holder.addClass('error')
        equal_error.addClass('hidden')
        greater_than_error.addClass('hidden')
        pls_complete_error.removeClass('hidden')
        ae_error_counter = ae_error_counter + 1
      }
    })

    if(ae_error_counter > 0){
      return false
    }
    else {
      return true
    }

  }

  function clearErrorMessage() {
    $('.grand_parent_element').find('.min_holder').removeClass('error')
    $('.grand_parent_element').find('.max_holder').removeClass('error')
    $('.pminage').removeClass('error')
    $('.greater_than_validation_message').addClass('hidden')
    $('.equal_equal_validation_message').addClass('hidden')
    $('.pls_complete_validation_message').addClass('hidden')

    $('#noDaysValidContainer').removeClass('error')
    $('.error_no_days_valid_message').addClass('hidden')

    $('#isMedinaContainer').removeClass('error')
    $('.error_sonny_medina_message').addClass('hidden')

    $('#smp_limit_container').removeClass('error')
    $('.error_sonny_medina_plimit_message').addClass('hidden')
  }

  const checkModeOfAvailment = () => {
    if($('#product_loa_facilitated').is(':checked') || $('#product_reimbursement').is(':checked')) {
      return true
    } else {
      $(".mof").addClass("error")
      $(".error_mode_of_availment").removeClass("hidden")
      return false
    }
  }

  $('.validate-r').click(function(){
    clearErrorMessage()
  })

  $('#product_smp_limit').click(function(){
    clearErrorMessage()
  })

  $('.mof_input').change(function() {
    $(".mof").removeClass("error")
    $(".error_mode_of_availment").addClass("hidden")
  })

  $('.form_validation').submit(() => {
    if (ageEligibilityChecker()) {
      // console.log(checkLoaCondition() ? true:false)
      // console.log(checkRNBValue() ? true:false)
      // console.log( checkLTValue() ? true:false)
      // console.log(checkSOPValue() ? true:false)
      // console.log(checkMdedValue() ? true:false)
      if(checkLoaCondition() == true && checkRNBValue() == true && checkLTValue() == true && checkSOPValue() == true && checkMdedValue() == true && checkModeOfAvailment() == true){
          var input = document.getElementById('adnb');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          var test = $('#adnb').val(unmasked)

          var input = document.getElementById('adnnb');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          var test = $('#adnnb').val(unmasked)

          var input = document.getElementById('opmnb');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          var test = $('#opmnb').val(unmasked)

          var input = document.getElementById('opmnnb');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          var test = $('#opmnnb').val(unmasked)

          var input = document.getElementById('product_smp_limit');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          var test = $('#product_smp_limit').val(unmasked)

          return true
      }
      else {
        return false
      }
    }
    else {
      return false
    }
  })



  $('.clearError').on('click', function(e){
    $('#noDaysValidContainer').removeClass('error')
    $('.error_no_days_valid_message').addClass('hidden')

    $('#isMedinaContainer').removeClass('error')
    $('.error_sonny_medina_message').addClass('hidden')

    $('#smp_limit_container').removeClass('error')
    $('.error_sonny_medina_plimit_message').addClass('hidden')
  })

  $('input[name="product[is_medina]"]').change(function(){
    let val = $(this).val()
    if(val == "true"){
      mask_decimal.mask($('#product_smp_limit'));
      $('#product_smp_limit').prop('disabled', false)
    }
    else{
      $('#product_smp_limit').prop('disabled', true)
      var input = document.getElementById('product_smp_limit');
      var unmasked = input.inputmask.unmaskedvalue()
      input.inputmask.remove()
      var test = $('#product_smp_limit').val(unmasked)
      $('#product_smp_limit').val('')
    }
  })

  let mask_numeric = new Inputmask("numeric", {
    allowMinus:false,
    rightAlign: false,
    max: 100,
    min: 1
  });
  mask_numeric.mask($('#product_no_days_valid'));

  let mask_decimal = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    allowMinus:false,
    rightAlign: false,
    max: 100000,
    min: 1
  });
  mask_decimal.mask($('#product_smp_limit'));

  function checkLoaCondition(){
    let no_days_valid = $('#product_no_days_valid').val()
    let smp_limit = $('#product_smp_limit').val()

    if( (no_days_valid == "" || no_days_valid == null) ){
      $('#noDaysValidContainer').addClass('error')
      $('.error_no_days_valid_message').removeClass('hidden')

      if( !($('#medina_yes:checked').val()?true:false || $('#medina_no:checked').val()?true:false) ){
        $('#isMedinaContainer').addClass('error')
        $('.error_sonny_medina_message').removeClass('hidden')
      }
      else{
        if( ($('#medina_yes:checked').val()?true:false) && (smp_limit.length < 1) ){
          $('#smp_limit_container').addClass('error')
          $('.error_sonny_medina_plimit_message').removeClass('hidden')
        }
      }
      return false
    }
    else{
      if( !($('#medina_yes:checked').val()?true:false || $('#medina_no:checked').val()?true:false) ){
        $('#isMedinaContainer').addClass('error')
        $('.error_sonny_medina_message').removeClass('hidden')
      }
      else{
        if( ($('#medina_yes:checked').val()?true:false) && (smp_limit.length < 1) ){
          $('#smp_limit_container').addClass('error')
          $('.error_sonny_medina_plimit_message').removeClass('hidden')
          return false
        }
        else{
          return true
        }

      }
    }

  }

  function checkSOPValue() {
    let error_counter = 0
    $('.sop_val').each(function(){
      let container = $(this).closest('.field')
      if(container.hasClass('hidden') == false) {
        if($(this).dropdown('get value') == ""){
          let error_msg = container.find('.error_sop')
          container.addClass('error')
          error_msg.removeClass('hidden')
          error_msg.addClass('visible')
          error_counter++
        }
      }
    })
    if(error_counter > 0){
      return false
    } else {
      return true
    }
  }

  function checkMdedValue() {
    let error_counter = 0
    $('.mded_val').each(function(){
      let container = $(this).closest('.field')
        if($(this).dropdown('get value') == ""){
          let error_msg = container.find('.error_mded')
          container.addClass('error')
          error_msg.removeClass('hidden')
          error_msg.addClass('visible')
          error_counter++
        }
    })
    if(error_counter > 0){
      return false
    } else {
      return true
    }
  }

  $('.sop_val').click(function(){
    let container = $(this).closest('.field')
    let error_msg = container.find('.error_sop')
    container.removeClass('error')
    error_msg.addClass('hidden')
    error_msg.removeClass('visible')
  })

  $('.mded_val').click(function(){
    let container = $(this).closest('.field')
    let error_msg = container.find('.error_mded')
    container.removeClass('error')
    error_msg.addClass('hidden')
    error_msg.removeClass('visible')
  })

  function checkLTValue() {
    let checker = 0
    let error_message = ''
    $('.outer_limit_threshold').each(function(){
      let lt_id = $(this).attr('lt_id')
      let lt_name = $(this).attr('lt_name')
      let outer_value = $(this).val()
      let inner_values = $('#pcltf_table_' + lt_id).find('.lt_value')
      $.each(inner_values, function(){
        if($(this).text() == outer_value) {
          $('#otl_field_' + lt_id).addClass('error')
          $('#otl_validation_' + lt_id).removeClass('hidden')
          if(error_message == ''){
            error_message = '<div class="item"> Outer limit threshold of ' + lt_name + ' is equal to one or more limit threshold in exceptions.</div>'
          } else {
            error_message = error_message + '<div class="item"> Outer limit threshold of ' + lt_name + ' is equal to one or more limit threshold in exceptions. </div>'
          }
          checker++
        }
      })
    })
    if(checker > 0){
      let merged_messages = `
      Please enter another value to these limit thresholds:\
        <div class="ui bulleted list">\
        ` + error_message +  `\
        </div>`

      $('#optionValidation').show();
      $('#lt_error_message').html(merged_messages)
      return false
    } else {
      return true
    }

  }

  function checkRNBValue(){
    let error_counter = 0
    let rnb_message = "  "
    $('.rnb_validate').each(function(){
      let fields = $(this).closest('.four.fields')
      let field = $(this).closest('.field')
      let rnb_val = fields.find('div[role="rnb"]').dropdown('get value')
      let role = $(this).attr('role')
      let coverage = $(this).attr('coverage_name')
      switch(rnb_val){
        case '':
          switch(role){
            case 'rnb':
              if($(this).dropdown('get value') == ""){
                let message = field.find('.rnb_validation_message')
                message.removeClass('hidden')
                field.addClass('error')
                error_counter++
                rnb_message = generateErrorMessage("Room and Board (" + coverage + ")" , rnb_message)
              }
              break
          }
          break
        case 'Alternative':
          switch(role){
            case 'rnb':
              if($(this).dropdown('get value') == ""){
                let message = field.find('.rnb_validation_message')
                message.removeClass('hidden')
                field.addClass('error')
                error_counter++
                rnb_message = generateErrorMessage("Room and Board (" + coverage + ")" , rnb_message)
              }
              break
            case 'rt':
              if($(this).dropdown('get value') == ""){
                let message = field.find('.rnb_validation_message')
                message.removeClass('hidden')
                field.addClass('error')
                error_counter++
                rnb_message = generateErrorMessage($(this).attr('field_name') + " (" + coverage + ")", rnb_message)
              }
              break
            case 'rla':
              let value_rla = parseInt($(this).val())
              if($(this).val() == "" || value_rla < 1){
                let message = field.find('.rnb_validation_message')
                message.removeClass('hidden')
                field.addClass('error')
                error_counter++
                rnb_message = generateErrorMessage($(this).attr('field_name') + " (" + coverage + ")", rnb_message)
              }
              break
          }
          break
        case 'Nomenclature':
          switch(role){
            case 'rnb':
              if($(this).dropdown('get value') == ""){
                let message = field.find('.rnb_validation_message')
                message.removeClass('hidden')
                field.addClass('error')
                error_counter++
                rnb_message = generateErrorMessage("Room and Board (" + coverage + ")" , rnb_message)
              }
              break
            case 'rt':
              if($(this).dropdown('get value') == ""){
                let message = field.find('.rnb_validation_message')
                message.removeClass('hidden')
                field.addClass('error')
                error_counter++
                rnb_message = generateErrorMessage($(this).attr('field_name') + " (" + coverage + ")", rnb_message)
              }
              break
          }
          break
        case 'Peso Based':
          switch(role){
            case 'rnb':
              if($(this).dropdown('get value') == ""){
                let message = field.find('.rnb_validation_message')
                message.removeClass('hidden')
                field.addClass('error')
                error_counter++
                rnb_message = generateErrorMessage("Room and Board (" + coverage + ")" , rnb_message)
              }
              break
            case 'rla':
              let value_rla = parseInt($(this).val())
              if($(this).val() == "" || value_rla < 1){
                let message = field.find('.rnb_validation_message')
                message.removeClass('hidden')
                field.addClass('error')
                error_counter++
                rnb_message = generateErrorMessage($(this).attr('field_name') + " (" + coverage + ")", rnb_message)
              }
              break
          }
          break
      }
    })

    if(error_counter == 0) {
      let error_counter_form = 0
      $('.validate-r').each(function(){
        if($(this).val() == ""){
          error_counter_form++
        }
      })
      if(error_counter_form > 0){
        return false
      } else {
        return true
      }
    } else {
      let merged_messages = `
      Please enter value for these Room and Board field\/s:\
        <div class="ui bulleted list">\
        ` + rnb_message +  `\
        </div>`

      $('#optionValidation').show();
      $('#condition_error_message').html(merged_messages)
      return false
    }
  }

  function generateErrorMessage(field, message){
    if(message == ''){
      message = message
    } else {
      message = message + '<div class="item">' + field + '</div>'
    }
    return message
  }

  function refreshRNBData() {
    let rnb_array = ""
    $('.rnb_row').each(function(){
      let coverage_id = $(this).attr('coverageID')
      let rnb_id = $('#rnb_id_' + coverage_id).val()
      let rnb = ($('#rnb_' + coverage_id).dropdown('get value') != "" ? $('#rnb_' + coverage_id).dropdown('get value') : "nil")
      let rt = ($('#rt_' + coverage_id).dropdown('get value') != "" ? $('#rt_' + coverage_id).dropdown('get value') : "nil")
      let rla = ($('#rla_' + coverage_id).val() != "" ? $('#rla_' + coverage_id).val() : "nil")
      let ru = ($('#ru_' + coverage_id).val() != "" ? $('#ru_' + coverage_id).val() : "nil")
      let rut = ($('#rut_' + coverage_id).val() != "" ? $('#rut_' + coverage_id).val() : "nil")
      let unmasking_regex = new RegExp(',', 'g')
      let unmasked_rla = rla.replace(unmasking_regex, "").trim()
      let rnb_record = rnb_id + "_" + rnb + "_" + rt + "_" + unmasked_rla + "_" + ru + "_" + rut
      if(rnb_array == ""){
        rnb_array = rnb_record
      } else {
        rnb_array = rnb_array + "," + rnb_record
      }
    })
    $('input[name="product[rnb_array]"]').val(rnb_array)
  }

  function setRNBData(selector, value) {
    if(value != "nil"){
      $(selector).val(value)
    }
  }

  function validate_rnb(rnb_cov_id){
    let rnb = $('#rnb_' + rnb_cov_id).dropdown('get value');
    let rt = '#rt_' + rnb_cov_id;
    let rla = '#rla_' + rnb_cov_id;

    if(rnb == ""){
      /* both disable */
      $(rt).addClass('disabled');
      $(rla).prop('disabled', true);
    } else if(rnb == "Nomenclature") {
      /* room type enabled */
      $(rt).removeClass('disabled');
      $(rla).prop('disabled', true);
    } else if(rnb == "Peso Based") {
      /* room limit amount enabled */
      $(rt).addClass('disabled');
      $(rla).prop('disabled', false);
      $(rt).dropdown('clear')
      var im = new Inputmask("decimal", {
        radixPoint: ".",
        groupSeparator: ",",
        digits: 2,
        autoGroup: true,
        // prefix: '₱ ',
        rightAlign: false,
        oncleared: function () { self.Value(''); }
      });
      im.mask($(rla));

    } else if(rnb == "Alternative") {
      /* both enabled */
      $(rt).removeClass('disabled');
      $(rla).prop('disabled', false);
      var im = new Inputmask("decimal", {
        radixPoint: ".",
        groupSeparator: ",",
        digits: 2,
        autoGroup: true,
        // prefix: '₱ ',
        rightAlign: false,
        oncleared: function () { self.Value(''); }
      });
      im.mask($(rla));
    }
  }

  $('.rnb_elements').on('click', function(){
    $('.rnb_validation_message').addClass('hidden')
    let field = $('.rnb_validation_message').closest('.field')
    $('#optionValidation').hide();
    field.removeClass('error')
  })

  $('.rnb_elements').on('focusout', function(){
    refreshRNBData()
  })

  $('.title.rnb_accordion').on('click', function(){
    let product_id = $(this).attr('productID');
    let coverage_id = $(this).attr('coverageID');
    let csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/products/${product_id}/update_rnb_coverage/${coverage_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'put',
      success: function(response){
        let obj = JSON.parse(response)
      }
    });
    validate_rnb(coverage_id)
  })

  $('.rnb_select_c').click(function(){
    let coverage_id = $(this).attr('coverageID');
    let rt = '#rt_' + coverage_id;
    let rla = '#rla_' + coverage_id;
    $(rt).val('').change();
    $(rla).val('');
    validate_rnb(coverage_id)
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

  $('#step_6').click(function(){
    let counter = 0;
    $('.validate-r').each(function(){
      let val = $(this).val()

      if(val == ''){
        counter++;
        //alert(val)
      }
    });

    if(counter > 0){
      $('#optionValidation').show();
    } else {
      let p_id = $(this).attr('productID')
      let link = "/products/" + p_id + "/setup?step=6"
      window.location.replace(link)
    }
  });

  // for edit condition rnb
  $('.condition_item_edit').click(function(){
    if(checkRNBValue()) {
      let p_id = $(this).attr('productID')
      let tab = $(this).attr('link')
      if (tab == "show"){
        let link = `/products/${p_id}/`
        window.location.replace(link)
      } else {
        let link = `/products/${p_id}/edit?tab=${tab}`
        window.location.replace(link)
      }
    } else {
      $('#optionValidation').show();
    }

    // let link_tab = $(this).attr('link')
    // let counter = 0;
    // $('.validate-r').each(function(){
    //   let val = $(this).val()

    //   if(val == ''){
    //     counter++;
    //     //alert(val)
    //   }
    // });

    // if(counter > 0){
    // }
    // else {
    //   if(link_tab == "show"){

    //   }
    //   else {
    //     let p_id = $(this).attr('productID')
    //     let link = "/products/" + p_id + "/edit?tab=" + link_tab
    //     window.location.replace(link)
    //   }
    // }
  });
  // end of edit condition rnb

  var im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('#adnb'));
  im.mask($('#adnnb'));
  im.mask($('#opmnb'));
  im.mask($('#opmnnb'));

  $('.form_validation')
  .form({
    inline : true,
    on     : 'blur',
    fields: {
      'product[nem_principal]': {
        identifier: 'product[nem_principal]',
        optional: true,
        rules: [
          {
            type: 'integer',
            prompt: 'Please enter number of eligible members'
          }
        ]
      },
      'product[nem_dependent]': {
        identifier: 'product[nem_dependent]',
        optional: true,
        rules: [
          {
            type: 'integer',
            prompt: 'Please enter number of eligible members'
          }
        ]
      }
    }
  })

  // room and board js /////////////////////////////////////////////////////////

  $('.rnb_hidden').each(function(){
    let record = $(this).val()
    let rnb_array = record.split("_")

    /* RNB Fields */
    let room_and_board = rnb_array[1]
    let product_coverage_id = rnb_array[6]

    setRNBData('#rnb_' + product_coverage_id, room_and_board)
  })

  let active_rnb_cov_id = $('.title.rnb_accordion.active').attr('coverageID');
  validate_rnb(active_rnb_cov_id)

  $('.rnb_hidden').each(function(){
    let record = $(this).val()
    let rnb_array = record.split("_")

    /* RNB Fields */
    let id = rnb_array[0]
    let room_type = rnb_array[2]
    let room_limit_amount = rnb_array[3]
    let room_upgrade = rnb_array[4]
    let room_upgrade_time = rnb_array[5]
    let product_coverage_id = rnb_array[6]

    setRNBData('#rt_' + product_coverage_id, room_type)
    setRNBData('#rla_' + product_coverage_id, room_limit_amount)
    setRNBData('#ru_' + product_coverage_id, room_upgrade)
    setRNBData('#rut_' + product_coverage_id, room_upgrade_time)
  })

  refreshRNBData()
  // end of room and board js ////////////////////////////////////////////
  loopThroughLimitThresholds()
  $('.outer_limit_threshold').on('focusout', function(){
    loopThroughLimitThresholds()
    $('.otl_vs').addClass('hidden')
    $('.otl_fields').removeClass('error')
  })

  function loopThroughLimitThresholds(){
    let limit_threshold_values = ''
    $('input[name="product[outer_limit_threshold]"]').val(limit_threshold_values)
    $('.outer_limit_threshold').each(function(){
      let val = $(this).val()
      if(val != ''){
        let id = $(this).attr('lt_id')
        let unmasking_regex = new RegExp(',', 'g')
        let unmasked_val = val.replace(unmasking_regex, "").trim()
        if(limit_threshold_values == ''){
          limit_threshold_values = "" + unmasked_val + "_" + id
          $('input[name="product[outer_limit_threshold]"]').val(limit_threshold_values)
        } else {
          limit_threshold_values = $('input[name="product[outer_limit_threshold]"]').val()
          limit_threshold_values = limit_threshold_values + "," + unmasked_val + "_" + id
          $('input[name="product[outer_limit_threshold]"]').val(limit_threshold_values)
        }
      }
    })
  }

});

onmount('div[id="HOED_container"]', function () {
  function loopHierarchyItems(items){
    let hierarchy_type = "";
    items.each(function(index, value){
      let index_count = index + 1
      let item_value = $(this).text();
      if(hierarchy_type != ''){
        hierarchy_type = hierarchy_type + ',' + index_count + '-' + item_value
      } else {
        hierarchy_type = index_count + '-' + item_value
      }
    });
    return hierarchy_type
  }

  function refreshHierarchyData(){
    let me_order = loopHierarchyItems($('#me_sortable').find('span'));
    let se_order = loopHierarchyItems($('#se_sortable').find('span'));
    let spe_order = loopHierarchyItems($('#spe_sortable').find('span'));

    $('input[name="product[married_employee]"]').val(me_order);
    $('input[name="product[single_employee]"]').val(se_order);
    $('input[name="product[single_parent_employee]"]').val(spe_order);
  }

  function checkHierarchy(){
    let me_order = $('input[name="product[married_employee]"]').val();
    let se_order = $('input[name="product[single_employee]"]').val();
    let spe_order = $('input[name="product[single_parent_employee]"]').val();

    if(me_order == ''){
      me_order = '1-Spouse,2-Child,3-Parent,4-Sibling'
    }
    if(se_order == '') {
      se_order = '1-Parent,2-Sibling'
    }
    if(spe_order == '') {
      spe_order = '1-Parent,2-Child,3-Sibling'
    }

    checkHierarchyArray(me_order, '#me_sortable', 'me')
    checkHierarchyArray(se_order, '#se_sortable', 'se')
    checkHierarchyArray(spe_order, '#spe_sortable', 'spe')
    refreshHierarchyData()
  }

  function checkHierarchyArray(dependent, container, type){
    let count = 0;
    if(dependent != ''){
      let dependent_array = dependent.split(",")
      for(let i = 1; i <= dependent_array.length; i++){
        $.each(dependent_array, function(index,value){
          let item_array = value.split("-")
          let item_index = item_array[0]
          let item_value = item_array[1]
          let container_dd;

          if(i == item_index){
            let new_item = `\
              <div class="ui large fluid black basic label">\
              <span class="left floated">${item_value}</span>\
              <a class="right floated circular ui icon negative mini button delete_sortable" dependent="${item_value}" category="${type}">\
              <i class="icon minus"></i>\
              </a>\
              </div>\
              `

            switch(type){
              case 'me':
                container_dd = $('#me_dd');
              break;
              case 'se':
                container_dd = $('#se_dd');
              break;
              case 'spe':
                container_dd = $('#spe_dd');
              break;
            }

            let dropdowns = container_dd.find('div')
            $.each(dropdowns, function(){
              if($(this).attr('dependent') == item_value){
                $(this).remove()
              }
            });

            $(container).append(new_item)
          }
        })
      }
    }
  }

  checkHierarchy()

  $('#me_sortable').sortable({
    appendTo: 'body',
    helper: 'clone',
    start: function(event, ui){
      $("#me_validation").addClass('hidden');
    },
    stop: function(event, ui){
      refreshHierarchyData()
    },
    drag: function(event,ui){
      ui.helper.offset(ui.position);
    }
  });

  $('#se_sortable').sortable({
    appendTo: 'body',
    helper: 'clone',
    start: function(event, ui){
      $("#se_validation").addClass('hidden');
    },
    stop: function(event, ui){
      refreshHierarchyData()
    },
    drag: function(event,ui){
      ui.helper.offset(ui.position);
    }
  });

  $('#spe_sortable').sortable({
    appendTo: 'body',
    helper: 'clone',
    start: function(event, ui){
      $("#spe_validation").addClass('hidden');
    },
    stop: function(event, ui){
      refreshHierarchyData()
    },
    drag: function(event,ui){
      ui.helper.offset(ui.position);
    }
  });

  $('div[id="product_condition').on('click', '.delete_sortable',function(){
    let dependent = $(this).attr('dependent')
    let category = $(this).attr('category')
    let container;
    let checker;


    switch(category){
      case 'me':
        container = $('#me_dd');
        checker = $('#me_sortable').find('div').length;
        break;
      case 'se':
        container = $('#se_dd');
        checker = $('#se_sortable').find('div').length;
        break;
      case 'spe':
        container = $('#spe_dd');
        checker = $('#spe_sortable').find('div').length;
        break;
    }

    if(checker == 1){
      $("#" + category + "_validation").removeClass('hidden');
    } else {
      let new_item = `\
        <div href="#" class="item clickable-row append_sortable" dependent="${dependent}" category="${category}" >\
        ${dependent}\
        </div>\
        `
      container.append(new_item)

      $(this).closest('div').remove()
      refreshHierarchyData()
    }

  })

  $('div[id="product_condition').on('click', '.append_sortable',function(){
    let dependent = $(this).attr('dependent')
    let category = $(this).attr('category')

    let container;
    switch(category){
      case 'me':
        container = $('#me_sortable');
        break;
      case 'se':
        container = $('#se_sortable');
        break;
      case 'spe':
        container = $('#spe_sortable');
        break;
    }
    let new_item = `\
      <div class="ui large fluid black basic label">\
      <span class="left floated">${dependent}</span>\
      <a class="right floated circular ui icon negative mini button delete_sortable" dependent="${dependent}" category="${category}">\
      <i class="icon minus"></i>\
      </a>\
      </div>\
    `
    container.append(new_item)
    $("#" + category + "_validation").addClass('hidden');
    refreshHierarchyData()
    $(this).remove()
  })



});

onmount('div[id="limit_threshold_container"]', function () {
  let im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  })
  im.mask($('.outer_limit_threshold'));
  im.mask($('.lt_value'));

  $('.btnFacility').click(function(){
    let csrf = $('input[name="_csrf_token"]').val();
    let product_limit_threshold_id = $(this).attr('productLimitThreshold')
    let product_id = $(this).attr('productID')

    im.mask($('#limit_threshold'));

    $('a[role="edit"]').hide()
    $('a[role="delete"]').hide()

    $('.pclt.field.error').removeClass("error");
    $('.pclt.error').removeClass("error");

    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });

    $.ajax({
      url:`/products/${product_limit_threshold_id}/get_product_limit_threshold`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let obj = JSON.parse(response)
        $('#facility').find('.item').remove()
        for(let facility of obj){
          let new_row = `<div class="item" data-value="${facility.id}">${facility.display}</div>`
          $('#facility_rows').append(new_row)
        }
        $('#limit_threshold').val('')
        $('button[role="add"]').html('<i class="plus icon"></i>Add')
        $('button[role="add"]').show()
        $('.ui.search.selection.dropdown.facility').removeClass('disabled')
        $('.limit_threshold_field').removeClass('disabled')
        $('#limit_threshold_modal').modal({autofocus: false}).modal('show')
        $('#facility').dropdown('clear')
        $('#facility').dropdown('refresh')
        $('input[name="product[pclt_id]"]').val(product_limit_threshold_id)
        $('input[name="product[pcltf_id]"]').val('')
        clearErrorMessagesLT()
        $('input[name="product[product_id]"]').val(product_id)
        $('input[name="prev_lt"]').val($('#outer_lt_' + product_limit_threshold_id).val())
        $('#facility').dropdown()
        $('#facility').dropdown({fullTextSearch: 'exact'})
      }
    })
  })

  $('.title.lt_accordion').on('click', function(){
    let product_id = $(this).attr('productID');
    let coverage_id = $(this).attr('coverageID');
    let csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/products/${product_id}/update_lt_coverage/${coverage_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'put',
      success: function(response){
        let obj = JSON.parse(response)
      }
    });
  })

  $('div[id="limit_threshold_container"]').on('click', '.editBtnFacility', function(){
    let csrf = $('input[name="_csrf_token"]').val();
    let product_limit_threshold_id = $(this).attr('productLimitThreshold')
    let pcltf_id = $(this).attr('productLimitThresholdFacility')
    let f_id = $(this).attr('facilityID')
    let lt = $(this).attr('lt')
    let product_id = $(this).attr('productID')

    im.mask($('#limit_threshold'));

    $('.pclt.field.error').removeClass( "error" );
    $('.pclt.error').removeClass( "error" );

    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });

    $.ajax({
      url:`/products/${product_limit_threshold_id}/get_product_limit_threshold_edit`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let obj = JSON.parse(response)
        $('#facility').find('option').remove()
        for(let facility of obj){
          let new_row = `<div class="item" data-value="${facility.id}">${facility.display}</div>`
          $('#facility_rows').append(new_row)
        }
        $('#limit_threshold_modal').modal({autofocus: false}).modal('show')
        $('#facility').dropdown()
        $('#facility').dropdown('refresh')
        $('#facility').dropdown('set selected', f_id)
        $('button[role="add"]').hide()
        $('a[role="edit"]').show()
        $('a[role="delete"]').show()
        $('a[role="delete"]').removeClass('disabled')
        $('.ui.search.selection.dropdown.facility').addClass('disabled')
        $('.limit_threshold_field').addClass('disabled')
        $('input[name="product[pclt_id]"]').val(product_limit_threshold_id)
        $('input[name="product[pcltf_id]"]').val(pcltf_id)
        $('input[name="prev_lt"]').val($('#outer_lt_' + product_limit_threshold_id).val())
        $('#limit_threshold').val(lt)
        clearErrorMessagesLT()
        $('input[name="product[product_id]"]').val(product_id)
      }
    })
  })

  $('#pclt_form')
  .form({
    inline : true,
    on     : 'blur',
    fields: {
      'product[facility_id]': {
        identifier: 'product[facility_id]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter a facility.'
          }
        ]
      },
      'product[limit_threshold]': {
        identifier: 'product[limit_threshold]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter limit threshold.'
          }
        ]
      }
    },
    onSuccess: function(event, fields) {
      let input = document.getElementById('limit_threshold');
      var unmasked = input.inputmask.unmaskedvalue()
      input.inputmask.remove()
      $('#limit_threshold').val(unmasked)
    }
  })

  function clearErrorMessagesLT(){
      $('.pclt_facility').css({"color": ""})
      $('div[id="facility"]').find('.text').css({"color": ""})
      $('div[id="facility"]').css({"border-color": "", "background": ""})
      $('.pclt_lt').css({"color": ""})
      $('#limit_threshold').css({"border-color": "", "background": ""})
      $('.lt_validation_message').addClass('hidden')
  }

  $('#facility').click(function(){clearErrorMessagesLT()})
  $('#limit_threshold').click(function(){clearErrorMessagesLT()})


  $('button[role="add"]').click(function(){
    let pclt_id = $('input[name="product[pclt_id]"]').val()
    let pcltf_id = $('input[name="product[pcltf_id]"]').val()
    let facility_id = $('div[id="facility"]').dropdown('get value')
    let limit_threshold = $('#limit_threshold').val()
    let product_id = $('input[name="product[product_id]"]').val()
    let csrf = $('input[name="_csrf_token"]').val();

    if(facility_id == ""){
      $('.pclt_facility').css({"color": "#9F3A38"})
      $('div[id="facility"]').find('.text').css({"color": "#9F3A38"})
      $('div[id="facility"]').css({"border-color": "#E0B4B4", "background": "#FFF6F6"})
      let validation_message = $('.pclt_facility').find('.lt_validation_message')
      $('.lt_validation_message').css(
        {
          "white-space": "normal",
          "border": "1px",
          "border-style": "solid",
          "border-color": "#E0B4B4",
          "color": "#9F3A38 !important"})
      $('.lt_validation_message').text('Please enter a valid facility.')
      validation_message.removeClass('hidden')
    } else {
      if(limit_threshold == ""){
        $('.pclt_lt').css({"color": "#9F3A38"})
        $('#limit_threshold').css({"border-color": "#E0B4B4", "background": "#FFF6F6"})
        let validation_message = $('.pclt_lt').find('.lt_validation_message')
        $('.lt_validation_message').css(
          {
            "white-space": "normal",
            "border": "1px",
            "border-style": "solid",
            "border-color": "#E0B4B4",
            "color": "#9F3A38 !important"})
            $('.lt_validation_message').text('Please enter a valid limit threshold.')
            validation_message.removeClass('hidden')
      } else {
        if(limit_threshold == $('input[name="prev_lt"]').val()){
          $('.pclt_lt').css({"color": "#9F3A38"})
          $('#limit_threshold').css({"border-color": "#E0B4B4", "background": "#FFF6F6"})
          let validation_message = $('.pclt_lt').find('.lt_validation_message')
          $('.lt_validation_message').css(
            {
              "white-space": "normal",
              "border": "1px",
              "border-style": "solid",
              "border-color": "#E0B4B4",
              "color": "#9F3A38 !important"})
              $('.lt_validation_message').text('Inner limit is equal to outer limit.')
              validation_message.removeClass('hidden')
        } else {
          if(facility_id != "" && limit_threshold != "" && limit_threshold != $('input[name="prev_lt"]').val()) {
            let unmasking_regex = new RegExp(',', 'g')
            let unmasked_lt = limit_threshold.replace(unmasking_regex, "").trim()

            $.ajax({
              url:`/products/${product_id}/save_pcltf`,
              headers: {"X-CSRF-TOKEN": csrf},
              type: 'post',
              data: {product_id: product_id, product_params: {"pclt_id": pclt_id, "pcltf_id": pcltf_id, "facility_id": facility_id, "limit_threshold": unmasked_lt}},
              dataType: 'json',
              success: function(response){
                $('#limit_threshold_modal').modal('hide')
                alertify.success('<i class="close icon"></i><div class="header">Success</div><p>Limit threshold table has been updated successfully.</p>');
                let result = response.result
                let dataSet = []
                for (let pcltf of result){
                  let data_array = []
                  data_array.push('<a href="#!" class="open href editBtnFacility" productLimitThreshold="' + pclt_id + '" productLimitThresholdFacility="' + pcltf.id  + '" facilityID="' + pcltf.facility_id + '" lt="' + pcltf.limit_threshold  + '" productID="' + product_id  +  '" >' + pcltf.code + '</a>')
                  data_array.push(pcltf.name)
                  data_array.push(pcltf.limit_threshold)
                  dataSet.push(data_array)
                }

                let datatable_id = '#pcltf_table_' + pclt_id
                $(datatable_id).DataTable( {
                  destroy: true,
                  data: dataSet,
                  "columnDefs": [
                    { "title": "Facility Code", "targets": 0 },
                    { "title": "Facility Name", "targets": 1  },
                    { "className": "lt_value", "targets": 2 }
                  ]
                });
                im.mask($('.lt_value'))
                let table_header = $('#pcltf_table_' + pclt_id).find('th')
                let header = table_header
                header.removeClass('lt_value')
                $.each(header, function(){
                  if($(this).text() == '') {
                    $(this).text('Limit Threshold')
                  }
                })
              }
            })
          }
        }
      }
    }

  })

  $('a[role="edit"]').click(function(){
    $('.limit_threshold_field').removeClass('disabled')
    $('button[role="add"]').html('<i class="save icon"></i>Save')
    $('button[role="add"]').show()
    $('a[role="delete"]').addClass('disabled')
    $(this).hide()
  })

  $('a[role="delete"]').click(function(){
    $('#pcltf_confirmation').modal('show')
    let pcltf_id = $('input[name="product[pcltf_id]"]').val()
    $('#confirmation_pcltf_id').val(pcltf_id)
  })

  $('#confirmation_cancel_pcltf').click(function(){
    $('#limit_threshold_modal').modal({autofocus: false}).modal('show')
  })

  $('#confirmation_submit_pcltf').click(function(){
    let pclt_id = $('input[name="product[pclt_id]"]').val()
    let facility_id = $('div[id="facility"]').dropdown('get value')
    let limit_threshold = $('#limit_threshold').val()
    let product_id = $('input[name="product[product_id]"]').val()
    let pcltf_id = $('#confirmation_pcltf_id').val()
    let csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/products/${pcltf_id}/delete_pcltf`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        $('#pcltf_confirmation').modal('hide')
        alertify.success('<i class="close icon"></i><div class="header">Success</div><p>Limit Threshold Facility has been deleted successfully.</p>');
        let result = response.result
        let dataSet = []
        for (let pcltf of result){
          let data_array = []
          data_array.push('<a href="#!" class="open href editBtnFacility" productLimitThreshold="' + pclt_id + '" productLimitThresholdFacility="' + pcltf.id  + '" facilityID="' + pcltf.facility_id + '" lt="' + pcltf.limit_threshold  + '" productID="' + product_id  +  '" >' + pcltf.code + '</a>')
          data_array.push(pcltf.name)
          data_array.push(pcltf.limit_threshold)
          dataSet.push(data_array)
        }

        let datatable_id = '#pcltf_table_' + pclt_id
        $(datatable_id).DataTable( {
          destroy: true,
          data: dataSet,
          "columnDefs": [
            { "title": "Facility Code", "targets": 0 },
            { "title": "Facility Name", "targets": 1  },
            { "className": "lt_value", "targets": 2 }
          ]
        });
        im.mask($('.lt_value'))
        let table_header = $('#pcltf_table_' + pclt_id).find('th')
        let header = table_header
        header.removeClass('lt_value')
        $.each(header, function(){
          if($(this).text() == '') {
            $(this).text('Limit Threshold')
          }
        })
      }
    })
  })
})
