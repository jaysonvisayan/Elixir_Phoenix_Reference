onmount('div[id="pf_batch"]', function(){
  let currentDate = new Date()
  let date_received_selector = $('input[name="batch[date_received]"]')
  $('.facility-card').css('display', 'none')
  $('.practitioner-card').css('display', 'none')

  if(date_received_selector.val() == ""){
   date_received_selector.val(currentDate)
  }

  $('#date_received').calendar({
    type: 'date',
    maxDate: new Date(currentDate),
    endCalendar: $('#rangeend'),
    onChange: function (date_received, text, mode) {
      let received = new Date(date_received)
      let plus_month = received.getMonth()
      let due = received.setMonth(plus_month + 1)
      $('input[name="batch[date_due]"]').val(moment(due).format("YYYY-MM-DD"))
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
  })


  $('div[id="date_due"]').calendar({
    type: 'date',
    minDate: new Date(currentDate),
	  formatter: {
        date: function (due_date, settings) {
            if (!due_date) return '';
            var day = due_date.getDate() + '';
            if (day.length < 2) {
                day = '0' + day;
            }
            var month = (due_date.getMonth()) + '';
            if (month.length < 2) {
                month = '0' + month;
            }
            var year = due_date.getFullYear();
            return year + '-' + month + '-' + day;
        }
    }
  })

  const csrf = $('input[name="_csrf_token"]').val();
  let facility_id = $('#batch_facility_id').val()
  let practitioner_id = $('#batch_practitioner_id').val()
  let practitioner_onload = $('#practitioner_onload').val()

  const facility_address = (facility_id, csrf) => {
    if (facility_id != "") {
      $.ajax({
        url:`/batch_processing/${facility_id}/get_facility_address`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        success: function(response){
          let facility = JSON.parse(response)
          $('.facility-card-empty').css('display', 'none')
          $('.facility-card').css('display', 'block')
          $('span[facility="name"]').html(facility.name)
          $('span[facility="code"]').html(facility.code)
          $('span[facility="line_1"]').html(facility.line1)
          $('span[facility="line_2"]').html(facility.line_2)
          $('span[facility="city"]').html(facility.city)

          $('span[practitioner="name"]').html("")
          $('span[practitioner="specializations"]').html("")
          let date_today = new Date()
          date_today.setDate(date_today.getDate() + parseInt(facility.prescription_term))

          if (!date_today) return '';
          var day = date_today.getDate() + '';
          if (date_today.length < 2) {
              date_today = '0' + day;
          }
          var month = (date_today.getMonth()) + 1 + '';
          if (month.length < 2) {
              month = '0' + month;
          }
          var year = date_today.getFullYear();
          let date_due = year + '-' + month + '-' + day;

          $('#batch_date_due').val(date_due)
          $('#due_date').removeClass('disabled')

          $('#date_due').calendar({
            type: 'date',
            minDate: new Date(currentDate),
            maxDate: new Date(date_today),
            formatter: {
                date: function (date, settings) {
                    if (!date) return '';
                    var day = date.getDate() + '';
                    if (day.length < 2) {
                        day = '0' + day;
                    }
                    var month = (date.getMonth()) + 1 + '';
                    if (month.length < 2) {
                        month = '0' + month;
                    }
                    var year = date.getFullYear();
                    return year + '-' + month + '-' + day;
                }
            }
          }, "set date", new Date(date_today))
        }
      })
    }
  }

  facility_address(facility_id, csrf)

  let facilities = JSON.parse($('input[id="facility"]').val());

  $('.ui.search').search({
    source: facilities,
    showNoResults: true,
    maxResults: 10,
    error: {
      noResults   : 'Not affiliated facility.'
    },
    onSelect: function(result, response) {
      $('#batch_facility_id').val(result.id)
      facility_address(result.id, csrf)
      $('div[id="search_facility"]').removeClass("error")
      $('div[class="ui basic red pointing prompt label transition visible"]').remove()


      if ($('#batch_facility_id').val() != ""){
        $('div[id="practitioner_id"]').find('div[class="ui disabled fluid search selection dropdown"]').removeClass("disabled");
      }
      affiliated_practitioner(result.id, csrf)
    },
    minCharacters: 0
  });

  if ($('#batch_facility_id').val() != ""){
    $('div[id="practitioner_id"]').find('div[tabindex=0]').removeClass("disabled");
  }

  function checkPaymentMode(practitioner_id){
    let mode = $(`option[value="${practitioner_id}"]`).data('mode')
    if (mode == "Umbrella"){
      swal({
        title: "Warning",
        text: "Practitioner’s mode of payment is umbrella.",
        // buttons: true,
        type: "warning",
        showCancelButton: true,
        confirmButtonText: 'Remain here',
        cancelButtonText: 'Create HB instead',
        confirmButtonClass: 'ui primary button',
        cancelButtonClass: 'ui button',
        buttonsStyling: false,
        reverseButtons: true,
        allowOutsideClick: false
      })

      $('button[class="swal2-cancel ui button"]').on('click', function(){
        window.document.location = "/batch_processing/hb_batch/new";
      })
    }
  }

  const practitioner_details = (practitioner_id, csrf) => {
    if (practitioner_id != "" && practitioner_id != null) {
      $.ajax({
        url:`/batch_processing/${practitioner_id}/get_practitioner_details`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        success: function(response){
          let practitioner = JSON.parse(response)
          $('span[practitioner="name"]').html(`${practitioner.first_name} ${practitioner.middle_name} ${practitioner.last_name}`)
          let specialization = []
          $.each(practitioner.practitioner_specializations
        , function(index, value ) {
      specialization.push(value.specialization.name)
        })
        $('.practitioner-card-empty').css('display', 'none')
        $('.practitioner-card').css('display', 'block')
        $('span[practitioner="specializations"]').html("")
        $('span[practitioner="specializations"]').html(specialization.join(', '))

        checkPaymentMode(practitioner_id);
        }
      })
    }
  }


  const affiliated_practitioner = (facility_id, csrf) => {
    if (facility_id != "")
      {
        $.ajax({
          url:`/batch_processing/${facility_id}/get_affiliated_practitioner`,
          headers: {"X-CSRF-TOKEN": csrf},
          type: 'get',
          success: function(response){
            let result  = JSON.parse(response)
            $('#batch_practitioner_id').html('')
            $('#batch_practitioner_id').dropdown('clear')
            $('#batch_practitioner_id').append('<option value="">Select Principal ID</option>')
            for (let pf of result) {
              if (pf.practitioner.suffix == "" || pf.practitioner.suffix == null){
                $('#batch_practitioner_id').append(`<option value="${pf.practitioner.id}" data-mode="${pf.payment_mode}">${pf.practitioner.first_name} ${pf.practitioner.middle_name} ${pf.practitioner.last_name}  </option>`)
              }
              else {
                $('#batch_practitioner_id').append(`<option value="${pf.practitioner.id}" data-mode="${pf.payment_mode}">${pf.practitioner.first_name} ${pf.practitioner.middle_name} ${pf.practitioner.last_name} ${pf.practitioner.suffix} </option>`)
              }
            }
            $('#batch_practitioner_id').dropdown()
          }
        })
      }
  }

  const affiliated_practitioner_onload = (facility_id, csrf, practitioner_id) => {
    if (facility_id != "")
      {
        $.ajax({
          url:`/batch_processing/${facility_id}/get_affiliated_practitioner`,
          headers: {"X-CSRF-TOKEN": csrf},
          type: 'get',
          success: function(response){
            let result  = JSON.parse(response)
            $('#batch_practitioner_id').html('')
            $('#batch_practitioner_id').dropdown('clear')
            $('#batch_practitioner_id').append('<option value="">Select Principal ID</option>')
            for (let pf of result) {
              if (pf.practitioner.suffix == "" || pf.practitioner.suffix == null){
                $('#batch_practitioner_id').append(`<option value="${pf.practitioner.id}" data-mode="${pf.payment_mode}">${pf.practitioner.first_name} ${pf.practitioner.middle_name} ${pf.practitioner.last_name}  </option>`)
              }
              else {
                $('#batch_practitioner_id').append(`<option value="${pf.practitioner.id}" data-mode="${pf.payment_mode}">${pf.practitioner.first_name} ${pf.practitioner.middle_name} ${pf.practitioner.last_name} ${pf.practitioner.suffix} </option>`)
              }
            }
            $('#batch_practitioner_id').dropdown()

            setTimeout(function () {
              $('#batch_practitioner_id').dropdown('set selected', practitioner_id)
            }, 1)
          }
        })
      }
  }


  practitioner_details(practitioner_id, csrf)
  affiliated_practitioner_onload(facility_id, csrf, practitioner_onload)


  // if ($('#batch_facility_id').val() == ""){
  //   alert("hey")
  //   $('div[id="practitioner_id"]').find('div[tabindex=0]').addClass("disabled");
  // }

  $('#batch_facility_id').on('change', function(){
    if ($('#batch_facility_id').val() != ""){
      $('div[id="practitioner_id"]').find('div[class="ui disabled fluid search selection dropdown"]').removeClass("disabled");
    }

    let facility_id = $(this).val()
    facility_address(facility_id, csrf)
    affiliated_practitioner(facility_id, csrf)
  })

  $('#batch_practitioner_id').on('change', function(){
    let practitioner_id = $(this).val()
    practitioner_details(practitioner_id , csrf)
    checkPaymentMode(practitioner_id);
  })

 $('button[id="comment"]').on('click', function(){

      $('#comment_field').removeClass('error')
    let batch_id = $('#batchID').attr('batchid')
    let comment = $('#pf_comment').val()
    if (comment == '') {
      $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
        $(this).remove();
      });

      $('#comment_field').addClass('error').append(`<div class="ui basic red pointing prompt label transition visible">Please enter comment</div>`)
    }
    else{
      requestCommentDetails(batch_id, comment)
    }
  })

  function requestCommentDetails(batch_id, comment){
    let params = {comment: comment}
    $.ajax({
      url:`/batch_processing/${batch_id}/add_comment`,
      headers: {"X-CSRF-TOKEN": csrf},
      data: {batch_params: params},
      type: 'POST',
      success: function(response){
        let response_obj = JSON.parse(response)
        if (comment != ""){
          let to_moment = convertToMoment(response_obj.inserted_at)
          $('div[id="maincomment"]').prepend(`<div class="comment-views mb-1"><div><p class="mb-0 blacken">${response_obj.comment}</p><p class="blacken"><i class="user icon mr-1"></i>${response_obj.created_by}</p></div><div class="small blacken commentDateTime">${to_moment}</div></div><hr/>`)
          $('textarea[name="batch[pf_comment]"]').val("")
          $('#pf_comment').val('')
          $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
            $(this).remove();
          });
        }

      }
    })
  }


  $('.alphanumeric').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[``~<>^'{}[\]\\;'|:"/?!#@$%&*()+=]|\,/;

    if( regex.test(key) ) {
      theEvent.returnValue = false;
      if(theEvent.preventDefault) theEvent.preventDefault();
    }
  })

  const number_input = () => {
    $('input[type="number"]').on('keypress', function(evt){
      let theEvent = evt || window.event;
      let key = theEvent.keyCode || theEvent.which;
      key = String.fromCharCode( key );
      let regex = /[a-zA-Z``~<>^'{}[\]\\;':",./?!@#$%&*()_+=-]|\./;
      let min = $(this).attr("minlength")

      if( regex.test(key) ) {
        theEvent.returnValue = false;
        if(theEvent.preventDefault) theEvent.preventDefault();
      }else{
        if($(this).val().length >= $(this).attr("maxlength")){
          $(this).next('p[role="validate"]').hide();
          $(this).on('keyup', function(evt){
            if(evt.keyCode == 8){
              $(this).next('p[role="validate"]').show();
            }
          })
          return false;
        }else if( min > $(this).val().length){
          $(this).next('p[role="validate"]').show();
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
        else{
          $(this).next('p[role="validate"]').hide();
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      }
    })
  }

  number_input()

  $.fn.form.settings.rules.checkDateDue = function(param) {
    let date_received = $('input[name="batch[date_received]"]').val()
    date_received = new Date(date_received)
    let date_due = new Date(param)

    let dr_year = date_received.getFullYear()
    let dd_year = date_due.getFullYear()
    let dr_month = date_received.getMonth()
    let dd_month = date_due.getMonth()
    let dr_date = date_received.getDate()
    let dd_date = date_due.getDate()
    let minus_dr_dd_month = dd_month - dr_month

    if(dr_year > dd_year){
      return true
    }else if(dr_year <= dd_year && dr_month < dd_month && minus_dr_dd_month >= 2){
      return true
    }else if(dr_year <= dd_year && dr_month < dd_month && dr_date <= dd_date){
      return true
    }else{
      return false
    }
  }

  $.fn.form.settings.rules.checkFacility= function(param) {
    let curfacility = $('input[name="batch[description]"]').val()
    let obj = facilities.find(o => o.title === curfacility )

    if(obj == undefined) {
      return false
    }else{
      facility_address(obj.id, csrf)
      return true
    }
  }

  // Validations
  // $('button[id="submit-batch"]').on('click', function(){
    $('#pf_batch_form')
   .form({
      on: 'blur',
      inline: true,
      fields: {
        'batch[soa_ref_no]': {
          identifier: 'batch[soa_ref_no]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter a SOA Reference No.'
            }
          ]
        },
        'batch[coverage_id]': {
          identifier: 'batch[coverage_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please select a coverage.'
            }
          ]
        },
        'batch[facility_id]': {
          identifier: 'batch[facility_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please select a facility.'
            },
            {
              type  : 'checkFacility[param]',
              prompt: 'Not affiliated facility.'
            }
          ]
        },
        'batch[practitioner_id]': {
          identifier: 'batch[practitioner_id]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please select a practitioner.'
            }
            // {
            //   type: 'checkUmbrella[param]',
            //   prompt: 'Practitioner’s mode of payment is umbrella.'
            // }
          ]
        },
        'batch[coverage]': {
          identifier: 'batch[coverage]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please select Coverage.'
            }
          ]
        },
        'batch[soa_amount]': {
          identifier: 'batch[soa_amount]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter SOA Amount.'
            }
          ]
        },
        'batch[date_received]': {
          identifier: 'batch[date_received]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please select date received.'
            }
          ]
        },
        'batch[date_due]': {
          identifier: 'batch[date_due]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please select due date.'
            },
            {
              type : 'checkDateDue[param]',
              prompt: 'Invalid date, date due must be greater than or equal to 1 month after date received.'
            }
          ]
        },
        'batch[estimate_no_of_claims]': {
          identifier: 'batch[estimate_no_of_claims]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Est. No. of Claims'
            }
          ]
        },
        'batch[mode_of_receiving]': {
          identifier: 'batch[mode_of_receiving]',
          rules: [
            {
              type: 'empty',
              prompt: 'Please select mode of receiving.'
            }
          ]
        }
      }
    })
  // })

 $('.commentDateTime').each(function(index, value){
    let date = $(value).text();
    $(value).text(convertToMoment(date))
  })

  function convertToMoment(dateTime){
    return moment(dateTime).format('MMMM Do YYYY, h:mm:ss a')
  }

  $('#scan_document').on('click', function(){
    if ($('#pf_batch_form').form('is valid')) {
      $('#modal_scan')
      .modal({
        closable: false,
        autofocus: false
      })
      .modal('show')
    }
    else {
      alertify.error('Please fill-out required fields first.')
      $('#pf_batch_form').submit()
    }
  })

  $('.btnViewDocument').on('click', function(){
    $('#modal_view_document')
    .modal({
      closable: false,
      autofocus: false
    })
    .modal('show')

    let image_source = $(this).attr('source')
    $('#image_source').attr('src', image_source)
  })

  $('.btnRemoveDocument').on('click', function(){
    let batch_file_id = $(this).attr('batch_file_id')

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
        window.location.replace(`/batch_processing/${batch_file_id}/delete`);
    })
  })
});

onmount('div[id="created-pf-batch-alert"]', function(){
  let batch_no = $('input[name="swal-batch-no"]').val()
  let facility_name = $('input[name="swal-facility-name"]').val()
  swal({
    title: 'Batch Successfully created.',
    text: `Batch No. ${batch_no}, ${facility_name}`,
    type: 'success',
    showCancelButton: true,
    confirmButtonText: '<i class="check icon"></i> Yes',
    cancelButtonText: '<i class="remove icon"></i> No',
    confirmButtonClass: 'ui positive button',
    cancelButtonClass: 'ui negative button',
    buttonsStyling: false,
    reverseButtons: true,
    allowOutsideClick: false

  }).then(function() {
    //$('#form-cancel').submit()
  })
  $('#swal2-content').append("</br></br><b>Do you want to create another PF batch?</b>")

  $('button[class="swal2-cancel ui negative button"]').on('click', function(){
    window.document.location = "/batch_processing";
  })
})

onmount('div[id="edit-pf-batch-alert"]', function(){
  let batch_no = $('input[name="swal-batch-no"]').val()
  let facility_name = $('input[name="swal-facility-name"]').val()
  swal({
    title: 'Batch Updated Successfully.',
    text: `Batch No. ${batch_no}, ${facility_name}`,
    type: 'success',
    showCancelButton: true,
    confirmButtonText: '<i class="check icon"></i> Yes',
    cancelButtonText: '<i class="remove icon"></i> No',
    confirmButtonClass: 'ui positive button',
    cancelButtonClass: 'ui negative button',
    buttonsStyling: false,
    reverseButtons: true,
    allowOutsideClick: false

  }).then(function() {
    //$('#form-cancel').submit()
  })
  $('#swal2-content').append("</br></br><b>Do you want to stay and edit this PF batch?</b>")

  $('button[class="swal2-cancel ui negative button"]').on('click', function(){
    window.document.location = "/batch_processing";
  })
})
