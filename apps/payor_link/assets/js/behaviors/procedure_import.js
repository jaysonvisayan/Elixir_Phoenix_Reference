onmount('div[id="main_file_upladed_procedure"]', function(){

  $('#import').form({
    on: blur,
    inline: true,
      fields: {
        'payor_procedure[file]': {
          identifier: 'payor_procedure[file]',
            rules: [{
              type  : 'empty',
              prompt: 'Please choose file.'
            }
           ]
        }
      }
   });


  function alert_error_file(){
    alertify.error('<i id="notification_error" class="close icon"></i><p>Invalid file format. Please upload CSV file only.</p>');
    alertify.defaults = {
        notifier:{
            delay:8,
            position:'top-right',
            closeButton: false
        }
    };
  }

  function alert_error_size(){
    alertify.error('<i id="notification_error" class="close icon"></i><p>Invalid file upload you reach maximum size</p>');
    alertify.defaults = {
        notifier:{
            delay:8,
            position:'top-right',
            closeButton: false
        }
    };
  }

  $('#file_upload').on('change', function(event){
    let pdffile = event.target.files[0];
    if (pdffile != undefined){
        if((pdffile.name).indexOf('.csv') >= 0){
            if(pdffile.size <= 8000000){
                pdffile = (window.URL || window.webkitURL).createObjectURL(pdffile)
            }
            else{
                  $(this).val('')
                  alert_error_size()
            }
          }
          else{
              $(this).val('')
              alert_error_file()
          }
    }
    else{
        $(this).val('')
    }
  })


  $('#import_button').on('click', function(event){
    let allRows = pdffile.split(/\r?\n|\r/);
    alert(allRows)

  })


})
