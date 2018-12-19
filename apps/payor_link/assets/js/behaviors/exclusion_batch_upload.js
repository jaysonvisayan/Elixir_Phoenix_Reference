onmount('div[id="exclusion_batch_upload"]', function(){

    $('a[id="cpt_success"]').on('click', function(){
      const csrf = $('input[name="_csrf_token"]').val();
      let log_id = $(this).attr("file_id")
      let status = $(this).attr("status")

      $.ajax({
        url:`/api/v1/exclusions/${log_id}/${status}/cpt_batch_download`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        dataType: 'json',
        success: function(response){

          let utc = new Date()
          let date = moment(utc)
          let time = moment(utc)
          date = date.format("MM-DD-YYYY")
          time = time.format("HHmmss")
          let filename = 'Successful_GENERAL_EXCLUSION_CPT_Upload' + date + '-' + time +'.csv'
          // Download CSV file
          downloadCSV(response, filename);
        }
      });

    });

    $('a[id="cpt_failed"]').on('click', function(){
      const csrf = $('input[name="_csrf_token"]').val();
      let log_id = $(this).attr("file_id")
      let status = $(this).attr("status")

      $.ajax({
        url:`/api/v1/exclusions/${log_id}/${status}/cpt_batch_download`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        dataType: 'json',
        success: function(response){

          let utc = new Date()
          let date = moment(utc)
          let time = moment(utc)
          date = date.format("MM-DD-YYYY")
          time = time.format("HHmmss")
          let filename = 'Failed_GENERAL_EXCLUSION_CPT_Upload' + date + '-' + time + '.csv'
          // Download CSV file
          downloadCSV(response, filename);
        }
      });

    });

    $('a[id="diagnosis_success"]').on('click', function(){
      const csrf = $('input[name="_csrf_token"]').val();
      let log_id = $(this).attr("file_id")
      let status = $(this).attr("status")

      $.ajax({
        url:`/api/v1/exclusions/${log_id}/${status}/icd_batch_download`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        dataType: 'json',
        success: function(response){

          let utc = new Date()
          let date = moment(utc)
          let time = moment(utc)
          date = date.format("MM-DD-YYYY")
          time = time.format("HHmmss")
          let filename = 'Successful_GENERAL_EXCLUSION_DIAGNOSIS_Upload' + date + '-' + time +'.csv'
          // Download CSV file
          downloadCSV(response, filename);
        }
      });

    });

    $('a[id="diagnosis_failed"]').on('click', function(){
      const csrf = $('input[name="_csrf_token"]').val();
      let log_id = $(this).attr("file_id")
      let status = $(this).attr("status")

      $.ajax({
        url:`/api/v1/exclusions/${log_id}/${status}/icd_batch_download`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        dataType: 'json',
        success: function(response){

          let utc = new Date()
          let date = moment(utc)
          let time = moment(utc)
          date = date.format("MM-DD-YYYY")
          time = time.format("HHmmss")
          let filename = 'Failed_GENERAL_EXCLUSION_DIAGNOSIS_Upload' + date + '-' + time + '.csv'
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

