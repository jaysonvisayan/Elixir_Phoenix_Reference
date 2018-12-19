onmount('div[id="file_upload_facility"]', function(){

  $('#upload').on('click', function(event){
    if($('input[name="facility[file]"]').val() == ""){
      $('.ajs-message.ajs-error.ajs-visible').remove()
      alert_no_file()
    }
    else
    {
      $('#import').submit()
    }
  })

  function alert_no_file(){
    alertify.error('<i id="notification_error" class="close icon"></i><p>Please choose a file.</p>');
    alertify.defaults = {
        notifier:{
            delay:8,
            position:'top-right',
            closeButton: false
        }
    };
  }

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


  function downloadCSV(csv, filename) {
    let csvFile;
    let downloadLink;

    // CSV file
    csvFile = new Blob([csv], {type: "text/csv"});

    // Download link
    downloadLink = document.createElement("a");

    // File name
    downloadLink.download = filename;

    // Create a link to the file
    downloadLink.href = window.URL.createObjectURL(csvFile);

    // Hide download link
    downloadLink.style.display = "none";

    // Add the link to DOM
    document.body.appendChild(downloadLink);

    // Click download link
    downloadLink.click();
  }

  $('.download_success_button').on('click', function(){
      const csrf2 = $('input[name="_csrf_token"]').val();

      const fu_id = $(this).attr('fu_id')
      const status = $(this).attr('status')
      const s_filename = $(this).attr('fu_filename').slice(0, -4)
      const list = [fu_id,status]
          let csv = [];
      $.ajax({
          url:`/facilities/download/success/uploaded`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {facility: { "list" : list}},
          dataType: 'json',
          success: function(response){
          let utc = new Date()
          let date = moment(utc)
          date = date.format("MM-DD-YYYY")

          let filename = s_filename + '_Success.csv'
          //Generate and Download CSV File
          downloadCSV(response, filename)
        }
      });

  });

  $('.download_failed_button').on('click', function(){
    const csrf2 = $('input[name="_csrf_token"]').val();

    const fu_id = $(this).attr('fu_id')
    const status = $(this).attr('status')
    const f_filename = $(this).attr('fu_filename').slice(0, -4)

    const list = [fu_id,status]
        let csv = [];
    $.ajax({
        url:`/facilities/download/success/uploaded`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {facility: { "list" : list}},
        dataType: 'json',
        success: function(response){
        let utc = new Date()
        let date = moment(utc)
        date = date.format("MM-DD-YYYY")

        let filename = f_filename + '_Failed.csv'
        //Generate and Download CSV File
        downloadCSV(response, filename)
      }
    });

  });
})