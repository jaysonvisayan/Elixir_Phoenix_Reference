onmount('div[id="main_member_batch_upload"]', function(){
  const csrf = $('input[name="_csrf_token"]').val();
  $('#batch_upload_table').DataTable({
    "ajax": {
      "url": "/web/members/index/batch_data",
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },

    "processing": true,
    "serverSide": true,
    "deferRender": true,
    "drawCallback": _ => {

      ////////////////////////////// start JS loading /////////////////////////
      $('#batch_upload_table').find('tbody').find('tr').each(function(){
        let member_upload_file_id = $(this).find('input').val()
        let property = $(this).find('.isDisabled')
        $(this).addClass('dim')
        let properties = {property: property, propertyDim: $(this)}
        job_status_checker(member_upload_file_id, properties)
      })

      // setInterval(() => {
      //   check_status()
      // }, 1000)
    }

  });



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

  const job_status_checker = (member_upload_file_id, properties) => {
    const csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url: `/web/members/upload_status`,
        headers: {
        "X-CSRF-TOKEN": csrf
      },
      dataType: 'json',
      type: 'post',
      data: {id: member_upload_file_id},
      success: function(response) {
        let obj = JSON.parse(response)

        if (obj.valid){
          properties.propertyDim.removeClass('dim')
          properties.property.removeClass('isDisabled')
        } else {
          properties
          .propertyDim
          .find(".mul_sucess")
          .text(
            obj.mul_count.success
          )

          properties
            .propertyDim
            .find(".mul_failed")
            .text(
              obj.mul_count.failed
            )

          properties
            .propertyDim
            .find(".total")
            .text(
              obj.mul_count.total
            )
        }
      }
    })
  }

  const check_status = _ => {
    $('#batch_upload_table')
      .find('tbody')
      .find('tr')
      .each(function() {
        if( $(this).hasClass("dim") ) {
          let member_upload_file_id = $(this).find('input').val()
          let property = $(this).find('.isDisabled')
          let properties = {property: property, propertyDim: $(this)}
          job_status_checker(member_upload_file_id, properties)
        }
      })
  }

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

  $(document).on('click', 'a[id="success"]', function() {
    const csrf = $('input[name="_csrf_token"]').val();
    let log_id = $(this).attr("member_upload_logs_id")
    let status = $(this).attr("status")
    let str2 = "Member";
    let file = $(this).attr("file_name")
    let type = $(this).attr("type")
    let batch_no  = $(this).attr("batch_no")

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
        let filename = str2 + " " + "(" + type + ")" + " " + "(" + batch_no + ")" + '_Success' + '.csv'
        // Download CSV file
        downloadCSV(response, filename);
      }
    });

  });

  $(document).on('click', 'a[id="failed"]', function() {
    const csrf = $('input[name="_csrf_token"]').val();
    let log_id = $(this).attr("member_upload_logs_id")
    let status = $(this).attr("status")
    let str1 = "Member";
    let file = $(this).attr("file_name")
    let type = $(this).attr("type")
    let batch_no  = $(this).attr("batch_no")

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
        let filename = str1 + " " + "(" + type + ")" + " " + "(" + batch_no + ")" + '_Failed' + '.csv'
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

});
