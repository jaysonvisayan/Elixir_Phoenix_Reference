onmount('div[id="benefits_index"]', function(){
    $('a#export_button').on('click', function(){
    let benefit_codes = []
    var table = $('#benefits_table').DataTable()
    var search_result = table.rows({order:'current', search: 'applied'}).data()
    var search_value = $('.dataTables_filter input').val()

    if (search_result.length > 0) {
      const csrf2 = $('input[name="_csrf_token"]').val()
      $.ajax({
          url:`/benefits/index/download`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {benefit_param: { "search_value" : search_value.trim()}},
          dataType: 'json',
          success: function(response){
            let utc = new Date()
            let date = moment(utc)
            date = date.format("MM-DD-YYYY")
            let filename = 'Benefit_' + date + '.csv'
            // Download CSV file
            downloadCSV(response, filename)
          }
      })
    }
  })


  function downloadCSV(csv, filename){
    var csvFile
    var downloadLink

    // CSV file
    csvFile = new Blob([csv], {type: "text/csv"})

    // Download link
    downloadLink = document.createElement("a")

    // File name
    downloadLink.download = filename

    // Create a link to the file
    downloadLink.href = window.URL.createObjectURL(csvFile)

    // Hide download link
    downloadLink.style.display = "none"

    // Add the link to DOM
    document.body.appendChild(downloadLink)

    // Click download link
    downloadLink.click()
  }
})