onmount('button[id="export_migration"]', function(){

  // const csrf = $('input[name="_csrf_token"]').val();
  // $('#migration_table').DataTable({
  //   "ajax": {
  //     "url": "/web/benefits/index/data",
  //     "headers": { "X-CSRF-TOKEN": csrf },
  //     "type": "get"
  //   },
  //   "processing": true,
  //   "serverSide": true,
  //   "deferRender": true
  // });

  $('#export_migration').on('click', function(){
    var table = $('#migration_table').DataTable();
    var search_result = table.rows({order:'current', search: 'applied'}).data();
    var search_value = $('.dataTables_filter input').val();

    if (search_result.length > 0) {
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
          url:`/migration/index/download`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {migration_param: { "search_value" : search_value.trim()}},
          dataType: 'json',
          success: function(response){
            let utc = new Date()
            let date = moment(utc)
            date = date.format("MM-DD-YYYY")
            let filename = 'MigrationResult_' + date + '.csv'
            // Download CSV file
            downloadCSV(response, filename);
          }
      });
    }
  });

  function downloadCSV(csv, filename){
    var csvFile;
    var downloadLink;

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
  };

})
