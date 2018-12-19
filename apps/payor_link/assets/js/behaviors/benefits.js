onmount('button[id="deleteBenefit"]', function () {

  const csrf = $('input[name="_csrf_token"]').val()

  $('#deleteBenefit').on('click', function() {
    let benefitID = $(this).attr('benefitID')
    swal({
      title: 'Delete Benefit?',
      text: "Deleting this Benefit will permanently remove it from the system.",
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Benefit',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Benefit',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false
    }).then(function() {

      $.ajax({
        url:`/benefits/${benefitID}`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'DELETE',
        success: function(response){
          window.location.href = '/benefits'
        },
        error: function(){
          alert("Erorr deleting benefit!")
        }
      })

    }).catch(swal.noop)
  })

})

onmount('button[id="preventNext"]', function () {

  $('#preventNext').on('click', function(){
    let message = $(this).attr('message')
    swal({
      title: `${message}`,
      type: 'error',
      allowOutsideClick: true,
      confirmButtonText: 'OK',
      confirmButtonClass: 'ui button primary',
      buttonsStyling: false
    }).catch(swal.noop)
  })


})

onmount('.prevent-next', function () {

  $('.prevent-next').on('click', function(){
    let message = $(this).attr('message')
    swal({
      title: `${message}`,
      type: 'error',
      allowOutsideClick: true,
      confirmButtonText: 'OK',
      confirmButtonClass: 'ui button primary',
      buttonsStyling: false
    }).catch(swal.noop)
  })

})

onmount('div[id="benefitACUprocedures"]', function () {

  $('#benefitPackage').change(function() {
    let id = $(this).val()
    let test = document.getElementById(id)
    let body = document.getElementById('packageBody')
    $('#tblPackage').dataTable().fnDestroy()
    body.innerHTML = test.innerHTML
    $('#tblPackage').dataTable({
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
            "<'six wide column'i>"+
            "<'right aligned ten wide column'p>"+
          ">"+
        ">",
      renderer: 'semanticUI',
      pagingType: "full_numbers",
      pageLength: 5,
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
      }
    })
  })

  $('#modalEditAcuProcedure').modal({autofocus: false, observeChanges: true}).modal('attach events', '.edit-acu-procedure', 'show')

  $.fn.form.settings.rules.checkBenefitName = function(param) {
    return array2.indexOf(param) == -1 ? true : false
  }

  // add package validations
  $('#formAddPackage').form({
      inline: true,
      fields: {
        package: {
          identifier: 'package',
          rules: [{
            type: 'empty',
            prompt: 'Please enter package'
          }]
        }
      }
    })

  $.fn.form.settings.rules.checkOverlap = function(param) {
    let age_to = $('input[name="benefit[age_to]"]').val()
    if (parseInt(param) > parseInt(age_to)) {
      return false
    }else{
      return true
    }
  }

  // edit procedure validations
  $('#formEditProcedure').form({
      inline: true,
      fields: {
        age_from: {
          identifier: 'age_from',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter age from'
            },
            {
              type: 'checkOverlap[param]',
              prompt: 'Age from cannot be greater than age to'
            }
          ]
        },
        age_to: {
          identifier: 'age_to',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter age to'
            }
          ]
        },
        gender: {
          identifier: 'gender',
          rules: [{
            type: 'empty',
            prompt: 'Please enter gender'
          }]
        }
      }
    })

  $(".edit-acu-procedure").click(function() {
    let id = $(this).attr('bpid')
    let std_code = $(this).text()
    let std_description = $(this).closest('tr').find('td[field="std_description"]').text()
    let code = $(this).closest('tr').find('td[field="code"]').text()
    let description = $(this).closest('tr').find('td[field="description"]').text()
    let gender = $(this).closest('tr').find('td[field="gender"]').text()
    let gender_array = gender.split(" & ")
    let age_from = $(this).closest('tr').find('td[field="age"]').attr('from')
    let age_to = $(this).closest('tr').find('td[field="age"]').attr('to')

    // set values on modal
    $('#stdCode').val(std_code)
    $('#stdDesc').val(std_description)
    $('#payorCode').val(code)
    $('#payorDesc').val(description)
    $('#selectGender').dropdown('remove selected', ["Male", "Female"])
    $('#selectGender').dropdown('set selected', gender_array)
    $('#ageFrom').val(age_from)
    $('#ageTo').val(age_to)
    $('#formEditProcedure').form('validate form')
    $('input[name="benefit[benefit_procedure_id]"]').val(id)
  })

})

onmount('#modalDeleteBenefitProcedure', function () {

  $('.delete-benefit-procedure').on('click', function(){
    let benefit_procedure_id = $(this).attr('benefitProcedureID')
    $('#deleteBenefitProcedureID').val(benefit_procedure_id)
    $('#modalDeleteBenefitProcedure').modal('show')
  })

  $('#confirmDeleteBenefitProcedure').click(function(){
    let csrf = $('input[name="_csrf_token"]').val()
    let benefit_procedure_id = $('#deleteBenefitProcedureID').val()

    $.ajax({
      url:`/benefit_procedure/${benefit_procedure_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        window.location.href = window.location.href
      },
      error: function(){
        alert('Error deleting benefit procedure!')
      }
    })
  })

})

function showAllLogs(benefit_id)
{
  $.ajax({
      url:`/benefits/${benefit_id}/logs`,
      type: 'GET',
      success: function(response){
        let obj = JSON.parse(response)
        $("#package_logs_table tbody").html('')
        if (jQuery.isEmptyObject(obj)) {
          let no_log =
          `No Matching Logs Found!`
          $("#timeline").removeClass('feed timeline');
          $('p[role="append_benefit_logs"]').text(no_log)
        }
        else  {
          for (let logs of obj) {
            let new_row =
            `<div class="event row_logs"> \
             <div class="label"> \
             <i class="blue circle icon"></i> \
             </div> \
              <div class="content"> \
              <div class="summary"> \
              <a> \
             <p class="log-date">${logs.inserted_at}</p>\
             </a> \
             </div> \
             <div class="extra text" id="log_message"> \
             ${logs.message}\
             </div> \
             </div> \
             </div> \
              </tr>`

          $("#timeline").addClass('feed timeline')
          $('div[class="ui feed timeline"]').append(new_row)
            }
        }
        $('p[class="log-date"]').each(function(){
           let date = $(this).html();
           $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
        })
      }
   })
}

onmount('#benefit_modals', function () {
  let benefit_id = $('input[name="benefit_id"]').val();
// onmount('#benefit_options', function () {
  $('#DiscontinueBenefitID').on('click', function(){
  // console.log(haha)
  let haha = $('#benefit_id_disabler').val()
   $('#b_id').text(haha)
  // console.log(test)
    $('#modalDiscontinuePeme').modal({autofocus: false, closable : false}).modal('show')
  let currentDate = new Date()
  let tomorrowsDate = currentDate.setDate(currentDate.getDate() + 1)
  $('#discontinueDate').calendar({
    type: 'date',
    minDate: new Date(tomorrowsDate),
    onChange: function (start_date, text, mode) {
      let start = new Date(start_date)
      let end_date = start.setDate(start.getDate() + 1)
      end_date = new Date(end_date)
      $('input[name="hidden-date"]').val(end_date)
      let start_date1 = start_date.setDate(start_date.getDate() -1)
      let new_end_date = moment(start_date1).add(1, 'year').calendar()
      new_end_date = moment(new_end_date).format("MM-DD-YYYY")
      $('input[name="account[end_date]"]').val(new_end_date)
      $('input[name="account[start_date]"]').val(moment(start_date.setDate(start_date.getDate() +1)).format("MM-DD-YYYY"))

      $('#account_end_date').calendar({
        type: 'date',
        minDate: new Date(end_date),
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
            return month + '-' + day + '-' + year;
          }
        }
      })
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
              if (year < date.getFullYear() || year > 9999){
                year.setFullYear(date.getFullYear);
                return month + '-' + day + '-' + year;
              }
              else
            return month + '-' + day + '-' + year;
        }
    }
  });
  })
  $('#reDirect').click(function(){
    $('#benefit_discontinue_date').val('')
    $('#discontinue_remarks').val('')
  })
  // $('#cutoff_timer').calendar({
  //   ampm: false,
  //   type: 'time'
  // });

  $('#discontinued_benefit_form').form({
      inline: true,
      fields: {
        'benefit[discontinue_date]': {
          identifier: 'benefit[discontinue_date]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter discontinue_date'
          }]
        }
      }
  })


  $('#confirmDiscontinueBenefitID').click(() => {

    let result = $('#discontinued_benefit_form').form('validate form')

    if (result) {
      let date = $('input[name="benefit[discontinue_date]"]').val()
      $('#dbdate').text(date)
      $('#modalDiscontinuingPemeConfirmation').modal({closable: false}).modal('show')
    }
  })

  $('#confirmDiscontinueBenefit').click(() => {
    $('#discontinued_benefit_form').submit()
  })


  $('#NoDB').on('click', function(){
    $('#modalDiscontinuePeme').modal('show')
  })

 $('#benefitlogsModal').modal({
    closable  : false,
    onHide: function() {
        $('input[name="benefit[search]"]').val("");
        $('.row_logs').remove();
        $('p[role="append_benefit_logs"]').text(" ")
        showAllLogs(benefit_id)
     }
  })
  .modal('attach events', '#benefit_logs', 'show');

 $('p[class="log-date"]').each(function(){
    let date = $(this).html();
    $(this).html(moment(date).format("MMMM Do YYYY, h:mm a"));
  })

 $('div[id="log_message"]').each(function(){
    var $this = $(this);
    var t = $this.text();
    $this.html(t.replace('&lt','<').replace('&gt', '>'));
  })

  $('#btnSearchBenefitLogs').on('click', function(){

    let message = $('input[name="benefit[search]"]').val();

    if (message == "" || message == null)
      {
        $('.row_logs').remove();
        $('p[role="append_benefit_logs"]').text(" ")
        showAllLogs(benefit_id)
      }
      else
        {
          $('.row_logs').remove();
          $('p[role="append_benefit_logs"]').text(" ")
          $.ajax({
            url:`/benefits/${benefit_id}/${message}/logs`,
            type: 'GET',
            success: function(response){
              let obj = JSON.parse(response)
              $("#package_logs_table tbody").html('')
              if (jQuery.isEmptyObject(obj)) {
                let no_log =
                  `No Matching Logs Found!`
                $("#timeline").removeClass('feed timeline');
                $('p[role="append_benefit_logs"]').text(no_log)
              }
              else  {
                for (let benefit_logs of obj) {
                  let new_row =
                    `<div class="event row_logs"> \
                    <div class="label"> \
                    <i class="blue circle icon"></i> \
                    </div> \
                    <div class="content"> \
                    <div class="summary"> \
                    <a> \
                    <p class="log-date">${benefit_logs.inserted_at}</p>\
                    </a> \
                    </div> \
                    <div class="extra text" id="log_message"> \
                    ${benefit_logs.message}\
                    </div> \
                    </div> \
                    </div> \
                    </tr>`

                  $("#timeline").addClass('feed timeline')
                  $('div[class="ui feed timeline"]').append(new_row)
                }
              }
              $('p[class="log-date"]').each(function(){
                let date = $(this).html();
                $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
              })
            }
          })
        }
  })
});

// })

  $('#DisableBenefitID').on('click', function(){
  let benefit_value = $('#benefit_id_disabler').val()
   $('#b_id').text(benefit_value)
  // console.log(test)
    $('#modalDisablingPeme').modal({autofocus: false, closable: false}).modal('show')

    let currentDate = new Date()
    let tomorrowsDate = currentDate.setDate(currentDate.getDate() + 1)
  $('#disabledDate').calendar({
    type: 'date',
    minDate: new Date(tomorrowsDate),
    onChange: function (start_date, text, mode) {
      let start = new Date(start_date)
      let end_date = start.setDate(start.getDate() + 1)
      end_date = new Date(end_date)
      $('input[name="hidden-date"]').val(end_date)
      let start_date1 = start_date.setDate(start_date.getDate() -1)
      let new_end_date = moment(start_date1).add(1, 'year').calendar()
      new_end_date = moment(new_end_date).format("YYYY-MM-DD")
      $('input[name="account[end_date]"]').val(new_end_date)
      $('input[name="account[start_date]"]').val(moment(start_date.setDate(start_date.getDate() + 1)).format("YYYY-MM-DD"))

      $('#account_end_date').calendar({
        type: 'date',
        minDate: new Date(end_date),
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
  })
  // open modal for yes/no benefit disabled
  $('#confirmDisableBenefitID').click(function() {
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('.discontinuedateFormPicker').removeClass('error')
    if ($('#disabled_date').val() != ''){
      $('#modalDisablingPemeConfirmation').modal({autofocus: false, closable: false}).modal('show')
    }
    else{
      $('.discontinuedateFormPicker').addClass('error')
      $('.discontinuedateFormPicker').append('<div class="ui basic red pointing prompt label transition visible">Please enter disabled_date</div>')
    }
  })

  $('#disabled_date').change(function(){
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('.discontinuedateFormPicker').removeClass('error')
  })

  $('#cancel_disabled_button').click(function() {
    $('#disabled_date').val('')
    $('#disabled_remarks').val('')
  })

  // submit yes/no benefit modal
  $('#confirmDisableBenefitID1').click(function(){
     $('#disabled_benefit_form').submit()
  })

  $('#no_keep_benefit_button').click(function(){
    $('#modalDisablingPeme').modal({autofocus: false, closable: false}).modal('show')
  })

  $('#disabled_benefit_form').form({
      inline: true,
      fields: {
        'benefit[disabled_date]': {
          identifier: 'benefit[disabled_date]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter disabled_date'
          }]
        }
      }
    })
// })


  $('#DeleteBenefitID').on('click', function(){
  let deletePeme = $('#benefit_id_delete').val()
   $('#b_id').text(deletePeme)
  // console.log(test)
 $('#modalDeletePeme').modal({autofocus: false, closable: false}).modal('show')
  let currentDate = new Date()
  let tomorrowsDate = currentDate.setDate(currentDate.getDate() + 1)
  $('#CancelDelete').on('click', function(){
   $('#delete_date_picker').val('')
   $('#delete_remarks').val('')
  })
  $('#deleteDate').calendar({
    type: 'date',
    minDate: new Date(tomorrowsDate),
    onChange: function (start_date, text, mode) {
      let start = new Date(start_date)
      let end_date = start.setDate(start.getDate() + 1)
      end_date = new Date(end_date)
      $('input[name="hidden-date"]').val(end_date)
      let start_date1 = start_date.setDate(start_date.getDate() -1)
      let new_end_date = moment(start_date1).add(1, 'year').calendar()
      new_end_date = moment(new_end_date).format("YYYY-MM-DD")
      $('input[name="account[end_date]"]').val(new_end_date)
      $('input[name="account[start_date]"]').val(moment(start_date.setDate(start_date.getDate() + 1)).format("YYYY-MM-DD"))

      $('#account_end_date').calendar({
        type: 'date',
        minDate: new Date(end_date),
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
              if (year < date.getFullYear() || year > 9999){
                year.setFullYear(date.getFullYear);
                return month + '-' + day + '-' + year;
              }
              else
            return month + '-' + day + '-' + year;
        }
    }
  });
  })

  // $('#confirmDisableBenefitID').click(function(){
  //   $('#disabled_benefit_form').submit()
  // })

  $('#delete_benefit_form').form({
      inline: true,
      fields: {
        'benefit[delete_date]': {
          identifier: 'benefit[delete_date]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter delete_date'
          }]
        }
      }
    })

$('#confirmDeleteBenefitID').click(() => {

    let result = $('#delete_benefit_form').form('validate form')

    if (result) {
    let date = $('input[name="benefit[delete_date]"]').val()
    $('#dbdeletedate').text(date)
    $('#modalDeletePemeConfirmation').modal('show')
    }
  })

  $('#confirmDeleteBenefit').click(() => {
    $('#delete_benefit_form').submit()
  })


  $('#NoDL').on('click', function(){
    $('#modalDeletePeme').modal('show')
  })


onmount('#modalDeleteBenefitDisease', function () {

  $('.delete-benefit-disease').on('click', function(){
    let benefit_disease_id = $(this).attr('benefitDiseaseID')
    $('#deleteBenefitDiseaseID').val(benefit_disease_id)
    $('#modalDeleteBenefitDisease').modal('show')
  })

  $('#confirmDeleteBenefitDisease').click(function(){
    let csrf = $('input[name="_csrf_token"]').val()
    let benefit_disease_id = $('#deleteBenefitDiseaseID').val()

    $.ajax({
      url:`/benefit_disease/${benefit_disease_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        window.location.href = window.location.href
      },
      error: function(){
        alert('Error deleting benefit disease!')
      }
    })
  })

})

onmount('#modalDeleteBenefitPharmacy', function () {

  $('.delete-benefit-pharmacy').on('click', function(){
    let benefit_pharmacy_id = $(this).attr('benefitPharmacyID')
    $('#deleteBenefitPharmacyID').val(benefit_pharmacy_id)
    $('#modalDeleteBenefitPharmacy').modal('show')
  })

  $('#confirmDeleteBenefitPharmacy').click(function(){
    let csrf = $('input[name="_csrf_token"]').val()
    let benefit_pharmacy_id = $('#deleteBenefitPharmacyID').val()

    $.ajax({
      url:`/benefit_pharmacy/${benefit_pharmacy_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        window.location.href = window.location.href
      },
      error: function(){
        alert('Error deleting benefit pharmacy!')
      }
    })
  })

})

onmount('#modalDeleteBenefitMiscellaneous', function () {

  $('.delete-benefit-miscellaneous').on('click', function(){
    let benefit_miscellaneous_id = $(this).attr('benefitMiscellaneousID')
    $('#deleteBenefitMiscellaneousID').val(benefit_miscellaneous_id)
    $('#modalDeleteBenefitMiscellaneous').modal('show')
  })

  $('#confirmDeleteBenefitMiscellaneous').click(function(){
    let csrf = $('input[name="_csrf_token"]').val()
    let benefit_miscellaneous_id = $('#deleteBenefitMiscellaneousID').val()

    $.ajax({
      url:`/benefit_miscellaneous/${benefit_miscellaneous_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        window.location.href = window.location.href
      },
      error: function(){
        alert('Error deleting benefit miscellaneous')
      }
    })
  })

})

onmount('#modalDeleteBenefitRUV', function () {

  $('.delete-benefit-ruv').on('click', function(){
    let benefit_ruv_id = $(this).attr('benefitRUVID')
    $('#deleteBenefitRUVID').val(benefit_ruv_id)
    $('#modalDeleteBenefitRUV').modal('show')
  })

  $('#confirmDeleteBenefitRUV').click(function(){
    let csrf = $('input[name="_csrf_token"]').val()
    let benefit_ruv_id = $('#deleteBenefitRUVID').val()

    $.ajax({
      url:`/benefit_ruv/${benefit_ruv_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        window.location.href = window.location.href
      },
      error: function(){
        alert('Error deleting benefit RUV!')
      }
    })
  })

})

onmount('#modalDeleteBenefitPackage', function () {
  let this_tr
  $('.delete-benefit-package').on('click', function(){
    this_tr = $(this)
    let package_id = $(this).attr('benefitPackageID')
    let payor_procedure = $(this).attr('benefitPayorProcedure')
    $('#deleteBenefitPackageID').val(package_id)
    $('#deleteBenefitPayorProcedure').val(payor_procedure)
    $('#modalDeleteBenefitPackage').modal('show')
  })

  $('#confirmDeleteBenefitPackage').click(function(){
        // let table = $('#benefit_package_index').DataTable()
        // console.log(table.row( this_tr.parents('tr') ))
    $(this).addClass('disabled')
    let csrf = $('input[name="_csrf_token"]').val()
    let package_id = $('#deleteBenefitPackageID').val()
    let payor_procedure = $('#deleteBenefitPayorProcedure').val()
    let benefit_id = $('#benefit_id').val()


    $.ajax({
      url:`/benefit_package/${package_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){

        let str = window.location.href
        let test = str.includes("setup")
        if (test)
        {
          window.location.href = `/benefits/${benefit_id}/4/redirect_delete`
         }
         else
       {
           window.location.href = `/benefits/${benefit_id}/4/edit/redirect_delete`
         }

        // let table = $('#benefit_package_index').DataTable()
        // table.row( this_tr.parents('tr') )
        // .remove()
        // .draw();
      },
      error: function(){
        alertify.error('<i class="close icon"></i>Error deleting benefit Package!')
      }
    })
  })

})

onmount('div[id="benefits_index"]', function () {
let delay = (function(){
  let timer = 0;
  return function(callback, ms){
    clearTimeout (timer);
    timer = setTimeout(callback, ms);
  };
})()

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
      "<'six wide column'i>"+
      "<'right aligned ten wide column'p>"+
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
    }
  });
 $('input[type="search"]').unbind('on').on('keyup', function(){
let search_val = $(this).val()
    delay(function(){
  const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/benefits/load_datatable`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      data: {params: { "search_value" : search_val.trim(), "offset" : 0}},
      dataType: 'json',
      success: function(response){
        table.clear()
        let dataSet = []
        for (let i=0;i<response.benefit.length;i++){
          table.row.add( [
            index_benefit_step(response.benefit[i]),
            response.benefit[i].name,
            response.benefit[i].created_by,
            response.benefit[i].inserted_at,
            response.benefit[i].updated_by,
            response.benefit[i].updated_at,
            response.benefit[i].coverages
          ] ).draw();
        }
      }
    })
    }, 400 );

  })
  $('.dataTables_length').find('.ui.dropdown').on('change', function(){
    if ($(this).find('.text').text() == 100){
      let info = table.page.info();

      if (info.pages - info.page == 1){
        let search_value = $('.dataTables_filter input').val();
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/benefits/load_datatable`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {params: { "search_value" : search_value.trim(), "offset" : info.recordsTotal}},
          dataType: 'json',
          success: function(response){
            let dataSet = []
           for (let i=0;i<response.benefit.length;i++){
          table.row.add( [
            index_benefit_step(response.benefit[i]),
            response.benefit[i].name,
            response.benefit[i].created_by,
            response.benefit[i].inserted_at,
            response.benefit[i].updated_by,
            response.benefit[i].updated_at,
            response.benefit[i].coverages
              ] ).draw( false );
            }
          }
        })
      }
    }
  })
 let info
  table.on('page', function () {
    info = table.page.info();
    if (info.pages - info.page == 1){
      let search_value = $('.dataTables_filter input').val();
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/benefits/load_datatable`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {params: { "search_value" : search_value.trim(), "offset" : info.recordsTotal}},
        dataType: 'json',
        success: function(response){
        for (let i=0;i<response.benefit.length;i++){
          table.row.add( [
            index_benefit_step(response.benefit[i]),
            // response.benefit[i].code,
            response.benefit[i].name,
            response.benefit[i].created_by,
            response.benefit[i].inserted_at,
            response.benefit[i].updated_by,
            response.benefit[i].updated_at,
            response.benefit[i].coverages
              ] ).draw( false );
          }
        }
      })
    }
  });

  function index_benefit_step(benefit){
    if(benefit.step != 0){
       return   `<a href="/benefits/${benefit.id}/setup?step=${benefit.step || 1}">${benefit.code} (Draft)</a>`
   } else{
       return  `<a href="/benefits/${benefit.id}">${benefit.code}</a>`
     }
 }
})
