onmount('table[role="datatable"]', function () {
	$('table[role="datatable"]').dataTable({
	  	dom:
			"<'ui grid'"+
				"<'row'"+
					"<'eight wide column'l>"+
					"<'right aligned eight wide column'f>"+
				">"+
				"<'row dt-table'"+
					"<'sixteen wide column'tr>"+
				">"+
				"<'row'"+
					"<'six wide column'i>"+
					"<'right aligned ten wide column'p>"+
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
				first: "<i class='angle single left icon'></i> First",
				previous: "<i class='angle double left icon'></i> Previous",
				next: "Next <i class='angle double right icon'></i>",
				last: "Last <i class='angle single right icon'></i>"
			}
		},
    drawCallback: function () {
      add_search(this)
    }
	})
})

onmount('table[role="datatable2"]', function () {
  $('table[role="datatable2"]').dataTable({
      dom:
      "<'ui grid'"+
        "<'row'"+
          "<'eight wide column'l>"+
          "<'right aligned eight wide column'f>"+
        ">"+
        "<'row dt-table'"+
          "<'sixteen wide column'tr>"+
        ">"+
        "<'row'"+
          "<'six wide column'i>"+
          "<'right aligned ten wide column'p>"+
        ">"+
      ">",
    renderer: 'semanticUI',
    pagingType: "full_numbers",
    language: {
      emptyTable:     "No result(s) found",
      zeroRecords:    "No result(s) found",
      search:         "",
      info: "_TOTAL_",
      infoEmpty: "",
      paginate: {
        first: "<i class='angle single left icon'></i> First",
        previous: "<i class='angle double left icon'></i> Previous",
        next: "Next <i class='angle double right icon'></i>",
        last: "Last <i class='angle single right icon'></i>"
      }
    },
    drawCallback: function () {
      add_search(this)
    }
  })
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
    $(`#${id}_filter`).find('input[type="search"]').attr("placeholder", `Search`)
    $(`#${id}_filter`).find('input[type="search"]').append(`</div>`)
    $(`#${id}_filter`).val(1)
  }
}
