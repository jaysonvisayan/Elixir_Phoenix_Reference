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
					"<'seven wide column'i>"+
					"<'right aligned nine wide column'p>"+
				">"+
			">",
		renderer: 'semanticUI',
		pagingType: "full_numbers",
		language: {
			emptyTable:     "No Records Found!",
			zeroRecords:    "No Matching Records Found!",
			search:         "Search",
			paginate: {
				first: "<i class='angle single left icon'></i> First",
				previous: "<i class='angle double left icon'></i> Previous",
				next: "Next <i class='angle double right icon'></i>",
				last: "Last <i class='angle single right icon'></i>"
			}
		}
	});

});
