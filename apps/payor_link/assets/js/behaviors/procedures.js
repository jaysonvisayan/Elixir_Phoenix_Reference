onmount('div[id="ProcedureLogsModal"]', function(){

  $(this).modal({
    closable: false,
     onDeny    : function(){
      $('#procedure_div').removeClass("eight column row")
      $('#procedure_div').addClass("hidden")
      $('#facility_procedure').removeClass("hidden")
      $('#facility_procedure').addClass("column")
      $('#facility_procedure_hide').removeClass("column")
      $('#facility_procedure_hide').addClass("hidden")
    }
  })
  .modal('attach events', '#procedure_logs', 'show')

})

function decodeCharEntity(value){
  let parser = new DOMParser;
  let dom = parser.parseFromString(value, 'text/html')
  return dom.body.textContent;
}

function edit_procedures(){
  $('#procedures_table tbody').on('click', '.edit_procedure', function () {
    $('#edit_modal').modal('show');
  })

  $('#edit_modal').modal({
    closable: false,
    autofocus: false,
    observeChanges: true,
    onHide: function() {
      $('#procedure_div').removeClass("eight column row")
      $('#procedure_div').addClass("hidden")
      $('#facility_procedure').removeClass("hidden")
      $('#facility_procedure').addClass("column")
      $('#facility_procedure_hide').removeClass("column")
      $('#facility_procedure_hide').addClass("hidden")
    }
  })

  $('#facility_procedure').on('click', function() {
    $('#procedure_div').removeClass("hidden")
    $('#procedure_div').addClass("eight column row")
    $('#facility_procedure_hide').removeClass("hidden")
    $('#facility_procedure_hide').addClass("column")
    $(this).removeClass("column")
    $(this).addClass("hidden")
  })

  $('#facility_procedure_hide').on('click', function() {
    $('#procedure_div').removeClass("eight column row")
    $('#procedure_div').addClass("hidden")
    $('#facility_procedure').removeClass("hidden")
    $('#facility_procedure').addClass("column")
    $(this).removeClass("column")
    $(this).addClass("hidden")

  })
  $('#procedures_table tbody').on('click', '.edit_procedure', function () {
    let procedure_id = $(this).attr('pid')
    let payor_procedure_id = $(this).attr('ppid')
    let std_code = $(this).closest('tr').find('a[field="std_code"]').html()
    let std_description = $(this).closest('tr').find('td[field="std_description"]').html()
    let payor_code = $(this).attr('pp_code')
    let payor_description = $(this).attr('pp_description')
    let exclusion_type = $(this).closest('tr').find('td[field="exclusion_type"]').text()
    let status = $('#status').val()
    if (status == "Active") {
      $('#deactivate_btn').prop("disabled", false)
    } else {
      $('#deactivate_btn').prop("disabled", true)
    }

    $('input[field="payor_procedure_id"]').val(payor_procedure_id)
    $('#std_code').text(std_code)
    $('#std_description').text(std_description)
    $('#payor_code').text(payor_code)
    $('#payor_description').text(decodeCharEntity(payor_description))
    $('#exclusion_type').text(exclusion_type)
    $("#deactivated_table").hide()
    $(".ui .dimmer").addClass('active')
    $('#edit_button').attr('href', 'procedures/'+ procedure_id +'/edit/'+ payor_procedure_id)

      let fpp = []
      let ppp = []
      let epp = []
      $.ajax({
        url: `/procedures/${payor_procedure_id}/payor_procedure`,
        type: 'get',
        success: function(response) {
        $(".ui .dimmer").removeClass('active')
          let obj = response
          fpp = obj.facility_payor_procedures
          ppp = obj.package_payor_procedures
          epp = obj.exclusion_procedures
          //console.log(epp)
          // FOR PROCEDURE FACILITIES
          $("#procedure_facility_table tbody").html('')
          if (jQuery.isEmptyObject(fpp)) {
            let data_null =
              `<tr>\
              <td colspan="7" class="center aligned">NO FACILITIES FOUND</td>\
              </tr>`
            $("#procedure_facility_table tbody").append(data_null)
          } else {
            $('#procedure_facility_table').attr('class', 'ui striped table')
            $('#procedure_facility_table').removeAttr('role')
            $('#procedure_facility_table').removeAttr('aria-describedby')
            $('#procedure_facility_table').removeAttr('style')

            let dataSet = []
            for (let fpp of fpp){
              let data_array = []
              data_array.push(fpp.facility.code)
              data_array.push(fpp.facility.name)
              data_array.push(fpp.code)
              data_array.push(fpp.name)
              dataSet.push(data_array)
            }
            /* for (let fpp of fpp) {
               let new_row =
               `<tr>\
               <td>${fpp.facility.code}</td>\
               <td>${fpp.facility.name}</td>\
               <td>${obj.code}</td>\
               <td>${obj.description}</td>\
               </tr>`
               $("#procedure_facility_table tbody").append(new_row)

               }
               */
            $('#procedure_facility_table').DataTable( {
              destroy: true,
              data: dataSet,
              columns: [
                { title: "Facility Code" },
                { title: "Facility Name" },
                { title: "Facility Cpt Code" },
                { title: "Facility Cpt Description" }
              ]
            } );
          }
          // END OF PROCEDURE FACILITIES
        }
      })


      $('#procedure_logs_table').css("overflow-y", "scroll")
      $.ajax({
        url: `/procedures/${procedure_id}/procedure`,
        type: 'get',
        success: function(response) {
          // console.log(response)
          let obj = response
          let logs = obj.procedure_logs
          // FOR PROCEDURE LOGS
          $("#procedure_logs_table tbody").html('')
          if (jQuery.isEmptyObject(logs)) {
            $('#extend_logs').attr('style','')
            let no_log =
              `NO LOGS FOUND`
            $("#timeline").removeClass('feed timeline')
            $("#procedure_logs_table tbody").append(no_log)
          } else {
            let i=0
            for (let plogs of logs) {
              i++
                if(i==5) {$('#extend_logs').attr('style','overflow:scroll;height:300px;overflow:auto')}
              else {$('#extend_logs').attr('style','')}
              let new_row =
                `<div class="ui feed">\
                <div class="event"> \
                <div class="label"> \
                <i class="blue circle icon"></i> \
                </div> \
                <div class="content"> \
                <div class="summary">\
                <p class="procedure_log_date">${plogs.inserted_at}</p>\
                </div>\
                <div class="extra text"> \
                ${plogs.message}\
                </div> \
                </div> \
                </div> </tr>
              `
              $("#timeline").addClass('feed timeline')
              $("#procedure_logs_table tbody").prepend(new_row)
            }
          }
          $('p[class="procedure_log_date"]').each(function() {
            let date = $(this).html();
            $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
          })
          // END OF PROCEDURE LOGS

        }
      })

      $('#deactivate_btn').on('click', function() {

      let modules = ""
      if (fpp == undefined || fpp == '[]') {
        fpp = []
      }
      if (ppp == undefined || ppp == '[]') {
        ppp = []
      }
      if (epp == undefined || epp == '[]') {
        epp = []
      }
      fpp = JSON.stringify(fpp)
      ppp = JSON.stringify(ppp)
      epp = JSON.stringify(epp)
      if (fpp != '[]')
        {
          modules = `*Facility Module <br>`
        }
      if (ppp != '[]')
          {
            modules = modules + `*Package Module <br>`
          }
      if (epp != '[]')
            {
              modules = modules + `*Exclusion Module`
            }

            if(fpp == '[]' && ppp == '[]' && epp == '[]')
              {
                swal({
                  title: 'Remove Payor CPT?',
                  html: "<br><div class='ui grid container'><div class='eight wide computer column'><b>Payor CPT Code</b></div>" +
                    "<div class='eight wide computer column'>" + payor_code + "</div>" + "</div>" +
                    "<div class='ui grid container'><div class='eight wide computer column'><b>Payor CPT Description</b></div>" +
                    "<div class='eight wide computer column'>" + payor_description + "</div>" + "</div>" +
                    "<div class='ui grid container'><div class='eight wide computer column'><b>Exclusion Type</b></div>" +
                    "<div class='eight wide computer column'>" + exclusion_type + "</div>" + "</div><br><br>",
                  type: 'warning',
                  showCancelButton: true,
                  confirmButtonText: '<i class="check icon"></i> Yes, Remove Payor CPT',
                  cancelButtonText: '<i class="remove icon"></i> No, Keep Payor CPT',
                  confirmButtonClass: 'ui button',
                  cancelButtonClass: 'ui button',
                  buttonsStyling: false,
                  reverseButtons: true,
                  allowOutsideClick: false
                }).then(function() {
                  $('#deactivate_form').submit()
                }, function(dismiss) {
                  if (dismiss === 'cancel') {
                    swal({
                      title: 'Cancelled',
                      type: 'error',
                      confirmButtonText: '<i class="check icon"></i> Ok',
                      confirmButtonClass: 'ui blue button'
                    })
                  }
                })
              }
              else
                {
                  swal({
                    title: "<br><div class='ui grid container'><div class='sixteen wide computer column'><b>This Payor CPT has been already mapped,</b></div>" + "<div class='ui grid container'><div class='sixteen wide computer column'><b>CPT must be remove first in these modules:</b></div>",
                    html: "<br><div class='ui grid container'><div class='sixteen wide computer column'>" + modules + "</div>",
                    type: 'warning',
                    width: '800px',
                    confirmButtonText: '<i class="remove icon"></i> Close',
                    confirmButtonClass: 'ui blue button'
                  })
                }
    })
  })
}

onmount('div[id="procedures_index"]', function() {

  let table = $('#procedures_table').DataTable({
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
        'targets': 1,
        'createdCell': function (td, cellData, rowData, row, col) {
          $(td).attr('field', 'std_description');
        }
      }
    ]
  });

  edit_procedures()

  $('input[type="search"]').unbind('on').on('keyup', function(){
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/procedures/load_datatable`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      data: {params: { "search" : $(this).val().trim(), "offset" : 0}},
      dataType: 'json',
      success: function(response){
        table.clear()
        for (let i=0;i<response.length;i++){
          table.row.add( [
            `<a class="edit_procedure pointer" field="std_code" ppid="${response[i].id}" pid="${response[i].procedure_id}" pp_code="${response[i].code}" pp_description="${response[i].description}">${response[i].procedure_code}</a>`,
              `${response[i].procedure_description}
            <input type="hidden" id="status" value="${display_status(response[i].is_active)}">
            `
          ] ).draw(false);
        }
        edit_procedures()
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
          url:`/procedures/load_datatable`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {params: { "search" : search.trim(), "offset" : info.recordsTotal}},
          dataType: 'json',
          success: function(response){
            for (let i=0;i<response.length;i++){
              table.row.add( [
                `<a class="edit_procedure pointer" field="std_code" ppid="${response[i].id}" pid="${response[i].procedure_id}" pp_code="${response[i].code}" pp_description="${response[i].description}">${response[i].procedure_code}</a>`,
                  `${response[i].procedure_description}
                <input type="hidden" id="status" value="${display_status(response[i].is_active)}">
                `
              ] ).draw(false);
            }
            edit_procedures()
          }
        })
      }
    }
  })
  let info
  table.on('page', function () {
    info = table.page.info();
    // console.log(info.recordsTotal)
    if (info.pages - info.page == 1){
      let search = $('.dataTables_filter input').val();
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/procedures/load_datatable`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {params: { "search" : search.trim(), "offset" : info.recordsTotal}},
        dataType: 'json',
        success: function(response){
          for (let i=0;i<response.length;i++){
            table.row.add( [
              `<a class="edit_procedure pointer" field="std_code" ppid="${response[i].id}" pid="${response[i].procedure_id}" pp_code="${response[i].code}" pp_description="${response[i].description}">${response[i].procedure_code}</a>`,
                `${response[i].procedure_description}
              <input type="hidden" id="status" value="${display_status(response[i].is_active)}">
              `
            ] ).draw(false);
          }
          edit_procedures()
        }
      })
    }
  });

  function display_status(is_active){
    if (is_active == true){
     return "Active"
    }
    else{
     return "Inactive"
    }
  }

});

onmount('div[id="procedures_new"]', function() {

  let active_codes = []

  $('.active-codes').each(function() {
    active_codes.push($(this).val())
  })

  $.fn.form.settings.rules.checkCode= function(param) {
    return active_codes.indexOf(param) == -1 ? true : false;
  }

  $.fn.form.settings.rules.checkDesc= function(param) {
    param = param.charAt(0)
    if (/^[^@+=-]*$/.test(param) == true){
      return true
    } else {
      return false
    }
  }

  $('#procedure')
    .form({
      inline: true,
      fields: {
        procedure_id: {
          identifier: 'procedure_id',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Standard CPT Code / Description'
          }]
        },
        code: {
          identifier: 'code',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Payor CPT Code'
            },
            {
              type  : 'checkCode[param]',
              prompt: 'Payor CPT Code is already taken'
            }
          ]
        },
        description: {
          identifier: 'description',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Payor CPT Description'
          },
          {
            type  : 'checkDesc[param]',
            prompt: '- = @ + is not allowed at the beginning of Payor CPT Description'
          }]
        }
      }
    })
})
