export function load_tbl_cdt(_) {
  const acu_tbl_limit = $('#acu_tbl_limit').DataTable()
  const tbl_limit = $('#tbl_limit').DataTable()

  $('#tbl_cdt').DataTable({
   "dom":
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
          "<'left aligned two wide column dt-append-button'>"+
          "<'right aligned one wide column inline field'>"+
          "<'left aligned five wide column'l>"+
          "<'center aligned six wide column'p>"+
        ">"+
      ">",
      "destroy": true,
      "pagingType": "full_numbers",
      "language": {
        "emptyTable":     "No CDT found",
        "zeroRecords":    "No CDT matched your search",
        "info": "Showing _END_ out of _MAX_ results",
        "infoEmpty": "Showing 0 out of 0 result",
        "infoFiltered": "",
        "lengthMenu": "Show: _MENU_",
        "search":         "",
          "paginate": {
            "previous": "<i class='angle single left icon'></i>",
            "next": "<i class='angle single right icon'></i>",
          }
        },
        "drawCallback": function (settings) {
        var table = $('#tbl_cdt').DataTable();
        var info = table.page.info();
        append_jump_inclusion(info.page, info.pages)
        add_search(this)
        $('.modal.diagnosis').modal('hide');
        }
    })

    acu_tbl_limit
    .clear()
    .draw()

    tbl_limit
    .clear()
    .draw()

    let cdt3_search_id = $('#tbl_cdt_wrapper')

    cdt3_search_id.find('.dataTables_info').attr("style", "margin-left: 1rem;")

function append_jump_inclusion(page, pages) {
    let cdt3_search_id = $('#tbl_cdt_wrapper')
    let results;

    if (results = cdt3_search_id.find('.table > tbody  > tr').html().includes("matched your search") || cdt3_search_id.find('.table > tbody  > tr').html().includes("found")) {
      results = 0
    }
    else {
      results = cdt3_search_id.find('.table > tbody  > tr').length
    }
    cdt3_search_id.find('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    // $('#tbl_cdt_info').html(`Showing ${results} out of ${total} results`)
    cdt3_search_id.find('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    cdt3_search_id.find('.jump-to-page').remove()
    cdt3_search_id.find('.jtp-selection').remove()
    cdt3_search_id.find('.one.wide').remove()
    cdt3_search_id.find('.show').remove()
    cdt3_search_id.find('.append-result').append(`<span class="show" >Showing ${results} results</span>`)
    cdt3_search_id.find('#tbl_cdt_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
    cdt3_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
      `<div class="right aligned two wide column inline field jump-to-page" style="padding-top: 0.8rem;"> Jump to page: </div>\
        <div class="right aligned one wide column inline field jtp-selection">\
        <select class="ui fluid dropdown inclusion" id="jump">\
        </select>\
        </div>`
    )

    var select = $('#jump')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
      options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
    cdt3_search_id.find('.ui.fluid.dropdown').dropdown()
    cdt3_search_id.find('.ui.fluid.dropdown.selection').css("width", "6rem")
    cdt3_search_id.find('.ui.fluid.dropdown.selection').css("margin-left", "-1.2rem")

    cdt3_search_id.find('#jump').dropdown('set selected', page + 1)
  }

  $(document).unbind('change').on('change', '.ui.fluid.dropdown.inclusion', function(){
    let page = $(this).find($('.text')).html()
    var table = $('#tbl_cdt').DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })
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
