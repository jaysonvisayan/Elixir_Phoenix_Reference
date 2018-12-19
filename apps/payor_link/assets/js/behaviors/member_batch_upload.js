onmount('div[id="member_batch_upload_export"]', function(){
  $('#overlay2').css("display", "none");

  $('#upload_batch_csv').on('click', function(e){
  
    $('.ajs-message.ajs-error.ajs-visible').remove()

    let file = $('input[name="member[file]"]').val()

    if(file == ""){
      alertify.error('<i class="close icon"></i> Please upload a file')
    } else {
      $("#import_member").submit()
      $('#overlay2').css("display", "block");
    }
  })

  ////////////////////////////// start JS loading /////////////////////////
  $('#batch_upload_datatable').find('tbody').find('tr').each(function(){
    let member_upload_file_id = $(this).find('input').val()
    let property = $(this).find('.isDisabled')
    let propertyDim = $(this).closest('.dim')
    let properties = {property: property, propertyDim: propertyDim}
    job_status_checker(member_upload_file_id, properties)
  })

  function job_status_checker(member_upload_file_id, properties) {
    const csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url: `/web/members/upload_status`,
        headers: {
        "X-CSRF-TOKEN": csrf
      },
      type: 'post',
      data: {id: member_upload_file_id},
      success: function(response) {
        let obj = JSON.parse(response)
        if (obj.valid == true){
          properties.propertyDim.removeClass('dim')
          properties.property.removeClass('isDisabled')
        }
        else{
          console.log(properties)
        }
      }
    })
  }

  ////////////////////////////// end JS loading /////////////////////////

  $('a[id="success"]').on('click', function(){
    const csrf = $('input[name="_csrf_token"]').val();
    let log_id = $(this).attr("member_upload_logs_id")
    let status = $(this).attr("status")
    let file = $(this).attr("file_name")
    let type = $(this).attr("type")

    $.ajax({
      url:`/api/v1/members/${log_id}/${status}/${type}/member_batch_download`,
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
    let log_id = $(this).attr("member_upload_logs_id")
    let status = $(this).attr("status")
    let file = $(this).attr("file_name")
    let type = $(this).attr("type")

    $.ajax({
      url:`/api/v1/members/${log_id}/${status}/${type}/member_batch_download`,
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

})
