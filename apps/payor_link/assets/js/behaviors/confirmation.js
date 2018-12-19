onmount('div[role="confirmation"]', function(){
	$('#btnDelete').on('click', function(){
		swal({
		  title: 'Confirm',
		  text: "Are you sure you want to delete this file? You cannot undo this action.",
		  type: 'warning',
		  showCancelButton: true,
		  confirmButtonText: '<i class="trash icon"></i> Delete',
		  cancelButtonText: '<i class="remove icon"></i> Cancel',
		  confirmButtonClass: 'ui button',
		  cancelButtonClass: 'ui button',
		  buttonsStyling: false
		}).then(function () {
		  swal({
		    title:'Deleted!',
		    text: 'Your file has been deleted.',
		    type: 'success',
		    confirmButtonText: '<i class="check icon"></i> Ok',
		    confirmButtonClass: 'ui blue button'
		  })
		}, function (dismiss) {
		  if (dismiss === 'cancel') {
		    swal({
		      	title: 'Cancelled',
		      	text: 'Your imaginary file is safe :)',
		      	type: 'error',
		      	confirmButtonText: '<i class="check icon"></i> Ok',
		    	confirmButtonClass: 'ui blue button'
		    })
		  }
		})
	})

	$('#btnCancel').on('click', function(){
		swal({
		  title: 'Unsaved Changes',
		  text: "Are you sure you want to cancel the changes you've made?",
		  type: 'warning',
		  showCancelButton: true,
		  confirmButtonText: '<i class="check icon"></i> Yes',
		  cancelButtonText: '<i class="remove icon"></i> No',
		  confirmButtonClass: 'ui positive button',
		  cancelButtonClass: 'ui negative button',
		  buttonsStyling: false
		}).then(function () {
		  swal({
		    title: 'Cancelled',
	      	text: 'Your changes has not been saved.',
	      	type: 'error',
	      	confirmButtonText: '<i class="check icon"></i> Ok',
	    	confirmButtonClass: 'ui blue button'
		  })
		})
	})

	$('#btnSave').on('click', function(){
		swal({
		  title: 'Save changes',
		  text: "Are you sure you want to save the changes you've made?",
		  type: 'question',
		  showCancelButton: true,
		  confirmButtonText: '<i class="save icon"></i> Save',
		  cancelButtonText: '<i class="remove icon"></i> Cancel',
		  confirmButtonClass: 'ui blue button',
		  cancelButtonClass: 'ui button',
		  buttonsStyling: false
		}).then(function () {
		  swal({
		    title:'Saved changes',
		    text: 'Your changes has been saved.',
		    type: 'success',
		    confirmButtonText: '<i class="check icon"></i> Ok',
		    confirmButtonClass: 'ui blue button'
		  })
		}, function (dismiss) {
		  if (dismiss === 'cancel') {
		    swal({
		      	title: 'Cancelled',
		      	text: 'Your changes has not been saved. ',
		      	type: 'error',
		      	confirmButtonText: '<i class="check icon"></i> Ok',
		    	confirmButtonClass: 'ui blue button'
		    })
		  }
		})
	})

	$('#btnSubmit').on('click', function(){
		swal({
		  title: 'Submit CPT Details',
		  text: "Are you sure you want to create this CPT?",
		  type: 'question',
		  showCancelButton: true,
		  confirmButtonText: '<i class="send icon"></i> Submit',
		  cancelButtonText: '<i class="remove icon"></i> Cancel',
		  confirmButtonClass: 'ui blue button',
		  cancelButtonClass: 'ui button',
		  buttonsStyling: false
		}).then(function () {
		  swal({
		    title:'CPT Created',
		    text: 'CPT has been successfully created!',
		    type: 'success',
		    confirmButtonText: '<i class="check icon"></i> Ok',
		    confirmButtonClass: 'ui blue button'
		  })
		})
	})
})

onmount('button[id="cancelBtn"]', function() {

  $('#cancelBtn').on('click', function() {
    let link = $(this).attr('redirect-to')
    swal({
      title: 'Discard Changes?',
      text: 'If you go back now, your draft will be discarded.',
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Discard Changes',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Changes',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false
    }).then(function() {
      window.location.href = link
    }).catch(swal.noop)
  })

});
