onmount('.download-csv', function () {
  $('div[role="download"]').on('click', function(){
    const csrf = $('input[name="_csrf_token"]').val();
    let member_id = $(this).attr("memberID")

    $.ajax({
      url:`/en/export/${member_id}/loa`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      success: function(response){

        let utc = new Date()
        let date = moment(utc)
        let time = moment(utc)
        date = date.format("MM-DD-YYYY")
        time = time.format("HHmmss")
        let filename =  'export' + '_loa' +'.csv'
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

onmount('.export-pdf', function () {
  $('.export-pdf-loa').click(function() {
    let member_id = $(this).attr('memberID')
    window.open(`/en/transaction/${member_id}/export_pdf`, '_blank')
  });

})
