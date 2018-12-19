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

onmount('div[id="procedures_uploaded_file"]', function(){
  $('.download_success_button').on('click', function(){
      const csrf2 = $('input[name="_csrf_token"]').val();

      const ppu_id = $(this).attr('ppu_id')
      const status = $(this).attr('status')
      const s_filename = $(this).attr('ppu_filename').slice(0, -4)
      const list = [ppu_id,status]
          let csv = [];
      $.ajax({
          url:`/procedures/download/success/uploaded`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {payor_procedure: { "list" : list}},
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

    const ppu_id = $(this).attr('ppu_id')
    const status = $(this).attr('status')
    const f_filename = $(this).attr('ppu_filename').slice(0, -4)

    const list = [ppu_id,status]
        let csv = [];
    $.ajax({
        url:`/procedures/download/success/uploaded`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {payor_procedure: { "list" : list}},
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

onmount('div[id="product_index"]', function(){

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


  $('#export_button').on('click', function(){
    let col
    let csv = [];
    let rows = document.querySelectorAll("table tr");
    if (rows.length == 2)
      {
        col = rows[1].querySelectorAll("td, th")
        if (col[0].innerText == 'No Matching Records Found!')
          {
            alert('No Record Found to Download')
          }
          else
            {
              for (let i = 0; i < rows.length; i++) {
                let row = [], cols = rows[i].querySelectorAll("td, th");

                for (let j = 0; j < 1; j++)
                {
                  if (i == 0){
                  }
                  else
                    {
                      let str = (cols[j].innerText).replace(' (Draft)','');
                      row.push(str);
                      csv.push(row.join(','));
                    }
                }
              }

            }
      }
      else

        {
          for (let i = 0; i < rows.length; i++) {
            let row = [], cols = rows[i].querySelectorAll("td, th");

            for (let j = 0; j < 1; j++)
            {
              if (i == 0){
              }
              else
                {
                  let str = (cols[j].innerText).replace(' (Draft)','');
                  row.push(str);
                  csv.push(row.join(','));
                }
            }
          }
        }

        col = rows[1].querySelectorAll("td, th")
        if (col[0].innerText != 'No Matching Records Found!')
          {
      const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/api/v1/products/download`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {product_param: { "product_code" : csv}},
          dataType: 'json',
          success: function(response)
          {
            const data = JSON.parse(response)
            let csv = []
            let title = "Plan Code,Plan Name,Plan Description,Plan Classification,Created By,Date Created,Updated By,Date Updated"
            csv.push(title)
            let string = ""
            for (let i = 0; i < data.length; i++) {
              for (let j = 0; j < data[i].length; j++)
              {
                if (j == 0)
                  {
                    string = '"' + string + data[i][j] + '"'
                  }
                  else if(j == data[i].length -1 )
                    {
                      string = string + ',' + '"' + data[i][j] + '"'
                    }
                    else
                      {
                        if (j == 3 && data[i][j] == 'Yes') {

                          string = string + ',' + '"' + 'Standard' + '"'
                        }
                        else if (j == 3 && data[i][j] == 'No')
                          {
                          string = string + ',' + '"' + 'Custom' + '"'
                          }
                          else
                            {
                          string = string + ',' + '"' + data[i][j] + '"'
                            }
                      }

              }
              csv.push(string)
              string = ''
            }
            let utc = new Date()
            let date = moment(utc)
            date = date.format("MM-DD-YYYY")
            let filename = 'Product_' + date + '.csv'
            // Download CSV file
            downloadCSV(csv.join("\n"), filename);
            }
        });
          }


  });

  });


onmount('div[id="procedures_index"]', function(){
    $('a#export_button').on('click', function(){
    let procedure_codes = [];
    var table = $('#procedures_table').DataTable();
    var search_result = table.rows({order:'current', search: 'applied'}).data();
    var search_value = $('.dataTables_filter input').val();

    if (search_result.length > 0) {
      const csrf2 = $('input[name="_csrf_token"]').val();
      let utc = new Date()
      let date = moment(utc)
      date = date.format("MM-DD-YYYY")
      let filename = 'Procedure_' + date + '.csv'
      $.ajax({
          url:`/procedures/index/download`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {procedure_param: { "search_value" : search_value.trim()}},
          dataType: 'json',
          success: function(response){
            if(response == ""){
              alert("Error exporting procedures!")
            }
            else{
              downloadCSV(response, filename);
            }
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
});

onmount('div[id="practitioners_index"]', function(){
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
  $('#export_button').on('click', function(){
    let csv = [];
    let rows = document.querySelectorAll("table tr");
if (rows.length == 2)
  {
    let col = rows[1].querySelectorAll("td, th")
    if (col[0].innerText == 'No Records Found!')
      {
        alert('No Records Found to Download')
      }
      else
        {
          for (let i = 0; i < rows.length; i++) {
            let row = [], cols = rows[i].querySelectorAll("td, th");

            for (let j = 0; j < 1; j++)
            {
              if (i == 0){
              }
              else
                {
                  row.push(cols[j].innerText);
                  csv.push(row.join(','));
                }
            }
          }

        }
  }
  else

    {
      for (let i = 0; i < rows.length; i++) {
        let row = [], cols = rows[i].querySelectorAll("td, th");

        for (let j = 0; j < 1; j++)
        {
          if (i == 0){
          }
          else
            {
              row.push(cols[j].innerText);
              csv.push(row.join(','));
            }
        }
      }
    }



    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/api/v1/practitioners/download`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      data: {practitioner_param: {"practitioner_code" : csv}},
      dataType: 'json',
      success: function(response)
      {
        const data = JSON.parse(response)
        let csv = []
        let title = "Physician Code,Physician Name,Status,Specialization,Sub-Specialization,Provider Code,Provider Name"
        csv.push(title)
        let string = ""
        for (let i = 0; i < data.length; i++) {
          for (let j = 0; j < data[i].length; j++)
          {
            if (j == 0)
              {
                string = '"' + string + data[i][j] + '"'
              }
              else if(j == data[i].length -1 && i == data.length -1)
                {

                  string = string + ',' + '"' + data[i][j] + '"'
                }
                else if(j == data[i].length -1 )
                  {
                    string = string + ',' + '"' + data[i][j] + '"'
                  }

                  else
                    {
                      string = string + ',' + '"' + data[i][j] + '"'
                    }

          }
          csv.push(string)
          string = ''
        }
        let utc = new Date()
        let date = moment(utc)
        date = date.format("MM-DD-YYYY")
        let filename = 'Practitioner_' + date + '.csv'
        // Download CSV file
        downloadCSV(csv.join("\n"), filename);
      }
    });
  });
});
