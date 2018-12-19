export function PreexistingCondition(table, dataSrc, token, data, url) {
   let dTable = '#' + table
   let tbl_length = dTable + '_length'
   let tbl_wrapper = dTable + '_wrapper'

  $(dTable).DataTable({
    "serverSide": true,
    "dom":
      "<'ui grid'"+
        "<'row hidden'"+
          // "<'left aligned nine wide column'>"+
          // "<'left aligned two wide column'i>"+
          // "<'right aligned two wide column'>"+
          // "<'right aligned three wide column'f>"+
          "<'two wide column'f>"+
          "<'eight wide column'i>"+
        ">"+
        "<'row dt-table'"+
          "<'sixteen wide column'tr>"+
        ">"+
        // "<'row'"+
        //   "<'right aligned nine wide column'l>"+
        //   "<'right aligned four wide column'p>"+
        // ">"+
      ">",
      "ajax": {
        "url": url,
        "type": "POST",
        "data": data,
        "beforeSend": function (request) {
          request.setRequestHeader("Authorization", `bearer ${token}`)
        }
      },
      "renderer": 'semanticUI',
      "pagingType": "full_numbers",
      "language": {
        "emptyTable": `No ${dataSrc} records`,
        "zeroRecords": `No ${dataSrc} matched your search`,
        "info": "Showing _START_ to _END_ out of _TOTAL_ results",
        "lengthMenu": "Show: _MENU_",
        "search":         "",
        "paginate": {
          "previous": "<i class='angle single left icon'></i>",
          "next": "<i class='angle single right icon'></i>",
        }
      },
      "drawCallback": function () {
        let checkTbl = $(dTable).html()

        if (checkTbl.includes(`No ${dataSrc} records`)) {
          $(`#${dataSrc}`).hide()
        }

        let principal = $('#condition_prin_tbl').html()
        let dependent = $('#condition_dep_tbl').html()

        if (principal.includes("No principal records") && dependent.includes("No dependent records")) {
          $('div[id="hide-condition"]').hide()
          $('h3[id="hide-condition"]').hide()
        }
      },
      "processing": true,
      "deferRender": true
  });

  $(document)
    .find(tbl_wrapper)
    .on('change', '.ui.fluid.search.dropdown', function(){
      let page = $(this).find($('.text')).html()
      let dt = $(dTable).DataTable();
      let no = parseInt(page) -1
      dt.page( no ).draw( 'page' );
    })

  $(tbl_wrapper)
    .find('.dataTables_filter')
    .addClass('ui left icon input')

  $(tbl_wrapper)
    .find('.dataTables_filter')
    .find('label')
    .after('<i class="search icon"></i>')

  $(tbl_wrapper)
    .find('.dataTables_filter')
    .find('input[type="search"]')
    .unwrap()

  $(tbl_wrapper)
    .find('.dataTables_filter')
    .find('input[type="search"]')
    .attr("placeholder", `Search`)

  $(tbl_wrapper)
    .find('.dataTables_filter')
    .find('input[type="search"]')
    .append(`</div>`)
}

export function PreexistingDiagnosis(table, dataSrc, token, data, url) {
   let dTable = '#' + table
   let tbl_length = dTable + '_length'
   let tbl_wrapper = dTable + '_wrapper'

  $(dTable).DataTable({
    "serverSide": true,
    "dom":
      "<'ui grid'"+
        "<'row'"+
          // "<'left aligned nine wide column'>"+
          // "<'left aligned two wide column'i>"+
          // "<'right aligned two wide column'>"+
          // "<'right aligned three wide column'f>"+
          "<'three wide column'f>"+
          "<'eight wide column'i>"+
        ">"+
        "<'row dt-table'"+
          "<'sixteen wide column'tr>"+
        ">"+
        "<'row'"+
          "<'right aligned nine wide column'l>"+
          "<'right aligned four wide column'p>"+
        ">"+
      ">",
      "ajax": {
        "url": url,
        "type": "POST",
        "data": data,
        "beforeSend": function (request) {
          request.setRequestHeader("Authorization", `bearer ${token}`)
        }
      },
      "renderer": 'semanticUI',
      "pagingType": "full_numbers",
      "language": {
        "emptyTable": `No ${dataSrc} records`,
        "zeroRecords": `No ${dataSrc} matched your search`,
     "info": "Showing _END_ out of _MAX_ results",
      "infoEmpty": "",
      "infoFiltered": "",
        "lengthMenu": "Show: _MENU_",
        "search":         "",
        "paginate": {
          "previous": "<i class='angle single left icon'></i>",
          "next": "<i class='angle single right icon'></i>",
        }
      },
      "drawCallback": function () {
        let dt = $(dTable).DataTable();
        let info = dt.page.info();
        append_jump(table, tbl_length, tbl_wrapper, info.page, info.pages)
        search()
      },
      "processing": true,
      "deferRender": true
  });

  $(document)
    .find(tbl_wrapper)
    .on('change', '.ui.fluid.search.dropdown', function(){
      let page = $(this).find($('.text')).html()
      let dt = $(dTable).DataTable();
      let no = parseInt(page) -1
      dt.page( no ).draw( 'page' );
    })

  $(tbl_wrapper)
    .find('.dataTables_filter')
    .addClass('ui left icon input')

  $(tbl_wrapper)
    .find('.dataTables_filter')
    .find('label')
    .after('<i class="search icon"></i>')

  $(tbl_wrapper)
    .find('.dataTables_filter')
    .find('input[type="search"]')
    .unwrap()

  $(tbl_wrapper)
    .find('.dataTables_filter')
    .find('input[type="search"]')
    .attr("placeholder", `Search`)

  $(tbl_wrapper)
    .find('.dataTables_filter')
    .find('input[type="search"]')
    .append(`</div>`)
}

export function append_jump(table, tbl_length, tbl_wrapper, page, pages){
  // let results = $(`select[name="${table + '_length'}"]`).val()

    let resulta2;
    let diagnosis_search_id = $('#diagnosis_tbl_wrapper')

    if (resulta2 = diagnosis_search_id.find('.table > tbody  > tr').html().includes("matched your search")) {
      resulta2 = 0
    }
    else {
      resulta2 = diagnosis_search_id.find('.table > tbody  > tr').length
    }

  let results = $(`#diagnosis_tbl >tbody >tr`).length
  let total = $(`#diagnosis_tbl_info`).html()

  // if(results == 1){
  //   if($(`#diagnosis_tbl >tbody >tr >td.dataTables_empty`).length > 0){
  //     $(`#diagnosis_tbl_info`).html(`Showing 0 out of 0 ${total} results`)
  //   }
  //   else{
  //     $(`#diagnosis_tbl_info`).html(`Showing ${results} out of ${total} results`)
  //   }
  // }
  // else{
  //   $(`#diagnosis_tbl_info`).html(`Showing ${results} out of ${total} results`)
  // }

  $('.table > tbody  > tr').each(function(){
    $(this).attr('style', 'height:50px')
  })

  $(tbl_wrapper)
    .find(".first.paginate_button, .last.paginate_button")
    .hide()

  $(tbl_wrapper)
    .find('.one.wide')
    .remove()

  $(tbl_wrapper)
    .find('#jump_to_page')
    .remove()

  $(tbl_wrapper)
    .find('.show')
    .remove()

  $(tbl_length)
    .find('label')
    .before(`<span class="show" style="margin-right:50px; color:#9b9b9b;"> Showing ${resulta2} results</span>`)

  $(tbl_wrapper)
    .find('#diagnosis_tbl_info')
    .attr('style', 'color:#9b9b9b;')

  $(tbl_wrapper)
    .find(".dataTables_paginate.paging_full_numbers")
    .parent()
    .parent()
    .attr('style', 'margin-left:100px')

  $(tbl_wrapper)
    .find(".dataTables_info")
    .parent()
    .attr('style', 'margin-left:30px')

  $(tbl_wrapper)
    .find("#jump_to_page")
    .attr('style', 'margin-left:-15px')

  $(tbl_wrapper)
    .find(".dataTables_paginate.paging_full_numbers")
    .parent()
    .parent()
    .append(
      `<div class="right aligned two wide column inline field" id="jump_to_page"> Jump to page: </div>\
       <div class="right aligned one wide column inline field" id="jump_search">\
        <select class="ui fluid search dropdown" id="jump_${table}">\
        </select>\
       </div>`)

  $(tbl_wrapper)
  .find("#jump_to_page")
  .attr('style', 'margin-left:-25px')

  let select = $(`#jump_${table}`)
  let options = []

  for(var x = 1; x < parseInt(pages) + 1; x++){
     options.push(`<option value='${x}'>${x}</option>`)
  }

  select.append(String(options.join('')))

  $(tbl_wrapper)
    .find('.ui.fluid.search.dropdown')
    .dropdown()

  $(tbl_wrapper)
    .find(`#jump_search > div > div.text`)
    .text(page + 1)

  $(tbl_wrapper)
    .find(`#jump_search`)
    .closest('div')
    .closest('div')
    .closest('div')
    .closest('div')
    .find(`div[data-value="1"]`)
    .removeClass("active selected")

  $(tbl_wrapper)
    .find(`#jump_search`)
    .closest('div')
    .closest('div')
    .closest('div')
    .closest('div')
    .find(`div[data-value="${page + 1}"]`)
    .addClass("active selected")
}

export function search() {
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
