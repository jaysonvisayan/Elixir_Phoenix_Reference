onmount('div[id="user_roles"]', function () {
	
	let selectedApplication = $('.select_application').dropdown('get value');
	$('#' + selectedApplication).show();

	$('.select_application').dropdown({
	    onChange: function() {
	      	let application_name = $('.select_application').dropdown('get value');
	      	$('.roles_table').hide();
			$('#' + application_name).show();
	    }
	  })
	;

});