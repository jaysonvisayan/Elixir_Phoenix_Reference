onmount('div[id="product_edit_dental_plan"]', function () {

  $('#btn_add_edit_benefit').unbind('click').click(function () {
    $('#overlay').attr('style', ';height:100%;width:100%;z-index: 10;position:fixed')
    const csrf = $('input[name="_csrf_token"]').val();
    let selected_procedure_ids = []
    let selected_benefit_ids = []
    let selected_benefit_rows = []
    let selected_benefit_rows2 = []
    let rows_selected2 = []
    let selected_procedure_ids2 = []

    var table = $('#tbl_benefit_dt_table_edit').DataTable()
    var rows = table.rows({'search': 'applied'}).nodes();

    $('.selected_procedure_id', rows).each(function() {
      selected_procedure_ids.push($(this).text())
    })

    let procedure_ids = selected_procedure_ids.join(",")

    var rows_selected = [];
    var procedure_rows_selected = []
    var benefit_limit_rows_selected = []
    let datatable = $('#dt-dental-benefit')

    // Add Benefit Modal Datatable
    var table = datatable.DataTable({
      "serverSide": true,
      "lengthMenu": [
        [10, 50, 100, 500, 1000],
        [10, 50, 100, 500, 1000]
      ]  ,
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
            "<'left aligned three wide column test'>"+
            "<'right aligned two wide column inline field append-result'>"+
            "<'left aligned two wide column'l>"+
            "<'center aligned six wide column'p>"+
          ">"+
        ">",
      "ajax": {
        'url': '/web/products/load_dental_benefit',
        'type': "POST",
        'headers': {"X-CSRF-TOKEN": csrf},
        'data':
          function( d ) {
            d.procedure_ids = procedure_ids,
            d.selected_benefit_ids = removeDuplicateUsingFilter(selected_benefit_ids)
          },
        'dataType': 'json'
      },
      "renderer": 'semanticUI',
      "processing": true,
      "pagingType": "simple_numbers",
      "language": {
        "info": "_TOTAL_",
        "infoEmpty": "",
      },
      "drawCallback": function () {
        add_search(this)
        $('#overlay').attr('style', 'display: none')
            // Add Benefit Modal Show
        $('.modal.procedure').modal({
          autofocus: false,
          closable: false,
          observeChanges: true,
          onHide: function() {
            let table = $('#dt-dental-benefit').DataTable()
            table.destroy()
            $('#benefit_field').removeClass('error')
            $('#benefit_field').find('.prompt').remove()
          }
        }).modal('show')

        $('#clear-select-message').remove()
        var table = datatable.DataTable();
        var info = table.page.info();
        var id = 'dt-dental-benefit'
        var result = '.append-result'
        var jump ='jump'
        append_jump(id, result, jump)
        $('#option').val(info.pages)
        $('#page').val(info.page)
        $('#option').trigger('change')
        $('input[type="search"]').css("width", "250px")
        $('#btn_submit_benefit').remove()
        $('.test').append('<button class="approve left floated fluid ui primary big button" id="btn_submit_benefit" type="submit">Add</button>')

        // Select All Benefits
        $(document).on('click', '#select-all-benefits', function() {
          $.ajax({
            url:`/web/products/load_all_dental_benefit`,
            headers: {"X-CSRF-TOKEN": csrf},
            type: 'POST',
            data: {"benefit_ids" : procedure_ids, "selected_benefit_ids" : removeDuplicateUsingFilter(selected_benefit_ids)},
            dataType: 'json',
            success: function(response) {
              $.each(response.data, function(index, value){
                rows_selected.push(value.id)

                $.each(value.procedure_ids, function(x, y){
                  procedure_rows_selected.push(y)
                })

                $('#clear-select-message').remove()

                $('.dt-append').append(`<div class="ui attached message" id="clear-select-message" style="background-color: #fff8ea;"> \
                <p>All ${response.data.length} benefits are selected. <a id="clear-all-benefits"> <span class="green"> <u> Clear selection </u> </span> </a> \
                </p></div>`)
              })
            }
          })
        })

        // Clear Benefits
        $(document).on('click', '#clear-all-benefits', function() {
          rows_selected = []
          procedure_rows_selected = []
          selected_benefit_rows = []
          benefit_limit_rows_selected = []
          $('.procedure_chkbx').prop("checked", false)
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
        "info":           "_TOTAL_",
        "infoEmpty":      "",
        "emptyTable": "No Records Found!",
        "zeroRecords": "No results found",
        "lengthMenu": "Show: _MENU_",
        "paginate": {
            "previous": "<i class='angle single left icon'></i>",
            "next": "<i class='angle single right icon'></i>",
        }
      }
    });

  // Handle click on checkbox
  $('#dt-dental-benefit tbody').unbind('click').on('click', 'input[type="checkbox"]', function(e){
    var $row = $(this).closest('tr');
    var data = table.row($row).data();
    var rowId = $(data[0]).attr('id');
    var procedureId = $(data[0]).attr('procedure_ids');
    var firstColData = data[1];
    var res = firstColData.split('>')
    res = res[1].split('<')
    firstColData = res[0]

    var secondColData = data[2];
    var thirdColData = data[3];
    var fourthColData = data[4];
    var fifthColData = data[5];


    if(fourthColData == "Peso"){
      fifthColData = formatLimit(fifthColData);
    }
    var datas =
      [
        `<span class="${firstColData}" value="${rowId}"> ${firstColData} </span>`,
        `<span class="${firstColData}${secondColData}"> ${secondColData} </span>`,
        `<span class="${firstColData}${thirdColData}"> ${thirdColData} </span>`,
        `<span class="${firstColData}${fourthColData}"> ${fourthColData} </span>`,
        `<span class="${firstColData}${fifthColData}"> ${fifthColData} </span>`,
        `<div class="ui dropdown" tabindex="0">\
            <i class="ellipsis vertical icon"></i>\
            <div class="menu transition hidden">\
              <div class="item clickable-row edit_limit" data-href="#" \
                   style="color:#00B24F" \
                   benefit_id="${rowId}" \
                   code="${firstColData}" \
                   name="${secondColData}" \
                   limit_type="${fourthColData}" \
                   limit_amount="${fifthColData}" \
                   >Edit limit\
                <span class="selected_procedure_id hidden">${rowId}</span> \
                <span class="${firstColData}_ben_rows selected_ben_rows hidden">${rowId}|${fourthColData}|${fifthColData}</span> \
              </div>\
              <div class="item">\
               <a href="#" class="remove_package" role = "${rowId}" product_id="<%= product_benefit.product_id %>" product_benefit_id="<%= product_benefit.id %>"> Remove </a><span class="selected_procedure_id hidden">${rowId}</span>\
              </div>\
            </div>\
        </div>`
      ]

    var bl_values = `${rowId},${fourthColData},${fifthColData}`

    // Determine whether row ID is in the list of selected row IDs
    var index = $.inArray(rowId, rows_selected);
    var procedure_list = $.inArray(procedureId, procedure_rows_selected)
    var benefit_datas = $.inArray(datas, selected_benefit_rows)
    var benefilit_limit_datas = $.inArray(bl_values, benefit_limit_rows_selected)

    // If checkbox is checked and row ID is not in list of selected row IDs
    if(this.checked && index === -1){
      rows_selected.push(rowId);
      procedure_rows_selected.push(procedureId)
      selected_benefit_rows.push(datas)
      benefit_limit_rows_selected.push(bl_values)
      selected_benefit_rows2.push(rowId)
    // Otherwise, if checkbox is not checked and row ID is in list of selected row IDs
    } else if ((!this.checked && index !== -1 ) || (!this.checked && procedure_list !== -1 ) || (!this.checked && benefit_datas !== -1 ) || (!this.checked && bl_values !== -1 )) {
      $('#clear-select-message').remove()
      rows_selected = removeDuplicateUsingFilter(rows_selected)
      rows_selected.splice(index, 1);
      procedure_rows_selected.splice(procedure_list, 1)
      benefit_limit_rows_selected.splice(bl_values, 1)
      let haha = selected_benefit_rows2.indexOf(rowId)
      selected_benefit_rows.splice(haha, 1)
      selected_benefit_rows2.splice(haha, 1)
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
  })

  // Handle click on table cells with checkboxes
  $('#dt-dental-benefit').on('click', 'tbody td, thead th:first-child', function(e){
      $(this).parent().find('label[type="text"]').trigger('click');
  });

  // Handle click on "Select all" control
  $('thead input[name="select_all"]', table.table().container()).on('click', function(e){
    let selected_benefit_count_start = datatable.DataTable().page.info().start;
    let selected_benefit_count_end = datatable.DataTable().page.info().end;
    let selected_benefit_count = selected_benefit_count_end - selected_benefit_count_start
    let total_count = datatable.DataTable().page.info().recordsTotal;

    if(this.checked){
      $('#clear-select-message').remove()
      $('.dt-append').append(`<div class="ui attached message" id="clear-select-message" style="background-color: #fff8ea;"> \
      <p>All ${selected_benefit_count} benefits on this \
      page are selected <a id="select-all-benefits"> <span class="green"> <u> Select \
      all ${total_count} benefits </u> </span> </a> \
      </p></div>`)

      $('#dt-dental-benefit tbody input[type="checkbox"]:not(:checked)').trigger('click');
    } else {
      $('#clear-select-message').remove()
      $('#dt-dental-benefit tbody input[type="checkbox"]:checked').trigger('click');

    }

  e.stopPropagation();
  });

  // Handle table draw event
  table.on('draw', function(){
    updateDataTableSelectAllCtrl(table); // Update state of "Select all" control
  });

  // Add Benefit
  $(document).unbind('click').on('click', '#btn_submit_benefit', function() {
    const csrf = $('input[name="_csrf_token"]').val();
    let checked_procedure = $('input[class="procedure_chkbx"]:checked')

    if(rows_selected.length > 0){
      let dt = $('#tbl_benefit_dt_table_edit').DataTable();
      $.ajax({
        url:`/web/products/compare_procedure_ids`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'POST',
        data: {"procedure_ids" : procedure_rows_selected},
        dataType: 'json',
        success: function(response) {
          if(response === "true")
            {
              $.ajax({
                url:`/web/products/load_all_selected_dental_benefit`,
                headers: {"X-CSRF-TOKEN": csrf},
                type: 'POST',
                data: {"benefit_ids" : rows_selected},
                dataType: 'json',
                success: function(response) {
                  swal({

                    type: 'warning',
                    title: 'Oops!',
                    html:
                      '<span> It seems like you have selected benefits which includes the same CDT/s. Please select benefit. </span' +
                      '<br>' +
                      '<br>' +
                      '<br>' +
                      '<div class="right aligned one wide column inline field">' +
                      '</div>',
                    showCancelButton: false,
                    width: '50rem',
                    heightAuto: true
                  })
                }
              })
            }
          else
            {
              $(selected_benefit_rows).each(function(x, y) {
                dt.row.add(y).draw(false)
              })

              $('.modal.procedure').modal('hide');
              $('input[name="is_valid_procedure"]').val("true")
              $('.ui.dropdown').dropdown();

              $('.edit_limit').click(function() {
                let benefit_id = $(this).attr("benefit_id")
                let b_code = $(this).attr("code")
                let b_name = $(this).attr("name")
                let limit_type = $(this).attr("limit_type")
                let limit_amount = $(this).attr("limit_amount")

                let ben_code = $(`span[class="${b_code}"]`).text()
                let ben_name = $(`span[class="${b_code}${b_name}"]`).text()
                let ben_limit_type = $(`span[class="${b_code}${limit_type}"]`).text().trim()
                let ben_limit_amount = $(`span[class="${b_code}${limit_amount}"]`).text().trim()
                ben_limit_amount = ben_limit_amount.replace(/,/g,"")

                $('text[id="dntl_code"]').text(b_code);
                $('#dntl_name').text(b_name);
                $("input[id='h_limit_type']").val(ben_limit_type);
                $("select[id='limit_type'] option:selected").val(ben_limit_type).change();
                $('input[name="limit_amount"]').val(ben_limit_amount);
                $('input[id="h_limit_amount"]').val(ben_limit_amount);
                $('.modal.limit').modal({
                    autofocus: false,
                    closable: false,
                    observeChanges: true,
                    selector: {
                      deny: '.deny.button',
                      approve: '.approve.button'
                    },
                    onApprove: () => {
                      let updated_limit_amount = $('input[name="limit_amount"]').val().replace(/,/g,"");
                      if (updated_limit_amount == "") {
                        $('#limit_form')
                        .form({
                          inline : true,
                          on: 'blur',
                          fields: {
                            'limit_amount': {
                              identifier: 'limit_amount',
                              rules: [
                                {
                                  type: 'empty',
                                  prompt: 'Please enter a limit'
                                }
                              ]
                            }
                          }
                        }).submit()
                        return false
                      } else {
                        $(`span[class="${b_code}${limit_amount}"]`).text("")
                        $(`span[class="${b_code}${limit_type}"]`).text("")
                        $(`span[class="${b_code}_ben_rows selected_ben_rows hidden"]`).val("")

                        let updated_limit_type = $("select[name='limit_type'] option:selected").val();


                      if(updated_limit_type == "Peso"){
                        updated_limit_amount = formatLimit(updated_limit_amount);
                      }
                        $(`span[class="${b_code}${limit_amount}"]`).text(updated_limit_amount)
                        $(`span[class="${b_code}${limit_type}"]`).text(updated_limit_type)
                        $(`span[class="${b_code}_ben_rows selected_ben_rows hidden"]`).text(`${benefit_id}|${updated_limit_type}|${updated_limit_amount}`)
            $(".edit_limit").attr("limit_amount", updated_limit_amount)
                      }
                      }
                    }).modal('show')
                  })

                  $('.remove_package').click(function() {
                    let dt = $('#tbl_benefit_dt_table_edit').DataTable();
                    let row = $(this).closest('tr')

                    remove_row($(this), dt, row)
                  })

                    let table = $('#dt-dental-benefit').DataTable()
                    table.destroy()

                    selected_procedure_ids = [];
                    selected_benefit_ids = [];
                    selected_benefit_rows = [];
                    selected_procedure_ids2 = [];
                  }
                }})
            } else {
              alertify.error('<i class="close icon"></i>Please select at least one Benefit.')
            }
          })
       })

      $('.edit_limit').click(function() {
        let benefit_id = $(this).attr("benefit_id")
        let b_code = $(this).attr("code")
        let b_name = $(this).attr("name")
        let limit_type = $(this).attr("limit_type")
        let limit_amount = $(this).attr("limit_amount")

        let ben_code = $(`span[class="${b_code}"]`).text()
      let ben_name = $(`span[class="${b_code}${b_name}"]`).text()
      let ben_limit_type = $(`span[class="${b_code}${limit_type}"]`).text().trim()
      let ben_limit_amount = $(`span[class="${b_code}${limit_amount}"]`).text().trim()
      ben_limit_amount = ben_limit_amount.replace(/,/g,"")

      $('text[id="dntl_code"]').text(b_code);
      $('#dntl_name').text(b_name);
      $("input[id='h_limit_type']").val(limit_type);
      $("select[id='limit_type']").val(ben_limit_type).change();
      $('input[name="limit_amount"]').val(ben_limit_amount);
      $('input[id="h_limit_amount"]').val(ben_limit_amount);
      $('.modal.limit').modal({
          autofocus: false,
          closable: false,
          observeChanges: true,
          selector: {
            deny: '.deny.button',
            approve: '.approve.button'
          },
          onApprove: () => {
                      let updated_limit_amount = $('input[name="limit_amount"]').val().replace(/,/g,"");
                      if (updated_limit_amount == "") {
                        $('#limit_form')
                        .form({
                          inline : true,
                          on: 'blur',
                          fields: {
                            'limit_amount': {
                              identifier: 'limit_amount',
                              rules: [
                                {
                                  type: 'empty',
                                  prompt: 'Please enter a limit'
                                }
                              ]
                            }
                          }
                        }).submit()
                        return false
                      } else {
                        $(`span[class="${b_code}${limit_amount}"]`).text("")
                        $(`span[class="${b_code}${limit_type}"]`).text("")
                        $(`span[class="${b_code}_ben_rows selected_ben_rows hidden"]`).val("")

                        let updated_limit_type = $("select[name='limit_type'] option:selected").val();


                      if(updated_limit_type == "Peso"){
                        updated_limit_amount = formatLimit(updated_limit_amount);
                      }
                        $(`span[class="${b_code}${limit_amount}"]`).text(updated_limit_amount)
                        $(`span[class="${b_code}${limit_type}"]`).text(updated_limit_type)
                        $(`span[class="${b_code}_ben_rows selected_ben_rows hidden"]`).text(`${benefit_id}|${updated_limit_type}|${updated_limit_amount}`)
            $(".edit_limit").attr("limit_amount", updated_limit_amount)
                      }
          }
        }).modal('show')
      })

      $('.remove_package').click(function() {
      let dt = $('#tbl_benefit_dt_table_edit').DataTable();
      let row = $(this).closest('tr')

      remove_row($(this), dt, row)
      })

  $('#dental_edit_form').form({
    on: 'blur',
    inline : true,
    fields: {
      'product[name]': {
        identifier: 'product[name]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter a name'
          }
        ]
      },
      'product[limit_applicability][]': {
        identifier: 'product[limit_applicability][]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please enter a limit applicability'
          }
        ]
      },
      'product[standard_product]': {
        identifier: 'product[standard_product]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please enter a plan classification'
          }
        ]
      },
      'product[benefit_ids][]': {
        identifier: 'product[benefit_ids][]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please choose atleast one benefit'
          }
        ]
      }
    }
  })


  $('#create_dental').click(function(){
  let selected_benefit_ids = []
  let selected_ben_rows = []
  let table = $('#tbl_benefit_dt_table_edit').DataTable()

  var rows = table.rows({'search': 'applied'}).nodes();
  $('.selected_ben_rows', rows).each(function(){
    selected_ben_rows.push($(this).text().replace(/,/g,"").replace(".00",""))
  })
  $('input[name="product[benefit_limit_datas][]"]').val(Array.from(new Set(selected_ben_rows)))

  $('.selected_procedure_id', rows).each(function() {
    selected_benefit_ids.push($(this).text())
  })
  $('input[name="product[benefit_ids][]"]').val(Array.from(new Set(selected_benefit_ids)))

    let validate_form = $('#dental_edit_form').form('validate form')
    if (validate_form){
      $('#dental_edit_form').submit()
    }
  })

  $('#option').on('change', function () {
    var pages = $('#option').val()
    var page = $('#page').val()
    var select = $('#jump')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
      if(parseInt(x) == parseInt(page) + 1){
        options.push(`<option value='${x}' selected>${x}</option>`)
      }
      else{
        options.push(`<option value='${x}'>${x}</option>`)
      }
    }
    select.append(String(options.join('')))
    select.dropdown('set selected', page + 1)
  })

  $('#option2').on('change', function () {
    var pages = $('#option2').val()
    var page = $('#page2').val()
    var select = $('#jump2')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
      if(parseInt(x) == parseInt(page) + 1){
        options.push(`<option value='${x}' selected>${x}</option>`)
      }
      else{
        options.push(`<option value='${x}'>${x}</option>`)
      }
    }
    select.append(String(options.join('')))
    select.dropdown('set selected', page + 1)
  })

  $(document).on('change', '#jump', function(){
    let datatable = $('#dt-dental-benefit')
    let page = $('#jump_search > div > div.text').html()
    var table = datatable.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  $(document).on('change', '#jump2', function(){
    let datatable = $('#tbl_benefit_dt_table_edit')
    let page = $('#jump2_search > div > div.text').html()
    var table = datatable.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

})

onmount('#tbl_benefit_dt_table_edit', function () {
  $('#tbl_benefit_dt_table_edit').dataTable({
    lengthMenu: [
      [10, 50, 100, 500, 1000],
      [10, 50, 100, 500, 1000]
    ]  ,
    dom:
    "<'ui grid'"+
      "<'row'"+
        "<'four wide column'f>"+
        "<'left aligned twelve wide column'i>"+
      ">"+
      "<'row'"+
        "<'center aligned sixteen wide column'>"+
      ">"+
      "<'row dt-table'"+
        "<'sixteen wide column'tr>"+
      ">"+
      "<'row'"+
        "<'two wide column inline field append-result2'>"+
        "<'seven wide column'l>"+
        "<'right aligned four wide column'p>"+
      ">"+
    ">",
    renderer: 'semanticUI',
    pagingType: "full_numbers",
    language: {
      emptyTable:     "No Records Found!",
      zeroRecords:    "No Records Found!",
      search:         "",
      info: "_TOTAL_",
      infoEmpty: "",
      paginate: {
            "previous": "<i class='angle single left icon'></i>",
            "next": "<i class='angle single right icon'></i>",
        }
    },
    'columns': [         // datatable excempt elipsis from searching
      null,
      null,
      null,
      null,
      null,
      { 'searchable': false }
    ],
    drawCallback: function () {
      var id='tbl_benefit_dt_table_edit'
      var result = '.append-result2'
      var jump ='jump2'
      var table = $(`#${id}`).DataTable();
      var info = table.page.info();
      append_jump(id, result, jump)
      add_search(this)
      $('#option2').val(info.pages)
       $('#page2').val(info.page)
      $('#option2').trigger('change')
    }
  })
})

function removeDuplicateUsingFilter(arr){
  let unique_array = arr.filter(function(elem, index, self) {
    return index == self.indexOf(elem);
  })
  return unique_array
}

// Updates "Select all" control in a data table
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

  $('td').unbind('click').one('click', function(){
    let i = $(this).find('input').attr('role')
    if (i == "disabled_checkbox") {
      alertify.error('<i class="close icon"></i>This benefit has the same CDT/s with an already added benefit.')
    }
  })

}

function append_jump(id, result, jump){
  let results = $(`#${id} >tbody >tr`).length

  $(".first.paginate_button, .last.paginate_button").hide()
  $(`${result}`).css("padding-top", "10px")
  $('.table > tbody  > tr').each(function(){
    $(this).attr('style', 'height:50px')
  })

  if(jump == 'jump'){

    $('.show').remove()
    if(results == 1){
      if($(`#${id} >tbody >tr >td.dataTables_empty`).length > 0){
        $(`${result}`).append(`<span class="show" > Showing 0 results</span>`)
      }
      else{
        $(`${result}`).append(`<span class="show" > Showing ${results} results</span>`)
      }
    }
    else{
      $(`${result}`).append(`<span class="show" > Showing ${results} results</span>`)
    }

    $('.jump').remove()
    $(`#${id}_paginate`).parent().parent().append(
    `<div class="right aligned two wide column jump inline field" style="padding-top:10px"> Jump to page: </div>\
    <div class="one wide column jump inline field" id="jump_search" style="padding-left:0px">\
      <div style="width:60px">\
        <select class="ui fluid search dropdown" id="jump">\
        </select>\
      </div>\
    </div>`
    )
  }
  else{
    $('.show2').remove()
    if(results == 1){
      if($(`#${id} >tbody >tr >td.dataTables_empty`).length > 0){
        $(`${result}`).append(`<span class="show2" > Showing 0 results</span>`)
      }
      else{
        $(`${result}`).append(`<span class="show2" > Showing ${results} results</span>`)
      }
    }
    else{
      $(`${result}`).append(`<span class="show2" > Showing ${results} results</span>`)
    }

    $('.jump2').remove()
    $(`#${id}_paginate`).parent().parent().append(
    `<div class="right aligned two wide column jump2 inline field" style="padding-top:10px"> Jump to page: </div>\
    <div class="one wide column jump2 inline field" id="jump2_search" style="padding-left:0px">\
      <div style="width:60px">\
        <select class="ui fluid search dropdown" id="jump2">\
        </select>\
      </div>\
    </div>`
    )
  }
}

function remove_row(row, dt, row2){
  let product_id = row.attr("product_benefit_id")
  let id = row.parent().find('span').html()
  const csrf = $('input[name="_csrf_token"]').val();
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
    if (count === 0)
    {
      alertify.error('<i class="close icon"></i>Cannot delete all benefit.')
    }
    else
    {
      $.ajax({
          url: `/web/products/delete/${id}/${product_id}/product_benefit`,
          headers: {
            "X-CSRF-TOKEN": csrf
          },
          type: 'get',
          success: function(response) {
              dt.row(row2)
              .remove()
              .draw()

          var rows = dt.rows({'search': 'applied'}).nodes();

          $('.selected_procedure_id', rows).each(function() {
             if (row.text() == id) {
                row.remove()
             }
          })
          },
        error: function(err){
              dt.row(row2)
              .remove()
              .draw()

          var rows = dt.rows({'search': 'applied'}).nodes();

          $('.selected_procedure_id', rows).each(function() {
             if (row.text() == id) {
                row.remove()
             }
          })
        }
        })
    }
  })
}

function add_search(table){
  let id = table[0].getAttribute("id")
  let value = $(`#${id}_filter`).val()
  let results = $(`#${id} >tbody >tr`).length
  let total = $(`#${id}_info`).html()

  if(results == 1){
    if($(`#${id} >tbody >tr >td.dataTables_empty`).length > 0){
      $(`#${id}_info`).html(`Showing 0 out of 0 ${total} results`)
    }
    else{
      $(`#${id}_info`).html(`Showing ${results} out of ${total} results`)
    }
  }
  else{
    $(`#${id}_info`).html(`Showing ${results} out of ${total} results`)
  }

  if(value != 1){
    $(`#${id}_filter`).addClass('ui left icon input')
    $(`#${id}_filter`).find('label').after('<i class="search icon"></i>')
    $(`#${id}_filter`).find('input[type="search"]').unwrap()
    $(`#${id}_filter`).find('input[type="search"]').attr("placeholder", `Search`)
    $(`#${id}_filter`).find('input[type="search"]').append(`</div>`)
    $(`#${id}_filter`).val(1)
  }
}

function formatLimit(n){
    var c = isNaN(c = Math.abs(c)) ? 2 : c,
    d = d == undefined ? "." : d,
    t = t == undefined ? "," : t,
    s = n < 0 ? "-" : "",
    i = String(parseInt(n = Math.abs(Number(n) || 0).toFixed(c))),
    j = (j = i.length) > 3 ? j % 3 : 0;

    return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
}
