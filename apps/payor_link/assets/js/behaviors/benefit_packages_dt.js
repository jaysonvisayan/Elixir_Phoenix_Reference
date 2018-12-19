export function BenefitPackageDatatable(table, benefit_id, csrf) {
let datatable_package = table
let ajax2 = `/web/benefits/${benefit_id}/load_benefit_packages?id=${benefit_id}`

  datatable_package.DataTable({
    "dom":
      "<'ui grid'"+
        "<'row'"+
          "<'five wide column'f>"+
          "<'eight wide column'>"+
        ">"+
        "<'row dt-table'"+
          "<'sixteen wide column'tr>"+
        "<'right aligned ten wide column'>"+
        "<'right aligned four wide column'>"+
        ">"+
        "<'row'"+
          "<'right aligned eight wide column'l>"+
          "<'right aligned three wide column pagination'p>"+
        ">"+
      ">",
    "ajax": {
      "url": ajax2,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "renderer": 'semanticUI',
    "pagingType": "full_numbers",
    "language": {
      "emptyTable":     "No Benefit Package Records",
      "zeroRecords":    "No benefit package matched your search",
      "info": "Showing _END_ out of _MAX_ results",
      "infoFiltered": "",
      "infoEmpty": "Showing 0 out of _MAX_ result",
      "lengthMenu": "Show: _MENU_",
      "search":         "",
      "paginate": {
        "previous": "<i class='angle single left icon'></i>",
        "next": "<i class='angle single right icon'></i>",
      }
    },
     "drawCallback": function () {
     $('input[type="search"]').css("width", "400px")
      var table = datatable_package.DataTable();
      var info = table.page.info();
      append_jump_package(info.page, info.pages)
      add_search(this)
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true
  });

  $(document).on('change', '.ui.fluid.search.dropdown.package', function(){
    let page = $(this).find($('.text')).html()
    var table = datatable_package.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  let package_search_id = $('#benefit_packages_dt2_wrapper')
  package_search_id.find('.dataTables_info').attr("style", "margin-left: 1rem;")
  package_search_id.find('.pagination').attr("style", "z-index: 100;")

  function append_jump_package(page, pages){
  let package_search_id = $('#benefit_packages_dt2_wrapper')
    let results;
    if (results = package_search_id.find('.table > tbody  > tr').html().includes("matched your search") || package_search_id.find('.table > tbody  > tr').html().includes("Found")) {
      results = 0
    }
    else {
      results = package_search_id.find('.table > tbody  > tr').length
    }
    package_search_id.find('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    package_search_id.find(".first.paginate_button, .last.paginate_button").hide()
    package_search_id.find('.one.wide').remove()
    package_search_id.find('.three.wide.column.inline.field').remove()
    package_search_id.find('.show').remove()
    package_search_id.find('#benefit_packages_dt2_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
    package_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
    package_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
    `<div style="line-height: 39px;" class="right aligned three wide column inline field"> Jump to page: </div>\
    <div class="right aligned one wide column inline field" id="jump_search">\
      <select class="ui fluid search dropdown package" id="jump_package">\
      </select>\
    </div>`
    )
    var select = $('#jump_package')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
       options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
    package_search_id.find('.ui.fluid.search.dropdown').dropdown()
    package_search_id.find('#jump_package').dropdown('set selected', page + 1)

    package_search_id.find(document).find('input[class="search"]').keypress(function(evt) {
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
}

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
