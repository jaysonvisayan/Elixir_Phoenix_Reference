const locale = $('#locale').val();

onmount('div[id="fileUpload"]', function () {
	$('#imageLabel').on('click', function(){
		$('#photo').click();
	});

	$('#imageRemove').on('click', function(){
		$("#photo").css("background-image", "none");
   	$("#photo").attr('src', '/images/file-upload (1).png');
    $("#imageLabel").html('<i class="folder open icon"></i> Browse Photo');

    let member_id = $('#imageUpload').attr('memberID')

    if(member_id != undefined){
      let csrf = $('input[name="_csrf_token"]').val()

      $.ajax({
        url:`/${locale}/members/${member_id}/delete_member_photo`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'delete',
        success: function(response){
          location.reload()
        },
        error: function() {
          alert('Error deleting photo!')
        }
      });
    }
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
                // var photo = URL.createObjectURL(loadedFile);

                // Check image file type
                var ValidImageTypes = ['image/jpg', 'image/jpeg', 'image/png'];
                if ($.inArray(file.type, ValidImageTypes) > -1) {
                  // Check 5mb allowed
                  if (file.size > 5242880) {
                    alertify.error('Maximum image file size is 5 megabytes.<i id="notification_error" class="close icon"></i>');
                    alertify.defaults = {
                      notifier:{
                        delay:5,
                        position:'top-right',
                        closeButton: false
                      }
                    };
                    $("#imageLabel").html('<i class="folder open icon"></i> Browse Photo');
                  }
                  else {
                    // Image
                    $(settings.preview_box).css("background-image", "url("+photo+")");
                    $(settings.preview_box).attr('src', '');
                    $(settings.preview_box).css("background-size", "cover");
                    $(settings.preview_box).css("background-position", "center center");
                    $(settings.preview_box).css("height", "150px");
                  }
                }
                else {
                  alertify.error('Invalid file type. Valid file types are JPG, JPEG, and PNG.<i id="notification_error" class="close icon"></i>');
                  alertify.defaults = {
                    notifier:{
                      delay:5,
                      position:'top-right',
                      closeButton: false
                    }
                  };
                  $("#imageLabel").html('<i class="folder open icon"></i> Browse Photo');
                  $('#imageUpload').val('')
                  $("#photo").css("background-image", "none");
                  $("#photo").attr('src', '/images/file-upload (1).png');
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
        alertify.error('You need a browser with file reader support, to use this form properly.<i id="notification_error" class="close icon"></i>');
        alertify.defaults = {
          notifier:{
            delay:5,
            position:'top-right',
            closeButton: false
          }
        };
        $("#imageLabel").html('<i class="folder open icon"></i> Browse Photo');
        return false;
      }
    }
  });
})(jQuery);

onmount('div[id="upload_senior"]', function () {
  $('#file_senior').on('change', function(e) {
    const extensionListsImage  = ['jpg', 'jpeg', 'png'];

    // Size checker
    if($(this)[0].files[0].size <= 1024 * 1024 * 5){
      // Type checker
      if(extensionListsImage.indexOf($(this).val().split('.').pop()) > -1){
        // Success upload image
        let file_name = $(this)[0].files[0].name

        if (file_name.length > 20){
          $('span[name="'+ name +'"]').text(file_name.substring(0,20) + ' ...')
        }else{
          $('span[name="'+ name +'"]').text(file_name)
        }

        $(this).attr("value", file_name)
        $('#text_senior', $(e.target).parent()).val(file_name)
      }else{
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
  });
});

onmount('div[id="upload_pwd"]', function () {
$('#file_pwd').on('change', function(e) {
  const extensionListsImage  = ['jpg', 'jpeg', 'png'];

  // Size checker
  if($(this)[0].files[0].size <= 1024 * 1024 * 5){
    // Type checker
    if(extensionListsImage.indexOf($(this).val().split('.').pop()) > -1){
      // Success upload image
      let file_name = $(this)[0].files[0].name

      if (file_name.length > 20){
        $('span[name="'+ name +'"]').text(file_name.substring(0,20) + ' ...')
      }else{
        $('span[name="'+ name +'"]').text(file_name)
      }

      $(this).attr("value", file_name)
      $('#text_pwd', $(e.target).parent()).val(file_name)
    }else{
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
});
});
