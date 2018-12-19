onmount('#main_exclusions', function() {
let datatable = $('#condition_tbl')
let exclusions_id = $('#exclusions_id').val()

const csrf_token = $('input[name="_csrf_token"]').val();

  datatable.DataTable({
    "dom":
      "<'ui grid'"+
        "<'row'"+
          "<'left aligned nine wide column'>"+
          "<'left aligned two wide column'i>"+
          "<'right aligned two wide column'>"+
          "<'right aligned three wide column'f>"+
        ">"+
        "<'row dt-table'"+
          "<'sixteen wide column'tr>"+
        ">"+
        "<'row'"+
          "<'right aligned ten wide column'l>"+
          "<'right aligned four wide column'p>"+
        ">"+
      ">",
      "ajax": {
        "url": `/web/exclusions/${exclusions_id}/show/load_condition`,
        "type": "GET",
        "headers": {"X-CSRF-TOKEN": csrf_token},
      },
    "renderer": 'semanticUI',
    "pagingType": "full_numbers",
    "language": {
      "emptyTable":     "No post enrolled dependents",
      "zeroRecords":    "No post enrolled dependents  matched your search",
      "info": "Showing _START_ to _END_ out of _TOTAL_ results",
      "lengthMenu": "Show: _MENU_",
      "search":         "",
      "paginate": {
        "previous": "<i class='angle single left icon'></i>",
        "next": "<i class='angle single right icon'></i>",
      }
    },
      "drawCallback": function () {
      var table = datatable.DataTable();
      var info = table.page.info();
      append_jump(info.page, info.pages)
    },
      "processing": true,
      "deferRender": true,
      "serverSide": true
  })

  $(document).on('change', '.ui.fluid.search.dropdown', function(){
    let page_2 = $(this).find($('.text')).html()
    var table_2 = datatable.DataTable();
    let no_2 = parseInt(page_2) -1
    table_2.page( no_2 ).draw( 'page' );
  })

  function append_jump(page, pages){
    let results = $('select[name="condition_tbl_length"]').val()
    $('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    $(".first.paginate_button, .last.paginate_button").hide()
    $('.one.wide').remove()
    $('.show').remove()
    $('#condition_tbl_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
    $('#condition_tbl_wrapper').find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
    $('#condition_tbl_wrapper').find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
    `<div class="right aligned one wide column inline field"> Jump to page: </div>\
    <div class="right aligned one wide column inline field" id="jump_search">\
      <select class="ui fluid search dropdown" id="jump">\
      </select>\
    </div>`
    )
    var select_2 = $('#jump')
    var options_2 = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
       options_2.push(`<option value='${x}'>${x}</option>`)
    }
    select_2.append(String(options_2.join('')))
    $('#condition_tbl_wrapper').find('.ui.fluid.search.dropdown').dropdown()
    $('#jump').dropdown('set selected', page + 1)

    $(document).find('input[class="search"]').keypress(function(evt) {
        evt = (evt) ? evt : window.event
        var charCode = (evt.which) ? evt.which : evt.keyCode
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
