onmount('div[id="facility_payor_procedure"]', function(){

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

  $('#export_btn').on('click', function(){
    let facility_id = $(this).attr('facilityID')
    let diagnosis_codes = [];
    var table = $('#fpp_table').DataTable();
    var search_result = table.rows({search: 'applied'}).data();
    var search_value = $('#fpp_table_filter input').val();

    if (search_result.length > 0){
      const csrf = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/api/v1/facilities/${facility_id}/fpp_download`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        data: {fpp_param: { "search_value" : search_value.trim()}},
        dataType: 'json',
        success: function(response){

          let utc = new Date()
          let date = moment(utc)
          date = date.format("MM-DD-YYYY")
          let filename = 'ProviderCPT_' + date + '.csv'
          // Download CSV file
          downloadCSV(response, filename);
        }
      });
    }

  });


})


onmount('div[id="ruv_index"]', function(){

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

  $('#export_ruv_btn').on('click', function(){
    let facility_id = $(this).attr('facilityID')
    var table = $('#fr_table').DataTable();
    var search_result = table.rows({search: 'applied'}).data();
    var search_value = $('#fr_table_filter input').val();

    if (search_result.length > 0){
      const csrf = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/api/v1/facilities/${facility_id}/fr_download`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        data: {fr_param: { "search_value" : search_value.trim()}},
        dataType: 'json',
        success: function(response){

          let utc = new Date()
          let date = moment(utc)
          date = date.format("MM-DD-YYYY")
          let filename = 'FacilityRUV_' + date + '.csv'
          // Download CSV file
          downloadCSV(response, filename);
        }
      });
    }

  });


})


onmount('div[id="fpp_import"]', function(){

  $('a[id="success"]').on('click', function(){
    const csrf = $('input[name="_csrf_token"]').val();
    let log_id = $(this).attr("fppLogsID")
    let status = $(this).attr("status")

    $.ajax({
      url:`/api/v1/facilities/${log_id}/${status}/fpp_batch_download`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      success: function(response){

        let utc = new Date()
        let date = moment(utc)
        let time = moment(utc)
        date = date.format("MM-DD-YYYY")
        time = time.format("HHmmss")
        let filename = 'Successful_CPT_Upload' + date + '-' + time +'.csv'
        // Download CSV file
        downloadCSV(response, filename);
      }
    });

  });

  $('a[id="failed"]').on('click', function(){
    const csrf = $('input[name="_csrf_token"]').val();
    let log_id = $(this).attr("fppLogsID")
    let status = $(this).attr("status")

    $.ajax({
      url:`/api/v1/facilities/${log_id}/${status}/fpp_batch_download`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      success: function(response){

        let utc = new Date()
        let date = moment(utc)
        let time = moment(utc)
        date = date.format("MM-DD-YYYY")
        time = time.format("HHmmss")
        let filename = 'Failed_CPT_Upload' + date + '-' + time + '.csv'
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


onmount('div[id="fr_import"]', function(){

  $('a[id="success"]').on('click', function(){
    const csrf = $('input[name="_csrf_token"]').val();
    let log_id = $(this).attr("frLogsID")
    let status = $(this).attr("status")

    $.ajax({
      url:`/api/v1/facilities/${log_id}/${status}/fr_batch_download`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      success: function(response){

        let utc = new Date()
        let date = moment(utc)
        let time = moment(utc)
        date = date.format("MM-DD-YYYY")
        time = time.format("HHmmss")
        let filename = 'Successful_RUV_Upload' + date + '-' + time +'.csv'
        // Download CSV file
        downloadCSV(response, filename);
      }
    });

  });

  $('a[id="failed"]').on('click', function(){
    const csrf = $('input[name="_csrf_token"]').val();
    let log_id = $(this).attr("frLogsID")
    let status = $(this).attr("status")

    $.ajax({
      url:`/api/v1/facilities/${log_id}/${status}/fr_batch_download`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      success: function(response){

        let utc = new Date()
        let date = moment(utc)
        let time = moment(utc)
        date = date.format("MM-DD-YYYY")
        time = time.format("HHmmss")
        let filename = 'Failed_RUV_Upload' + date + '-' + time + '.csv'
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
