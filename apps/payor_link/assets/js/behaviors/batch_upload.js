onmount('#batch_upload', function(){

  $('#overlay2').css("display", "none");

  $('#upload_batch_user_csv').on('click', function(e){
    $('.ajs-message.ajs-error.ajs-visible').remove()

    let file = $('input[name="user[file]"]').val()

    if(file == ""){
      alertify.error('<i class="close icon"></i> Please upload a file')
    } else {
      $("#import-user-activation").submit()
      $('#overlay2').css("display", "block");
    }
  })

  $('a[id="success"]').on('click', function(){
    const csrf = $('input[name="_csrf_token"]').val();
    let uaa_file_id = $(this).attr("uaa_file_id")
    let status = $(this).attr("status")
    let file = $(this).attr("file_name")
    let type = $(this).attr("type")

    $.ajax({
      url:`/api/v1/user_access_activations/${uaa_file_id}/${status}/csv_download`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      success: function(response){

        let utc = new Date()
        let date = moment(utc)
        let time = moment(utc)
        date = date.format("MM-DD-YYYY")
        time = time.format("HHmmss")
        let filename = file + '_Success' +'.csv'
        // Download CSV file
        downloadCSV(response, filename);
      }
    });

  });

  $('a[id="failed"]').on('click', function(){
    const csrf = $('input[name="_csrf_token"]').val();
    let uaa_file_id = $(this).attr("uaa_file_id")
    let status = $(this).attr("status")
    let file = $(this).attr("file_name")
    let type = $(this).attr("type")

    $.ajax({
      url:`/api/v1/user_access_activations/${uaa_file_id}/${status}/csv_download`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      success: function(response){
        let utc = new Date()
        let date = moment(utc)
        let time = moment(utc)
        date = date.format("MM-DD-YYYY")
        time = time.format("HHmmss")
        let filename = file + '_Failed' +'.csv'
        // Download CSV file
        downloadCSV(response, filename);
      }
    });

  });

  const downloadCSV = (csv, filename) => {
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

})
