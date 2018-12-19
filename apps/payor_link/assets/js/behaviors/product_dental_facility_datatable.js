onmount('table[id="product_dental_facility_index"]', function() {
let product_id = $('#product_id').val()
let datatable = $('#product_dental_facility_index')
let ajax = `/web/products/dental_facility_index/data?product_id=${product_id}`

  const csrf = $('input[name="_csrf_token"]').val();
  datatable.DataTable({
    "dom":
      "<'ui grid'"+
        "<'row'"+
          "<'three wide column'f>"+
          "<'eight wide column'i>"+
        ">"+
        "<'row dt-table'"+
          "<'sixteen wide column'tr>"+
        ">"+
        "<'row'"+
          "<'six wide column'l>"+
          "<'right aligned six wide column'p>"+
        ">"+
      ">",
    "ajax": {
      "url": ajax,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "renderer": 'semanticUI',
    "pagingType": "full_numbers",
    "language": {
      "emptyTable":     "No records found",
      "zeroRecords":    "No records found",
      "info": "_TOTAL_",
      "infoEmpty": "",
      "lengthMenu": "Show: _MENU_",
      "search": "",
      "paginate": {
        "previous": "<i class='angle single left icon'></i>",
        "next": "<i class='angle single right icon'></i>",
      }
    },
     "drawCallback": function () {
      add_search(this)
      var table = datatable.DataTable();
      var info = table.page.info();
      if(info.recordsTotal != 0){
        append_jump(info.page, info.pages)
      }
      else
      {
        remove_datatable()
      }
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true
  });

  function append_jump(page, pages){
    let results = $(`#product_dental_facility_index >tbody >tr`).length
    $('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    $('#product_dental_facility_index_first').hide()
    $('#product_dental_facility_index_last').hide()
    $('#one_wide_facility').remove()
    $('#jump2_page').remove()
    $('#jump2_search').remove()
    $('#show2').remove()
    $('#product_dental_facility_index_length').find('label').before(`<span id="show2" style="margin-right:30px"> Showing ${results} results</span>`)
    $("#product_dental_facility_index_paginate").parent().parent().append(
    `<div class="one wide column inline field" id="one_wide_facility"> </div>\
     <div class="right aligned two wide column inline field" id="jump2_page" style="padding-top:10px"> Jump to page: </div>\
    <div class="right aligned one wide column inline field" id="jump2_search" style="width:60px; padding-left:0px">\
      <div style="width:60px">\
        <select id="jump2" class="ui fluid search dropdown" style="width:60px">\
        </select>\
      </div>\
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

  $(document).on('change', '#jump2', function(){
    let page = $('#jump2_search > div > div > div.text').html()
    var table = datatable.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  function remove_datatable(){
    $('#product_dental_facility_index_info').hide()
    $('#product_dental_facility_index_paginate').hide()
    $('#product_dental_facility_index_length').hide()
  }

})

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
    $(`#${id}_filter`).find('input[type="search"]').attr("placeholder", `Search Facility`)
    $(`#${id}_filter`).find('input[type="search"]').append(`</div>`)
    $(`#${id}_filter`).val(1)
  }
}