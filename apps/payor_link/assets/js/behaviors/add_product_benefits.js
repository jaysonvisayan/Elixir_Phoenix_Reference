onmount('div[id="product_benefits"]', function () {

  $('.modal_benefit').modal({autofocus: false}).modal('attach events', '.btn_add_benefit', 'show');
    var valArray = [];

    $(".input_benefit").each(function () {
      var value = $(this).val();

      if(this.checked) {
        valArray.push(value);
      } else {
        var index = valArray.indexOf(value);

        if (index >= 0) {
          valArray.splice( index, 1)
        }
      }
      $('input[name="product[benefit_ids_main]"]').val(valArray);
    });

    // $(".input_benefit").on('change', function () {
    //   var value = $(this).val();

    //   if(this.checked) {
    //     valArray.push(value);
    //   } else {
    //     var index = valArray.indexOf(value);

    //     if (index >= 0) {
    //       valArray.splice( index, 1)
    //     }
    //   }
    //   $('input[name="product[benefit_ids_main]"]').val(valArray);
    // });

    $("#select_benefit").on('change', function(){
      let value = $(this).val()
      let b_array = [];

      if(value == 'false'){
        $('.input_benefit').each(function () {
          $(this).prop('checked', true);
          b_array.push($(this).val());
        });
        $(this).val('true');
      } else {
        $('.input_benefit').each(function () {
          $(this).prop('checked', false);
        });
        $(this).val('false');
      }
      valArray = b_array
      $('input[name="product[benefit_ids_main]"]').val(b_array);
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

    $('.delete_benefit').click(function(){
      let p_id = $(this).attr('productID');
      let pb_id = $(this).attr('productBenefitID');
      $('#benefit_removal_confirmation').modal('show');
      $('#confirmation_p_id').val(p_id);
      $('#confirmation_pb_id').val(pb_id);
    });

    $('#confirmation_cancel_b').click(function(){
      $('#benefit_removal_confirmation').modal('hide');
    });

    $('#confirmation_submit_b').click(function(){
      $(this).addClass('disabled')
      let csrf = $('input[name="_csrf_token"]').val();
      let p_id = $('#confirmation_p_id').val();
      let pb_id = $('#confirmation_pb_id').val();
      $.ajax({
        url:`/products/${p_id}/product_benefit/${pb_id}/step`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'delete',
        success: function(response){
          let obj = JSON.parse(response)
          // this is to prevent the open modal to be openned
          window.location.replace("/products/" + p_id  + "/setup?step=3");
        }
      });
    });

    $('#confirmation_submit_b_peme').click(function(){
      $(this).addClass('disabled')
      let csrf = $('input[name="_csrf_token"]').val();
      let p_id = $('#confirmation_p_id').val();
      let pb_id = $('#confirmation_pb_id').val();
      $.ajax({
        url:`/products/${p_id}/product_benefit/${pb_id}/step`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'delete',
        success: function(response){
          let obj = JSON.parse(response)
          // this is to prevent the open modal to be openned
          window.location.replace("/products/" + p_id  + "/setup?step=2");
        }
      });
    });

    $('#confirmation_submit_b_edit').click(function(){
      $(this).addClass('disabled')
      let csrf = $('input[name="_csrf_token"]').val();
      let p_id = $('#confirmation_p_id').val();
      let pb_id = $('#confirmation_pb_id').val();
      $.ajax({
        url:`/products/${p_id}/product_benefit/${pb_id}/step`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'delete',
        success: function(response){
          let obj = JSON.parse(response)
          // this is to prevent the open modal to be openned
          window.location.replace("/products/" + p_id  + "/edit?tab=benefit");
        }
      });
    });

    $('#step3_next').click(function(){
      let product_id = $(this).attr('productID');
      let benefit_cards = $('#benefit_cards').text();
      let nxtStep = $(this).attr('nxt_step')
      let csrf = $('input[name="_csrf_token"]').val();

      if(benefit_cards.indexOf('Benefit Code') > -1) {
        $.ajax({
          url:`/products/${product_id}/next_btn/${nxtStep}`,
          headers: {"X-CSRF-TOKEN": csrf},
          type: 'GET',
          success: function(response){
            let obj = JSON.parse(response)
            if (obj.id == undefined){
              alertify.error(`<i class="close icon"></i>${obj.message}`)
            }
            else{
              window.location.replace('/products/' + product_id + '/setup?step=' + nxtStep)
            }
          }
        });
      }
      else {
        $('#optionValidation').removeClass('hidden');
      }
    });

    $('#benefit_search').keyup(function(){
      let current_search = $(this).val().toLowerCase();

      $('.b_card').each(function(){
        $(this).show();
      });

      $('.b_card').each(function(){
        let val = $(this).text().toLowerCase();
        if(val.indexOf(current_search) == -1) {
          $(this).hide();
        }
      });
      if($('.b_card:visible').length == 0){
        $('#no_result').removeAttr('style')
      }
      else{
        $('#no_result').removeAttr('style')
        $('#no_result').attr('style', 'visibility: hidden')
      }
    });


    var im = new Inputmask("decimal", {
      radixPoint: ".",
      groupSeparator: ",",
      digits: 2,
      autoGroup: true,
      // prefix: '₱ ',
      rightAlign: false,
      oncleared: function () { self.Value(''); }
    });
    im.mask($('.benefit_modal_product_limit_amt'));

    var im = new Inputmask("decimal", {
      radixPoint: ".",
      groupSeparator: ",",
      digits: 2,
      autoGroup: true,
      // prefix: '₱ ',
      rightAlign: false,
      oncleared: function () { self.Value(''); }
    });
    im.mask($('.benefit_modal_limit_amt'));

  $('.benefit_item_edit').click(function(e){
    let link = $(this).attr('link')
    let product_id = $(this).attr('productID')
    checkBenefits(link, product_id)
  })

  function checkBenefits(link_tab, p_id) {
    let counter = 0
    $('.benefit_validate').each(function(){
      counter++
    })
    if(counter == 0){
       $('#benefitOptionValidation').removeClass('hidden')
    }
    else {
        let link = "/products/" + p_id + "/edit?tab=" + link_tab
        window.location.replace(link)
    }
  }

  // for product step3 benefit modal
  // onload
  let product_id = ($('#product_id').val())
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
      "<'six wide column'i>"+
      "<'right aligned ten wide column'p>"+
      ">"+
      ">",
    // "ordering": [[2, 'asc' ]],
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
  // console.log("search txtbox")
  // console.log($(this).val())
    // search txtbox
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${product_id}/benefit_load_datatable`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      data: {params: { "search_value" : $(this).val().trim(), "offset" : 0}},
      dataType: 'json',
      success: function(response){
        // console.log(response)
        table.clear()
        let dataSet = []
        // console.log(response.benefits.length)
        for (let i=0;i<response.benefits.length;i++){
          table.row.add( [
            append_checkbox(response.benefits[i]),
            response.benefits[i].code,
            response.benefits[i].name,
            response.benefits[i].benefit_coverages,
            response.benefits[i].total_limit_amount
          ] ).draw();
        }

      }
    })
  })
  $('.dataTables_length').find('.ui.dropdown').on('change', function(){
    if ($(this).find('.text').text() == 100){
      // dropdown shows
      let info = table.page.info();
      if (info.pages - info.page == 1){
        let search_value = $('.dataTables_filter input').val();
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/products/${product_id}/benefit_load_datatable`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {params: { "search_value" : search_value.trim(), "offset" : info.recordsTotal}},
          dataType: 'json',
          success: function(response){
            let dataSet = []
            for (let i=0;i<response.benefits.length;i++){
              table.row.add( [
                append_checkbox(response.benefits[i]),
                response.benefits[i].code,
                response.benefits[i].name,
                response.benefits[i].benefit_coverages,
                response.benefits[i].total_limit_amount
              ] ).draw(false);
            }

          }
        })
      }
    }
  })
  let info
  table.on('page', function () {

    // console.log("page numbers")
    // page numbers
    info = table.page.info();
    if (info.pages - info.page == 1){
      let search_value = $('.dataTables_filter input').val();
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/products/${product_id}/benefit_load_datatable`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {params: { "search_value" : search_value.trim(), "offset" : info.recordsTotal}},
        dataType: 'json',
        success: function(response){
          let dataSet = []
          for (let i=0;i<response.benefits.length;i++){
            table.row.add( [
              append_checkbox(response.benefits[i]),
              response.benefits[i].code,
              response.benefits[i].name,
              response.benefits[i].benefit_coverages,
              response.benefits[i].total_limit_amount
            ] ).draw(false);
          }

        }
      })
    }
  });

  function append_checkbox(benefit){
    let current_benefits = $('input[name="product[benefit_ids_main]"]').val()
    console.log(current_benefits)
    if(current_benefits != ""){
      if (current_benefits.includes(benefit.id)) {
        return `<td><div class=""><input type="checkbox" style="height: 20px; width: 20px;" class="input_benefit" name="product[benefit_ids][]" value="${benefit.id}" checked /></div></td>`
      }
      else{
        return `<td><div class=""><input type="checkbox" style="height: 20px; width: 20px;" class="input_benefit" name="product[benefit_ids][]" value="${benefit.id}" /></div></td>`
      }
    }
    else {
      return `<td><div class=""><input type="checkbox" style="height: 20px; width: 20px;" class="input_benefit" name="product[benefit_ids][]" value="${benefit.id}" /></div></td>`
    }
  }


  // remedy for 2nd page onwards
  $("#modal_benefit_tbl").on('change', ".input_benefit",function () {
    var value = $(this).val();

    if(this.checked) {
      valArray.push(value);
    } else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('input[name="product[benefit_ids_main]"]').val(valArray);
  });


});
