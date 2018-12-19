onmount('div[role="notification"]', function(){
	$('#defaultNotification').on('click', function(){
		 alertify.message('<i class="close icon"></i><div class="header">Default Notification!</div><p>Default notification message.</p>'); 
	});

	$('#errorNotification').on('click', function(){
		 alertify.error('<i class="close icon"></i><div class="header">Error Notification!</div><p>Error notification message.</p>'); 
	});

	$('#warningNotification').on('click', function(){
		 alertify.warning('<i class="close icon"></i><div class="header">Warning Notification!</div><p>Warning notification message.</p>'); 
	});

	$('#successNotification').on('click', function(){
		 alertify.success('<i class="close icon"></i><div class="header">Success Notification!</div><p>Success notification message.</p>'); 
	});

	$('#infoNotification').on('click', function(){
		 // alertify.notify('Warning notification message.'); 
		 alertify.notify('<i class="close icon"></i><div class="header">Info Notification!</div><p>Info notification message.</p>', 'info');
	});

	alertify.defaults = {
        // notifier defaults
        notifier:{
            // auto-dismiss wait time (in seconds)  
            delay:5,
            // default position
            position:'top-right',
            // adds a close button to notifier messages
            closeButton: false
        }
    };
});

onmount('button[id="preventNextAlertify"]', function () {
  $('#preventNextAlertify').on('click', function(){
    $('.ajs-message.ajs-error.ajs-visible').remove()
    let message = $(this).attr('message')
    alertify.error(`<i class="close icon"></i><p>${message}</p>`); 
  })

})
