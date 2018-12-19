onmount('div[id="package_payor_procedure"]', function () {

  $('select#package_payor_procedure_id').select2({
      placeholder: "Select Procedure",
      theme: "bootstrap",
      minimumInputLength: 3
    })

  $('.btnRemoveProcedure').on('click', function(){
    let package_payor_procedure_id = $(this).attr('package_payor_procedure_id')

    swal({
          title: 'Delete Procedure?',
          type: 'question',
          showCancelButton: true,
          cancelButtonText: '<i class="remove icon"></i> No, keep procedure',
          confirmButtonText: '<i class="check icon"></i> Yes, delete procedure',
          cancelButtonClass: 'ui negative button',
          confirmButtonClass: 'ui positive button',
          reverseButtons: true,
          buttonsStyling: false
          }).then(function () {
              window.location.replace(`/packages/${package_payor_procedure_id}/delete_package_payor_procedure`);
          })
  })

  $('.ui.modal')
  .modal({
    closable  : false,
    onHide: function() {
        $('div').removeClass('error')
        $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      }
  })
  .modal('attach events', '.add.button', 'show');

  $('#btnNextStepToSummary2').on('click', function(e){

    alertify.error('<i id="notification_error" class="close icon"></i><p>Please add atleast one procedure.</p>');
    alertify.defaults = {
        notifier:{
            delay:5,
            position:'top-right',
            closeButton: false
        }
    };
    $('#btnNextStepToSummary2').addClass('disabled');
  });

  $('#btnPackage').on('click', function(){
    $('div[id="message_add_procedure_form"]').remove()
    $('div[id="message_add_procedure"]').remove()
    $('#div_male_checkbox').removeClass('error');
    $('#div_female_checkbox').removeClass('error');
  });

});

$('.facility_rate').on('click', function(){
  let facility_name = $(this).attr('facility_name');
  let facility_code = $(this).attr('facility_code');
  let facility_id = $(this).attr('facility_id');
  let package_id = $(this).attr('package_id');
  let package_facility_id = $(this).attr('package_facility_id');
  let package_facility_rate = $(this).attr('package_facility_rate');
  $('div[role="package_procedure_modal"]')
  .modal({
    closable  : false,
    onHide: function() {
        $('div').removeClass('error')
        $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      }
  })
  .modal('show');

  $('div[role="package_procedure_modal"]').find('#package_facility_facility_name').val(facility_name);
  $('div[role="package_procedure_modal"]').find('#package_facility_facility_code').val(facility_code);
  $('div[role="package_procedure_modal"]').find('#package_facility_rate').val(package_facility_rate);
  $('div[role="package_procedure_modal"]').find('#facility_id').val(facility_id);
  $('div[role="package_procedure_modal"]').find('#package_id').val(package_id);
  $('div[role="package_procedure_modal"]').find('#package_facility_id').val(package_facility_id);

});

onmount('div[id="edit_package_facility"]', function () {

  $('#add_package_facility_form')
  .modal({
    closable  : false,
    onHide: function() {
        $('div').removeClass('error')
        $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      }
  })
  .modal('attach events', '.add.button', 'show');

  $('.btnRemove').on('click', function(){
    let package_facility_id = $(this).attr('package_facility_id')

    swal({
          title: 'Delete Facility?',
          type: 'question',
          showCancelButton: true,
          cancelButtonText: '<i class="remove icon"></i> No, keep facility',
          confirmButtonText: '<i class="check icon"></i> Yes, delete facility',
          cancelButtonClass: 'ui negative button',
          confirmButtonClass: 'ui positive button',
          reverseButtons: true,
          buttonsStyling: false
          }).then(function () {
              window.location.replace(`/packages/${package_facility_id}/delete_package_facility`);
          })
  })

  $('#package_rate').keypress(function (evt)
  {
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

  $('#package_facility_rate').keypress(function (evt)
  {
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

  $('#add_package_facility_form').find("#package_facility_id").change(function(){

  let facility_id = $('#add_package_facility_form').find('#package_facility_id').find( 'option:selected' ).val();
  var name = $('#add_package_facility_form').find('#package_facility_id').find( 'option:selected' ).text()
  let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/api/v1/packages/${facility_id}/${name}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        const data =  JSON.parse(response)
          $('#add_package_facility_form').find('#package_facility_code').removeAttr("disabled");
          $('#add_package_facility_form').find('#package_facility_code').val(data[0].code)
          $('#add_package_facility_form').find('#package_facility_code').attr("disabled", "disabled");
      },
    })
  });
});

/* PACKAGE PAGE */
onmount('div[name="PackageValidation"]', function () {


  /* CAPITALIZE FIRST LETTER OF PACKAGE NAME IN EVERY WORD*/
  $.fn.capitalize = function() {
    $.each(this, function() {
      this.value = this.value.replace(/\b[a-z]/gi, function($0) {
        return $0.toUpperCase();
      });
      this.value = this.value.replace(/@([a-z])([^.]*\.[a-z])/gi, function($0, $1) {
        console.info(arguments);
        return '@' + $0.toUpperCase() + $1.toLowerCase();
      });
    });
  }

  $('input[id="package_name"]').keypress(function() {
    $(this).capitalize();
  }).capitalize();

  $('input[id="package_code"]').keypress(function() {
    $(this).capitalize();
  }).capitalize();

  let csrf = $('input[name="_csrf_token"]').val();
  let package_code = $('input[name="package[code]"]').attr("value")
  let package_name = $('input[name="package[name]"]').attr("value")

  $.ajax({
    url:`/api/v1/packages/get_all_package_code_and_name`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let data = JSON.parse(response)
      console.log(data)
      let array = $.map(data, function(value, index) {
        return [value.code]
      });

      let array2 = $.map(data, function(value, index) {
        return [value.name]
      });

      if(package_code != undefined){
        array.splice($.inArray(package_code, array),1)
      }

      if(package_name != undefined){
        array2.splice($.inArray(package_name, array2),1)
      }

      $.fn.form.settings.rules.checkPackageCode = function(param) {
        return array.indexOf(param) == -1 ? true : false
      }

      $.fn.form.settings.rules.checkPackageName = function(param) {
        return array2.indexOf(param) == -1 ? true : false
      }

      $('#Package')
      .form({
        on: blur,
        inline: true,
        fields: {
          'package[code]': {
            identifier: 'package[code]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter package code.'
              },
              {
                type   : 'checkPackageCode[param]',
                prompt: 'Package Code already exist!'
              }
            ]
          },
          'package[name]': {
            identifier: 'package[name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter package name.'
              },
              {
                type   : 'checkPackageName[param]',
                prompt: 'Package Name already exist!'
              }
            ]
          }
        }
      });
    },
      error: function(){}
  })
});

onmount('div[name="Step2PackageValidation"]', function () {

  let _male_checker;
  let _female_checker;

  $('#package_age_from').keypress(function (e)
  {
    if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57))
    {
       return false;
    }
  });

  $('#package_age_to').keypress(function (e)
  {
    if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57))
    {
       return false;
    }
  });

  $('#male_checkbox').on('change',function(){
    _male_checker = $(this).is(':checked') ? 'checked' : 'unchecked';
    if(_male_checker == 'checked')
    {
      $('#div_male_checkbox').removeClass('error')
      $('#div_male_checkbox').find('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('#div_female_checkbox').removeClass('error')
      $('#div_female_checkbox').find('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
    }

  });

  $('#female_checkbox').on('change',function(){
    _female_checker = $(this).is(':checked') ? 'checked' : 'unchecked';
    if(_female_checker == 'checked')
    {
      $('#div_female_checkbox').removeClass('error')
      $('#div_female_checkbox').find('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('#div_male_checkbox').removeClass('error')
      $('#div_male_checkbox').find('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
    }
  });

  $.fn.form.settings.rules.checkOverlap = function(param) {
    let age_to = parseInt($('input[name="package[age_to]"]').val())

    if (parseInt(param) > age_to){
      return false
    }else{
      return true
    }
  }

  $.fn.form.settings.rules.checkAgeRange = function(param) {
    let age_from = $('input[name="package[age_from]"]').val()

    if (param == age_from){
      return false
    }else{
      return true
    }
  }

  $.fn.form.settings.rules.checkMale = function(param) {
    let female = $('input[name="package[female]"]').is(':checked')
    let male = $('input[name="package[male]"]').is(':checked')

    if (female || male){
      return true
    }else{
      return false
    }
  }
  $.fn.form.settings.rules.checkFemale = function(param) {
    let female = $('input[name="package[female]"]').is(':checked')
    let male = $('input[name="package[male]"]').is(':checked')

    if (female || male){
      return true
    }else{
      return false
    }
  }

  $('#add_procedure')
  .form({
  on: blur,
  inline: true,
  fields: {
    'package[age_from]': {
      identifier: 'package[age_from]',
      rules: [
        {
          type: 'empty',
          prompt: 'Please enter age.'
        },
        {
          type: 'checkOverlap[param]',
          prompt: 'Age should not overlap!'
        }
      ]
    },
    'package[age_to]': {
      identifier: 'package[age_to]',
      rules: [
        {
          type: 'empty',
          prompt: 'Please enter age.'
        },
        {
          type: 'checkAgeRange[param]',
          prompt: 'Invalid age range! Age must be greater than the other age. Please enter other value.'
        }
      ]
    },
    'package[payor_procedure_id]': {
      identifier: 'package[payor_procedure_id]',
      rules: [
        {
          type: 'empty',
          prompt: 'Please select a procedure.'
        }
      ]
    },
    'package[male]': {
      identifier: 'package[male]',
      rules: [{
        type: 'checkMale[param]',
        prompt: 'Please choose a gender.'
      }]
    },
    'package[female]': {
      identifier: 'package[female]',
      rules: [{
        type: 'checkFemale[param]',
        prompt: 'Please choose a gender.'
      }]
     }
  }
  });
});

onmount('div[name="PackageValidations"]', function () {

  let csrf = $('input[name="_csrf_token"]').val();
  let package_code = $('input[name="package[code]"]').attr("value")
  let package_name = $('input[name="package[name]"]').attr("value")

  $.ajax({
    url:`/api/v1/packages/get_all_package_code_and_name`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let data = JSON.parse(response)
      console.log(data)
      let array = $.map(data, function(value, index) {
        return [value.code]
      });

      let array2 = $.map(data, function(value, index) {
        return [value.name]
      });

      if(package_code != undefined){
        array.splice($.inArray(package_code, array),1)
      }

      if(package_name != undefined){
        array2.splice($.inArray(package_name, array2),1)
      }

      $.fn.form.settings.rules.checkPackageCode = function(param) {
        return array.indexOf(param) == -1 ? true : false
      }

      $.fn.form.settings.rules.checkPackageName = function(param) {
        return array2.indexOf(param) == -1 ? true : false
      }

      $('#Package')
      .form({
        on: blur,
        inline: true,
        fields: {
          'package[code]': {
            identifier: 'package[code]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter package code.'
              },
              {
                type   : 'checkPackageCode[param]',
                prompt: 'Package Code already exist!'
              }
            ]
          },
          'package[name]': {
            identifier: 'package[name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter package name.'
              },
              {
                type   : 'checkPackageName[param]',
                prompt: 'Package Name already exist!'
              }
            ]
          }
        }
      });
    },
      error: function(){}
  })

  $.fn.form.settings.rules.checkZeroValue = function(param) {
    if (param == 0){
      return false
    }else{
      return true
    }
  }

  $('#add_package_facility_form')
  .form({
  on: blur,
  inline: true,
  fields: {
    'package[facility_id]': {
      identifier: 'package[facility_id]',
      rules: [
        {
          type: 'empty',
          prompt: 'Please select a facility.'
        }
      ]
    },
    'package[rate]': {
      identifier: 'package[rate]',
      rules: [
        {
          type: 'empty',
          prompt: 'Please enter rate.'
        },
        {
          type: 'checkZeroValue[param]',
          prompt: 'Value must be greater than 0. Please enter other value.'
        }
      ]
    }
  }
  });

  $('#add_package_facility')
  .form({
  on: blur,
  inline: true,
  fields: {
    'package_facility[rate]': {
      identifier: 'package_facility[rate]',
      rules: [
        {
          type: 'empty',
          prompt: 'Please enter facility rate.'
        },
        {
          type: 'checkZeroValue[param]',
          prompt: 'Value must be greater than 0. Please enter other value.'
        }
      ]
    }
  }
  });
})

function showAllLogs(package_id)
{
  $.ajax({
      url:`/packages/${package_id}/logs`,
      type: 'GET',
      success: function(response){
        let obj = JSON.parse(response)
        $("#package_logs_table tbody").html('')
        if (jQuery.isEmptyObject(obj)) {
          let no_log =
          `No Matching Logs Found!`
          $("#timeline").removeClass('feed timeline');
          $('p[role="append_logs"]').text(no_log)
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

onmount('div[id="showPackage"]', function(){

  $('#logsModal')
  .modal({
    closable  : false,
    onHide: function() {
        $('input[name="package[search]"]').val("");
        $('.row_logs').remove();
        $('p[role="append_logs"]').text(" ")
        showAllLogs(package_id)
     }
  })
  .modal('attach events', '#logs', 'show');


  $('p[class="log-date"]').each(function(){
    let date = $(this).html();
    $(this).html(moment(date).format("MMMM Do YYYY, h:mm a"));
  })

  $('div[id="log_message"]').each(function(){
    var $this = $(this);
    var t = $this.text();
    $this.html(t.replace('&lt','<').replace('&gt', '>'));
  })

  let package_id = $('input[name="package_id"]').val();

  $('#btnSearchLogs').on('click', function(){

      let message = $('input[name="package[search]"]').val();

      if (message == "" || message == null)
      {
        $('.row_logs').remove();
        $('p[role="append_logs"]').text(" ")
        showAllLogs(package_id)
      }
      else
      {
        $('.row_logs').remove();
        $('p[role="append_logs"]').text(" ")

        $.ajax({
        url:`/packages/${package_id}/${message}/logs`,
        type: 'GET',
        success: function(response){
          let obj = JSON.parse(response)
          $("#package_logs_table tbody").html('')
          if (jQuery.isEmptyObject(obj)) {
            let no_log =
            `No Matching Logs Found!`
            $("#timeline").removeClass('feed timeline');
            $('p[role="append_logs"]').text(no_log)
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
   })
});

onmount('button[id="deletePackage"]', function () {

  const csrf = $('input[name="_csrf_token"]').val()

  $('#deletePackage').on('click', function() {
    let packageID = $(this).attr('packageID')
    swal({
      title: 'Delete Package?',
      text: "Deleting this Package will permanently remove it from the system.",
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Package',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Package',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false
    }).then(function() {
        window.location.replace(`/packages/${packageID}/delete`)
    }).catch(swal.noop)
  })

})
