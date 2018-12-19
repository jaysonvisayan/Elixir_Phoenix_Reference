onmount('div[id="main_product_benefit"]', function () {

    $('.view_packages').click(function(){
      let b_id = $(this).attr('benefitid')
      const csrf = $('input[name="_csrf_token"]').val();
      $('#modal_package_table').DataTable({
        "ajax": {
          url:`/web/products/benefit/${b_id}/view_package`,
          "headers": { "X-CSRF-TOKEN": csrf },
          "type": "get"
        },
        "processing": true,
        "serverSide": true,
        "deferRender": true,
        "bDestroy": true,
        "bSortable": true,
      });
    $('.modal_packages').modal({autofocus: false, observeChanges: true}).modal('show');
  });

  $('.modal_benefit').modal({
    autofocus: false,
    selector: {
      deny: '.close.button'
    }
  }).modal('attach events', '.btn_add_benefit', 'show');
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
        url:`/web/products/${p_id}/product_benefit/${pb_id}/step`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'delete',
        success: function(response){
          let obj = JSON.parse(response)
          // this is to prevent the open modal to be openned
          window.location.replace("/web/products/" + p_id  + "/setup?step=2");
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

    $('#confirmation_submit_button_edit').click(function(){
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
          window.location.replace("/web/products/" + p_id  + "/edit?tab=benefit");
        }
      });
    });

    $('#step3_next').click(function(){
      let product_id = $(this).attr('productID');
      let pb_index_length = $('#pb_index tr').length;
      let nxtStep = $(this).attr('nxt_step')
      let csrf = $('input[name="_csrf_token"]').val();

      if(pb_index_length > 1) {
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
              window.location.replace('/web/products/' + product_id + '/setup?step=' + nxtStep)
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
    pageLength: 5,
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
    },
    drawCallback: _ => {
      $('.modal_benefit').modal({
        autofocus: false,
        selector: {
          deny: '.close.button'
        }
      }).modal('refresh');
    }
  });

  $(document).on('keyup', 'input[type="search"]', function(){
    let table = $('#modal_benefit_tbl').DataTable()
    const csrf2 = $('input[name="_csrf_token"]').val();
    var value = $(this).val().trim()

    delay(function(){
      request_ajax(table, csrf2, value)
    }, 2500 );

  })

  $('.dataTables_length').find('.ui.dropdown').on('change', function(){
    // dropdown shows
    if ($(this).find('.text').text() == 100){
      let info = table.page.info();
      if (info.pages - info.page == 1){
        let search_value = $('.dataTables_filter input').val();
        const csrf2 = $('input[name="_csrf_token"]').val();
        request_ajax2(table, csrf2, info, search_value.trim())
      }
    }
  })

  let info
  table.on('page', function () {
    info = table.page.info();
    if (info.pages - info.page == 1){
      let search_value = $('.dataTables_filter input').val();
      const csrf2 = $('input[name="_csrf_token"]').val();

      request_ajax2(table, csrf2, info, search_value.trim())
    }
  });

  var delay = (function(){
    var timer = 0;
    return function(callback, ms){
      clearTimeout (timer);
      timer = setTimeout(callback, ms);
    };
  })();

  const request_ajax = (table, csrf, value) => {
    $.ajax({
      url:`/products/${product_id}/benefit_load_datatable`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      data: {params: { "search_value" : value, "offset" : 0}},
      dataType: 'json',
      success: function(response){
        table.rows().remove()
        let dataSet = []

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
  }

  const request_ajax2 = (table, csrf, info, value) => {
    $.ajax({
      url:`/products/${product_id}/benefit_load_datatable`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      data: {params: { "search_value" : value, "offset" : info.recordsTotal}},
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
    }
    else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('input[name="product[benefit_ids_main]"]').val(valArray);
  });

  $('#submit_btn_modalbenefit').on("click", function(e){
    if (valArray.length == 0){
      alertify.error(`<i class="close icon"></i>Atleast One Benefit must be added.`)
      e.preventDefault()
    }
  })

  // $('#clear_checkbox').click(function () {
  //   $('.select_benefit').prop('checked',false);
  //   $('.input_benefit').prop('checked', false);
  // })
});

// onmount('#select_pemebenefit', function() {
//   $('input[type=checkbox]').change(function () {
//     if ($(this).is(':checked')) {
//       $('input[type=checkbox]').attr('disabled', true);
//       $(this).attr('disabled', '');
//     }
//     else {
//       $('input[type=checkbox]').attr('disabled', '');
//     }
//   });

//   $('#clear_checkbox').click(function () {
//     $('.input_benefit').attr('disabled', false);
//     $('.input_benefit').prop('checked', false);
//   })
// })
