onmount('div[id="fileUpload"]', function () {
	$('.special.cards .image').dimmer({
	  on: 'hover'
	});

	$('#imageLabel').on('click', function(){
		$('#photo').click();
	});

	$('#imageRemove').on('click', function(){
		    $("#photo").css("background-image", "none");
      	$("#photo").attr('src', '/images/file-upload (1).png');
        $("#imageLabel").html('<i class="folder open icon"></i> Browse Photo');
      	// $("#imagePreview").remove();
      	// $("#imagePreview").attr('src', '/images/file-upload.png');
        $('#delete-photo').submit()
	});

	$.uploadPreview({
	    input_field: "#imageUpload",
	    preview_box: "#photo",
	    label_field: "#imageLabel"
	});
});

(function ($) {
  $.extend({
    uploadPreview : function (options) {

      // Options + Defaults
      var settings = $.extend({
        input_field: ".image-input",
        preview_box: ".image-preview",
        label_field: ".image-label",
        label_default: " Browse Photo",
        label_selected: " Change Photo",
        no_label: false,
        success_callback : null,
      }, options);

      // Check if FileReader is available
      if (window.File && window.FileList && window.FileReader) {
        if (typeof($(settings.input_field)) !== 'undefined' && $(settings.input_field) !== null) {
          $(settings.input_field).change(function() {
            var files = this.files;

            if (files.length > 0) {
              var file = files[0];
              var photo = URL.createObjectURL(event.target.files[0]);
              var reader = new FileReader();

              // Load file
              reader.addEventListener("load",function(event) {
                var loadedFile = event.target;
                let size = file.size <= 1024 * 1024 * 5
                // var photo = URL.createObjectURL(loadedFile);
                // Check format
                if (file.type.match('image')) {
                  // Image
                  if (size) {
                    $(settings.preview_box).css("background-image", "url("+photo+")");
                    $(settings.preview_box).attr('src', '');
                    $(settings.preview_box).css("background-size", "cover");
                    $(settings.preview_box).css("background-position", "center center");
                    $(settings.preview_box).css("height", "150px");
                  } else {
                    $('input[name="account[photo]"]').val("")
                    alertify.error('<i class="close icon"></i> Maximum file size is 5MB')
                  }
                }
                else {
                  $('input[name="account[photo]"]').val("")
                  alertify.error('<i class="close icon"></i> Acceptable file types are jpg, jpeg and png.')
                }
              });

              if (settings.no_label == false) {
                // Change label
                $(settings.label_field).html('<i class="refresh icon"></i>' + settings.label_selected);
              }

              // Read the file
              reader.readAsDataURL(file);

              // Success callback function call
              if(settings.success_callback) {
                settings.success_callback();
              }
            } else {
              if (settings.no_label == false) {
                // Change label
                $(settings.label_field).html('<i class="folder open icon"></i>' + settings.label_default);
              }

              // Clear background
              // $(settings.preview_box).css("background-image", "none");
              // $(settings.preview_box).attr('src', '/images/file-upload (1).png');

            }
          });
        }
      } else {
        alert("You need a browser with file reader support, to use this form properly.");
        return false;
      }
    }
  });
})(jQuery);

 // $('#imageUpload').change(function(e) {
 //    var photo = document.getElementById('photo');
 //    photoPreview(photo, '290px', '300px');
 //  });

 // $('#uploadPhoto').change(function(e) {
 //    var photo = document.getElementById('photo');
 //    photoPreview(photo, '290px', '300px');
 //  });

 // const photoPreview = (element, width, height) => {
 //    element.src = URL.createObjectURL(event.target.files[0]);
 //    //element.style.width = width;
 //    //element.style.height = height;
 //  }

	// $('a[role="upload"]').on('click', function(){
 //    console.log($('input[name="account[photo]"]').val())
	// });

 //  $('a[role="remove"]').on('click', function(e){
 //    $('#photo').attr("src", "/images/file-upload.png")
 //    $('#uploadPhoto').val("");

 //    let account_group_id = $('#photo').attr('accountGroupID');
 //    let account_id = $('#photo').attr('accountID');

 //    if(account_group_id != undefined){
 //      let csrf = $('input[name="_csrf_token"]').val();

 //      $.ajax({
 //        url:`/accounts/${account_group_id}/remove_photo`,
 //        headers: {"X-CSRF-TOKEN": csrf},
 //        type: 'delete',
 //        success: function(response){
 //          location.reload()
 //        },
 //        error: function() {
 //          location.reload()
 //        },
 //      });
 //    }

 //    let fulfillment_id = $('#imageUpload').attr('fulfillmentID');
 //    let fulfillment_account_id = $('#imageUpload').attr('fulfillmentaccountID')
 //    let card = $('#imageUpload').attr('card')
 //    if(fulfillment_id != undefined){
 //      let csrf = $('input[name="_csrf_token"]').val();

 //      $.ajax({
 //        url:`/fulfillments/${fulfillment_id}/remove_photo`,
 //        headers: {"X-CSRF-TOKEN": csrf},
 //        type: 'get',
 //        success: function(response){
 //          if (card == "2"){
 //            window.location.href=`/accounts/${fulfillment_account_id}/card/${fulfillment_id}/edit_card`;
 //          }
 //          else if (card == "1")
 //            {
 //              window.location.href=`/accounts/${fulfillment_account_id}/card/${fulfillment_id}/new_edit_card`;
 //            }
 //        },
 //        error: function() {
 //          if (card == "2"){
 //          window.location.href=`/accounts/${fulfillment_account_id}/card/${fulfillment_id}/edit_card`;
 //          }
 //          else if (card == "1")
 //            {
 //              window.location.href=`/accounts/${fulfillment_account_id}/card/${fulfillment_id}/new_edit_card`;
 //            }
 //        },
 //      });
 //    }



 //  });

onmount('div[id="upload_file_photo"]', function(){
  $('button[id="upload"]').on('click', function(){
    // Get file input name
    let name =  $(this).attr("file")
    const file_input_selector = $('input[name="member['+ name +']"]')
    const extensionListsImage  = ['jpg', 'jpeg', 'png'];
    const extensionListsFile  = ['jpg', 'jpeg', 'png', 'pdf'];

    // On click file name
    file_input_selector.on('click', function(){
      $(this).on('change', function(){
        // Size checker
        if($(this)[0].files[0].size <= 1024 * 1024 * 5){
          // Type checker
          if(name == "pwd_photo" || name == "senior_photo"){
             if(extensionListsImage.indexOf($(this).val().split('.').pop()) > -1){
              // Success upload image
              let file_name = $(this)[0].files[0].name

              if (file_name.length > 20){
                $('span[name="'+ name +'"]').text(file_name.substring(0,20) + ' ...')
              }else{
                $('span[name="'+ name +'"]').text(file_name)
              }

              $(this).attr("value", file_name)

              // Remove error notifications
              // Ex. Please Upload CIR Form
              $(this).prev().css("color", "gray")
              $(this).next().next().remove()
             }else{
              // Remove error notifications
              // Ex. Please Upload CIR Form
              $(this).prev().css("color", "gray")
              $(this).next().next().remove()

              // Alert file type error
              $(this).val('')
              alertify.error('<i class="close icon"></i>Acceptable file types are jpg, jpeg and png.');
              alertify.defaults = {
                  notifier:{
                      delay:8,
                      position:'top-right',
                      closeButton: false
                  }
              }
             }
          }else{
            if(extensionListsFile.indexOf($(this).val().split('.').pop()) > -1){
            // Success upload file
              let file_name = $(this)[0].files[0].name

              if (file_name.length > 20){
                $('span[name="'+ name +'"]').text(file_name.substring(0,20) + ' ...')
              }else{
                $('span[name="'+ name +'"]').text(file_name)
              }

              $(this).attr("value", file_name)

              // Remove error notifications
              // Ex. Please Upload CIR Form
              $(this).prev().css("color", "gray")
              $(this).next().next().remove()
            }else{
              // Remove error notifications
              // Ex. Please Upload CIR Form
              $(this).prev().css("color", "gray")
              $(this).next().next().remove()

                // Alert file type error
                $(this).val('')
                alertify.error('<i class="close icon"></i>Acceptable file types are jpg, jpeg, png and pdf.');
                alertify.defaults = {
                    notifier:{
                        delay:8,
                        position:'top-right',
                        closeButton: false
                    }
                }
             }
          }
        }else{
          // Remove error notifications
          // Ex. Please Upload CIR Form
          $(this).prev().css("color", "gray")
          $(this).next().next().remove()

          // Alert file size error
          $(this).val('')
          alertify.error('<i class="close icon"></i>Maximum file size is 5MB');
          alertify.defaults = {
              notifier:{
                  delay:8,
                  position:'top-right',
                  closeButton: false
              }
          };
        }
      })
    })

    // Click file input
    file_input_selector.click()
  })
// R.Navarro
})
