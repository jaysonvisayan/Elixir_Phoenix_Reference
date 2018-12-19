onmount('div[id="member_account_reports"]', function () {

  $('#export_btn_account_members').on("click", function(e){
    var account_group_code = $('#account_group_code_name').val()
    var table = $('#account_member_tbl').DataTable();
    var search_result = table.rows({search: 'applied'}).data();
    var search_value = $('#account_member_tbl_filter input').val();
    // console.log$('#account_member_tbl_filter input').val()
    var member_type = $('#params_member_type').val();
    var member_status = $('#params_member_status').val();

    if (search_result.length > 0){
      const csrf = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/api/v1/members/reports/csv_download`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        data: {am_param: { "search_value" : search_value.trim(),"account_code" : account_group_code, "member_type" : member_type,"member_status" : member_status }},
        dataType: 'json',
        success: function(response){

          let utc = new Date()
          let date = moment(utc)
          date = date.format("MM-DD-YYYY")
          let filename = 'AccountMember' + date + '.csv'
          // Download CSV file
          downloadCSV(response, filename);
        }
      });
    }
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


})
