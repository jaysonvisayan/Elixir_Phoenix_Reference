onmount('div[id="product_dental_step"]', function () {

    function removeDuplicateUsingFilter(arr){
      let unique_array = arr.filter(function(elem, index, self) {
          return index == self.indexOf(elem);
      });
      return unique_array
    }

		let location_group_id;

    location_group_id = $("select[id='product_dental_group_type'] option:selected").val()
		$('.location-group').on('change', function() {
      $('.dental-group-type').removeClass('error')
      $('#location-group-field').remove()
      // $('#dentl_add_fa_btn').removeClass('disabled')
      location_group_id = $('#product_dental_group_type').dropdown('get value')
      let product_coverage_id = $('input[name="product[product_coverage_id]"]').val()
      let product_id = $('input[name="product[id]"]').val()
      $('input[name="product[location_group_id]"]').val(location_group_id)
      const csrf = $('input[name="_csrf_token"]').val();

      // if ($('input[id="product_dentl][type_All_Affiliated_Facilities"]').is('checked')){
        $.ajax({
          url: `/web/products/${product_id}/dental/insert_pclg`,
          headers: {
            "X-CSRF-TOKEN": csrf
          },
          type: 'post',
          data: {product_coverage_id: product_coverage_id, location_group_id: location_group_id},
          dataType: 'json',
          success: function(response) {
            response = JSON.parse(response)
            return true
          }
        })
      // }
    })

    $('#dentl_add_fa_btn').on('click', function(){
      $('.dental-group-type').removeClass('error')
      $('#location-group-field').remove()
    })

    const get_provider_access = provider_access => {
        return (provider_access == undefined) ? '' : provider_access
		}

		const get_selected_facilities = (coverage, type) => {
			let selected_ids = []
			$(`.selected_${coverage}_${type}_id`).each(function () {
				selected_ids.push($(this).text())
			})
			return selected_ids
    }

    //
    // Updates "Select all" control in a data table
    //
    function updateDataTableSelectAllCtrl(table){
      var $table             = table.table().node();
      var $chkbox_all        = $('tbody input[type="checkbox"]', $table);
      var $chkbox_checked    = $('tbody input[type="checkbox"]:checked', $table);
      var chkbox_select_all  = $('thead input[name="select_all"]', $table).get(0);

      // If none of the checkboxes are checked
      if($chkbox_checked.length === 0){
          chkbox_select_all.checked = false;
          if('indeterminate' in chkbox_select_all){
            chkbox_select_all.indeterminate = false;
          }

      // If all of the checkboxes are checked
      } else if ($chkbox_checked.length === $chkbox_all.length){
          chkbox_select_all.checked = true;
          if('indeterminate' in chkbox_select_all){
            chkbox_select_all.indeterminate = false;
          }

      // If some of the checkboxes are checked
      } else {
          chkbox_select_all.checked = true;
          if('indeterminate' in chkbox_select_all){
            chkbox_select_all.indeterminate = true;
          }
      }
    }

    //
    // Add Jump to Page to Datatable
    //

    let datatable = $('#dt-dental-exclusion')
    $(document).unbind('change').on('change', '.ui.fluid.search.dropdown', function(){
      let page = $(this).find($('.text')).html()
      var table = datatable.DataTable();
      let no = parseInt(page) -1
      table.page( no ).draw( 'page' );
    })

    $('.modal-open-facilities').click(function () {
        $('#btn_submit').remove()

        let product_coverage_id = $('input[name="product[product_coverage_id]"]').val()
        const csrf = $('input[name="_csrf_token"]').val();
        let coverage = $(this).attr('coverage')
        let dt = $(`#${coverage}_fa_modal_tbl`)
        let provider_access = get_provider_access($(this).attr('providerAccess'))
        let type = $(`input[name="product[${coverage}][type]"]:checked`).val()

        let selected_facility_ids = [];

        $('.selected_facility_id').each(function() {
          selected_facility_ids.push($(this).text())
        })

        let facility_ids = selected_facility_ids.join(",")

        switch (type) {
          case 'All Affiliated Facilities':
          // ALL AFFILIATED FACILITIES DATATABLE
            if (location_group_id === undefined || location_group_id === "")
            {
              $('.dental-group-type').addClass('error')
              $('.dental-group-type').append('<div id="location-group-field" class="ui basic red pointing prompt label transition visible">Please select a location group.</div>')
            }
            else
            {
              $('.dental-group-type').removeClass('error')
              $('#location-group-field').remove()
              const csrf = $('input[name="_csrf_token"]').val();
              var rows_selected = [];
              let selected_rows_selected = []
              let datatable = $('#dt-dental-exclusion')

              $(`.exclusion.modal.${coverage}`)
                .modal({
                  autofocus: false,
                  closable: false,
                  observeChanges: true,
                  onHide: function() {
                    let table = $('#dt-dental-exclusion').DataTable()
                    table.clear()
                    table.destroy()
                    rows_selected = []
                  }
                })
                .modal('show');

              // Array holding selected row IDs

              var table = datatable.DataTable({
                "serverSide": true,
                "lengthMenu": [
                  [10, 50, 100, 500, 1000],
                  [10, 50, 100, 500, 1000]
                ],
                "language": {"search": ""},
                "dom":
                  "<'ui grid'"+
                    "<'row'"+
                      "<'four wide column'f>"+
                      "<'left aligned twelve wide column'i>"+
                    ">"+
                    "<'row'"+
                      "<'center aligned sixteen wide column dt-append'>"+
                    ">"+
                    "<'row dt-table'"+
                      "<'sixteen wide column'tr>"+
                    ">"+
                    "<'row'"+
                      "<'left aligned three wide column dt-append-button'>"+
                      "<'right aligned two wide column inline field append-result'>"+
                      "<'left aligned two wide column'l>"+
                      "<'center aligned six wide column'p>"+
                    ">"+
                  ">",
                'ajax': {
                  'url': '/web/products/dental/load_facility_datatable',
                  'type': "POST",
                  'headers': {"X-CSRF-TOKEN": csrf},
                  'data':
                    function( d ) {
                      d.location_group_id = location_group_id,
                      d.selected_facility_ids = facility_ids,
                      d.type = "exclusion",
                      d.product_coverage_id = product_coverage_id
                    },
                  'dataType': 'json'
                },
                "renderer": 'semanticUI',
                "pagingType": "simple_numbers",
                "drawCallback": function () {
                  add_search(this)
                  $('#clear-select-message').remove()
                  // CUSTOMIZE JUMP TO PAGE
                  var table = datatable.DataTable();
                  var info = table.page.info();
                  append_jump_exclusion(info.page, info.pages, "exception")

                  // CUSTOMIZE SEARCH BAR
                  $('input[type="search"]').css("width", "250px")
                  $('#btn_submit').remove()
                  $('.dt-append-button').append('<button class="approve left floated fluid ui primary big button" id="btn_submit" type="submit">Add</button>')

                  // DRAW CALL BACK EXCLUSION

                  $(document).on('click', '#select-all-checkbox', function(e) {
                    e.preventDefault()

                    $.ajax({
                      url:`/web/products/dental/load_all_facility`,
                      headers: {"X-CSRF-TOKEN": csrf},
                      type: 'POST',
                      data: {"facility_ids" : facility_ids, "location_group_id" : location_group_id},
                      dataType: 'json',
                      success: function(response) {

                        $.each(response.data, function(index, value){
                          rows_selected.push(value)

                          $('#clear-select-message').remove()

                          $('.dt-append').append(`<div class="ui attached message" id="clear-select-message" style="background-color: #fff8ea;"> \
                          <p>All ${response.data.length} facilities are selected. <a id="clear-all-checkbox"> <span class="green"> <u> Clear selection </u> </span> </a> \
                          </p></div>`)
                        });
                      }})
                  })

                  $(document).on('click', '#clear-all-checkbox', function(e) {
                      e.preventDefault()
                      rows_selected = []

                      $('.facility_chkbx').prop("checked", false)
                      $('#clear-select-message').remove()
                    })
                  },
                  'columnDefs': [{
                    'targets': 0,
                    'searchable': false,
                    'orderable': false,
                    'width': '1%',
                    'className': 'dt-body-center',
                    'render': function (data, type, full, meta){
                      return full[0]
                    }
                  }],
                  'order': [[1, 'asc']],
                  'rowCallback': function(row, data, dataIndex){
                    // Get row ID
                    var rowId = $(data[0]).attr('id');

                    // If row ID is in the list of selected row IDs
                    if($.inArray(rowId, rows_selected) !== -1){
                        $(row).find('input[type="checkbox"]').prop('checked', true);
                        $(row).addClass('selected');
                    }
                  },
                  "language": {
                    "search": "",
                    "searchPlaceholder": "",
                    "decimal":        "",
                    "emptyTable":     "No data available in table",
                    "info": "Showing _END_ out of _TOTAL_ results",
                    "infoEmpty": "Showing 0 out of 0 result",
                    "infoFiltered":   "(filtered from _MAX_ total results)",
                    "emptyTable": "No Records Found!",
                    "zeroRecords": "No results found",
                    "lengthMenu": "Show: _MENU_",
                    "paginate": {
                        "previous": "<i class='angle single left icon'></i>",
                        "next": "<i class='angle single right icon'></i>",
                    }
                  }
                });


                $(document).unbind('change').on('change', '.ui.fluid.dropdown', function(){
                  let page = $(this).find($('.text')).html()
                  var table = datatable.DataTable();
                  let no = parseInt(page) -1
                  table.page( no ).draw( 'page' );
                })

                $('#dt-dental-exclusion_wrapper').find('.dataTables_filter').addClass('ui left icon input')
                $('#dt-dental-exclusion_wrapper').find('.dataTables_filter').find('input[type="search"]').unwrap('Search')
                $('#dt-dental-exclusion_wrapper').find('.dataTables_filter').find('input[type="search"]').attr("placeholder", `Search`)
                $('#dt-dental-exclusion_wrapper').find('.dataTables_filter').find('input[type="search"]').append(`</div>`)

                function append_jump_exclusion(page, pages, type){
                  let results = $(`#dt-dental-exclusion >tbody >tr`).length

                  let total = $('#dt-dental-exclusion_info').html()

                  // $('#dt-dental-exclusion_info').html(`Showing ${results} out of ${total} results`)
                  $('.table > tbody  > tr').each(function(){
                    $(this).attr('style', 'height:50px')
                  })
                  $('#dt-dental-exclusion_wrapper').find('.jump-to-page').remove()
                  $('#dt-dental-exclusion_wrapper').find('.jtp-selection').remove()
                  $('#dt-dental-exclusion_wrapper').find('.one.wide').remove()
                  $('#dt-dental-exclusion_wrapper').find('.show').remove()
                  $('#dt-dental-exclusion_wrapper').find('.append-result').append(`<span class="show" > Showing ${results} results</span>`)
                  $('#dt-dental-exclusion_wrapper').find('.append-result').css("padding-top", "10px")
                  $('#dt-dental-exclusion_wrapper').find(".dataTables_paginate.paging_simple_numbers").parent().parent().append(
                    `<div class="right aligned two wide column inline field jump-to-page" style="padding-top: 0.8rem;"> Jump to page: </div>\
                      <div class="right aligned one wide column inline field jtp-selection">\
                      <select class="ui fluid dropdown" id="jump">\
                      </select>\
                      </div>`
                  )
                  var select = $('#jump')
                  var options = []
                  for(var x = 1; x < parseInt(pages) + 1; x++){
                    options.push(`<option value='${x}'>${x}</option>`)
                  }
                  select.append(String(options.join('')))
                  $('#dt-dental-exclusion_wrapper').find('.ui.fluid.dropdown').dropdown()
                  $('#dt-dental-exclusion_wrapper').find('.ui.fluid.dropdown.selection').css("width", "6rem")
                  $('#dt-dental-exclusion_wrapper').find('.ui.fluid.dropdown.selection').css("margin-left", "-1.2rem")
                  $('#dt-dental-exclusion_wrapper').find('#jump').dropdown('set selected', page + 1)
                }

                  // Handle click on checkbox

                $('#dt-dental-exclusion tbody').unbind('click').on('click', 'input[type="checkbox"]', function(e){
                    var $row = $(this).closest('tr');

                    // Get row data
                    var data = table.row($row).data();
                    // Get row ID
                    var rowId = $(data[0]).attr('id');

                    // Determine whether row ID is in the list of selected row IDs
                    var index = $.inArray(rowId, rows_selected);

                    // If checkbox is checked and row ID is not in list of selected row IDs
                    if(this.checked && index === -1){
                      rows_selected.push(rowId);
                      selected_rows_selected.push(rowId)

                    // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
                    } else if (!this.checked && index !== -1){
                      $('#clear-select-message').remove()
                      rows_selected = removeDuplicateUsingFilter(rows_selected)
                      rows_selected.splice(index, 1);
                      let haha = selected_benefit_rows2.indexOf(rowId)
                      selected_facility_ids.splice(haha, 1)
                    }

                    if(this.checked){
                      $row.addClass('selected');
                    } else {
                      $row.removeClass('selected');
                    }

                    // Update state of "Select all" control
                    updateDataTableSelectAllCtrl(table);

                    // Prevent click event from propagating to parent
                    e.stopPropagation();
                });

                // Handle click on table cells with checkboxes
                $('#dt-dental-exclusion').unbind('click').on('click', 'tbody td, thead th:first-child', function(e){
                    $(this).parent().find('label[type="text"]').trigger('click');
                });

                // Handle click on "Select all" control
                $('thead input[name="select_all"]', table.table().container()).unbind('click').on('click', function(e){
                  let selected_data_count_start = datatable.DataTable().page.info().start;
                  let selected_data_count_end = datatable.DataTable().page.info().end;
                  let selected_data_count = selected_data_count_end - selected_data_count_start
                  let total_count = datatable.DataTable().page.info().recordsTotal;

                  if(this.checked){
                    $('#clear-select-message').remove()
                    $('.dt-append').append(`<div class="ui attached message" id="clear-select-message" style="background-color: #fff8ea;"> \
                    <p>All ${selected_data_count} facilities on this \
                    page are selected <a id="select-all-checkbox"> <span class="green"> <u> Select \
                    all ${total_count} facilities </u> </span> </a> \
                    </p></div>`)

                    $('#dt-dental-exclusion tbody input[type="checkbox"]:not(:checked)').trigger('click');
                  } else {
                    $('#clear-select-message').remove()
                    $('#dt-dental-exclusion tbody input[type="checkbox"]:checked').trigger('click');
                  }

                  // Prevent click event from propagating to parent
                  e.stopPropagation();
                });

                // Handle table draw event
                table.on('draw', function(){
                    // Update state of "Select all" control
                    updateDataTableSelectAllCtrl(table);
                });

                $(document)
                  .unbind('click').on('click', '#btn_submit', function() {

                  $('#btn_submit').remove()
                  let product_id = $('input[name="product[id]"]').val()
                  let location_group_id = $('#product_dental_group_type').val()
                  const csrf = $('input[name="_csrf_token"]').val();
                  let checked_facility = $('input[class="facility_chkbx"]:checked')

                  if(checked_facility.length > 0){
                    let dt = $('#dentl_lt_tbl').DataTable();
                    $('#btnAddRiskShare').removeClass('disabled')

                    var req = $.ajax({
                      url:`/web/products/${product_id}/dental/insert_pcf`,
                      headers: {"X-CSRF-TOKEN": csrf},
                      type: 'post',
                      data: { product_coverage_id: product_coverage_id, facility_ids: rows_selected, location_group_id: location_group_id, type: "exception"},
                      dataType: 'json',
                      beforeSend: function()
                      {
                        $('#overlay-inclusion').removeClass('hidden');
                      },
                      complete: function()
                      {
                        $('#overlay-inclusion').addClass('hidden');
                      }
                    });

                    req.done(function (response){
                        $('#fa_tbl').val('true')
                        // Iterate over all selected checkboxes
                        $.each(rows_selected, function(index, rowId){
                          // Create a hidden element
                          $('#product_coverage_form').append(
                              $('<input>')
                                  .attr('type', 'hidden')
                                  .attr('name', 'product[dentl][facility_ids2][]')
                                  .attr('class', 'selected_procedure_id')
                                  .val(rowId)
                                  .text(rowId)
                          );
                        });

                        const results = JSON.parse(response)

                        $.each(results, function(index, data){

                            dt.row.add([
                            `<span class="${data.code} pcf_fac_code" pcf_facility_code="${data.code}"> ${data.code} </span>`,
                            `<span class="${data.name}"> ${data.name} </span>`,
                            `<span class=""> ${data.line_1}, ${data.line_2}, ${data.city}, ${data.province}, ${data.region},
                            ${data.country}, ${data.postal_code} </span>`,
                            `<span class="${data.l_name}"> ${data.l_name} </span>`,
                            `<a href="#!" pc_type="exception" product_id=${product_id} product_coverage_facility_id=${data.product_coverage_facility_id} class="remove_facility"> Remove\
                              <input type="hidden" name="product[dentl][facility_ids][]" value="${data.facility_id}"> \
                              <span class="selected_facility_id hidden">${data.facility_id}</span> </a>
                            `]).draw(false)
                          })

                          $('.remove_facility').on('click', function (e) {
                          e.preventDefault()
                          let pcf_id = $(this).attr('product_coverage_facility_id')
                          let product_id = $(this).attr('product_id')
                          let type = $(this).attr('pc_type')

                          swal({
                            title: 'Delete Facility?',
                            type: 'question',
                            showCancelButton: true,
                            cancelButtonText: '<i class="remove icon"></i> No, keep facility',
                            confirmButtonText: '<i class="check icon"></i> Yes, delete facility',
                            cancelButtonClass: 'ui negative button',
                            confirmButtonClass: 'ui positive button',
                            reverseButtons: true,
                            buttonsStyling: false
                          }).then(function () {
                            var count = $('#dental_fa_tbl>tbody>tr').length;

                            if (count === 1 && type === 'inclusion') {
                              $('.ajs-message.ajs-error.ajs-visible').remove()
                              alertify.error('<i class="close icon"></i>Cannot delete all facility')
                            } else {
                              window.location.replace(`/web/products/delete/${pcf_id}/${product_id}/product_coverage`);
                            }
                          })
                        })

                        $(`.exclusion.modal.${coverage}`).modal('hide');
                        $('#dentl_fa_tbl_info').show()
                        $('#dentl_fa_tbl_paginate').show()
                        $('#dentl_fa_tbl_length').show()
                        //TODO
                    });

                  } else {
                    $('.ajs-message.ajs-error.ajs-visible').remove()
                    alertify.error('<i class="close icon"></i>Please select at least one Facility.')
                    $('.dt-append-button').append('<button class="approve left floated fluid ui primary big button" id="btn_submit" type="submit">Add</button>')
                  }
                })
              }

            break
          case 'Specific Facilities':
             // SPECIFC FACILITIES DATATABLE

              $(`.inclusion.modal.${coverage}`)
              .modal({
                autofocus: false,
                closable: false,
                observeChanges: true,
                onHide: function() {
                  let table = $('#dt-dental-inclusion').DataTable()
                  table.destroy()
                }
              })
              .modal('show');

              // Array holding selected row IDs
              var rows_selected = [];
              let datatable = $('#dt-dental-inclusion')

              var table = datatable.DataTable({
                "serverSide": true,
                "lengthMenu": [
                  [10, 50, 100, 500, 1000],
                  [10, 50, 100, 500, 1000]
                ],
                "dom":
                  "<'ui grid'"+
                    "<'row'"+
                      "<'four wide column'f>"+
                      "<'left aligned twelve wide column'i>"+
                    ">"+
                    "<'row'"+
                      "<'center aligned sixteen wide column dt-append'>"+
                    ">"+
                    "<'row dt-table'"+
                      "<'sixteen wide column'tr>"+
                    ">"+
                    "<'row'"+
                      "<'left aligned three wide column dt-append-button'>"+
                      "<'right aligned two wide column inline field append-result'>"+
                      "<'left aligned two wide column'l>"+
                      "<'center aligned six wide column'p>"+
                    ">"+
                  ">",
                'ajax': {
                  'url': '/web/products/dental/load_facility_datatable',
                  'type': "POST",
                  'headers': {"X-CSRF-TOKEN": csrf},
                  'data':
                    function( d ) {
                      d.product_coverage_id = product_coverage_id,
                      d.selected_facility_ids = facility_ids,
                      d.type = "inclusion"
                    },
                  'dataType': 'json'
                },
                "renderer": 'semanticUI',
                "language": {
                  "info": "Showing _END_ out of _TOTAL_ results",
                  "infoEmpty": "Showing 0 out of 0 result",
                  "search": ""
                },
                "pagingType": "simple_numbers",
                "drawCallback": function () {
                  add_search(this)
                  $('#clear-select-message').remove()
                  // CUSTOMIZE JUMP TO PAGE
                  var table = datatable.DataTable();
                  var info = table.page.info();
                  append_jump_inclusion(info.page, info.pages, "inclusion")

                  // CUSTOMIZE SEARCH BAR
                  $('input[type="search"]').css("width", "250px")
                  $('#btn_submit').remove()
                  $('.dt-append-button').append('<button class="approve left floated fluid ui primary big button" id="btn_submit" type="submit">Add</button>')

                  // DRAW CALL BACK EXCLUSION

                  $(document).on('click', '#select-all-checkbox', function(e) {
                    e.preventDefault()

                    $.ajax({
                      url:`/web/products/dental/load_all_facility`,
                      headers: {"X-CSRF-TOKEN": csrf},
                      type: 'POST',
                      data: {"facility_ids" : facility_ids},
                      dataType: 'json',
                      success: function(response) {

                        $.each(response.data, function(index, value){
                          rows_selected.push(value)

                          $('#clear-select-message').remove()

                          $('.dt-append').append(`<div class="ui attached message" id="clear-select-message" style="background-color: #fff8ea;"> \
                          <p>All ${response.data.length} facilities are selected. <a id="clear-all-checkbox"> <span class="green"> <u> Clear selection </u> </span> </a> \
                          </p></div>`)
                        });
                      }})
                  })

                  $(document).on('click', '#clear-all-checkbox', function(e) {
                    e.preventDefault()
                    rows_selected = []

                    $('.facility_chkbx').prop("checked", false)
                    $('#clear-select-message').remove()
                  })
                  },
                  'columnDefs': [{
                    'targets': 0,
                    'searchable': false,
                    'orderable': false,
                    'width': '1%',
                    'className': 'dt-body-center',
                    'render': function (data, type, full, meta){
                      return full[0]
                    }
                  }],
                  'order': [[1, 'asc']],
                  'rowCallback': function(row, data, dataIndex){
                    // Get row ID
                    var rowId = $(data[0]).attr('id');

                    // If row ID is in the list of selected row IDs
                    if($.inArray(rowId, rows_selected) !== -1){
                        $(row).find('input[type="checkbox"]').prop('checked', true);
                        $(row).addClass('selected');
                    }
                  },
                  "language": {
                    "search": "",
                    "searchPlaceholder": "",
                    "decimal":        "",
                    "emptyTable":     "No data available in table",
                    "info": "Showing _END_ out of _TOTAL_ results",
                    "infoEmpty": "Showing 0 out of 0 result",
                    "infoFiltered":   "(filtered from _MAX_ total results)",
                    "emptyTable": "No Records Found!",
                    "zeroRecords": "No results found",
                    "lengthMenu": "Show: _MENU_",
                    "paginate": {
                        "previous": "<i class='angle single left icon'></i>",
                        "next": "<i class='angle single right icon'></i>",
                    }
                  }
                });

                $('#dt-dental-inclusion_wrapper').find('.dataTables_filter').addClass('ui left icon input')
                $('#dt-dental-inclusion_wrapper').find('.dataTables_filter').find('input[type="search"]').unwrap('Search')
                $('#dt-dental-inclusion_wrapper').find('.dataTables_filter').find('input[type="search"]').attr("placeholder", `Search`)
                $('#dt-dental-inclusion_wrapper').find('.dataTables_filter').find('input[type="search"]').append(`</div>`)

                $(document).unbind('change').on('change', '.ui.fluid.dropdown', function(){
                  let page = $(this).find($('.text')).html()
                  var table = datatable.DataTable();
                  let no = parseInt(page) -1
                  table.page( no ).draw( 'page' );
                })

                function append_jump_inclusion(page, pages, type){
                  let results = $(`#dt-dental-${type} >tbody >tr`).length
                  let total = $('#dt-dental-inclusion_info').html()

                  // $('#dt-dental-inclusion_info').html(`Showing ${results} out of ${total} results`)
                  $('.table > tbody  > tr').each(function(){
                    $(this).attr('style', 'height:50px')
                  })
                  $('#dt-dental-inclusion_wrapper').find('.jump-to-page').remove()
                  $('#dt-dental-inclusion_wrapper').find('.jtp-selection').remove()
                  $('#dt-dental-inclusion_wrapper').find('.one.wide').remove()
                  $('#dt-dental-inclusion_wrapper').find('.show').remove()
                  $('#dt-dental-inclusion_wrapper').find('.append-result').append(`<span class="show" > Showing ${results} results</span>`)
                  $('#dt-dental-inclusion_wrapper').find('.append-result').css("padding-top", "10px")
                  $('#dt-dental-inclusion_wrapper').find(".dataTables_paginate.paging_simple_numbers").parent().parent().append(
                    `<div class="right aligned two wide column inline field jump-to-page" style="padding-top: 0.8rem;"> Jump to page: </div>\
                      <div class="right aligned one wide column inline field jtp-selection">\
                      <select class="ui fluid dropdown" id="jump">\
                      </select>\
                      </div>`
                  )

                  var select = $('#jump')
                  var options = []
                  for(var x = 1; x < parseInt(pages) + 1; x++){
                    options.push(`<option value='${x}'>${x}</option>`)
                  }
                  select.append(String(options.join('')))
                  $('#dt-dental-inclusion_wrapper').find('.ui.fluid.dropdown').dropdown()
                  $('#dt-dental-inclusion_wrapper').find('.ui.fluid.dropdown.selection').css("width", "6rem")
                  $('#dt-dental-inclusion_wrapper').find('.ui.fluid.dropdown.selection').css("margin-left", "-1.2rem")

                  $('#dt-dental-inclusion_wrapper').find('#jump').dropdown('set selected', page + 1)
                }

                // Handle click on checkbox
                $('#dt-dental-inclusion tbody').unbind('click').on('click', 'input[type="checkbox"]', function(e){
                    var $row = $(this).closest('tr');

                    // Get row data
                    var data = table.row($row).data();

                    // Get row ID
                    var rowId = $(data[0]).attr('id');

                    // Determine whether row ID is in the list of selected row IDs
                    var index = $.inArray(rowId, rows_selected);

                    // If checkbox is checked and row ID is not in list of selected row IDs
                    if(this.checked && index === -1){
                      rows_selected.push(rowId);

                    // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
                    } else if (!this.checked && index !== -1){
                      $('#clear-select-message').remove()
                      rows_selected = removeDuplicateUsingFilter(rows_selected)
                      rows_selected.splice(index, 1);
                      let haha = selected_facility_ids.indexOf(rowId)
                      selected_facility_ids.splice(haha, 1)
                    }

                    if(this.checked){
                      $row.addClass('selected');
                    } else {
                      $row.removeClass('selected');
                    }

                    // Update state of "Select all" control
                    updateDataTableSelectAllCtrl(table);

                    // Prevent click event from propagating to parent
                    e.stopPropagation();
                });

                // Handle click on table cells with checkboxes
                $('#dt-dental-inclusion').unbind('click').on('click', 'tbody td, thead th:first-child', function(e){
                    $(this).parent().find('label[type="text"]').trigger('click');
                });

                // Handle click on "Select all" control
                $('thead input[name="select_all"]', table.table().container()).unbind('click').on('click', function(e){
                  let selected_data_count_start = datatable.DataTable().page.info().start;
                  let selected_data_count_end = datatable.DataTable().page.info().end;
                  let selected_data_count = selected_data_count_end - selected_data_count_start
                  let total_count = datatable.DataTable().page.info().recordsTotal;

                  if(this.checked){
                    $('#clear-select-message').remove()
                    $('.dt-append').append(`<div class="ui attached message" id="clear-select-message" style="background-color: #fff8ea;"> \
                    <p>All ${selected_data_count} facilities on this \
                    page are selected <a id="select-all-checkbox"> <span class="green"> <u> Select \
                    all ${total_count} facilities </u> </span> </a> \
                    </p></div>`)

                    $('#dt-dental-inclusion tbody input[type="checkbox"]:not(:checked)').trigger('click');
                  } else {
                    $('#clear-select-message').remove()
                    $('#dt-dental-inclusion tbody input[type="checkbox"]:checked').trigger('click');
                  }

                  // Prevent click event from propagating to parent
                  e.stopPropagation();
                });

                // Handle table draw event
                table.on('draw', function(){
                    // Update state of "Select all" control
                    updateDataTableSelectAllCtrl(table);
                });

                $(document)
                  .unbind('click').on('click', '#btn_submit', function() {
                  $('#btn_submit').remove()
                  let product_id = $('input[name="product[id]"]').val()
                  let location_group_id = $('#product_dental_group_type').val()
                  const csrf = $('input[name="_csrf_token"]').val();
                  let checked_facility = $('input[class="facility_chkbx"]:checked')

                  if(checked_facility.length > 0){
                    let dt = $('#dentl_fa_tbl').DataTable();
                    $('#btnAddRiskShare').removeClass('disabled')
                    $('.field.error').hide()
                    var req = $.ajax({
                      url:`/web/products/${product_id}/dental/insert_pcf`,
                      headers: {"X-CSRF-TOKEN": csrf},
                      type: 'post',
                      data: { product_coverage_id: product_coverage_id, facility_ids: removeDuplicateUsingFilter(rows_selected), type: "inclusion"},
                      dataType: 'json',
                      beforeSend: function()
                      {
                        $('#overlay-inclusion').removeClass('hidden');
                      },
                      complete: function()
                      {
                        $('#overlay-inclusion').addClass('hidden');
                      }
                    });

                    req.done(function (response){
                        $('#fa_tbl').val('true')
                      // Iterate over all selected checkboxes
                      $.each(rows_selected, function(index, rowId){
                        // Create a hidden element
                        $('#product_coverage_form').append(
                            $('<input>')
                                .attr('type', 'hidden')
                                .attr('class', 'selected_procedure_id')
                                .val(rowId)
                                .text(rowId)
                        );
                      });

                      const results = JSON.parse(response)

                      $.each(results, function(index, data){

                        dt.row.add([
                          `<span class="${data.code}"> ${data.code} </span>`,
                          `<span class="${data.name}"> ${data.name} </span>`,
                          `<span class=""> ${data.line_1}, ${data.line_2}, ${data.city}, ${data.province}, ${data.region}, ${data.country}, ${data.postal_code} </span>`,
                          `<span class="${data.name}"> ${data.name} </span>`,
                          `<a href="#!" pc_type="exception" product_id=${product_id} product_coverage_facility_id=${data.product_coverage_facility_id} class="remove_facility"> Remove\
                          <input type="hidden" name="product[dentl][facility_ids][]" value="${data.facility_id}"> \
                          <span class="selected_facility_id hidden">${data.facility_id}</span> </a>
                        `]).draw(false)
                      })

                      $('.remove_facility').on('click', function (e) {
                        e.preventDefault()
                        let pcf_id = $(this).attr('product_coverage_facility_id')
                        let product_id = $(this).attr('product_id')
                        let type = $(this).attr('pc_type')

                        swal({
                          title: 'Delete Facility?',
                          type: 'question',
                          showCancelButton: true,
                          cancelButtonText: '<i class="remove icon"></i> No, keep facility',
                          confirmButtonText: '<i class="check icon"></i> Yes, delete facility',
                          cancelButtonClass: 'ui negative button',
                          confirmButtonClass: 'ui positive button',
                          reverseButtons: true,
                          buttonsStyling: false
                        }).then(function () {
                          var count = $('#dental_fa_tbl>tbody>tr').length;

                          if (count === 1 && type === 'inclusion') {
                            alertify.error('<i class="close icon"></i>Cannot delete all facility')
                          } else {
                            window.location.replace(`/web/products/delete/${pcf_id}/${product_id}/product_coverage`);
                          }
                        })
                      })

                      $(`.inclusion.modal.${coverage}`).modal('hide');
                      $('#dentl_fa_tbl_info').show()
                      $('#dentl_fa_tbl_paginate').show()
                      $('#dentl_fa_tbl_length').show()

                    })

                  } else {
                    alertify.error('<i class="close icon"></i>Please select at least one Facility.')
                    $('.dt-append-button').append('<button class="approve left floated fluid ui primary big button" id="btn_submit" type="submit">Add</button>')
                  }
                })
            break
          default:
            break
        }

    })

  $('#product_dental_group_type').change(function(){
     let product_id = $('input[name="product[id]"]').val()
     const csrf = $('input[name="_csrf_token"]').val();

     $.ajax({
       url: `/web/products/${product_id}/delete/product_facilities`,
       headers: {
         "X-CSRF-TOKEN": csrf
       },
       data: {"type" : "exception"},
       type: 'delete',
       success: function (response) {
        let coverage = $('.coverage_type_radio').attr('coverage')
        let dt_fa = $(`#${coverage}_fa_tbl`).DataTable()
        let dt_lt = $(`#${coverage}_lt_tbl`).DataTable()

        dt_fa.clear().draw()
        dt_lt.clear().draw()
       }
     })
   })

  // delete data on dt upon on change of radio button

   // $('.coverage_type_radio').on('change', function () {
   //    var table = $('#dentl_fa_tbl').DataTable();
   //      table.draw();
   //    var table2 = $('#dentl_lt_tbl').DataTable();
   //      table.draw();
   //  })

})

function add_search(table){
  let id = table[0].getAttribute("id")
  let value = $(`#${id}_filter`).val()

  if(value != 1){
    $(`#${id}_filter`).addClass('ui left icon input')
    $(`#${id}_filter`).find('label').after('<i class="search icon"></i>')
    $(`#${id}_filter`).find('input[type="search"]').unwrap()
    $(`#${id}_filter`).find('input[type="search"]').attr("placeholder", `Search`)
    $(`#${id}_filter`).find('input[type="search"]').append(`</div>`)
    $(`#${id}_filter`).val(1)
  }
}
