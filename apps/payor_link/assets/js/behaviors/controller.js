onmount('.ui.dropdown', function () {
  //dropdown and select trigger
  $(".ui.dropdown").dropdown();
});

onmount('.ui.radio', function () {
  $('.ui.radio.checkbox').checkbox();
});

onmount('.menu .item', function(){
  $('.menu .item').tab();
});

onmount('.ui.radio.checkbox', function(){
  $('.ui.radio.checkbox').checkbox();
});

onmount('.tabular.menu .item', function(){
  $('.tabular.menu .item').tab();
  $('div[role="benefits"] > .item').tab();
});

onmount('.ui.checkbox', function(){
  $('.ui.checkbox').checkbox();
});

$('div[role="benefits"] > .item').on('click', function() {
	var tabActive = $(this).attr("data-tab");
	if (tabActive == "health_plan"){
		$('.health_plan.radio.checkbox').checkbox('set checked');
	}
	else {
		$('.health_plan.radio.checkbox').checkbox('set unchecked');
	}

	if (tabActive == "riders"){
		$('.riders.radio.checkbox').checkbox('set checked');
	}
	else {
		$('.riders.radio.checkbox').checkbox('set unchecked');
	}

	var tabActive = $(this).attr("data-tab");
	if (tabActive == "aaf"){
		$('.aaf.radio.checkbox').checkbox('set checked');
	}
	else {
		$('.aaf.radio.checkbox').checkbox('set unchecked');
	}

	if (tabActive == "sf"){
		$('.sf.radio.checkbox').checkbox('set checked');
	}
	else {
		$('.sf.radio.checkbox').checkbox('set unchecked');
	}

    var tabActive = $(this).attr("data-tab");

    if (tabActive == "exclusion"){
        $('.exclusion.radio.checkbox').checkbox('set checked');
    }
    else {
        $('.exclusion.radio.checkbox').checkbox('set unchecked');
    }

    if (tabActive == "pre_existing"){
        $('.pre_existing.radio.checkbox').checkbox('set checked');
    }
    else {
        $('.pre_existing.radio.checkbox').checkbox('set unchecked');
    }

});

onmount('a[name="cancel"]', function(){
  $(this).on('click', function(){
    if(confirm("You have unsaved changes. Are you sure you want to cancel?")) functionName();
  });
})

onmount('.ui.message', function(){
	$('.message .close')
	  .on('click', function() {
	    $(this)
	      .closest('.message')
	      .transition('fade')
	    ;
	  });
});

onmount('div[id="summary"]', function(){

	$('#btnEdit').on('click', function(){
		$('.editable').addClass('editableLabel');
		$('#btnEdit').addClass('display-none');
		$('#btnSave').removeClass('display-none');
	});

	$('#btnSave').on('click', function(){
		$('.editable').removeClass('editableLabel');
		$('#btnEdit').removeClass('display-none');
		$('#btnSave').addClass('display-none');
	});


	$('.editable').on('click', function(e){
		var lbl = $(e.target);
		var txt = $('<input type="text" value="'+lbl.text()+'">');

		lbl.replaceWith(txt);
		txt.focus();

			txt.blur(function(){
				txt.replaceWith(lbl);
			})
			.keydown(function(e){
				if(e.keyCode == 13){
					var newContent = $(this).val();
					lbl.text(newContent);
					txt.replaceWith(lbl);
				}
			});
	});

});

