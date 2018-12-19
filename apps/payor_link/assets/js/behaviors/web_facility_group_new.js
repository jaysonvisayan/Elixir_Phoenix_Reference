onmount('div[id="new_facility_group_id"]', function(){
  let main_datatable = $('#tbl_add_facility')
  let csrf = $('input[name="_csrf_token"]').val();

  let selected_table = $('#selected_facility_tbl').DataTable({
    "dom":
      "<'ui grid'"+
      "<'row'"+
      "<'two wide column'f>"+
      "<'eight wide column'i>"+
      ">"+
      "<'row dt-table'"+
      "<'sixteen wide column'tr>"+
      ">"+
      "<'row'"+
      "<'right aligned ten wide column'l>"+
      "<'right aligned four wide column'p>"+
      ">"+
      ">",
    "renderer": 'semanticUI',
    "pagingType": "full_numbers",
    "language": {
      "emptyTable":     "No results found.",
      "zeroRecords":    "No results found.",
      "info": "Showing _END_ out of _TOTAL_ results",
      "infoEmpty": "Showing 0 out of 0 result",
      "lengthMenu": "Show: _MENU_",
      "search":         "",
      "paginate": {
        "previous": "<i class='angle single left icon'></i>",
        "next": "<i class='angle single right icon'></i>",
      }
    },
    "drawCallback": function () {
      var table = $('#selected_facility_tbl').DataTable();
      var info = table.page.info();
      append_jump2(info.page, info.pages)
      add_search(this)
    }
  })

  $('input[name="location_group[selecting_type]"]').change(function () {
    if ($(this).val() == "Facilities"){
      $(`#facility_fields`).removeClass('hidden')
      $(`#facility-location-group`).addClass('hidden')
      $(`#region-validation`).addClass('hidden')

      $("#region-container :input").attr("disabled", true); // disabling form field from region_container
      $("#facility_fields :input").attr("disabled", false); // enabling form field from facility_fields (container)
      $('#region-container input:checkbox').prop('checked', false); // to clear checkbox if you decided to change type

      $('#selected_facility_tbl_info').css("margin-left", "100px")

      $('#region-container').find('.prompt').remove() // clears error prompt at onchange of type

      // removing error prompt in all of checkboxes
      $('#facility-location-group').find('.inline.field').each(function(){
        $(this).removeClass('error')
      })
    }
    else {
      $(`#facility_fields`).addClass('hidden')
      $(`#facility-location-group`).removeClass('hidden')
      $(`#region-validation`).removeClass('hidden')

      $("#facility_fields :input").attr("disabled", true); // disabling form field from facility container
      $("#region-container :input").attr("disabled", false); // enabling form field from facility fields

      //////////////////////////////////////////////////////// clearing of all datatable row
      selected_table.clear().draw()
      /////////////////////////////////////////////////////// also deleting all of hidden ids
      $('.hidden_ids').each(function(index, val){
        $(this).remove()
      })

      // reattach function of checkall region ////////////////////////////////////////////////
      $('input[id="LUZON"]').on('change', function(){
        if($(this).is(':checked')) {
          $('div[id="LUZON"]').find('input').each(function(){
            $(this).prop('checked', true)
          })
        } else {
          $('div[id="LUZON"]').find('input').each(function(){
            $(this).prop('checked', false)
          })
        }
      })

      $('input[id="VISAYAS"]').on('change', function(){
        if($(this).is(':checked')) {
          $('div[id="VISAYAS"]').find('input').each(function(){
            $(this).prop('checked', true)
          })
        } else {
          $('div[id="VISAYAS"]').find('input').each(function(){
            $(this).prop('checked', false)
          })
        }
      })

      $('input[id="MINDANAO"]').on('change', function(){
        if($(this).is(':checked')) {
          $('div[id="MINDANAO"]').find('input').each(function(){
            $(this).prop('checked', true)
          })
        } else {
          $('div[id="MINDANAO"]').find('input').each(function(){
            $(this).prop('checked', false)
          })
        }
      })

      $('#facility_fields').find('.prompt').remove() // clears error prompt at onchange of type
    }

  })

  $('#btn_add_facility').click(function () {
    initializeFacilityTbl()
    load_facility_table([])
    initializeDeleteFacilities()
  })

  // for deleting of selected facility
  const initializeDeleteFacilities = _ => {
    $(document).unbind('click').on('click', '.remove_facility', function() {
      let deleted_value = $(this).attr('facility_id')
      $('.hidden_ids').each(function(index, val){
        if ($(this).val() == deleted_value){
          $(this).remove()
        }
      })
      let row = $(this).closest('tr')
      let dt = $('#selected_facility_tbl').DataTable()
      dt.row(row)
      .remove()
      .draw()
    })
  }

  const initializeFacilityTbl = _ => {
    $('.modal.facility_group').modal({
      onHide: function(){
        let table = $('#tbl_add_facility').DataTable()
        table.destroy()
        selected_table.draw()
      },
      autofocus: false,
      centered: false,
      observeChanges: true
    }).modal('show');

    $('#btn_cancel_facility').click(function() {
      $('.modal.facility_group').modal('hide');
      let table = $('#tbl_add_facility').DataTable()
      table.destroy()
    })
  }

  // get ajax facility
  const load_facility_table = facility_ids => {
    var selected_facility_ids = []

    $('.hidden_ids').each(function(index, val){
      selected_facility_ids.push($(this).val())
    })

    // secret ingredients
    var rows_selected = [];
    var table = $('#tbl_add_facility').DataTable({
      "drawCallback": function () {
        var table = main_datatable.DataTable();
        var info = table.page.info();
        append_jump(info.page, info.pages)
        add_search(this)
      },
      "renderer": 'semanticUI',
      "pagingType": "full_numbers",
      "language": {
        "emptyTable":     "No results found.",
        "zeroRecords":    "No results found.",
        "info": "Showing _END_ out of _TOTAL_ results",
        "infoEmpty": "Showing 0 out of 0 result",
        "lengthMenu": "Show: _MENU_",
        "search":         "",
        "paginate": {
          "previous": "<i class='angle single left icon'></i>",
          "next": "<i class='angle single right icon'></i>",
        }
      },
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
        "<'left aligned one wide column test'>"+
        "<'center aligned five wide column'l>"+
        "<'left aligned eight wide column'p>"+
        ">"+
        ">",
      'processing': true,
      'serverSide': true,
      'ajax': {
        'url': '/web/facility_groups/load_facilities',
        'type': "POST",
        'headers': {"X-CSRF-TOKEN": csrf},
        'data':
          function( d ) {
          d.facility_ids = selected_facility_ids;
        },
        'dataType': 'json'
      },
      'columnDefs': [{
        'targets': 0,
        'searchable': false,
        'orderable': false,
        'width': '1%',
        'className': 'dt-body-center',
        'render': function (data, type, full, meta){
          return '<input type="checkbox" style="width:20px; height:20px">';
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
      }
    });

    // Handle click on checkbox
    // secret ingredients
    let data_2 = []
    $('#tbl_add_facility tbody').on('click', 'input[type="checkbox"]', function(e){
      var $row = $(this).closest('tr');

      // Get row data
      var data = table.row($row).data();

      // Get row ID
      var rowId = data[0];

      // Determine whether row ID is in the list of selected row IDs
      var index = $.inArray(rowId, rows_selected);

      // If checkbox is checked and row ID is not in list of selected row IDs
      if(this.checked && index === -1){
        rows_selected.push(rowId);
        data_2.push(data);

        // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
      } else if (!this.checked && index !== -1){
        rows_selected.splice(index, 1);
        data_2.splice(index, 1);
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
    $('#tbl_add_facility').on('click', 'tbody td, thead th:first-child', function(e){
      $(this).parent().find('input[type="checkbox"]').trigger('click');
    });

    // Handle click on "Select all" control
    $('thead input[name="select_all"]', table.table().container()).on('click', function(e){
      if(this.checked){
        $('#tbl_add_facility tbody input[type="checkbox"]:not(:checked)').trigger('click');
      } else {
        $('#tbl_add_facility tbody input[type="checkbox"]:checked').trigger('click');
      }

      // Prevent click event from propagating to parent
      e.stopPropagation();
    });

    // Handle table draw event
    table.on('draw', function(){
      // Update state of "Select all" control
      updateDataTableSelectAllCtrl(table);
    });

    // btn submit
    $('#btn_submit_facilityv2').unbind('click').click(function(){

      if($('#tbl_add_facility tbody input[type="checkbox"]:checked').length == 0){
        alertify.error('Select atleast one (1) facility')
      }
      else{
        $.each(rows_selected, function(index, rowId){
          // Create a hidden element
          $('#hidden-container').append(
            $('<input>')
            .attr('type', 'hidden')
            .attr('name', 'location_group[facility_ids][]')
            .attr('class', 'hidden_ids')
            .val(rowId)
          );
        });

        $('.modal.facility_group').modal({
          onHide: function(){
            let modal_table = $('#tbl_add_facility').DataTable()

            $.each(data_2, function(index, value){
              selected_table.row.add([
                `<span class="green selected_facility_id" facility_id="${value[0]}">${value[1]}</span>`,
                  `<b>${value[2]}</b>`,
                value[3],
                `<a class="remove_facility" style="color: gray; !important" facility_id="${value[0]}">Remove</a>`
              ]).draw('false')
            })
            rows_selected.length = 0
            data_2.length = 0
            modal_table.destroy()
          }
        }).modal('hide')
      }

    })


  }

  const updateDataTableSelectAllCtrl = table => {
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

  function append_jump(page, pages){
    // console.log([pages, page])
    let results = $('select[name="tbl_add_facility_length"]').val()
    $('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    $(".first.paginate_button, .last.paginate_button").hide()
    $('.one.wide').remove()
    $('.two.wide.test').remove()
    $('.show').remove()
    $('#tbl_add_facility_length').find('label').before(`<span class="show" style="margin-right:10px"> Showing ${results} results</span>`)
    $('#tbl_add_facility_wrapper').find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
    $('#tbl_add_facility_wrapper').find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
      `<div class="right aligned one wide column inline field"> Jump to page: </div>\
        <div class="right aligned two wide test column inline field">\
        <select class="ui fluid search dropdown" id="jump">\
        </select>\
        </div>`
    )
    var select = $('#jump')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
      options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
    $('#tbl_add_facility_wrapper').find('.ui.fluid.search.dropdown').dropdown()
    $('#jump').dropdown('set selected', page + 1)

    $(document).find('input[class="search"]').keypress(function(evt) {
      evt = (evt) ? evt : window.event
      var charCode = (evt.which) ? evt.which : evt.keyCode
      console.log(charCode)
      if (charCode == 8) {
        return true
      } else if (charCode == 46) {
        return false
      } else if (charCode == 37) {
        return false
      }  else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
        return false
      } else if (this.value.length == 0 && evt.which == 48) {
        return false
      } else if (parseInt(this.value + String.fromCharCode(charCode)) > pages){
        return false
      }
      return true
    })
  }

  function append_jump2(page, pages){
    let results = $('select[name="selected_facility_tbl_length"]').val()
    $('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    $(".first.paginate_button, .last.paginate_button").hide()
    $('.one.wide').remove()
    $('.show').remove()
    $('#selected_facility_tbl_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
    $('#selected_facility_tbl_wrapper').find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
    $('#selected_facility_tbl_wrapper').find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
      `<div class="right aligned one wide column inline field"> Jump to page: </div>\
        <div class="right aligned one wide column inline field">\
        <select class="ui fluid search dropdown" id="jump2">\
        </select>\
        </div>`
    )
    var select = $('#jump2')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
      options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
    $('.ui.fluid.search.dropdown').dropdown()
    $('#jump2').dropdown('set selected', page + 1)

    $(document).find('input[class="search"]').keypress(function(evt) {
      evt = (evt) ? evt : window.event
      var charCode = (evt.which) ? evt.which : evt.keyCode
      console.log(charCode)
      if (charCode == 8) {
        return true
      } else if (charCode == 46) {
        return false
      } else if (charCode == 37) {
        return false
      }  else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
        return false
      } else if (this.value.length == 0 && evt.which == 48) {
        return false
      } else if (parseInt(this.value + String.fromCharCode(charCode)) > pages){
        return false
      }
      return true
    })
  }

  $(document).on('change', '#tbl_add_facility_wrapper > div > div:nth-child(4) > div.right.aligned.two.wide.test.column.inline.field > div', function(){
    let table = $('#tbl_add_facility').DataTable()
    let page = $(this).find($('.text')).html()
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  $(document).on('change', '#selected_facility_tbl_wrapper > div > div:nth-child(3) > div:nth-child(4) > div', function(){
    let table = $('#selected_facility_tbl').DataTable()
    let page = $(this).find($('.text')).html()
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

}) //End of ONMOUNT 'div[id="new_facility_group_id"]'

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
