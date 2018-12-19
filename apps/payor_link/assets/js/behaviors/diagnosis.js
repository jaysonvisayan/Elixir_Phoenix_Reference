onmount('div[role="diagnosis-details"]', function(){
  $('.show-diagnosis-details').click(function() {
    $('div[role="show-details"]').modal('show');

    let diagnosis_id = $(this).attr('diagnosisId');
    let code = $(this).closest('tr').find('td[field="code"]').text().trim();
    let description = $(this).closest('tr').find('td[field="description"]').text().trim();
    let group_code = $(this).closest('tr').find('input[field="group_code"]').val().trim();
    let group_description = $(this).closest('tr').find('input[field="group_description"]').val().trim();
    let group_name = $(this).closest('tr').find('td[field="group_name"]').text().trim();
    let chapter = $(this).closest('tr').find('td[field="chapter"]').text().trim();
    let type = $(this).closest('tr').find('td[field="type"]').text().trim();
    let congenital = $(this).closest('tr').find('td[field="congenital"]').text().trim();
    let coverages = $(this).closest('tr').find('input[field="coverages"]').val().trim();

    $('label[id="code"]').text(code);
    $('label[id="description"]').text(description);
    $('label[id="group_code"]').text(group_code);
    $('label[id="group_description"]').text(group_description);
    $('label[id="group_name"]').text(group_name);
    $('label[id="chapter"]').text(chapter);
    $('label[id="type"]').text(type);
    $('label[id="congenital"]').text(congenital);
    $('label[id="coverages"]').text(coverages);
    $('input[id="diagnosis_id"]').val(diagnosis_id);
    $('a[id="edit_button"]').attr('href', '/diseases/' + diagnosis_id + '/edit')
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

  $('#export_button').on('click', function(){
    let diagnosis_codes = [];
    var table = $('#diagnosis_table').DataTable();
    var search_result = table.rows({order:'current', search: 'applied'}).data();
    var search_value = $('.dataTables_filter input').val();

    if (search_result.length > 0) {
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
          url:`/api/v1/diagnosis/download`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {diagnosis_param: { "search_value" : search_value.trim()}},
          dataType: 'json',
          success: function(response){

            let utc = new Date()
            let date = moment(utc)
            date = date.format("MM-DD-YYYY")
            let filename = 'Diagnosis_' + date + '.csv'
            // Download CSV file
            downloadCSV(response, filename);
          }
      });
    }
  });
});

onmount('div[role="diagnosis-logs"]', function(){
  $('a[id="diagnosis_logs"]').click(function() {
    var diagnosis_id = $('input[id="diagnosis_id"]').val();

    $.ajax({
      url: `/diseases/${diagnosis_id}/logs`,
      type: 'get',
      success: function(response) {
        var data = JSON.parse(response);

        $('div[role="diagnosis-logs"]').modal('show');
        $('#diagnosis_logs_table').html('');
        if(jQuery.isEmptyObject(data)){
          var no_log = 'NO LOGS FOUND'
          $("#diagnosis_logs_table").removeClass('feed timeline')
          $('#diagnosis_logs_table').append(no_log);
        }  else {
          $("#diagnosis_logs_table").addClass('feed timeline');
          for(let i=0; i < data.length; i++) {
            var new_row = '<div class="ui feed"><div class="event">' +
                          '<div class="label"><i class="blue circle icon"></i></div>' +
                          '<div class="scrolling content">' +
                          '<div class="summary"><p>' + moment(data[i].inserted_at).format('MMMM Do YYYY, h:mm a') + '</p></div>' +
                          '<div class="extra text">' + data[i].message + '</div>' +
                          '</div>' +
                          '</div></div>';
          $('#diagnosis_logs_table').append(new_row);
          }
        }
      }
    });
  });

});

onmount('div[role="diagnosis-details"]', function(){
  let table = $('table[role="datatable"]').DataTable({
    dom:
      "<'ui grid'"+
      "<'row'"+
      "<'eight wide column'l>"+
      "<'right aligned eight wide column'f>"+
      ">"+
      "<'row dt-table'"+
      "<'sixteen wide column'tr>"+
      ">"+
      "<'row'"+
      "<'seven wide column'i>"+
      "<'right aligned nine wide column'p>"+
      ">"+
      ">",
    renderer: 'semanticUI',
    pagingType: "full_numbers",
    language: {
      emptyTable:     "No Records Found!",
      zeroRecords:    "No Records Found!",
      search:         "Search",
      paginate: {
        first: "<i class='angle single left icon'></i> First",
        previous: "<i class='angle double left icon'></i> Previous",
        next: "Next <i class='angle double right icon'></i>",
        last: "Last <i class='angle single right icon'></i>"
      }
    },
    'columnDefs':[
      {
        'targets': 0,
        'createdCell': function (td, cellData, rowData, row, col) {
          $(td).attr('field', 'code');
        }
      },
      {
        'targets': 1,
        'createdCell': function (td, cellData, rowData, row, col) {
          $(td).attr('field', 'description');
        }
      },
      {
        'targets': 2,
        'createdCell': function (td, cellData, rowData, row, col) {
          $(td).attr('field', 'group_name');
        }
      },
      {
        'targets': 3,
        'createdCell': function (td, cellData, rowData, row, col) {
          $(td).attr('field', 'chapter');
        }
      },
      {
        'targets': 4,
        'createdCell': function (td, cellData, rowData, row, col) {
          $(td).attr('field', 'type');
        }
      },
      {
        'targets': 5,
        'createdCell': function (td, cellData, rowData, row, col) {
          $(td).attr('field', 'congenital');
        }
      }
    ]
  });
  $('input[type="search"]').unbind('on').on('keyup', function(){
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/diseases/load_datatable`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      data: {params: { "search" : $(this).val().trim(), "offset" : 0}},
      dataType: 'json',
      success: function(response){
        console.log(response.diagnosis)
        table.clear()
        let dataSet = []
        for (let i=0;i<response.diagnosis.length;i++){
          let coverages = response.diagnosis[i].diagnosis_coverages.toString()
          table.row.add( [
            `<a class="show-diagnosis-details pointer" diagnosisId="${response.diagnosis[i].id}">${response.diagnosis[i].code}</a></td>`,
            response.diagnosis[i].description,
            response.diagnosis[i].group_name,
            response.diagnosis[i].chapter,
            response.diagnosis[i].type,
            `${response.diagnosis[i].congenital}
            <input type="hidden" field="group_description" value="${response.diagnosis[i].group_description}">
            <input type="hidden" field="group_code" value="${response.diagnosis[i].group_code}">
            <input type="hidden" field="coverages" value="${coverages}">`
          ] ).draw();
        }

         $('#diagnosis-index tbody').on('click', '.show-diagnosis-details', function () {
          $('div[role="show-details"]').modal('show');
          let diagnosis_id = $(this).attr('diagnosisId');
          let code = $(this).closest('tr').find('td[field="code"]').text().trim();
          let description = $(this).closest('tr').find('td[field="description"]').text().trim();
          let group_code = $(this).closest('tr').find('input[field="group_code"]').val().trim();
          let group_description = $(this).closest('tr').find('input[field="group_description"]').val().trim();
          let group_name = $(this).closest('tr').find('td[field="group_name"]').text().trim();
          let chapter = $(this).closest('tr').find('td[field="chapter"]').text().trim();
          let type = $(this).closest('tr').find('td[field="type"]').text().trim();
          let congenital = $(this).closest('tr').find('td[field="congenital"]').text().trim();
          let coverages = $(this).closest('tr').find('input[field="coverages"]').val().trim();

          $('label[id="code"]').text(code);
          $('label[id="description"]').text(description);
          $('label[id="group_code"]').text(group_code);
          $('label[id="group_description"]').text(group_description);
          $('label[id="group_name"]').text(group_name);
          $('label[id="chapter"]').text(chapter);
          $('label[id="type"]').text(type);
          $('label[id="congenital"]').text(congenital);
          $('label[id="coverages"]').html(coverages);
          $('input[id="diagnosis_id"]').val(diagnosis_id);
          $('a[id="edit_button"]').attr('href', '/diseases/' + diagnosis_id + '/edit')
        });
      }
    })
  })
  $('.dataTables_length').find('.ui.dropdown').on('change', function(){
    if ($(this).find('.text').text() == 100){
      let info = table.page.info();
      if (info.pages - info.page == 1){
        let search = $('.dataTables_filter input').val();
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/diseases/load_datatable`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {params: { "search" : search.trim(), "offset" : info.recordsTotal}},
          dataType: 'json',
          success: function(response){
            let dataSet = []
            for (let i=0;i<response.diagnosis.length;i++){
              let coverages = response.diagnosis[i].diagnosis_coverages.toString()
              table.row.add( [
              `<a class="show-diagnosis-details pointer" diagnosisId="${response.diagnosis[i].id}">${response.diagnosis[i].code}</a>`,
              response.diagnosis[i].description,
              response.diagnosis[i].group_name,
              response.diagnosis[i].chapter,
              response.diagnosis[i].type,
              `${response.diagnosis[i].congenital}
              <input type="hidden" field="group_description" value="${response.diagnosis[i].group_description}">
              <input type="hidden" field="group_code" value="${response.diagnosis[i].group_code}">
              <input type="hidden" field="coverages" value="${coverages}">`
            ] ).draw(false);
            }
            $('div[role="diagnosis-details"] tbody').on('click', '.show-diagnosis-details', function () {
              $('div[role="show-details"]').modal('show');
              let diagnosis_id = $(this).attr('diagnosisId');
              let code = $(this).closest('tr').find('td[field="code"]').text().trim();
              let description = $(this).closest('tr').find('td[field="description"]').text().trim();
              let group_code = $(this).closest('tr').find('input[field="group_code"]').val().trim();
              let group_description = $(this).closest('tr').find('input[field="group_description"]').val().trim();
              let group_name = $(this).closest('tr').find('td[field="group_name"]').text().trim();
              let chapter = $(this).closest('tr').find('td[field="chapter"]').text().trim();
              let type = $(this).closest('tr').find('td[field="type"]').text().trim();
              let congenital = $(this).closest('tr').find('td[field="congenital"]').text().trim();
              let coverages = $(this).closest('tr').find('input[field="coverages"]').val().trim();

              $('label[id="code"]').text(code);
              $('label[id="description"]').text(description);
              $('label[id="group_code"]').text(group_code);
              $('label[id="group_description"]').text(group_description);
              $('label[id="group_name"]').text(group_name);
              $('label[id="chapter"]').text(chapter);
              $('label[id="type"]').text(type);
              $('label[id="congenital"]').text(congenital);
              $('label[id="coverages"]').text(coverages);
              $('input[id="diagnosis_id"]').val(diagnosis_id);
              $('a[id="edit_button"]').attr('href', '/diseases/' + diagnosis_id + '/edit')
            });
          }
        })
      }
    }
  })
  let info
  table.on('page', function () {
    info = table.page.info();
    if (info.pages - info.page == 1){
      let search = $('.dataTables_filter input').val();
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/diseases/load_datatable`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {params: { "search" : search.trim(), "offset" : info.recordsTotal}},
        dataType: 'json',
        success: function(response){
          let dataSet = []
            for (let i=0;i<response.diagnosis.length;i++){
              let coverages = response.diagnosis[i].diagnosis_coverages.toString()
              table.row.add( [
              `<a class="show-diagnosis-details pointer" diagnosisId="${response.diagnosis[i].id}">${response.diagnosis[i].code}</a>`,
              response.diagnosis[i].description,
              response.diagnosis[i].group_name,
              response.diagnosis[i].chapter,
              response.diagnosis[i].type,
              `${response.diagnosis[i].congenital}
              <input type="hidden" field="group_description" value="${response.diagnosis[i].group_description}">
              <input type="hidden" field="group_code" value="${response.diagnosis[i].group_code}">
              <input type="hidden" field="coverages" value="${coverages}">`
            ] ).draw(false);
          }
          $('div[role="diagnosis-details"] tbody').on('click', '.show-diagnosis-details', function () {
            $('div[role="show-details"]').modal('show');
            let diagnosis_id = $(this).attr('diagnosisId');
            let code = $(this).closest('tr').find('td[field="code"]').text().trim();
            let description = $(this).closest('tr').find('td[field="description"]').text().trim();
            let group_code = $(this).closest('tr').find('input[field="group_code"]').val().trim();
            let group_description = $(this).closest('tr').find('input[field="group_description"]').val().trim();
            let group_name = $(this).closest('tr').find('td[field="group_name"]').text().trim();
            let chapter = $(this).closest('tr').find('td[field="chapter"]').text().trim();
            let type = $(this).closest('tr').find('td[field="type"]').text().trim();
            let congenital = $(this).closest('tr').find('td[field="congenital"]').text().trim();
            let coverages = $(this).closest('tr').find('input[field="coverages"]').val().trim();

            $('label[id="code"]').text(code);
            $('label[id="description"]').text(description);
            $('label[id="group_code"]').text(group_code);
            $('label[id="group_description"]').text(group_description);
            $('label[id="group_name"]').text(group_name);
            $('label[id="chapter"]').text(chapter);
            $('label[id="type"]').text(type);
            $('label[id="congenital"]').text(congenital);
            $('label[id="coverages"]').text(coverages);
            $('input[id="diagnosis_id"]').val(diagnosis_id);
            $('a[id="edit_button"]').attr('href', '/diseases/' + diagnosis_id + '/edit')
          });
        }
      })
    }
  });
});
