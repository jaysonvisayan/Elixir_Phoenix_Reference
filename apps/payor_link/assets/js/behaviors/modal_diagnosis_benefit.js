export function modal_diagnosis_benefit(diagnosis_ids, csrf) {

    let type = ""
    let datatable = $('#tbl_add_diagnosis')
    let selected_diagnosis_ids = []
    function removeDuplicateUsingFilter(arr){
      let unique_array = arr.filter(function(elem, index, self) {
        return index == self.indexOf(elem);
      })
      return unique_array
    }

    $('.selected_diagnosis_id').each(function() {
      selected_diagnosis_ids.push($(this).text())
    })

    diagnosis_ids = removeDuplicateUsingFilter(selected_diagnosis_ids).join(",")
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

      // Array holding selected row IDs
      var rows_selected = [];
      var selected_cdt_rows = [];
      var table = $('#tbl_add_diagnosis').DataTable({
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
            "<'left aligned two wide column test'>"+
            "<'right aligned two wide column inline field append-result'>"+
            "<'left aligned two wide column'l>"+
            "<'center aligned seven wide column'p>"+
          ">"+
        ">",
        "destroy": true,
        "ajax": $.fn.dataTable.dt_timeout(
          `/web/benefits/load_diagnosis?diagnosis_ids=${diagnosis_ids}&type=${type}&is_all_selected=${ $('input[name="select_a2ll"').is(":checked") }`,
          csrf
        ),
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
            var rowId = data[0];

            // If row ID is in the list of selected row IDs
            if($.inArray(rowId, rows_selected) !== -1){
              $(row).find('input[type="checkbox"]').prop('checked', true);
              $(row).addClass('selected');
            }
        },
        "drawCallback": function (settings) {
          add_search(this)
          $('#clear-select-message').remove()
          $('#btn_submit_diagnosis').remove()
          $('.test').append('<button class=" send-rtp ui left floated primary button close" type="submit" id="btn_submit_diagnosis">Add</button>')

          // CUSTOMIZE JUMP TO PAGE
          var table = datatable.DataTable();
          var info = table.page.info();
          append_jump_exclusion(info.page, info.pages, "exception")

          // CUSTOMIZE SEARCH BAR
          $('input[type="search"]').css("width", "250px")

          submit_diagnosis(rows_selected, selected_cdt_rows)
          $(document).on('click', '#select-all-cdt', function() {
            $('#clear-select-message').remove()
            // AJAX TODO

            let diagnosis_ids = selected_diagnosis_ids.join(",")
            let type = $('#diagnosis_type_dropdown').dropdown('get value')
            alert(123)
             $.ajax({
               url:`/web/benefits/load_all_diagnosis?diagnosis_ids=${diagnosis_ids}`,
               headers: {"X-CSRF-TOKEN": csrf},
               type: 'GET',
               dataType: 'json',
               success: function(response) {
                $.each(response.data, function(index, value){
                  rows_selected.push(value.id)
                  var selected_datas = [
                    `<span class="green selected_diagnosis_id">${value.code}</span>`,
                    `<strong>${value.name}</strong><br><small class="thin dim">${value.description}</small>`,
                    `<a href="#!" id="${value.id}" class="remove_diagnosis"><u style="color: gray">Remove</u></a><input type="hidden" name="benefit[diagnosis_ids][]" value="${value.id}">`
                  ]
                  selected_cdt_rows.push(selected_datas)
                });

                $('#clear-select-message').remove()
                $('.dt-append').append(`<div class="ui attached message" id="clear-select-message" style="background-color: #fff8ea;"> \
                <p>All ${response.data.length} facilities are selected. <a id="clear-all-checkbox"> <span class="green"> <u> Clear selection </u> </span> </a> \
                </p></div>`)
               }})
          })

          $(document).on('click', '#clear-all-checkbox', function(e) {
            e.preventDefault()
            rows_selected = []

            $('.diagnosis_chkbx').prop("checked", false)
            $('input[name="select_all"]').prop("checked", false)
            $('#clear-select-message').remove()
          })
        },
        "renderer": 'semanticUI',
        "pagingType": "simple_numbers",
        "language": {
          "emptyTable":     "No CDT found",
          "zeroRecords":    "No CDT matched your search",
          "info": "Showing _END_ out of _MAX_ results",
          "infoEmpty": "Showing 0 out of 0 result",
          "lengthMenu": "Show: _MENU_",
          "infoFiltered": "",
          "search":         "",
          "paginate": {
            "previous": "<i class='angle single left icon'></i>",
            "next": "<i class='angle single right icon'></i>",
          }
        },
        "processing": true,
        "deferRender": true,
        "serverSide": true

      });

      $('#tbl_add_diagnosis_wrapper').find('.dataTables_filter').addClass('ui left icon input')
      $('#tbl_add_diagnosis_wrapper').find('.dataTables_filter').find('input[type="search"]').unwrap('Search')
      $('#tbl_add_diagnosis_wrapper').find('.dataTables_filter').find('input[type="search"]').attr("placeholder", `Search`)
      $('#tbl_add_diagnosis_wrapper').find('.dataTables_filter').find('input[type="search"]').append(`</div>`)

      $(document).unbind('change').on('change', '.ui.fluid.dropdown.diagnosis', function(){
        let page = $(this).find($('.text')).html()
        var table = datatable.DataTable();
        let no = parseInt(page) -1
        table.page( no ).draw( 'page' );
      })

      let cdt2_search_id = $('#tbl_add_diagnosis_wrapper')

      cdt2_search_id.find('.dataTables_info').attr("style", "margin-left: 1rem;")

      function append_jump_exclusion(page, pages, type){
      let cdt2_search_id = $('#tbl_add_diagnosis_wrapper')
      let results;

      if (results = cdt2_search_id.find('.table > tbody  > tr').html().includes("matched your search") || cdt2_search_id.find('.table > tbody  > tr').html().includes("found")) {
        results = 0
      }
      else {
        results = cdt2_search_id.find('.table > tbody  > tr').length
      }
        $('.table > tbody  > tr').each(function(){
          $(this).attr('style', 'height:50px')
        })
        cdt2_search_id.find('.jump-to-page').remove()
        cdt2_search_id.find('.jtp-selection').remove()
        cdt2_search_id.find('.one.wide').remove()
        cdt2_search_id.find('.show').remove()
        cdt2_search_id.find('.append-result').append(`<span class="show" > Showing ${results} results</span>`)
        cdt2_search_id.find('.append-result').css("padding-top", "10px")
        cdt2_search_id.find(".dataTables_paginate.paging_simple_numbers").parent().parent().append(
          `<div class="right aligned two wide column inline field jump-to-page" style="padding-top: 0.8rem;"> Jump to page: </div>\
            <div class="right aligned one wide column inline field jtp-selection">\
            <select class="ui fluid dropdown diagnosis" id="jump2">\
            </select>\
            </div>`
        )
        var select = $('#jump2')
        var options = []
        for(var x = 1; x < parseInt(pages) + 1; x++){
          options.push(`<option value='${x}'>${x}</option>`)
        }
        select.append(String(options.join('')))
        cdt2_search_id.find('.ui.fluid.dropdown').dropdown()
        cdt2_search_id.find('.ui.fluid.dropdown.selection').css("width", "6rem")
        cdt2_search_id.find('.ui.fluid.dropdown.selection').css("margin-left", "-1.2rem")
        cdt2_search_id.find('#jump2').dropdown('set selected', page + 1)
      }

      // Handle click on checkbox
      $('#tbl_add_diagnosis tbody').on('click', 'input[type="checkbox"]', function(e){
        var $row = $(this).closest('tr');

        // Get row data
        var data = table.row($row).data();

        var CDTCode = $(data[0]).attr('code');
        var CDTName = $(data[0]).attr('diagnosis_name');
        var CDTDescription = $(data[0]).attr('description');
        var CDTId = $(data[0]).attr('diagnosis_id');
        var CDTType = $(data[0]).attr('diagnosis_type');

        // Get row ID
        var rowId = data[0];

        var datas =
          [
            `<span class="green selected_diagnosis_id">${CDTCode}</span>`,
            `<strong>${CDTName}</strong><br><small class="thin dim">${CDTDescription}</small>`,
            `<a href="#!" id="${CDTId}" class="remove_diagnosis"><u style="color: gray">Remove</u></a><input type="hidden" name="benefit[diagnosis_ids][]" value="${CDTId}">`
          ]

        var cdt_datas = $.inArray(datas, selected_cdt_rows)

        // Determine whether row ID is in the list of selected row IDs
        var index = $.inArray(CDTId, rows_selected);

        // If checkbox is checked and row ID is not in list of selected row IDs
        if(this.checked && index === -1){
            rows_selected.push(CDTId);
            selected_cdt_rows.push(datas)
            selected_diagnosis_ids.push(CDTCode)
        // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
        } else if (!this.checked && index !== -1){
            $('#clear-select-message').remove()
            rows_selected.splice(index, 1);
            selected_diagnosis_ids.splice(index, 1)
            let haha = selected_cdt_rows.indexOf(CDTId)
            selected_cdt_rows.splice(haha, 1)

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
      $('#tbl_add_diagnosis').on('click', 'tbody td, thead th:first-child', function(e){
        $(this).parent().find('input[type="checkbox"]').trigger('click');
      });

      // Handle click on "Select all" control
      $('thead input[name="select_all"]', table.table().container()).on('click', function(e){
        let id = "tbl_add_diagnosis"
        let results = $(`#${id} >tbody >tr`).length
        let selected_cdt_count_start = datatable.DataTable().page.info().start;
        let selected_cdt_count =  results
        let total_count = datatable.DataTable().page.info().recordsTotal;

        if(this.checked){
            $('#clear-select-message').remove()
            $('#tbl_add_diagnosis tbody input[type="checkbox"]:not(:checked)').trigger('click');
            $('.dt-append').append(`<div class="ui attached message" id="clear-select-message" style="background-color: #fff8ea;"> \
            <p>All ${selected_cdt_count} CDT on this \
            page are selected <a id="select-all-cdt"> <span class="green"> <u> Select \
            all ${total_count} CDT </u> </span> </a> \
            </p></div>`)
        } else {
            $('#clear-select-message').remove()
            $('#tbl_add_diagnosis tbody input[type="checkbox"]:checked').trigger('click');
        }

        // Prevent click event from propagating to parent
        e.stopPropagation();
      });

      // Handle table draw event
      table.on('draw', function(){
        // Update state of "Select all" control
        updateDataTableSelectAllCtrl(table);
      });
}

export function add_search(table){
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
  const initializeDeleteDiagnosis = _ => {
    $(document).on('click', '.remove_diagnosis', function(e) {
      let id = $(this).attr('id')
      let row = $(`a[id="${id}"]`).closest('tr')
      let dt = $('#tbl_cdt').DataTable()
      dt.row(row)
        .remove()
        .draw()
    })
  }

function submit_diagnosis(rows, datas) {
  function removeDuplicateUsingFilter(arr){
    let unique_array = arr.filter(function(elem, index, self) {
      return index == self.indexOf(elem);
    })
    return unique_array
  }

  $('#btn_submit_diagnosis').unbind('click').click(function() {
    
    let is_all_selected = $('input[name="select_all"]').is(":checked")

    let checked_diagnosis = $('input[class="diagnosis_chkbx"]:checked')
    if(checked_diagnosis.length > 0){
      let submit_btn = $(this)
      submit_btn.html('<span class="ui active tiny centered inline loader"></span>')
      let dt = $('#tbl_cdt').DataTable();
      console.log(datas)
      $(removeDuplicateUsingFilter(datas)).each(function(x, y) {
        dt.row.add(y).draw(false)
      })
      $('.modal.diagnosis').modal('hide');
      $(document).unbind('change').on('change', '.ui.fluid.dropdown.inclusion', function(){
        let page = $(this).find($('.text')).html()
        var table = $('#tbl_cdt').DataTable();
        let no = parseInt(page) -1
        table.page( no ).draw( 'page' );
      })
      //         //dt.clear().draw()
      //         $('input[class="diagnosis_chkbx"]:checked').each(function() {
      //           dt.row.add([
      //             `<span class="green selected_diagnosis_id">${$(this).attr('code')}</span>`,
      //             `<strong>${$(this).attr('diagnosis_name')}</strong><br><small class="thin dim">${$(this).attr('description')}</small>`,
      //             // `${$(this).attr('diagnosis_type')}`,
      // `<a href="#!" id="${$(this).attr('diagnosis_id')}" class="remove_diagnosis"><u style="color: gray">Remove</u></a><input type="hidden" name="benefit[diagnosis_ids][]" value="${$(this).attr('diagnosis_id')}">`
      //           ]).draw(false)
      //         })
      //         $('.modal.diagnosis').modal('hide');

//       if (is_all_selected) {
//         let selected_diagnosis_ids = []

//         $('.selected_diagnosis_id').each(function() {
//           selected_diagnosis_ids.push($(this).text())
//         })

//         let diagnosis_ids = selected_diagnosis_ids.join(",")
//         let type = $('#diagnosis_type_dropdown').dropdown('get value')
//         $('#tbl_diagnosis').DataTable({
//           "destroy": true,
//           "ajax": $.fn.dataTable.dt_timeout(
//             `/web/benefits/load_all_diagnosis?diagnosis_ids=${diagnosis_ids}&type=${type}`,
//             csrf
//           ),
//           "deferRender": true,
//           "drawCallback": function (settings) {
//             submit_btn.html('Add')
//             $('.modal.diagnosis').modal('hide');
//           },
//           "deferRender": true
//         })
//         } else {
//         let dt = $('#tbl_diagnosis').DataTable();
//         //dt.clear().draw()
//         $('input[class="diagnosis_chkbx"]:checked').each(function() {
//           dt.row.add([
//             `<span class="green selected_diagnosis_id">${$(this).attr('code')}</span>`,
//             `<strong>${$(this).attr('diagnosis_name')}</strong><br><small class="thin dim">${$(this).attr('description')}</small>`,
//             // `${$(this).attr('diagnosis_type')}`,
// `<a href="#!" id="${$(this).attr('diagnosis_id')}" class="remove_diagnosis"><u style="color: gray">Remove</u></a><input type="hidden" name="benefit[diagnosis_ids][]" value="${$(this).attr('diagnosis_id')}">`
//           ]).draw(false)
//         })
//         $('.modal.diagnosis').modal('hide');
//         }

        $('input[name="is_valid_diagnosis"]').val("true")

      initializeDeleteDiagnosis()
    } else {
      alertify.error('<i class="close icon"></i>Please select at least one diagnosis')
    }
  })
}



