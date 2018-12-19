let benefit_id = $('input[name="benefit[id]"]').val()
onmount('#benefit_procedure_dt', function () {
let datatable_bprocedure = $('#benefit_procedures_dt')
let ajax_procedure = `/web/benefits/${benefit_id}/load_procedure_data?id=${benefit_id}`

  const csrf = $('input[name="_csrf_token"]').val();
  datatable_bprocedure.DataTable({
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
      "url": ajax_procedure,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "renderer": 'semanticUI',
    "pagingType": "full_numbers",
    "language": {
      "emptyTable":     "No CPT Found",
      "zeroRecords":    "No CPT matched your search",
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
      var table = datatable_bprocedure.DataTable();
      var info = table.page.info();
      append_jump_procedure(info.page, info.pages)
      add_search(this)
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true
  });

  $(document).on('change', '.ui.fluid.search.dropdown.procedure', function(){
    let page = $(this).find($('.text')).html()
    var table = datatable_bprocedure.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  let procedure_search_id = $('#benefit_procedures_dt_wrapper')

  procedure_search_id.find('.dataTables_info').attr("style", "margin-left: 1rem;")


  function append_jump_procedure(page, pages){
    let procedure_search_id = $('#benefit_procedures_dt_wrapper')
    let results = $('select[name="benefit_procedures_dt_length"]').val()
    procedure_search_id.find('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    procedure_search_id.find(".first.paginate_button, .last.paginate_button").hide()
    procedure_search_id.find('.one.wide').remove()
    procedure_search_id.find('.show').remove()
    procedure_search_id.find('#benefit_procedures_dt_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
    procedure_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
    procedure_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
    `<div class="right aligned one wide column inline field"> Jump to page: </div>\
    <div class="right aligned one wide column inline field" id="jump_search">\
      <select class="ui fluid search dropdown procedure" id="jump_procedure">\
      </select>\
    </div>`
    )
    var select = $('#jump_procedure')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
       options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
    procedure_search_id.find('.ui.fluid.search.dropdown').dropdown()
    procedure_search_id.find('#jump_procedure').dropdown('set selected', page + 1)

    procedure_search_id.find(document).find('input[class="search"]').keypress(function(evt) {
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

onmount('#benefit_diagnosis_dt', function () {
let datatable_bdiagnosis = $('#benefit_diagnoses_dt')
let ajax_diagnosis = `/web/benefits/${benefit_id}/load_diagnosis_data?id=${benefit_id}`

  const csrf = $('input[name="_csrf_token"]').val();
  datatable_bdiagnosis.DataTable({
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
      "url": ajax_diagnosis,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "renderer": 'semanticUI',
    "pagingType": "full_numbers",
    "language": {
      "emptyTable":     "No Diagnosis Found",
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
      var table = datatable_bdiagnosis.DataTable();
      var info = table.page.info();
      append_jump_diagnosis(info.page, info.pages)
      add_search(this)
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true
  });

  $(document).on('change', '.ui.fluid.search.dropdown.diagnosis', function(){
    let page = $(this).find($('.text')).html()
    var table = datatable_bdiagnosis.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  let diagnosis_search_id = $('#benefit_diagnoses_dt_wrapper')

  diagnosis_search_id.find('.dataTables_info').attr("style", "margin-left: 2rem;")


  function append_jump_diagnosis(page, pages){
  let diagnosis_search_id = $('#benefit_diagnoses_dt_wrapper')
    let results = $('select[name="benefit_diagnoses_dt_length"]').val()

    diagnosis_search_id.find('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    diagnosis_search_id.find(".first.paginate_button, .last.paginate_button").hide()
    diagnosis_search_id.find('.one.wide').remove()
    diagnosis_search_id.find('.show').remove()
    diagnosis_search_id.find('#benefit_diagnoses_dt_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
    diagnosis_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
    diagnosis_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
    `<div class="right aligned one wide column inline field"> Jump to page: </div>\
    <div class="right aligned one wide column inline field" id="jump_search">\
      <select class="ui fluid search dropdown diagnosis" id="jump_diagnosis">\
      </select>\
    </div>`
    )
    var select = $('#jump_diagnosis')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
       options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
    diagnosis_search_id.find('.ui.fluid.search.dropdown').dropdown()
    diagnosis_search_id.find('#jump_diagnosis').dropdown('set selected', page + 1)

    diagnosis_search_id.find(document).find('input[class="search"]').keypress(function(evt) {
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

onmount('#benefit_procedure_dental_dt', function () {
let datatable_bproceduredental = $('#benefit_procedures_dental_dt')
let ajax_dental_procedure = `/web/benefits/${benefit_id}/load_dental_procedure_data?id=${benefit_id}`

  const csrf = $('input[name="_csrf_token"]').val();
  datatable_bproceduredental.DataTable({
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
      "url": ajax_dental_procedure,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "renderer": 'semanticUI',
    "pagingType": "full_numbers",
    "language": {
      "emptyTable":     "No CDT Found",
      "zeroRecords":    "No CDT matched your search",
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
      var table = datatable_bproceduredental.DataTable();
      var info = table.page.info();
      append_jump_dental(info.page, info.pages)
      add_search(this)
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true
  });

  $(document).on('change', '.ui.fluid.search.dropdown.dental', function(){
    let page = $(this).find($('.text')).html()
    var table = datatable_bproceduredental.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  let procedure_dental_search_id = $('#benefit_procedures_dental_dt_wrapper')

  procedure_dental_search_id.find('.dataTables_info').attr("style", "margin-left: 1rem;")


  function append_jump_dental(page, pages){
  let procedure_dental_search_id = $('#benefit_procedures_dental_dt_wrapper')
    let results = $('select[name="benefit_procedures_dental_dt_length"]').val()
    procedure_dental_search_id.find('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    procedure_dental_search_id.find(".first.paginate_button, .last.paginate_button").hide()
    procedure_dental_search_id.find('.one.wide').remove()
    procedure_dental_search_id.find('.show').remove()
    procedure_dental_search_id.find('#benefit_procedures_dental_dt_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
    procedure_dental_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
    procedure_dental_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
    `<div class="right aligned one wide column inline field"> Jump to page: </div>\
    <div class="right aligned one wide column inline field" id="jump_search">\
      <select class="ui fluid search dropdown dental" id="jump_procedure_dental">\
      </select>\
    </div>`
    )
    var select = $('#jump_procedure_dental')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
       options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
    procedure_dental_search_id.find('.ui.fluid.search.dropdown').dropdown()
    procedure_dental_search_id.find('#jump_procedure_dental').dropdown('set selected', page + 1)

    procedure_dental_search_id.find(document).find('input[class="search"]').keypress(function(evt) {
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
