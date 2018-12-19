let benefit_id = $('input[name="benefit[id]"]').val()

onmount('div[id="benefit_limit_dt"]', function() {
let datatable_limit = $('#benefit_limit_coverages_dt')
let ajax2 = `${benefit_id}/load_benefit_limit?id=${benefit_id}`

  const csrf = $('input[name="_csrf_token"]').val();
  datatable_limit.DataTable({
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
    "ajax": {
      "url": ajax2,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "renderer": 'semanticUI',
    "pagingType": "full_numbers",
    "language": {
      "emptyTable":     "No Benefit Limit Records",
      "zeroRecords":    "No benefit limit matched your search",
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
      var table = datatable_limit.DataTable();
      var info = table.page.info();
      append_jump_limit(info.page, info.pages)
      add_search(this)
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true
  });

  $(document).on('change', '.ui.fluid.search.dropdown.limit', function(){
    let page = $(this).find($('.text')).html()
    var table = datatable_limit.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  let limit_search_id = $('#benefit_limit_coverages_dt_wrapper')
  limit_search_id.find('.dataTables_info').attr("style", "margin-left: 1rem;")

  function append_jump_limit(page, pages){
  let limit_search_id = $('#benefit_limit_coverages_dt_wrapper')
    let results = limit_search_id.find('select[name="benefit_limit_coverages_dt_length"]').val()
    limit_search_id.find('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    limit_search_id.find(".first.paginate_button, .last.paginate_button").hide()
    limit_search_id.find('.one.wide').remove()
    limit_search_id.find('.show').remove()
     limit_search_id.find('#benefit_limit_coverages_dt_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
     limit_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
     limit_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
    `<div class="right aligned one wide column inline field"> Jump to page: </div>\
    <div class="right aligned one wide column inline field" id="jump_search">\
      <select class="ui fluid search dropdown limit" id="jump_limit">\
      </select>\
    </div>`
    )
    var select = $('#jump_limit')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
       options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
     limit_search_id.find('.ui.fluid.search.dropdown').dropdown()
     limit_search_id.find('#jump_limit').dropdown('set selected', page + 1)

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

onmount('div[id="benefit_package_dt"]', function() {
let datatable_package = $('#benefit_packages_dt')
let ajax2 = `${benefit_id}/load_benefit_packages?id=${benefit_id}`

  const csrf = $('input[name="_csrf_token"]').val();
  datatable_package.DataTable({
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
      "info": "Showing _END_ out of _TOTAL_ results",
      "lengthMenu": "Show: _MENU_",
      "search":         "",
      "paginate": {
        "previous": "<i class='angle single left icon'></i>",
        "next": "<i class='angle single right icon'></i>",
      }
    },
     "drawCallback": function () {
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

  let package_search_id = $('#benefit_packages_dt_wrapper')
  package_search_id.find('.dataTables_info').attr("style", "margin-left: 1rem;")

  function append_jump_package(page, pages){
  let package_search_id = $('#benefit_packages_dt_wrapper')
    let results = package_search_id.find('select[name="benefit_packages_dt_length"]').val()
    package_search_id.find('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    package_search_id.find(".first.paginate_button, .last.paginate_button").hide()
    package_search_id.find('.one.wide').remove()
    package_search_id.find('.show').remove()
    package_search_id.find('#benefit_packagees_dt_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
    package_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
    package_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
    `<div class="right aligned one wide column inline field"> Jump to page: </div>\
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
