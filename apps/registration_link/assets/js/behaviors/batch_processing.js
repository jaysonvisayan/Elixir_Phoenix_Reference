const SortTable = () => {
  $.fn.sortDomElements = (function() {
  return function(comparator) {
      return Array.prototype.sort.call(this, comparator).each(function(i) {
            this.parentNode.appendChild(this);
      });
  };
  })();

  $("#sortPlease").children().sortDomElements(function(a,b){
      let akey = parseInt($(a).attr("sortkey"));
      let bkey = parseInt($(b).attr("sortkey"));
      if (akey == bkey) return 0;
      if (akey < bkey) return -1;
      if (akey > bkey) return 1;
  })
}

const LoadLoa = (batch_id) => {
  $.ajax({
    url: `/batch_processing/${batch_id}/search_batch_loa`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'GET',
    success: function(response){
      var table = $('#batch_table2').DataTable();
      table.destroy();
      $('#batch_table2').remove()

      var table =
      "<table class='full-width ui celled striped table' role='loa_table' id='tbl_consult' >"
      + "<thead>"
      + "<tr>"
      + "<th class='bold dim'>LOA No</th>"
      + "<th class='bold dim'>Patient Name</th>"
      + "<th class='bold dim'>Card No</th>"
      + "<th class='bold dim'>Coverage</th>"
      + "<th class='bold dim'>Admission Date</th>"
      // + "<td></td>"
      + "</tr>"
      + "</thead>"
      + "<tbody>"

      var data = ""
      if (response.loas.length == 0){
      }
      else
      {
        $.each(response.loas, function(i, loa){
          let loa_number = loa.number
          let loa_id = loa.id
          let loa_member = loa.member
          let loa_card_number = loa.card_number
          let loa_coverage = loa.coverage
          let loa_admission_dt = loa.admission_datetime

          if (loa_number == null)
          {
            loa_number = ""
          }
          if (loa_id == null)
          {
            loa_id = ""
          }
          if (loa_member == null)
          {
            loa_member = ""
          }
          if (loa_card_number == null)
          {
            loa_card_number = ""
          }
          if (loa_coverage == null)
          {
            loa_coverage = ""
          }
          if (loa_admission_dt == null)
          {
            loa_admission_dt = ""
          }

          data =
          ` ${data}
            <tr>
            <td class='bold'><a href='#' class='btnAddAuthorization' authorization_id=${loa_id}>${loa_number}</a></td>
            <td class='bold'>${loa_member}</td>
            <td class='bold'>${loa_card_number}</td>
            <td class='bold'>${loa_coverage}</td>
            <td class='bold'><p class='convert_date'>${loa_admission_dt}</p></td>
            </tr>
          `
        });
      }

      $('div[id="div_consult"]').html(table + data + "</tbody></table>");
      loadDataTable();

      $('#showLOAModal')
      .modal({
        closable  : false,
        autofocus: false,
      }).modal('show');


    }
  })
}

function loadDataTable() {
  $('table[role="loa_table"]').dataTable({
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
    pagingType: "simple_numbers",
		language: {
			emptyTable:     "No Records Found!",
			zeroRecords:    "No Matching Records Found!",
			search:         "Search",
			paginate: {
				first: "<i class='angle single left icon'></i> First",
				previous: "<i class='angle double left icon'></i> Previous",
				next: "Next <i class='angle double right icon'></i>",
				last: "Last <i class='angle single right icon'></i>"
			}
    },
    searching: true,
    "lengthMenu": [[5, 10, 25, 50, -1], [5, 10, 25, 50, "All"]]
  });
}

onmount('table[role="loa_table"]', function () {
  loadDataTable();
});

onmount('div[id="batch_index"]', function () {
  let batch_id = ""

  let table = $('#batch_table').DataTable( {
    "order": [[ 6, "desc" ]]
  } );

  setInterval(function(){
    $('.convert_date').each(function() {
      let value = $(this).html()
      let converted_date = moment(value).format('MMMM DD, YYYY')
      $(this).html(converted_date)
    })
  }, 50);


  setInterval(function(){
    $('.aging').each(function() {
      let value = moment().diff($(this).html(), 'days')
      $(this).removeClass('aging')
      $(this).html(`${value} day`)
    })
  }, 50);

  // TEMPORARY
  // table.rows().every(function(rowIdx, tableLoop, rowLoop) {
  //   let data = this.data()
  //   let value = data[6]
  //   let converted_date = moment(value).format('MMM DD, YYYY HH:MM')
  //   data[6] = converted_date
  //   this.data(data)
  // })

  $('.dropdown').dropdown()

  $('#btnCreateBatch').on('click', function()
  {
    $('#showModal')
    .modal({
      closable  : false,
      autofocus: false,
    }).modal('show');
  })

  $('body').on('click', '.btnAddLOA', function() {
    batch_id = ""
    batch_id = $(this).attr('batch_id')
    LoadLoa(batch_id)
  });

  $('#batch_table').on('mouseover', function(){
    $('.clickable-row').on('click', function(){
      window.document.location = $(this).attr("href");
    })

    $('.openSCM').on('click', function() {
      $('#submitConfirmationModal').modal('show')
      let batch_id = $(this).attr('batchId')
      $('#SCM_batch_id').val(batch_id)
    })
  })

  $('#batch_table').DataTable();
  $('#batch_table2').DataTable();

  $("#batch_processing").addClass("active")

  $('.btnAddAuthorization').on('click', function(){
    let authorization_id = $(this).attr('authorization_id')
    window.location.replace(`/batch_processing/${batch_id}/loa/${authorization_id}/new`)
  })
  let selected_batch_id = ""
  selected_batch_id = $('input[id="batch_id_val"]').val()

  $('#showLOAModal').on('mouseover', function(){
    SortTable()
    $('.btnAddAuthorization').on('click', function(){
      let authorization_id = $(this).attr('authorization_id')
      if (batch_id == "" && selected_batch_id != "")
      {
        window.location.replace(`/batch_processing/${selected_batch_id}/loa/${authorization_id}/new`)
      }
      else
      {
        window.location.replace(`/batch_processing/${batch_id}/loa/${authorization_id}/new`)
      }
    })
  })

  $('#pf_batch_dropdown').click(function(){
    window.location.replace('/batch_processing/pf_batch/new')
  })
  $('#hb_batch_dropdown').click(function(){
    console.log($('showModal').attr('conn').val())
    window.location.replace('/batch_processing/hb_batch/new')
  })

  let selected_batch_val = ""
  let permissions = $('#showModal').attr('connVal').split(",")
  $('#select_batch_button').on('click', function(){
    if (selected_batch_val == "HB")
    {

      if(permissions.includes("manage_hbbatch")){
        window.location.replace('/batch_processing/hb_batch/new')
      }
      else{
        //alert("You're not allowed to access this page")
        swal({
          title: 'Access denied',
          text: "You're not allowed to access this page",
          type: 'warning',
          showCancelButton: false,
          confirmButtonColor: '#21BA45',
          cancelButtonColor: '#d33',
          confirmButtonText: 'Ok',
          closeOnConfirm: true
        },
        function() {
          swal(
            'Deleted!',
            'Your file has been deleted.',
            'success'
          );
        });

      }
    }
    else if (selected_batch_val == "PF")
    {
      if(permissions.includes("manage_pfbatch")){
        window.location.replace('/batch_processing/pf_batch/new')
      }
      else{
         // alert("You're not allowed to access this page")
        swal({
          title: 'Access denied',
          text: "You're not allowed to access this page",
          type: 'warning',
          showCancelButton: false,
          confirmButtonColor: '#21BA45',
          cancelButtonColor: '#d33',
          confirmButtonText: 'Ok',
          closeOnConfirm: true
        },
        function() {
          swal(
            'Deleted!',
            'Your file has been deleted.',
            'success'
          );
        });
      }
    }
    else
    {
      alertify.warning('<i class="close icon"></i> <p>Please select a type of batch.</p>');
    }
  })

  $('#hb_batch_button').on('click', function(){
    selected_batch_val = $('#hb_batch_button').val()
  })

  $('#pf_batch_button').on('click', function(){
    selected_batch_val = $('#pf_batch_button').val()
  })

  $('#batch_download_button').click(function() {

    var table = $('#batch_table').DataTable();
    var search_result = table.rows({order:'current', search: 'applied'}).data();
    var search_value = $('.dataTables_filter input').val();

    if (search_result.length > 0){
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
          url:`/batch_processing/index/download`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {batch_param: { "search_value" : search_value.trim()}},
          dataType: 'json',
          success: function(response){
            //let utc = new Date()
            //let date = moment(utc)
            //date = date.format("MM-DD-YYYY")
            let filename = 'Batch_' + '.csv'
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

  $('#submitConfirmationNo').on('click', function() {
    $('#submitConfirmationModal').modal('hide')
  })

  $('#submitConfirmationYes').on('click', function() {
    let batch_id = $('#SCM_batch_id').val()
    const csrf = $('input[id="csrf"]').val();
    $.ajax({
      url:`/batch_processing/${batch_id}/submit_batch`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'post',
      success: function(response){
        if(response == "success"){
          alertify.success('<i class="close icon"></i>Batch has been submitted.')
          $('#add_loa_' + batch_id).addClass('disabled')
          $('#edit_batch_' + batch_id).addClass('disabled')
          $('#submit_' + batch_id).addClass('disabled')
        } else {
          alertify.error('<i class="close icon"></i>Please add LOA first.')
        }
      }
    })
    $('#submitConfirmationModal').modal('hide')
  })

  $('#scan_loa').on('click', function(){
    $('#modal_scan')
    .modal({
      closable: false,
      autofocus: false
    })
    .modal('show')

    let batch_id = $(this).attr('batch_id')
    $('#batch_id').val(batch_id)
  })
})

onmount('div[id="create_pf_summary"]', function () {
  $("#batch_processing").addClass("active")
})

onmount('div[id="create_pf"]', function () {

  $("#batch_processing").addClass("active")
  $('#date_received').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
	  formatter: {
        date: function (date, settings) {
            if (!date) return '';
            var day = date.getDate() + '';
            if (day.length < 2) {
                day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
                month = '0' + month;
            }
            var year = date.getFullYear();
            return year + '-' + month + '-' + day;
        }
    }
  })
  $('#date_due').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
	  formatter: {
        date: function (date, settings) {
            if (!date) return '';
            var day = date.getDate() + '';
            if (day.length < 2) {
                day = '0' + day;
            }
            var month = (date.getMonth() + 1) + '';
            if (month.length < 2) {
                month = '0' + month;
            }
            var year = date.getFullYear();
            return year + '-' + month + '-' + day;
        }
    }
  })
  $('#date_created').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
    formatter: {
      date: function (date, settings) {
        if (!date) return '';
        var day = date.getDate() + '';
        if (day.length < 2) {
          day = '0' + day;
        }
        var month = (date.getMonth() + 1) + '';
        if (month.length < 2) {
          month = '0' + month;
        }
        var year = date.getFullYear();
        return month + '/' + day + '/' + year;
      }
    }
  })
})

onmount('div[id="create_hb_summary"]', function () {
  $("#batch_processing").addClass("active")
})

onmount('div[id="create_hb"]', function () {
  $("#batch_processing").addClass("active")
  $('#date_received').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
    formatter: {
      date: function (date, settings) {
        if (!date) return '';
        var day = date.getDate() + '';
        if (day.length < 2) {
          day = '0' + day;
        }
        var month = (date.getMonth() + 1) + '';
        if (month.length < 2) {
          month = '0' + month;
        }
        var year = date.getFullYear();
        return month + '/' + day + '/' + year;
      }
    }
  })
  $('#date_due').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
    formatter: {
      date: function (date, settings) {
        if (!date) return '';
        var day = date.getDate() + '';
        if (day.length < 2) {
          day = '0' + day;
        }
        var month = (date.getMonth() + 1) + '';
        if (month.length < 2) {
          month = '0' + month;
        }
        var year = date.getFullYear();
        return month + '/' + day + '/' + year;
      }
    }
  })
  $('#date_created').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
    formatter: {
      date: function (date, settings) {
        if (!date) return '';
        var day = date.getDate() + '';
        if (day.length < 2) {
          day = '0' + day;
        }
        var month = (date.getMonth() + 1) + '';
        if (month.length < 2) {
          month = '0' + month;
        }
        var year = date.getFullYear();
        return month + '/' + day + '/' + year;
      }
    }
  })
})

onmount('div[role="LOAFileUpload"]', function() {

    const alert_error_file = () => {
        alertify.error('<i id="notification_error" class="close icon"></i><p>Acceptable file types are jpg, jpeg, png and pdf.</p>');
        alertify.defaults = {
            notifier: {
                delay: 5,
                position: 'top-right',
                closeButton: false
            }
        };
    }

    const alert_error_size = () => {
        alertify.error('<i id="notification_error" class="close icon"></i><p>Maxium document file size is 5 megabytes.</p>');
        alertify.defaults = {
            notifier: {
                delay: 5,
                position: 'top-right',
                closeButton: false
            }
        };
    }

    let counter = 1
    let delete_array = []

    $('#addFile').on('click', function() {
        let file_id = '#file_' + counter
        $('#filePreviewContainer').append(`<input type="file" style="display: none;" id="file_${counter}" name="batch[files][]">`)
        $(file_id).on('change', function() {
            let file = $(file_id)[0].files[0]
            let file_type = $(file_id)[0].files[0].type
            let file_name = $(file_id)[0].files[0].name
            let icon = 'file outline'
            if ((file_name.indexOf('.png') >= 0) || (file_name.indexOf('.jpg') >= 0) || (file_name.indexOf('.jpeg') >= 0) || (file_name.indexOf('.pdf') >= 0)) {
                if (file.size < 5000000) {
                    file = (window.URL || window.webkitURL).createObjectURL(file)
                } else {
                    $(this).val('')
                    alert_error_size()
                }
            } else {
                $(this).val('')
                alert_error_file()
            }
            if ($(this).val() != '') {
                let new_row =
                    `\
          <div class="item file-item">\
            <div class="right floated content">\
              <button class="ui button remove-file" fileID="${file_id}" type="button">Remove</button>\
            </div>\
            <i class="big ${icon} icon"></i>\
            <div class="content">\
              ${file_name}\
            </div>\
          </div>\
          `
                $('#filePreviewContainer').append(new_row)
            }
        })
        $(file_id).click()
        counter++
    })

    $('body').on('click', '.remove-file', function() {
        let file_id = $(this).attr('fileID')
        $(file_id).remove()
        $(this).closest('.item').remove()
    });

    $('body').on('click', '.remove-uploaded', function() {
        let file_id = $(this).attr('fileID')
        $(this).closest('.item').remove()
        if (delete_array.includes(file_id) == false) {
            delete_array.push(file_id)
        }
        $('#deleteIDs').val(delete_array)
    });

});

onmount('div[id="batch_authorization_file_form"]', function () {

  $('div[id="acu_availment_date"]').calendar({
      monthFirst: false,
      type: 'date',
      minDate: new Date(),
      onChange: function (start_date, text, mode) {
        $('#field_availment_date').removeClass('error')
        $('#doc_type_error_amount').remove()
      },
      formatter: {
        date: function (date, settings) {
          if (!date) return '';
          var day = date.getDate() + '';
          if (day.length < 2) {
            day = '0' + day;
          }
          var month = (date.getMonth() + 1) + '';
          if (month.length < 2) {
            month = '0' + month;
          }
          var year = date.getFullYear();
          return year + '-' + month + '-' + day;
        }
      }
    });

  const alert_error_document = () => {
      alertify.error('<i class="close icon"></i> Please add atleast one document.');
      alertify.defaults = {
          notifier: {
              delay: 5,
              position: 'top-right',
              closeButton: false
          }
      };
  }

  const alert_error_add_document = () => {
      alertify.error('<i class="close icon"></i> Please click <i> Add Documents </i> to add the document.');
      alertify.defaults = {
          notifier: {
              delay: 5,
              position: 'top-right',
              closeButton: false
          }
      };
  }

  $('#btnAddDocuments').on('click', function(){
    const csrf = $('input[name="_csrf_token"]').val();
    let batch_id = $(this).attr('batch_id')
    let authorization_id = $(this).attr('authorization_id')
    let doc_type = $("select[id='batch_document_type'] option:selected").val()
    let file_count = $('div[class="item file-item"]').length
    let coverage_name = $(this).attr('coverage_name')

    $('#batch_status').remove()
    $('#field_document_type').append('<input type="hidden" value="Add" id="batch_status" name="batch[status]">')
    if (coverage_name == "ACU")
    {
      if ($('#batch_availment_date').val() == "")
      {
        $('#field_availment_date').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#field_availment_date').addClass('error')
        $('#field_availment_date').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please enter availment date.</div>')
      }
      if (doc_type == "")
      {
        $('#field_document_type').removeClass('error')
        $('#doc_type_error').remove()
        $('#field_document_type').addClass('error')
        $('#field_document_type').append('<div id="doc_type_error" class="ui basic red pointing prompt label transition visible">Please select document type.</div>')
      }

      if ($('#batch_availment_date').val() == "")
      {
        $('#field_availment_date').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#field_availment_date').addClass('error')
        $('#field_availment_date').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please enter availment date.</div>')
      }
      else if (doc_type == "")
      {
        $('#field_document_type').removeClass('error')
        $('#doc_type_error').remove()
        $('#field_document_type').addClass('error')
        $('#field_document_type').append('<div id="doc_type_error" class="ui basic red pointing prompt label transition visible">Please select document type.</div>')
      }
      else
      {
        $('#field_document_type').removeClass('error')
        $('#doc_type_error').remove()
        if (file_count == 0)
        {
          alert_error_document()
        }
        else
        {
          var req =
           $.ajax({
            url:`/batch_processing/${batch_id}/loa/${authorization_id}/checker`,
            headers: {"X-CSRF-TOKEN": csrf},
            type: 'post',
            data: {id: batch_id, authorization_id: authorization_id},
            dataType: 'json',
            beforeSend: function()
            {
              $('#overlay').css("display", "block");
            },
            complete: function()
            {
              $('#overlay').delay(100000).fadeOut();
            }
          });

          req.done(function (data){
            let obj = JSON.parse(data)
            if (obj.has_batch_authorization == false)
            {
               $('#batch').submit()
            }
            else
            {
              window.location.replace(`/batch_processing/${batch_id}/return_not_available_loa`);
            }
          })
       }
      }
    }
    else
    {
      if (doc_type == "")
      {
        $('#field_document_type').removeClass('error')
        $('#doc_type_error').remove()
        $('#field_document_type').addClass('error')
        $('#field_document_type').append('<div id="doc_type_error" class="ui basic red pointing prompt label transition visible">Please select document type.</div>')
      }
      else
      {
        $('#field_document_type').removeClass('error')
        $('#doc_type_error').remove()
        if (file_count == 0)
        {
          alert_error_document()
        }
        else
        {
          var req =
           $.ajax({
            url:`/batch_processing/${batch_id}/loa/${authorization_id}/checker`,
            headers: {"X-CSRF-TOKEN": csrf},
            type: 'post',
            data: {id: batch_id, authorization_id: authorization_id},
            dataType: 'json',
            beforeSend: function()
            {
              $('#overlay').css("display", "block");
            },
            complete: function()
            {
              $('#overlay').delay(100000).fadeOut();
            }
          });

          req.done(function (data){
            let obj = JSON.parse(data)
            if (obj.has_batch_authorization == false)
            {
               $('#batch').submit()
            }
            else
            {
              window.location.replace(`/batch_processing/${batch_id}/return_not_available_loa`);
            }
          })
       }
      }
    }


  })

  $("input[id='batch_assessed_amount']").keypress(function (evt)
  {
    $('#field_assessed_amount').removeClass('error')
    $('#doc_type_error_amount').remove()
    evt = (evt) ? evt : window.event;
    var charCode = (evt.which) ? evt.which : evt.keyCode;
    if (charCode == 8 || charCode == 37) {
      return true;
    } else if (charCode == 46 && $(this).val().indexOf('.') != -1) {
      return false;
    } else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
      return false;
    }
    return true;

  });

   $('#btnSaveLoa').on('click', function(){
    let doc_type = $("select[id='batch_document_type'] option:selected").val()
    let reason = $("select[id='batch_reason'] option:selected").val()
    let assessed_amount = $("input[id='batch_assessed_amount']").val()
    let file_count = $('div[class="item file-item"]').length
    let row_count = $('#document_table > tbody >tr').length
    let total_amount = $('#authorization_total_amounts').val()
    const csrf = $('input[name="_csrf_token"]').val();
    let batch_id = $(this).attr('batch_id')
    let authorization_id = $(this).attr('authorization_id')
    let coverage_name = $(this).attr('coverage_name')
    $('#batch_status').remove()
    $('#field_document_type').append('<input type="hidden" value="Save" id="batch_status" name="batch[status]">')
    $('#field_assessed_amount').removeClass('error')
    $('#doc_type_error_amount').remove()

    if (assessed_amount == "")
    {
      $('#field_assessed_amount').removeClass('error')
      $('#doc_type_error_amount').remove()
      $('#field_assessed_amount').addClass('error')
      $('#field_assessed_amount').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please enter assessed amount.</div>')
    }

    if (coverage_name == "ACU")
    {
      if ($('#batch_availment_date').val == "")
      {
        $('#field_availment_date').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#field_availment_date').addClass('error')
        $('#field_availment_date').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please enter availment date.</div>')
      }
    }

    if (assessed_amount == 0)
    {
      $('#field_assessed_amount').removeClass('error')
      $('#doc_type_error_amount').remove()
      $('#field_assessed_amount').addClass('error')
      $('#field_assessed_amount').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please do not enter 0 value.</div>')
    }
    if (reason == "")
    {
      $('#field_reason').removeClass('error')
      $('#doc_type_error_reason').remove()
      $('#field_reason').addClass('error')
      $('#field_reason').append('<div id="doc_type_error_reason" class="ui basic red pointing prompt label transition visible">Please select reason.</div>')
    }

    if (coverage_name == "ACU")
    {
      if ($('#batch_availment_date').val() == "")
      {
        $('#field_availment_date').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#field_availment_date').addClass('error')
        $('#field_availment_date').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please enter availment date.</div>')
      }
      else if (assessed_amount == "")
      {
        $('#field_assessed_amount').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#field_assessed_amount').addClass('error')
        $('#field_assessed_amount').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please enter assessed amount.</div>')
      }
      else if (reason == "")
      {
        $('#field_reason').removeClass('error')
        $('#doc_type_error_reason').remove()
        $('#field_reason').addClass('error')
        $('#field_reason').append('<div id="doc_type_error_reason" class="ui basic red pointing prompt label transition visible">Please select reason.</div>')
      }
      else if (assessed_amount == 0)
      {
        $('#field_assessed_amount').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#field_assessed_amount').addClass('error')
        $('#field_assessed_amount').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please do not enter 0 value.</div>')
      }
      else
      {
        if (parseFloat(assessed_amount) > parseFloat(total_amount))
        {
          $('#field_assessed_amount').removeClass('error')
          $('#doc_type_error_amount').remove()
          $('#field_assessed_amount').addClass('error')
          $('#field_assessed_amount').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Assessed Amount must not be greater than the Total LOA Amount.</div>')
        }
        else
        {
          if (file_count >= 1)
          {
            alert_error_add_document()
          }
          else
          {
            if(row_count >= 1)
            {
              $('#batch').submit()
            }
            else
            {
              alert_error_document()
            }
          }
        }
      }
    }
    else
    {
      if (assessed_amount == "")
      {
        $('#field_assessed_amount').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#field_assessed_amount').addClass('error')
        $('#field_assessed_amount').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please enter assessed amount.</div>')
      }
      else if (reason == "")
      {
        $('#field_reason').removeClass('error')
        $('#doc_type_error_reason').remove()
        $('#field_reason').addClass('error')
        $('#field_reason').append('<div id="doc_type_error_reason" class="ui basic red pointing prompt label transition visible">Please select reason.</div>')
      }
      else if (assessed_amount == 0)
      {
        $('#field_assessed_amount').removeClass('error')
        $('#doc_type_error_amount').remove()
        $('#field_assessed_amount').addClass('error')
        $('#field_assessed_amount').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Please do not enter 0 value.</div>')
      }
      else
      {
        if (parseFloat(assessed_amount) > parseFloat(total_amount))
        {
          $('#field_assessed_amount').removeClass('error')
          $('#doc_type_error_amount').remove()
          $('#field_assessed_amount').addClass('error')
          $('#field_assessed_amount').append('<div id="doc_type_error_amount" class="ui basic red pointing prompt label transition visible">Assessed Amount must not be greater than the Total LOA Amount.</div>')
        }
        else
        {
          if (file_count >= 1)
          {
            alert_error_add_document()
          }
          else
          {
            if(row_count >= 1)
            {
              $('#batch').submit()
            }
            else
            {
              alert_error_document()
            }
          }
        }
      }
    }
  })

  $("select[id='batch_document_type']").on('change', function(){
    $('#field_document_type').removeClass('error')
    $('#doc_type_error').remove()
  })

  $("select[id='batch_reason']").on('change', function(){
    $('#field_reason').removeClass('error')
    $('#doc_type_error_reason').remove()
  })

  let batch_id = ""

  $('#btnAddNewLoa').on('click', function()
  {
    batch_id = ""
    batch_id = $(this).attr('batch_id')
    LoadLoa(batch_id)
  })

   $('.btnAddAuthorization').on('click', function(){
    let authorization_id = $(this).attr('authorization_id')
    window.location.replace(`/batch_processing/${batch_id}/loa/${authorization_id}/new`)
  })

  $('div[class="ui simple basic top right pointing dropdown"]').find('a[class="item btnViewDocument"]').on('click', function(e){
    e.preventDefault()
    let file_location = ($(this).attr('location'))
    window.open(file_location, '_blank')
  })

  $('div[class="ui simple basic top right pointing dropdown"]').find('a[class="item btnRemoveDocument"]').on('click', function(e){

    let batch_authorization_file_id = ($(this).attr('batch_authorization_file_id'))

    swal({
      title: 'Remove Document?',
      text: "Deleting this document will permanently remove it from the system.",
      type: 'warning',
      showCancelButton: true,
      cancelButtonText: '<i class="remove icon"></i> No, Keep document',
      confirmButtonText: '<i class="check icon"></i> Yes, Remove document',
      cancelButtonClass: 'ui negative button',
      confirmButtonClass: 'ui positive button',
      reverseButtons: true,
      buttonsStyling: false
    }).then(function () {
        window.location.replace(`/batch_processing/${batch_authorization_file_id}/delete_batch_authorization_file`);
    })
  })

  $('#btnCancelLoa').on('click', function(e){

    let batch_authorization_id = ($(this).attr('batch_authorization_id'))

    swal({
      title: 'Are you sure you want to cancel?',
      text: "Canceling this transaction will discard documents.",
      type: 'question',
      showCancelButton: true,
      cancelButtonText: '<i class="remove icon"></i> No',
      confirmButtonText: '<i class="check icon"></i> Yes',
      cancelButtonClass: 'ui negative button',
      confirmButtonClass: 'ui positive button',
      reverseButtons: true,
      buttonsStyling: false
    }).then(function () {
      window.location.replace(`/batch_processing/${batch_authorization_id}/delete_batch_authorization`);
    })
  })

  $('#btnBackLoa').on('click', function(e){

    let batch_id = ($(this).attr('batch_id'))
    window.location.replace(`/batch_processing/${batch_id}/return_index`);
  })

})

onmount('input[id="open_modal_batch_index"]', function () {
  window.history.replaceState('', 'RegistrationLink', '/batch_processing');
  let selected_batch_id = ""
  selected_batch_id = $('input[id="batch_id_val"]').val()
  LoadLoa(selected_batch_id)

  $('.btnAddLOA').on('click', function()
  {
    selected_batch_id = ""
    selected_batch_id = $(this).attr('batch_id')
    LoadLoa(selected_batch_id)
  })

  $('.btnAddAuthorization').on('click', function(){
    let authorization_id = $(this).attr('authorization_id')
    window.location.replace(`/batch_processing/${selected_batch_id}/loa/${authorization_id}/new`)
  })

})
