onmount('div[id="special_details"]', function () {

  $('button[name="btn_reject"]').on('click', function(){
    if ($('hr[name="_hr"]').hasClass('hide') == true)
    {
      $('hr[name="_hr"]').removeClass('hide');
      $('div[name="reason_field"]').removeClass('hide');
    }
    else
    {
      $('input[name="authorization_amount[action]"]').val('Reject');
    }

    $('#approval')
      .form({
        on: 'blur',
        inline: true,
        fields: {
          reason: {
            identifier: 'authorization_amount[reason]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter a reason for rejected LOA.'
            }]
          }  
        }
      });
  });

  $('button[name="btn_approve"]').on('click', function(){
    $('#approval')
      .form({
        on: 'blur',
        inline: true,
        fields: {
          
        }
      });

    $('input[name="authorization_amount[action]"]').val('Approve');

  });

  $('input[id="authorization_amount_company_covered"]').keypress(function() {
    let total_amount = $('span[name="total_amount"]').html();
    let total = total_amount;
    let payor_pays = $('input[id="authorization_amount_payor_covered"]').val();
    let company_pays = $('input[id="authorization_amount_company_covered"]').val();
    if (company_pays == "")
    {
      total_amount = parseFloat(total_amount) - parseFloat(payor_pays);
    }
    else 
    {
      total_amount = parseFloat(total_amount) - parseFloat(payor_pays) - parseFloat(company_pays);
      if (total_amount < 0)
      {
        total_amount = 0
      }
      
      if (parseFloat(company_pays) > parseFloat(total)) 
      {
        alertify.error('<i class="close icon"></i>Amount is Exceeded')
      } 
    }
    $('input[id="authorization_amount_member_covered"]').val(total_amount);
  });
 
});

onmount('div[id="special_index"]', function () {

  $('#export_button').on('click', function(){
    
    let status = $('select[name="drpdwn_status"]').val();
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
        url:`/api/v1/special/download`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {special_param: { "search_value" : status.trim()}},
        dataType: 'json',
        success: function(response){
          let utc = new Date()
          let date = moment(utc)
          date = date.format("MM-DD-YYYY")
          let filename = 'Special_Approval_' + date + '.csv'
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
