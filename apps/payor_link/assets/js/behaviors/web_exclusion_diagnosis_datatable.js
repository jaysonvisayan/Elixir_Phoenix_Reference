onmount('#main_exclusions', function() {
 let datatable_show = $('#diagnosis_tbl')
 let id = $('#exclusions_id').val()

  const csrf = $('input[name="_csrf_token"]').val();

  datatable_show.DataTable({
"dom":
  "<'ui grid'"+
    "<'row'"+
      "<'left aligned nine wide column'>"+
      "<'left aligned two wide column'i>"+
      "<'right aligned two wide column'>"+
      "<'right aligned three wide column'f>"+
    ">"+
    "<'row table'"+
      "<'sixteen wide column'tr>"+
    ">"+
    "<'row'"+
      "<'right aligned nine wide column'l>"+
      "<'right aligned four wide column'p>"+
    ">"+
  ">",
  "ajax": {
    "url": `/web/exclusions/${id}/show/load_diagnosis`,
    "type": "GET",
    "headers": {"X-CSRF-TOKEN": csrf},
  },
"renderer": 'semanticUI',
"pagingType": "full_numbers",
"language": {
  "emptyTable":     "No diagnois records",
  "zeroRecords":    "No diagnosis matched your search",
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
  var table = datatable_show.DataTable();
  var info = table.page.info();
  append_jump(info.page, info.pages)
  add_search(this)
},
  "processing": true,
  "deferRender": true,
  "serverSide": true
})

  $(document).on('change', '.ui.fluid.search.dropdown', function(){
    let page = $(this).find($('.text')).html()
    var table = datatable_show.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  function append_jump(page, pages){
    let results = $('select[name="diagnosis_tbl_length"]').val()
    $('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    $(".first.paginate_button, .last.paginate_button").hide()
    $('.one.wide').remove()
    $('.show').remove()
    $('#diagnosis_tbl_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
   $('#diagnosis_tbl_wrapper').find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
   $('#diagnosis_tbl_wrapper').find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
    `<div class="right aligned one wide column inline field"></div>\
    <div class="right aligned one wide column inline field"> Jump to page: </div>\
    <div class="right aligned one wide column inline field" id="jump_search">\
      <select class="ui fluid search dropdown" id="jump_to">\
      </select>\
    </div>`
    )
    var select = $('#jump_to')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
       options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
    $('#diagnosis_tbl_wrapper').find('.ui.fluid.search.dropdown').dropdown()
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
