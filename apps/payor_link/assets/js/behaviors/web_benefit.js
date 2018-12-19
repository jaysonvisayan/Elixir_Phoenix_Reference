onmount('div[id="benefit_index_page"]', function () {
  $(document).ready(function () {
    $('.modal-open-main').click(function () {
      //$('.ui.rtp-modal').modal('show');
      $('.ui.modal:not(.ui.send-rtp-modal)').modal('show');
    });
  });

  $('.send-rtp-modal').modal('attach events', '.button.send-rtp');
  $('.benefit.modal').modal('attach events', '.modal-open-benefit');
  $('.packages.modal').modal('attach events', '.modal-open-package');
  $('.complete.modal').modal('attach events', '.modal-open-complete')
  $('.facilities.modal').modal('attach events', '.modal-open-facilities');
  $('.procedure.modal').modal('attach events', '.modal-open-procedure');
  $('.limit.modal').modal('attach events', '.modal-open-limit');

  const csrf = $('input[name="_csrf_token"]').val();

  $('#benefit_table').DataTable({
    "ajax": $.fn.dataTable.dt_timeout(
      `/web/benefits/index/data`,
      csrf
    ),
    "processing": true,
    "serverSide": true
  });

  $('.toggle_btn_modal').click(function(){
    $('.selection-button').removeClass('active_modal')
    $('.toggle_ico').removeClass('white')
    $('.toggle_ico').addClass('dark')

    $(this).find('.selection-button').addClass('active_modal')
    $(this).find('.toggle_ico').addClass('white')
    $(this).find('.toggle_ico').removeClass('dark')

    let option = $(this).find('.option').attr('value')
    $('#benefit_type').val(option)
  })

  $('a#export_button').on('click', function(){
    $('.ui.dimmer').addClass('active')
    var table = $('#benefit_table').DataTable()
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
          success: response => {
            let utc = new Date()
            let date = moment(utc)
            date = date.format("MM-DD-YYYY")
            let filename = 'Benefit_' + date + '.csv'
            // Download CSV file
            downloadCSV(response, filename)
            $('.ui.dimmer').removeClass('active')
          },
          error: (xhr, ajaxOptions, thrownError) => {
            window.location.replace('/sign_out_error_dt')
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
