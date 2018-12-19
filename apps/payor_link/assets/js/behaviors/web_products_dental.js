onmount('div[id="product_dental_plan"]', function () {
  let pc_array
  let bc_data

  const csrf = $('input[name="_csrf_token"]').val();

  $.ajax({
    url: `/web/get_all_product_code`,
    headers: {
      "X-CSRF-TOKEN": csrf
    },
    type: 'get',
    success: function(response) {
      bc_data = JSON.parse(response)

      let is_new = $('input[name="product_id"]').val() == undefined ? true : false
      if(is_new) {
        $('#product_form_dim').dimmer('hide')
      }
    }
  })

  if ($('#limit_applicability_value').val().includes("Principal")){
    $('#limit_principal').prop("checked", true)
  }

  if ($('#limit_applicability_value').val().includes("Dependent")){
    $('#limit_dependent').prop("checked", true)
  }

  $.fn.form.settings.rules.validateBenefitdt = function(param) {
    let table = $('#tbl_benefit_dt_table').DataTable()
    // if ($(`input[name="location_group[selecting_type]"]:checked`).val() == "Facilities") {
    if (table.rows().count() > 0){
      return true
    }
    else{
      return false
    }
  }

  const initializeDentalPlanValidations = _ => {
    $('#dental_form').form({
      on: 'blur',
      inline: true,
      fields: {
        'product[code]': {
          identifier: 'product[code]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a code.'
           }
         ]
       },
        'product[name]': {
          identifier: 'product[name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a name.'
          }]
        },
       // 'product[description]': {
       //  identifier: 'product[description]',
       //  rules: [
       //    {
       //      type: 'empty',
       //      prompt: 'Please enter a description.'
       //    }]
       //  },
        'product[benefit_ids][]': {
          identifier: 'product[benefit_ids][]',
          rules: [{
            type   : 'validateBenefitdt[param]',
            prompt : 'Please choose atleast one benefit.'
          }]
        },
      }
    })
  }

  $('#btnDraft_dental').click(function () {
    var table = $('#tbl_benefit_dt_table').DataTable()
    var rows = table.rows({'search': 'applied'}).nodes();
    let selected_ben_rows = []
    $('.selected_ben_rows', rows).each(function(){
      selected_ben_rows.push($(this).text())
    })
    $('input[name="product[benefit_limit_datas][]"]').val(Array.from(new Set(selected_ben_rows)))

    let selected_benefit_ids = []

    $('.selected_procedure_id', rows).each(function() {
      selected_benefit_ids.push($(this).text())
    })
    $('input[name="product[benefit_ids][]"]').val(Array.from(new Set(selected_benefit_ids)))

    $('#dental_form')
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
        }
      }
    })

    $('.field').removeClass('error');
    $('div[class="ui basic red pointing prompt label transition visible"]').remove();
    $('div[class="ui basic red pointing prompt label"]').remove();

    let result_coverage = $('#dental_form').form('validate field', 'product[name]')

    if(result_coverage) {
      $('.modal.confirmation')
      .modal({
        autofocus: false,
        closable: false,
        centered: false,
        observeChanges: true,
        selector: {
          deny: '.deny.button',
          approve: '.approve.button'
        },
        onShow: () => {
          $('#confirmation-header').text('Save as Draft')
          $('#confirmation-description').text(`Saving as draft allows the halt
            of creation of this product which can be continued later.`)
          $('#confirmation-question').text('Do you want to save this as draft?')
        },
        onApprove: () => {
          $('input[name="product[is_draft]"]').val(true)
          save_dental()
          $('#dental_form').submit()
          return false
        },
        onDeny: () => {
          $('input[name="plan[is_draft]"]').val('')
          // initializeDentalPlanValidations()
        }
      })
      .modal('show')
    }
  })

  $('#btnDraft_dental_update').click(function () {
    $('input[name="product[benefit_limit_datas][]"]').remove()
    $('#dental_form')
    .form({
      inline : true,
      fields: {
        'product[code]': {
          identifier: 'product[code]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a code.'
            }
          ]
        },
        'product[name]': {
          identifier: 'product[name]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a name.'
            }
          ]
        }
      }
    })

    $('.field').removeClass('error');
    $('div[class="ui basic red pointing prompt label transition visible"]').remove();
    $('div[class="ui basic red pointing prompt label"]').remove();

    let result_code = $('#dental_form').form('validate field', 'product[code]')
    let result_coverage = $('#dental_form').form('validate field', 'product[name]')

    if(result_code && result_coverage) {
      $('.modal.confirmation')
      .modal({
        autofocus: false,
        closable: false,
        centered: false,
        observeChanges: true,
        selector: {
          deny: '.deny.button',
          approve: '.approve.button'
        },
        onShow: () => {
          $('#confirmation-header').text('Save as Draft')
          $('#confirmation-description').text(`Saving as draft allows the halt
            of creation of this product which can be continued later.`)
          $('#confirmation-question').text('Do you want to save this as draft?')
        },
        onApprove: () => {
          $('input[name="product[is_draft]"]').val(true)
          update_dental()
          $('#dental_form').submit()
          return false
        },
        onDeny: () => {
          $('input[name="plan[is_draft]"]').val('')
          // initializeDentalPlanValidations()
        }
      })
      .modal('show')
    }
  })

  function removeDuplicateUsingFilter(arr){
    let unique_array = arr.filter(function(elem, index, self) {
        return index == self.indexOf(elem);
    });
    return unique_array
  }

  var valArray = []

  $("input:checkbox.selection").on('change', function () {
    var value = $(this).val()

    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    // $('input[name="product[benefit_ids_main]"]').val(valArray)
  })

  // FOR CHECK ALL
  $('#benefit_select_all').on('change', function(){
    if ($(this).is(':checked')) {
      $('input[class="procedure_chkbx"]').each(function(){
        var value = $(this).val()

        if(this.checked) {
          valArray.push(value)
        } else {
          var index = valArray.indexOf(value);

          if (index >= 0) {
            valArray.splice( index, 1)
          }
          valArray.push(value)
        }
        $(this).prop('checked', true)
      })
    } else {
      valArray.length = 0
      $('.input[class="procedure_chkbx"]').each(function(){
        $(this).prop('checked', false)
      })
    }
  })

  // $('#btn_add_benefit').click(function () {

  //   const csrf = $('input[name="_csrf_token"]').val();

  //   let selected_procedure_ids = []
  //   let selected_benefit_ids = []
  //   let selected_benefit_rows = []
  //   let selected_procedure_ids2 = []

  //   $('.selected_procedure_id').each(function() {
  //     selected_procedure_ids.push($(this).text())
  //   })

  //   let procedure_ids = selected_procedure_ids.join(",")

  //   $('.modal.procedure')
  //     .modal({
  //       autofocus: false,
  //     })
  //     .modal('show');

  //   function test(procedure_ids, selected_benefit_ids) {
  //     $('#tbl_add_procedure').DataTable({
  //       "dom":
  //       "<'ui grid'"+
  //         "<'row'"+
  //           "<'four wide column'f>"+
  //           "<'twelve wide column'i>"+
  //         ">"+
  //         "<'row dt-table'"+
  //           "<'sixteen wide column'tr>"+
  //         ">"+
  //         "<'row'"+
  //           "<'right aligned ten wide column'l>"+
  //           "<'right aligned four wide column'p>"+
  //         ">"+
  //       ">",
  //       "destroy": true,
  //       "lengthChange": false,
  //       "pageLength": 10,
  //       "pagingType": "simple_numbers",
  //       "displayStart": 0,
  //       "ajax": $.fn.dataTable.dt_timeout(
  //         `/web/products/load_benefit?procedure_ids=${procedure_ids}&selected_benefit_ids=${removeDuplicateUsingFilter(selected_benefit_ids)}`,
  //         csrf
  //       ),
  //       "deferRender": true,
  //       "drawCallback": function (settings) {
  //         // CUSTOMIZE JUMP TO PAGE
  //         $('#jump_to_page').html("")

  //         var table = $('#tbl_add_procedure').DataTable();
  //         var info = table.page.info();
  //         append_jump(info.page, info.pages)

  //         // CUSTOMIZE PAGINATION
  //         let pagination = $('#tbl_add_procedure_paginate').html()
  //         $('#tbl_add_procedure_paginate').html("")
  //         $('#tbl_add_procedure_paginate2').html("")
  //         $('#tbl_add_procedure_paginate2').append(pagination)

  //         // CUSTOMIZE PAGE INFO
  //         let page_info =$('#tbl_add_procedure_info').html()
  //         $('#tbl_add_procedure_info2').html("")
  //         $('#tbl_add_procedure_info2').append(page_info)

  //         // CUSTOMIZE SEARCH BAR

  //         $('input[type="search"]').css("width", "250px")

  //         $('.modal.procedure')
  //         .modal({
  //           autofocus: false,
  //         })
  //         .modal('refresh');

  //         $('.paginate_button').on('click', function(e){
  //           let offset = $(this).attr('data-dt-idx')
  //           let entries_count = $('select[name="tbl_add_procedure_length"]').find( 'option:selected' ).text();

  //           $('input[class="procedure_chkbx"]:checked').each(function() {
  //             selected_benefit_ids.push($(this).attr('pp_id'))
  //             if (!selected_procedure_ids2.includes($(this).attr('procedure_ids')))
  //             {
  //               selected_procedure_ids2.push($(this).attr('procedure_ids'))
  //               selected_benefit_rows.push([`<span class="${$(this).attr('b_code')}"> ${$(this).attr('b_code')} </span>`,
  //               `<span class="${$(this).attr('b_code')}${$(this).attr('b_name')}"> ${$(this).attr('b_name')} </span>`,
  //               `<span class="${$(this).attr('b_code')}${$(this).attr('bp_id')}"> ${$(this).attr('bp_id')} </span>`,
  //               `<span class="${$(this).attr('b_code')}${$(this).attr('bl_limit_type')}"> ${$(this).attr('bl_limit_type')} </span>`,
  //               `<span class="${$(this).attr('b_code')}${$(this).attr('bl_limit_amount')}"> ${$(this).attr('bl_limit_amount')} </span>`,
  //               `<div class="ui dropdown" tabindex="0">\
  //                   <i class="ellipsis vertical icon"></i>\
  //               <div class="menu transition hidden">\
  //               <div class="item clickable-row"> \
  //               <a href="#!" \
  //               benefit_id="${$(this).attr('pp_id')}"
  //               code="${$(this).attr('b_code')}" \
  //               name="${$(this).attr('b_name')}" \
  //               limit_type="${$(this).attr('bl_limit_type')}" \
  //               limit_amount="${$(this).attr('bl_limit_amount')}" \
  //               class="edit_limit">Edit limit</a>\
  //               <span class="selected_procedure_id hidden">${$(this).attr('pp_id')}</span> \
  //               <span class="${$(this).attr('b_code')}_ben_rows selected_ben_rows hidden">${$(this).attr('pp_id')},${$(this).attr('bl_limit_type')},${$(this).attr('bl_limit_amount')}</span> \

  //               <input type="hidden" name="product[benefit_ids][]" value="${$(this).attr('pp_id')}">\
  //               <input type="hidden" class="${$(this).attr('b_code')}_ben_rows selected_ben_rows hidden" name="product[benefit_limit_datas][]" value="${$(this).attr('pp_id')},${$(this).attr('bl_limit_type')},${$(this).attr('bl_limit_amount')}">\
  //               </div>\
  //                   <div class="item clickable-row">\
  //                 <a href="#!" class="remove_package"> Remove</a><span class="selected_procedure_id hidden">${$(this).attr('pp_id')}</span>\
  //               <input type="hidden" name="product[benefit_ids][]" value="${$(this).attr('pp_id')}"></div></div></div>`])
  //             }
  //           })

  //           if ($(this).attr('id') === "tbl_add_procedure_next")
  //           {
  //             let page_count = info.page + 1
  //             if (page_count === info.pages) {

  //               offset = (info.pages - 1) * entries_count
  //               test2(procedure_ids, selected_benefit_ids, offset, entries_count)
  //             }
  //             else
  //             {
  //               offset = (page_count) * entries_count
  //               test2(procedure_ids, selected_benefit_ids, offset, entries_count)
  //             }
  //           }
  //           else if ($(this).attr('id') === "tbl_add_procedure_previous")
  //           {
  //             if (info.page === 0)
  //             {
  //               test2(procedure_ids, selected_benefit_ids, 0, entries_count)
  //             }
  //             else
  //             {
  //               let page_info_count = (info.page - 1) * entries_count
  //               test2(procedure_ids, selected_benefit_ids, page_info_count, entries_count)
  //             }
  //           }
  //           else
  //           {
  //             offset = $(this).text();
  //             offset = (offset - 1) * entries_count
  //             console.log(offset)
  //             test2(procedure_ids, selected_benefit_ids, offset, entries_count)
  //           }
  //         })
  //       },
  //       "serverSide": true,
  //       "deferRender": true,
  //       "language": {
  //         "search": "",
  //         "searchPlaceholder": "Search",
  //         "decimal":        "",
  //         "emptyTable":     "No data available in table",
  //         "info":           "Showing _START_ out of _TOTAL_ results",
  //         "infoEmpty":      "Showing 0 to 0 of 0 entries",
  //         "infoFiltered":   "(filtered from _MAX_ total results)",
  //         "emptyTable": "No Records Found!",
  //         "zeroRecords": "No results found",
  //         "lengthMenu": "Show: _MENU_",
  //         "paginate": {
  //             "previous": "<i class='angle single left icon'></i>",
  //             "next": "<i class='angle single right icon'></i>",
  //         }
  //       }
  //     })
  //   }

  //   $(document).find('.ui.fluid.search.dropdown').keypress('input[class="search"]', function(evt) {
  //       evt = (evt) ? evt : window.event
  //       var charCode = (evt.which) ? evt.which : evt.keyCode
  //       if (charCode == 8 || charCode == 37) {
  //           return true
  //       } else if (charCode == 46) {
  //           return false
  //       } else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
  //           return false
  //       } else if (this.value.length == 0 && evt.which == 48) {
  //           return false
  //       }
  //       return true
  //   })

  //   function append_jump(page, pages){
  //     let results = $('select[name="tbl_add_procedure_length"]').val()
  //     $('.table > tbody  > tr').each(function(){
  //       $(this).attr('style', 'height:50px')
  //     })
  //     $('#tbl_add_procedure_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
  //     $("#jump_to_page").append(
  //       `<select class="ui fluid search dropdown" id="jump" name="tbl_add_procedure_jump_to_page">\
  //       </select>`
  //     )
  //     var select = $('#jump')
  //     var options = []
  //     for(var x = 1; x < parseInt(pages) + 1; x++){
  //       options.push(`<option value='${x}'>${x}</option>`)
  //     }
  //     select.append(String(options.join('')))
  //     $('.ui.fluid.search.dropdown').dropdown()
  //     $('#jump').dropdown('set selected', page + 1)
  //   }

  //   function test2(procedure_ids, selected_benefit_ids, offset, entries_count) {
  //     $('#tbl_add_procedure').DataTable({
  //       "dom":
  //       "<'ui grid'"+
  //         "<'row'"+
  //           "<'four wide column'f>"+
  //           "<'twelve wide column'i>"+
  //         ">"+
  //         "<'row dt-table'"+
  //           "<'sixteen wide column'tr>"+
  //         ">"+
  //         "<'row'"+
  //           "<'right aligned ten wide column'l>"+
  //           "<'right aligned four wide column'p>"+
  //         ">"+
  //       ">",
  //       "destroy": true,
  //       "lengthChange": false,
  //       "pageLength": entries_count,
  //       "displayStart": offset,
  //       "ajax": $.fn.dataTable.dt_timeout(
  //         `/web/products/load_benefit?procedure_ids=${procedure_ids}&selected_benefit_ids=${removeDuplicateUsingFilter(selected_benefit_ids)}`,
  //         csrf
  //       ),
  //       "deferRender": true,
  //       "drawCallback": function (settings) {
  //         // CUSTOMIZE JUMP TO PAGE
  //         $('#jump_to_page').html("")

  //         var table = $('#tbl_add_procedure').DataTable();
  //         var info = table.page.info();
  //         append_jump(info.page, info.pages)

  //         // CUSTOMIZE PAGINATION
  //         let pagination = $('#tbl_add_procedure_paginate').html()
  //         $('#tbl_add_procedure_paginate').html("")
  //         $('#tbl_add_procedure_paginate2').html("")
  //         $('#tbl_add_procedure_paginate2').append(pagination)

  //         // CUSTOMIZE PAGE INFO
  //         let page_info =$('#tbl_add_procedure_info').html()
  //         $('#tbl_add_procedure_info2').html("")
  //         $('#tbl_add_procedure_info2').append(page_info)

  //         // CUSTOMIZE SEARCH BAR
  //         $('input[type="search"]').css("width", "250px")

  //         $('.modal.procedure')
  //         .modal({
  //           autofocus: false,
  //         })
  //         .modal('refresh');

  //         var table = $('#tbl_add_procedure').DataTable();
  //         var info = table.page.info();

  //         $('.paginate_button').on('click', function(e){
  //           let offset = $(this).attr('data-dt-idx')
  //           let entries_count = $('select[name="tbl_add_procedure_length"]').find( 'option:selected' ).text();

  //           $('input[class="procedure_chkbx"]:checked').each(function() {
  //             selected_benefit_ids.push($(this).attr('pp_id'))
  //             if (!selected_procedure_ids2.includes($(this).attr('procedure_ids')))
  //             {
  //               selected_procedure_ids2.push($(this).attr('procedure_ids'))
  //               selected_benefit_rows.push([`<span class="${$(this).attr('b_code')}"> ${$(this).attr('b_code')} </span>`,
  //               `<span class="${$(this).attr('b_code')}${$(this).attr('b_name')}"> ${$(this).attr('b_name')} </span>`,
  //               `<span class="${$(this).attr('b_code')}${$(this).attr('bp_id')}"> ${$(this).attr('bp_id')} </span>`,
  //               `<span class="${$(this).attr('b_code')}${$(this).attr('bl_limit_type')}"> ${$(this).attr('bl_limit_type')} </span>`,
  //               `<span class="${$(this).attr('b_code')}${$(this).attr('bl_limit_amount')}"> ${$(this).attr('bl_limit_amount')} </span>`,
  //               `<div class="ui dropdown" tabindex="0">\
  //                   <i class="ellipsis vertical icon"></i>\
  //               <div class="menu transition hidden">\
  //               <div class="item clickable-row"> \
  //               <a href="#!" \
  //               benefit_id="${$(this).attr('pp_id')}"
  //               code="${$(this).attr('b_code')}" \
  //               name="${$(this).attr('b_name')}" \
  //               limit_type="${$(this).attr('bl_limit_type')}" \
  //               limit_amount="${$(this).attr('bl_limit_amount')}" \
  //               class="edit_limit">Edit limit</a>\
  //               <span class="selected_procedure_id hidden">${$(this).attr('pp_id')}</span> \
  //               <span class="${$(this).attr('b_code')}_ben_rows selected_ben_rows hidden">${$(this).attr('pp_id')},${$(this).attr('bl_limit_type')},${$(this).attr('bl_limit_amount')}</span> \

  //               <input type="hidden" name="product[benefit_ids][]" value="${$(this).attr('pp_id')}">\
  //               <input type="hidden" class="${$(this).attr('b_code')}_ben_rows selected_ben_rows hidden" name="product[benefit_limit_datas][]" value="${$(this).attr('pp_id')},${$(this).attr('bl_limit_type')},${$(this).attr('bl_limit_amount')}">\
  //               </div>\
  //                   <div class="item clickable-row">\
  //                 <a href="#!" class="remove_package"> Remove</a><span class="selected_procedure_id hidden">${$(this).attr('pp_id')}</span>\
  //               <input type="hidden" name="product[benefit_ids][]" value="${$(this).attr('pp_id')}"></div></div></div>`])
  //               }
  //           })

  //           if ($(this).attr('id') === "tbl_add_procedure_next")
  //           {
  //             let page_count = info.page + 1
  //             if (page_count === info.pages) {

  //               offset = (info.pages - 1) * entries_count
  //               test2(procedure_ids, selected_benefit_ids, offset, entries_count)
  //             }
  //             else
  //             {
  //               offset = (page_count) * entries_count
  //               test2(procedure_ids, selected_benefit_ids, offset, entries_count)
  //             }
  //           }
  //           else if ($(this).attr('id') === "tbl_add_procedure_previous")
  //           {
  //             if (info.page === 0)
  //             {
  //               test2(procedure_ids, selected_benefit_ids, 0)
  //             }
  //             else
  //             {
  //               let page_info_count = (info.page - 1) * entries_count
  //               test2(procedure_ids, selected_benefit_ids, page_info_count, entries_count)
  //             }
  //           }
  //           else
  //           {
  //             offset = $(this).text();
  //             offset = (offset - 1) * entries_count
  //             console.log(offset)
  //             test2(procedure_ids, selected_benefit_ids, offset, entries_count)
  //           }
  //         })
  //       },
  //       "serverSide": true,
  //       "deferRender": true,
  //       "language": {
  //         "search": "",
  //         "searchPlaceholder": "Search",
  //         "decimal":        "",
  //         "emptyTable":     "No data available in table",
  //         "info":           "Showing _START_ out of _TOTAL_ results",
  //         "infoEmpty":      "Showing 0 to 0 of 0 entries",
  //         "infoFiltered":   "(filtered from _MAX_ total results)",
  //         "emptyTable": "No Records Found!",
  //         "zeroRecords": "No results found",
  //         "lengthMenu": "Show: _MENU_",
  //         "paginate": {
  //             "previous": "<i class='angle single left icon'></i>",
  //             "next": "<i class='angle single right icon'></i>",
  //         }
  //       }
  //     })
  //   }

  //   test(procedure_ids, selected_benefit_ids)

  //   let valArray2 = []
  //   $('select[name="tbl_add_procedure_length"]').on('change', function(){
  //     let entries_count = $(this).find( 'option:selected' ).text();
  //     test2(procedure_ids, selected_benefit_ids, 0, entries_count)
  //   })

  //   $('select[name="tbl_add_procedure_jump_to_page"]').on('change', function(){
  //     alert(123)
  //     let entries_count = $('select[name="tbl_add_procedure_length"]').find( 'option:selected' ).text();
  //     let offset = $(this).find( 'option:selected' ).text();
  //     offset = (offset - 1) * entries_count
  //     test2(procedure_ids, selected_benefit_ids, offset, entries_count)
  //   })

  //   $('#btn_submit_benefit')
  //     .unbind('click')
  //     .click(function() {
  //     valArray2 = []
  //     const csrf = $('input[name="_csrf_token"]').val();
  //     let checked_procedure = $('input[class="procedure_chkbx"]:checked')

  //     if(checked_procedure.length > 0){
  //       let dt = $('#tbl_benefit_dt_table').DataTable();
  //       let has_procedure = [];
  //       // dt.clear().draw()

  //       $('input[class="procedure_chkbx"]:checked').each(function() {
  //         valArray2.push($(this).attr('procedure_ids'))
  //         valArray2.join(',')
  //       })

  //       $.ajax({
  //         url:`/web/products/compare_procedure_ids`,
  //         headers: {"X-CSRF-TOKEN": csrf},
  //         type: 'get',
  //         data: {"procedure_ids" : valArray2},
  //         dataType: 'json',
  //         success: function(response) {
  //           if(response === "true")
  //           {
  //             swal({
  //               type: 'warning',
  //               title: 'Oops!',
  //               text: 'It seems like you have selected benefits which includes the same CDT/s. Please select benefit for each.'
  //             })
  //           }
  //           else
  //           {
  //             $(selected_benefit_rows).each(function(x, y) {
  //               dt.row.add(y).draw(false)
  //             })
  //             $('input[class="procedure_chkbx"]:checked').each(function() {
  //               dt.row.add([
  //                 `<span class="${$(this).attr('b_code')}"> ${$(this).attr('b_code')} </span>`,
  //                 `<span class="${$(this).attr('b_code')}${$(this).attr('b_name')}"> ${$(this).attr('b_name')} </span>`,
  //                 `<span class="${$(this).attr('b_code')}${$(this).attr('bp_id')}"> ${$(this).attr('bp_id')} </span>`,
  //                 `<span class="${$(this).attr('b_code')}${$(this).attr('bl_limit_type')}"> ${$(this).attr('bl_limit_type')} </span>`,
  //                 `<span class="${$(this).attr('b_code')}${$(this).attr('bl_limit_amount')}"> ${$(this).attr('bl_limit_amount')} </span>`,
  //                 `<div class="ui dropdown" tabindex="0">\
  //                     <i class="ellipsis vertical icon"></i>\
  //                 <div class="menu transition hidden">\
  //                 <div class="item clickable-row"> \
  //                 <a href="#!" \
  //                 benefit_id="${$(this).attr('pp_id')}"
  //                 code="${$(this).attr('b_code')}" \
  //                 name="${$(this).attr('b_name')}" \
  //                 limit_type="${$(this).attr('bl_limit_type')}" \
  //                 limit_amount="${$(this).attr('bl_limit_amount')}" \
  //                 class="edit_limit">Edit limit</a>\
  //                 <span class="selected_procedure_id hidden">${$(this).attr('pp_id')}</span> \
  //                 <span class="${$(this).attr('b_code')}_ben_rows selected_ben_rows hidden">${$(this).attr('pp_id')},${$(this).attr('bl_limit_type')},${$(this).attr('bl_limit_amount')}</span> \

  //                 <input type="hidden" name="product[benefit_ids][]" value="${$(this).attr('pp_id')}">\
  //                 <input type="hidden" class="${$(this).attr('b_code')}_ben_rows selected_ben_rows hidden" name="product[benefit_limit_datas][]" value="${$(this).attr('pp_id')},${$(this).attr('bl_limit_type')},${$(this).attr('bl_limit_amount')}">\
  //                 </div>\
  //                     <div class="item clickable-row">\
  //                   <a href="#!" class="remove_package"> Remove</a><span class="selected_procedure_id hidden">${$(this).attr('pp_id')}</span>\
  //                 <input type="hidden" name="product[benefit_ids][]" value="${$(this).attr('pp_id')}"></div></div></div>`
  //               ]).draw(false)
  //             })

  //             $('.modal.procedure').modal('hide');
  //             $('input[name="is_valid_procedure"]').val("true")

  //             $('.ui.dropdown').dropdown();

  //             $('.edit_limit').click(function() {
  //               alert(1)
  //               let benefit_id = $(this).attr("benefit_id")
  //               let b_code = $(this).attr("code")
  //               let b_name = $(this).attr("name")
  //               let limit_type = $(this).attr("limit_type")
  //               let limit_amount = $(this).attr("limit_amount")

  //               let ben_code = $(`span[class="${b_code}"]`).text()
  //               let ben_name = $(`span[class="${b_code}${b_name}"]`).text()
  //               let ben_limit_type = $(`span[class="${b_code}${limit_type}"]`).text().trim()
  //               let ben_limit_amount = $(`span[class="${b_code}${limit_amount}"]`).text().trim()

  //               $("select[id='limit_type'] option:selected").val(ben_limit_type).change();
  //               $('input[name="limit_amount"]').val(ben_limit_amount);

  //               $('.modal.limit').modal({
  //                 autofocus: false,
  //                 closable: false,
  //                 observeChanges: true,
  //                 selector: {
  //                   deny: '.deny.button',
  //                   approve: '.approve.button'
  //                 },
  //                 onApprove: () => {
  //                   $(`span[class="${b_code}${limit_amount}"]`).text("")
  //                   $(`span[class="${b_code}${limit_type}"]`).text("")
  //                   $(`input[class="${b_code}_ben_rows selected_ben_rows hidden"]`).val("")

  //                   let updated_limit_amount = $('input[name="limit_amount"]').val();
  //                   let updated_limit_type = $("select[id='limit_type'] option:selected").val();

  //                   $(`span[class="${b_code}${limit_amount}"]`).text(updated_limit_amount)
  //                   $(`span[class="${b_code}${limit_type}"]`).text(updated_limit_type)
  //                   $(`input[class="${b_code}_ben_rows selected_ben_rows hidden"]`).val(`${benefit_id},${updated_limit_type},${updated_limit_amount}`)
  //                 }
  //               })
  //               .modal('show')
  //             })

  //             $('.remove_package').click(function() {
  //               swal({
  //                 title: 'Delete Benefit?',
  //                 type: 'question',
  //                 showCancelButton: true,
  //                 cancelButtonText: '<i class="remove icon"></i> No, keep benefit',
  //                 confirmButtonText: '<i class="check icon"></i> Yes, delete benefit',
  //                 cancelButtonClass: 'ui negative button',
  //                 confirmButtonClass: 'ui positive button',
  //                 reverseButtons: true,
  //                 buttonsStyling: false
  //               }).then(function () {
  //                 swal.closeModal()
  //                 var count = $('#tbl_benefit_dt_table>tbody>tr').length;
  //                 if (count === 0)
  //                 {
  //                   alertify.error('<i class="close icon"></i>Cannot delete all benefit.')
  //                 }
  //                 else
  //                 {
  //                   let row = $('input[class="procedure_chkbx"]').closest('tr')
  //                   dt.row(row)
  //                   .remove()
  //                   .draw()
  //                 }
  //               })
  //             })

  //             $('#tbl_add_procedure').DataTable().clear();
  //             $('#tbl_add_procedure').DataTable().destroy();
  //             test(procedure_ids, selected_benefit_ids)

  //             valArray2 = [];
  //             selected_procedure_ids = [];
  //             selected_benefit_ids = [];
  //             selected_benefit_rows = [];
  //             selected_procedure_ids2 = [];
  //           }
  //         }})
  //     } else {
  //       alertify.error('<i class="close icon"></i>Please select at least one Benefit.')
  //     }
  //   })
  // })

  // $('#btn_cancel_benefit').click(function() {
  //   $('.modal.procedure').modal('hide');
  // })

  // $('#btn_add_benefit_draft').click(function () {

  //   const csrf = $('input[name="_csrf_token"]').val();

  //   let selected_procedure_ids = []

  //   $('.selected_procedure_id').each(function() {
  //     selected_procedure_ids.push($(this).text())
  //   })

  //   let procedure_ids = selected_procedure_ids.join(",")

  //   $('.modal.proceduredraft')
  //     .modal({
  //       autofocus: false,
  //     })
  //     .modal('show');

  //   $('#tbl_add_procedure_draft').DataTable({
  //     "destroy": true,
  //     "pageLength": 5,
  //     "bLengthChange": false,
  //     "bFilter": true,
  //     "ajax": {
  //       "url":`/web/products/load_benefit?procedure_ids=${procedure_ids}`,
  //       "headers": {
  //         "X-CSRF-TOKEN": csrf
  //       },
  //       "type": "get"
  //     },
  //     "deferRender": true,
  //     "drawCallback": function (settings) {
  //       $('.modal.proceduredraft')
  //         .modal({
  //           autofocus: false,
  //         })
  //         .modal('refresh');
  //     },
  //     "serverSide": true,
  //     "deferRender": true,
  //     "language": {
  //       "emptyTable": "No Records Found!",
  //       "zeroRecords": "No results found"
  //     }
  //   })
  // })

  //   let valArray2 = []

  // $('#create_dental3').click(function() {
  //   $('input[name="product[add_benefit]"]').val(true)
  //   let valArray2 = []
  //   const csrf = $('input[name="_csrf_token"]').val();
  //   let checked_procedure = $('input[class="procedure_chkbx"]:checked')
  //   let procedure_ids = checked_procedure.attr('procedure_ids')
  //   let product_id = $('input[name="product[product_id]"]').val()

  //   if(checked_procedure.length > 0){
  //     let dt = $('#tbl_benefit_dt_table_draft').DataTable();
  //     let has_procedure = [];
  //     // dt.clear().draw()
  //     $('input[class="procedure_chkbx"]:checked').each(function() {
  //       valArray2.push(procedure_ids)
  //       valArray2.join(',')
  //     })

  //     $.ajax({
  //       url:`/web/products/compare_procedure_ids`,
  //       headers: {"X-CSRF-TOKEN": csrf},
  //       type: 'get',
  //       data: {"procedure_ids" : valArray2},
  //       dataType: 'json',
  //       success: function(response) {
  //         if(response === "true")
  //         {
  //           swal({
  //             type: 'warning',
  //             title: 'Oops!',
  //             text: 'It seems like you have selected benefits which includes the same CDT/s. Please select benefit for each.'
  //           })
  //         }
  //         else
  //         {
  //           $('input[class="procedure_chkbx"]:checked').each(function() {
  //             dt.row.add([
  //                 `<span class="${$(this).attr('b_code')}"> ${$(this).attr('b_code')} </span>`,
  //                 `<span class="${$(this).attr('b_code')}${$(this).attr('b_name')}"> ${$(this).attr('b_name')} </span>`,
  //                 `<span class="${$(this).attr('b_code')}${$(this).attr('bp_id')}"> ${$(this).attr('bp_id')} </span>`,
  //                 `<span class="${$(this).attr('b_code')}${$(this).attr('bl_limit_type')}"> ${$(this).attr('bl_limit_type')} </span>`,
  //                 `<span class="${$(this).attr('b_code')}${$(this).attr('bl_limit_amount')}"> ${$(this).attr('bl_limit_amount')} </span>`,
  //                 `<div class="ui dropdown" tabindex="0">\
  //                     <i class="ellipsis vertical icon"></i>\
  //                 <div class="menu transition hidden">\
  //                 <div class="item clickable-row"> \
  //                 <a href="#!" \
  //                 benefit_id="${$(this).attr('pp_id')}"
  //                 code="${$(this).attr('b_code')}" \
  //                 name="${$(this).attr('b_name')}" \
  //                 limit_type="${$(this).attr('bl_limit_type')}" \
  //                 limit_amount="${$(this).attr('bl_limit_amount')}" \
  //                 class="edit_limit">Edit limit</a>\
  //                 <span class="selected_procedure_id hidden">${$(this).attr('pp_id')}</span> \
  //                 <span class="${$(this).attr('b_code')}_ben_rows selected_ben_rows hidden">${$(this).attr('pp_id')},${$(this).attr('bl_limit_type')},${$(this).attr('bl_limit_amount')}</span> \

  //                 <input type="hidden" name="product[benefit_ids][]" value="${$(this).attr('pp_id')}">\
  //                 <input type="hidden" class="${$(this).attr('b_code')}_ben_rows selected_ben_rows hidden" name="product[benefit_limit_datas][]" value="${$(this).attr('pp_id')},${$(this).attr('bl_limit_type')},${$(this).attr('bl_limit_amount')}">\
  //                 </div>\
  //                     <div class="item clickable-row">\
  //                   <a href="#!" class="remove_package"> Remove</a><span class="selected_procedure_id hidden">${$(this).attr('pp_id')}</span>\
  //                 <input type="hidden" name="product[benefit_ids][]" value="${$(this).attr('pp_id')}"></div></div></div>`
  //             ]).draw(false)
  //           })
  //           $('.modal.proceduredraft').modal('hide');

  //           $('input[name="is_valid_procedure"]').val("true")

  //           $('.ui.dropdown').dropdown();

  //           $('.edit_limit').click(function() {
  //             alert(2)
  //             let benefit_id = $(this).attr("benefit_id")
  //             let b_code = $(this).attr("code")
  //             let b_name = $(this).attr("name")
  //             let limit_type = $(this).attr("limit_type")
  //             let limit_amount = $(this).attr("limit_amount")

  //             let ben_code = $(`span[class="${b_code}"]`).text()
  //             let ben_name = $(`span[class="${b_code}${b_name}"]`).text()
  //             let ben_limit_type = $(`span[class="${b_code}${limit_type}"]`).text().trim()
  //             let ben_limit_amount = $(`span[class="${b_code}${limit_amount}"]`).text().trim()

  //             $("select[id='limit_type'] option:selected").val(ben_limit_type).change();
  //             $('input[name="limit_amount"]').val(ben_limit_amount);

  //             $('.modal.limit').modal({
  //               autofocus: false,
  //               closable: false,
  //               observeChanges: true,
  //               selector: {
  //                 deny: '.deny.button',
  //                 approve: '.approve.button'
  //               },
  //               onApprove: () => {
  //                 $(`span[class="${b_code}${limit_amount}"]`).text("")
  //                 $(`span[class="${b_code}${limit_type}"]`).text("")
  //                 $(`input[class="${b_code}_ben_rows selected_ben_rows hidden"]`).val("")

  //                 let updated_limit_amount = $('input[name="limit_amount"]').val();
  //                 let updated_limit_type = $("select[id='limit_type'] option:selected").val();

  //                 $(`span[class="${b_code}${limit_amount}"]`).text(updated_limit_amount)
  //                 $(`span[class="${b_code}${limit_type}"]`).text(updated_limit_type)
  //                 $(`input[class="${b_code}_ben_rows selected_ben_rows hidden"]`).val(`${benefit_id},${updated_limit_type},${updated_limit_amount}`)
  //               }
  //             })
  //             .modal('show')
  //           })

  //           $('.remove_package').click(function() {
  //             swal({
  //               title: 'Delete Benefit?',
  //               type: 'question',
  //               showCancelButton: true,
  //               cancelButtonText: '<i class="remove icon"></i> No, keep benefit',
  //               confirmButtonText: '<i class="check icon"></i> Yes, delete benefit',
  //               cancelButtonClass: 'ui negative button',
  //               confirmButtonClass: 'ui positive button',
  //               reverseButtons: true,
  //               buttonsStyling: false
  //             }).then(function () {
  //               swal.closeModal()

  //               var count = $('#tbl_benefit_dt_table_draft>tbody>tr').length;

  //               // console.log(count)
  //               if (count === 1)
  //               {
  //                 alertify.error('<i class="close icon"></i>Cannot delete all benefit')
  //               }
  //               else
  //               {
  //                 let row = $('input[class="procedure_chkbx"]').closest('tr')
  //                 // console.log(row)
  //                 dt.row(row)
  //                 .remove()
  //                 .draw()
  //               }
  //             })
  //           })

  //           $('.edit_limit').click(function() {
  //             alert(3)
  //             let benefit_id = $(this).attr("benefit_id")
  //             let b_code = $(this).attr("code")
  //             let b_name = $(this).attr("name")
  //             let limit_type = $(this).attr("limit_type")
  //             let limit_amount = $(this).attr("limit_amount")

  //             let ben_code = $(`span[class="${b_code}"]`).text()
  //             let ben_name = $(`span[class="${b_code}${b_name}"]`).text()
  //             let ben_limit_type = $(`span[class="${b_code}${limit_type}"]`).text().trim()
  //             let ben_limit_amount = $(`span[class="${b_code}${limit_amount}"]`).text().trim()

  //             $("select[id='limit_type'] option:selected").val(ben_limit_type).change();
  //             $('input[name="limit_amount"]').val(ben_limit_amount);

  //             $('.modal.limit').modal({
  //               autofocus: false,
  //               closable: false,
  //               observeChanges: true,
  //               selector: {
  //                 deny: '.deny.button',
  //                 approve: '.approve.button'
  //               },
  //               onApprove: () => {
  //                 $(`span[class="${b_code}${limit_amount}"]`).text("")
  //                 $(`span[class="${b_code}${limit_type}"]`).text("")
  //                 $(`input[class="${b_code}_ben_rows selected_ben_rows hidden"]`).val("")

  //                 let updated_limit_amount = $('input[name="limit_amount"]').val();
  //                 let updated_limit_type = $("select[id='limit_type'] option:selected").val();

  //                 $(`span[class="${b_code}${limit_amount}"]`).text(updated_limit_amount)
  //                 $(`span[class="${b_code}${limit_type}"]`).text(updated_limit_type)
  //                 $(`input[class="${b_code}_ben_rows selected_ben_rows hidden"]`).val(`${benefit_id},${updated_limit_type},${updated_limit_amount}`)
  //               }
  //             })
  //             .modal('show')
  //           })
  //           valArray2 = []
  //         }
  //       }})

  //   } else {
  //     alertify.error('<i class="close icon"></i>Please select at least one Benefit.')
  //   }
  // })

  $('#tbl_benefit_dt_table_draft').DataTable();

  $('#btn_cancel_benefit1').click(function() {
    $('.modal.proceduredraft').modal('hide');
  })

  $('.toggle_btn_modal').click(function(){
    $('.selection-button').removeClass('active_modal')
    $('.toggle_ico').removeClass('white')
    $('.toggle_ico').addClass('dark')

    $(this).find('.selection-button').addClass('active_modal')
    $(this).find('.toggle_ico').addClass('white')
    $(this).find('.toggle_ico').removeClass('dark')

    let option = $(this).find('.option').attr('value')
    $('#product_limit_applicability').val(option)
  })

  $('button[type="submit"]').click(function(){
    let benefit_ids = $('#tbl_benefit_dt_table_wrapper').find('input[name="product[benefit_ids][]"]').val()
    $('.benefit_id').val(benefit_ids)
  })

  // $('#create_dental3').click(function(){
  //   $('input[name="product[add_benefit]"]').val(true)
  //   $('#dental_form').submit()
  // })

  $('#btnCancel').click(function () {

    $('.modal.cancel').modal({
      autofocus: false,
      closable: false,
      observeChanges: true,
      selector: {
        deny: '.deny.button',
        approve: '.approve.button'
      },
      onShow: () => {
        $('#discard-header').text('Cancel Plan')
        // $('#discard-description').text(`Cancel`)
        $('#discard-question').text('Are you sure you want to cancel this plan?')
      },
      onApprove: () => {
        window.location.replace('/web/products')
      }
    })
    .modal('show')
  })

  // $('#tbl_benefit_dt_table_draft').DataTable();

  $('.ui.dropdown').dropdown();

  $('.remove_package').on('click', function(e){
    e.preventDefault()
    let pb_id = $(this).attr('product_benefit_id')
    let product_id = $(this).attr('product_id')

    swal({
      title: 'Delete Benefit?',
      type: 'question',
      showCancelButton: true,
      cancelButtonText: '<i class="remove icon"></i> No, keep benefit',
      confirmButtonText: '<i class="check icon"></i> Yes, delete benefit',
      cancelButtonClass: 'ui negative button',
      confirmButtonClass: 'ui positive button',
      reverseButtons: true,
      buttonsStyling: false
    }).then(function () {
      var count = $('#tbl_benefit_dt_table_draft>tbody>tr').length;

      if (count === 1) {
        alertify.error('<i class="close icon"></i>Cannot delete all benefit')
      } else {
        window.location.replace(`/web/products/delete/${pb_id}/${product_id}/product_benefit`);
      }
    })
  })

  $('#btn_add_edit_benefit').click(function () {
    const csrf = $('input[name="_csrf_token"]').val();
    let selected_procedure_ids = []

    $('.selected_procedure_id').each(function() {
      selected_procedure_ids.push($(this).text())
    })

    let procedure_ids = selected_procedure_ids.join(",")

    $('.modal.procedureedit')
    .modal({
      autofocus: false,
    })
    .modal('show');

    $('#tbl_add_procedure_edit').DataTable({
      "destroy": true,
      "pageLength": 5,
      "bLengthChange": false,
      "bFilter": true,
      "ajax": {
        "url":`/web/products/load_benefit?procedure_ids=${procedure_ids}`,
        "headers": {
          "X-CSRF-TOKEN": csrf
        },
        "type": "get"
      },
      "deferRender": true,
      "drawCallback": function (settings) {
        $('.modal.procedureedit')
          .modal({
            autofocus: false,
          })
          .modal('refresh');
      },
      "serverSide": true,
      "deferRender": true,
      "language": {
        "emptyTable": "No Records Found!",
        "zeroRecords": "No results found"
      }
    })
  })

  let valArray3 = []

  $('#btn_submit_edit_benefit').click(function() {
    $('input[name="product[add_benefit]"]').val(true)
    valArray3 = []
    const csrf = $('input[name="_csrf_token"]').val();
    let checked_procedure = $('input[class="procedure_chkbx"]:checked')
    let procedure_ids = checked_procedure.attr('procedure_ids')
    let product_id = $('input[name="product[product_id]"]').val()

    if(checked_procedure.length > 0) {
      let dt = $('#tbl_benefit_dt_table_edit').DataTable();
      let has_procedure = [];
      // dt.clear().draw()
      $('input[class="procedure_chkbx"]:checked').each(function() {
        valArray3.push(procedure_ids)
        valArray3.join(',')
      })

      $.ajax({
        url:`/web/products/compare_procedure_ids`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        data: {"procedure_ids" : valArray3},
        dataType: 'json',
        success: function(response) {
          if(response === "true") {
            swal({
              type: 'warning',
              title: 'Oops!',
              text: 'It seems like you have selected benefits which includes the same CDT/s. Please select benefit for each.'
            })
          } else {
            $('input[class="procedure_chkbx"]:checked').each(function() {
              dt.row.add([
                `${$(this).attr('b_code')}`,
                `${$(this).attr('b_name')}`,
                `${$(this).attr('bp_id')}`,
                `${$(this).attr('bl_limit_type')}`,
                `${$(this).attr('bl_limit_amount')}`,
               `<div class="ui dropdown" tabindex="0">\
                   <i class="ellipsis vertical icon"></i>\
                <div class="menu transition hidden">\
                    <div class="item clickable-row">\
                  <a href="#!" class="remove_package"> Remove </a><span class="selected_procedure_id hidden">${$(this).attr('pp_id')}</span>\
                <input type="hidden" name="product[benefit_ids][]" value="${$(this).attr('pp_id')}"></div></div></div>`
              ]).draw(false)
            })

            $('.modal.procedureedit').modal('hide');

            $('input[name="is_valid_procedure"]').val("true")

            $('.ui.dropdown').dropdown();

            $('.remove_package').click(function() {
              swal({
                title: 'Delete Benefit?',
                type: 'question',
                showCancelButton: true,
                cancelButtonText: '<i class="remove icon"></i> No, keep benefit',
                confirmButtonText: '<i class="check icon"></i> Yes, delete benefit',
                cancelButtonClass: 'ui negative button',
                confirmButtonClass: 'ui positive button',
                reverseButtons: true,
                buttonsStyling: false
              }).then(function () {
                swal.closeModal()

                var count = $('#tbl_benefit_dt_table_edit>tbody>tr').length;
                if (count === 1) {
                  alertify.error('<i class="close icon"></i>Cannot delete all benefit')
                } else {
                  let row = $('input[class="procedure_chkbx"]').closest('tr')
                  dt.row(row)
                  .remove()
                  .draw()
                }
              })
            })
            valArray3 = []
          }
        }
      })
    } else {
      alertify.error('<i class="close icon"></i>Please select at least one Benefit.')
    }
  })

  $('#btn_cancel_edit_benefit').click(function() {
    $('.modal.procedureedit').modal('hide');
  })
});

onmount('div[id="product_header_btn"]', function () {
  $('#btnCancelDraft').click(function () {

    $('.modal.cancel').modal({
      autofocus: false,
      closable: false,
      observeChanges: true,
      selector: {
        deny: '.deny.button',
        approve: '.approve.button'
      },
      onShow: () => {
        $('#discard-header').text('Cancel Plan')
        // $('#discard-description').text(`Cancel`)
        $('#discard-question').text('Are you sure you want to cancel this plan?')
      },
      onApprove: () => {
        window.location.replace('/web/products')
      }
    })
    .modal('show')
  })

  $('#btn_Dental_Draft').click(function () {
    $('input[name="product[benefit_limit_datas][]"]').remove()
    let selected_ben_rows = []
    $('.selected_ben_rows').each(function(){
      $('#dental_edit_form').append(
        $('<input>')
        .attr('type', 'hidden')
        .attr('name', 'product[benefit_limit_datas][]')
        .val($(this).text())
      );
    })

    $('#dental_edit_form')
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
        }
      }
    })

    $('.field').removeClass('error');
    $('div[class="ui basic red pointing prompt label transition visible"]').remove();
    $('div[class="ui basic red pointing prompt label"]').remove();

    let result_coverage = $('#dental_edit_form').form('validate field', 'product[name]')

    if(result_coverage) {
    $ ('.modal.confirmation')
      .modal({
        autofocus: false,
        closable: false,
        centered: false,
        observeChanges: true,
        selector: {
          deny: '.deny.button',
          approve: '.approve.button'
        },
        onShow: () => {
          $('#confirmation-header').text('Save as Draft')
          $('#confirmation-description').text(`Saving as draft allows the halt
            of creation of this product which can be continued later.`)
          $('#confirmation-question').text('Do you want to save this as draft?')
        },
        onApprove: () => {
          $('input[name="product[is_draft]"]').val(true)
          update_dental()
          $('#dental_edit_form').submit()
          return false
        },
        onDeny: () => {
          $('input[name="plan[is_draft]"]').val('')
          // initializeDentalPlanValidations()
        }
      })
      .modal('show')
    }
  })
});

onmount('div[id="dental_condition_button"]', function () {
  $('#backDental').on('click', function () {
    $('input[name="product[backButton]"]').val('true')
    let input = document.getElementById('product_capitation_fee')
    let unmasked = input.inputmask.unmaskedvalue()
    input.inputmask.remove()
    $('#product_capitation_fee').val(unmasked)
    $('#dental_condition_form').form()
    $('#dental_condition_form').submit()
  })
});

//onmount('div[id="main_step1_general_dental"]', function () {
//  $('input[name="product[code]"]').on('keypress', function (evt) {
//    let theEvent = evt || window.event;
//    let key = theEvent.keyCode || theEvent.which;
//    key = String.fromCharCode(key);

//    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
//      return false;
//    } else {
//      $(this).on('focusout', function (evt) {
//        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
//      })
//    }
//  })

//  $.fn.form.settings.rules.checkProductLimit = function (param) {
//    let highest = $('#product_benefit_highest').val()
//    //c
//    // let submitted = param.split(',.').join('')
//    // console.log("submitted: " + submitted)
//    // console.log("highestpb: " + highest)
//    let submitted = param.split(',').join('')
//    if (highest == "") {
//      if (parseFloat(submitted) >= parseFloat(0)) {
//        return true
//      } else {
//        return false
//      }
//    } else {

//      if (parseFloat(submitted) >= parseFloat(highest)) {
//        return true
//      } else {
//        return false
//      }

//    }
//  }
//})

//onmount('div[id="name_validation"]', function () {
//  $('input[name="product[name]"]').on('keypress', function (evt) {
//    let theEvent = evt || window.event;
//    let key = theEvent.keyCode || theEvent.which;
//    key = String.fromCharCode(key);

//    if ($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)) {
//      return false;
//    } else {
//      $(this).on('focusout', function (evt) {
//        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
//      })
//    }
//  })
// })

onmount('div[id="main_step1_general_dental"]', function () {
  $('input[name="product[limit_amount]"]').keydown(function (evt) {
    var value = $('input[name="product[limit_amount]"]').val()

    if(evt.key == '.' || value.includes('.')) {
      if (value.length == 13 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    } else {
      if(value.length > 9 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    }
  })

  let im = new Inputmask("numeric", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false
  })
  im.mask($('#product_limit_amt'));

  if ($('#limit_applicability_value').val().includes("Principal")){
    $('#limit_principal').prop("checked", true)
  }

  if ($('#limit_applicability_value').val().includes("Dependent")){
    $('#limit_dependent').prop("checked", true)
  }
});

onmount('div[id="main_new_general_dental"]', function () {
  $('input[name="product[limit_amount]"]').keydown(function (evt) {
    var value = $('input[name="product[limit_amount]"]').val()

    var selection = window.getSelection();
    if(evt.key == '.' || value.includes('.')) {
      if (value.length == 13 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    } else {
      if(value.length > 9 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    }
  })

  let im = new Inputmask("numeric", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false
  })
  im.mask($('#product_limit_amt'));
});

onmount('div[id="dntl_modal_limit"]', function () {
  let sl = new Inputmask("numeric", {
    rightAlign: false,
    mask: "[999]"
  })
  let tl = new Inputmask("numeric", {
    rightAlign: false,
    mask: "[99]"
  })
  let pl = new Inputmask("numeric", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false
  })
  let ql = new Inputmask("numeric", {
    rightAlign: false,
    mask: "9",
    max: 4
  })
  pl.mask($('#limit_amount'));

  let quadrant = false;

  $('#limit_type').change(function() {
    let ltype = document.getElementById('limit_type');
    let itsType = $('#h_limit_type').val();
    let itsAmount = $('#h_limit_amount').val();
    let x = ltype.value;
    quadrant = false
    if (x == "Peso") {
      pl.mask($('#limit_amount'));
    } else if (x == "Sessions") {
      sl.mask($('#limit_amount'));
    } else if (x == "Tooth") {
      tl.mask($('#limit_amount'));
    } else {
      ql.mask($('#limit_amount'));
      quadrant = true
    }

    if(x != itsType) {
      $('#limit_amount').val('')
    } else {
      $('#limit_amount').val(itsAmount)
    }
  })

  $('input[id="limit_amount"]').keydown(function (evt) {
    var value = $('input[id="limit_amount"]').val()

    if (quadrant){
      if(!(evt.key <= 4 && evt.key >= 1)){
        evt.preventDefault();
      }
    }

    if (evt.key == '.' || value.includes('.')) {
      if (value.length == 13 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    } else {
      if (value.length > 9 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    }
  })
});

onmount('div[id="dental_summary_form"]', function(){
  let im = new Inputmask("numeric", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false
    // oncleared: function () {
    // self.Value('');
    // }
  })
  // document.getElementById('product_limit_amt').setAttribute("maxLength","10")
  im.mask($('span[role="mask-decimal"]'));
  // im.mask($('#capitation_fee'));

  let drsType = $('.dental-risk-share').attr('drsType')
  let drsfType = $('.dental-risk-share-facility-tr').attr('drsfType')
  let drsfVal = $('.dental-risk-share-facility').attr('pcdrVal')

  if(drsType == "N/A" || drsType == "" && drsfType == undefined) {
    $('.dental-risk-share-facility-div').addClass('hidden')
  }

  if(drsType == "" || drsType == "N/A") {
    $('.dental-risk-share').addClass('hidden')
  } else {
    $('.dental-risk-share').removeClass('hidden')
  }

  if(drsfType == ""|| drsfType == "N/A" || drsfType == undefined){
    $('.dental-risk-share-facility').addClass('hidden')
  } else {
    $('.dental-risk-share-facility').removeClass('hidden')
  }

  let covFac = $('.facility-coverage-table').attr('coverageFacilities')
  console.log(covFac)

  if(covFac == "") {
    setTimeout(function(){
      $('.facility-coverage').find('#DataTables_Table_1_wrapper').hide()
      $('.facility-coverage-table-div').hide()
    }, 100);
  }
});

function save_dental(){
  let selected_benefit_ids = []
  let selected_ben_rows = []
  let table = $('#tbl_benefit_dt_table').DataTable()

  var rows = table.rows({'search': 'applied'}).nodes();
  $('.selected_ben_rows', rows).each(function(){
    selected_ben_rows.push($(this).text().replace(/,/g,"").replace(".00",""))
  })
  $('input[name="product[benefit_limit_datas][]"]').val(Array.from(new Set(selected_ben_rows)))

  $('.selected_procedure_id', rows).each(function() {
    selected_benefit_ids.push($(this).text())
  })
  $('input[name="product[benefit_ids][]"]').val(Array.from(new Set(selected_benefit_ids)))
};
function update_dental(){
  let selected_benefit_ids = []
  let selected_ben_rows = []
  var table = $('#tbl_benefit_dt_table_edit').DataTable()

  var rows = table.rows({'search': 'applied'}).nodes();
  $('.selected_ben_rows', rows).each(function(){
    selected_ben_rows.push($(this).text().replace(/,/g,"").replace(".00",""))
  })
  $('input[name="product[benefit_limit_datas][]"]').val(Array.from(new Set(selected_ben_rows)))

  $('.selected_procedure_id', rows).each(function() {
    selected_benefit_ids.push($(this).text())
  })
  $('input[name="product[benefit_ids][]"]').val(Array.from(new Set(selected_benefit_ids)))
};
