onmount('div[id="create-facility-group"]', function(){
  const csrf = $('input[name="_csrf_token"]').val();
  let flg = []
  const names = []
  let type = []

  $.ajax({
    url:`/web/facility_groups/get_all_names`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      const data = JSON.parse(response)
      $.each(data, function(index, value){ names.push(value) })
    },
    error: function(){}
  })

  $.fn.form.settings.rules.checkName = function(param) {
    let facility_group_name = $('#facility_group_name_draft').val()
    let valid = true
    if (param != "") {
      if (facility_group_name == undefined) {
        $.ajax({
          async: false,
          url:`/web/facility_groups/check_existing_facility_group_name?facility_group_name=${param}`,
          type: 'POST',
          success: function(response){
            if (response.valid == true) {
              valid = true
            }  else {
              valid = false
            }
          }
        })
      }
    } else {
      valid = true
    }
    return valid
  }

  $.fn.form.settings.rules.checkType= function(param) {
    type = []
    $('#facility-group-type').find('input[tabindex="0"]').each(function(){
      type.push($(this).is(':checked'))
    })

    if (type.includes(true)){
      $(`#facility-group-type`).find('.field').removeClass('error') // removing error prompt radio_btn[type]

       return true
    } else{
      $(`#facility-group-type`).find('.field').addClass('error') // adding error prompt radio_btn[type]

       return false
    }
  }

  $.fn.form.settings.rules.regionSelected = function(param) {
    flg = []
    $('#facility-location-group').find('input[tabindex="1"]').each(function(){
      flg.push($(this).is(':checked'))
    })

     if (flg.includes(true)){
       // removing error prompt in all of checkboxes
       $('#facility-location-group').find('.inline.field').each(function(){
          $(this).removeClass('error')
       })

       return true
     }
     else {
       // adding error prompt in all of checkboxes
       $('#facility-location-group').find('.inline.field').each(function(){
          $(this).addClass('error')
       })

       return false
     }
  }

  $.fn.form.settings.rules.validateFacility = function(param) {
    let table = $('#selected_facility_tbl').DataTable()
    if ($(`input[name="location_group[selecting_type]"]:checked`).val() == "Facilities") {
      if (table.rows().count() > 0){
        return true
      }
      else{
        return false
      }
    }
    else{
      return true;
    }
  }

  let $form = $('#f-group-form')

  const form_f_group = () => {
    $('#f-group-form').form({
      on: blur,
      inline: true,
      fields: {
        'location_group[name]': {
          identifier: 'location_group[name]',
          rules: [{
            type  : 'empty',
            prompt: 'Enter Facility Group Name'
          },
          {
            type   : 'regExp[/^[a-zAZ0-9:() -]{1,81}$/gi]',
            prompt : 'Only Hyphen (-), Colon (:), and Parentheses (()) are the special characters allowed'
          },
          {
            type   : 'checkName[param]',
            prompt : 'Facility Group Name is already exists'
          }]
        },
        'selecting_type': {
          identifier: 'selecting_type',
          rules: [{
            type  : 'checkType',
            prompt: 'Select selecting type'
          }]
        },
         'region': {
          identifier: 'region',
          rules: [{
            type  : 'regionSelected[param]',
            prompt: 'Select atleast one (1) region'
          }]
        },
        'location_group[description]': {
          identifier: 'location_group[description]',
          rules: [{
            type  : 'empty',
            prompt: 'Enter Facility Group Description'
          },
          {
            type   : 'regExp[/^[a-zAZ0-9:() -]{1,81}$/gi]',
            prompt : 'Only Hyphen (-), Colon (:), and Parentheses (()) are the special characters allowed'
          }]
        },
        'is_valid_facility_fields': {
          identifier: 'is_valid_facility_fields',
          rules: [{
            type   : 'validateFacility',
            prompt : 'Add At least one (1) facility'
          }]
        },
      }
    })
  }

  form_f_group()

  $('#create-f-group').on("click", function(e){
     $form.removeClass("success error warning");
     if ($form.form("is valid")) {
       $('.prompt').remove()
       $form.removeClass("success error warning");
      swal({
        title: 'Create Facility Group?',
        text: "",
        type: 'warning',
        showCancelButton: true,
        confirmButtonColor: 'green',
        cancelButtonColor: '#d33',
        cancelButtonText: 'No',
        confirmButtonText: 'Yes',
        allowOutsideClick: false,
        reverseButtons: true
      }).then((result) => {
        $form.submit()
      })
     } else {
      form_f_group()
      $form.submit()
     }
  });

  $('button[role="save-as-draft"]').on("click", function(e){
     $form.removeClass("success error warning");
     if ($form.form("is valid")) {
       $('.prompt').remove()
       $form.removeClass("success error warning");
       $('input[name="location_group[status]"]').val("Draft")
       $form.submit()
     } else {
      form_f_group()
      $form.submit()
     }
  });

  if($('input[id="LUZON"]').is(':checked')) {
    $('div[id="LUZON"]').find('input').each(function(){
        $(this).prop('checked', true)
    })
  }

  if($('input[id="VISAYAS"]').is(':checked')) {
    $('div[id="VISAYAS"]').find('input').each(function(){
        $(this).prop('checked', true)
    })
  }

  if($('input[id="MINDANAO"]').is(':checked')) {
    $('div[id="MINDANAO"]').find('input').each(function(){
        $(this).prop('checked', true)
    })
  }

  $('input[id="LUZON"]').on('change', function(){
    if($(this).is(':checked')) {
      $('div[id="LUZON"]').find('input').each(function(){
        $(this).prop('checked', true)
      })
    } else {
      $('div[id="LUZON"]').find('input').each(function(){
        $(this).prop('checked', false)
      })
    }
  })

  $('input[id="VISAYAS"]').on('change', function(){
    if($(this).is(':checked')) {
      $('div[id="VISAYAS"]').find('input').each(function(){
        $(this).prop('checked', true)
      })
    } else {
      $('div[id="VISAYAS"]').find('input').each(function(){
        $(this).prop('checked', false)
      })
    }
  })

  $('input[id="MINDANAO"]').on('change', function(){
    if($(this).is(':checked')) {
      $('div[id="MINDANAO"]').find('input').each(function(){
        $(this).prop('checked', true)
      })
    } else {
      $('div[id="MINDANAO"]').find('input').each(function(){
        $(this).prop('checked', false)
      })
    }
  })

  $(window).scroll(function(){
     if($(window).scrollTop()>90){
       $('#save-as-draft').css('position', 'fixed');
       $('#save-as-draft').css('top', '65px');
       $('#save-as-draft').css('right', '80px');
     } else {
       $('#save-as-draft').css('position', 'fixed');
       $('#save-as-draft').css('top', '200px');
       $('#save-as-draft').css('right', '80px');
     }
  });

   if($(window).scrollTop()>90){
     $('#save-as-draft').css('position', 'fixed');
     $('#save-as-draft').css('top', '65px');
     $('#save-as-draft').css('right', '80px');
   } else {
     $('#save-as-draft').css('position', 'fixed');
     $('#save-as-draft').css('top', '200px');
     $('#save-as-draft').css('right', '80px');
   }

   let desc = $('input[name="location_group[description]"]').val()
   let name = $('input[name="location_group[name]"]') .val()

   if (desc == "" || name == "") {
     $('div[id="save-as-draft"]').hide()
   } else {
     $('div[id="save-as-draft"]').show()
   }

  $('input[name="location_group[name]"]').on('keyup', function(){
    let desc = $('input[name="location_group[description]"]').val()
    let name = $(this).val()

    if (desc == "" || name == "") {
      $('div[id="save-as-draft"]').hide()
    } else {
      $('div[id="save-as-draft"]').show()
    }
  })

  $('input[name="location_group[description]"]').on('keyup', function(){
    let name = $('input[name="location_group[name]"]').val()
    let desc = $(this).val()

    if (desc == "" || name == "") {
      $('div[id="save-as-draft"]').hide()
    } else {
      $('div[id="save-as-draft"]').show()
    }
  })
})


onmount('input[role="mount_swal"]', function(e){
  let id = $(this).attr("id")
  let code = $(this).attr("code")
  let name = $(this).attr("name")

  swal({
    title: ' Facility Group Successfully Created',
    text: `${code}, ${name}`,
    type: 'success',
    showCancelButton: true,
    confirmButtonColor: 'green',
    cancelButtonColor: '#d33',
    cancelButtonClass: 'redirect-cancel',
    cancelButtonText: 'No',
    confirmButtonText: 'Yes',
    allowOutsideClick: false,
    reverseButtons: true,
  }).then((result) => {
     window.document.location = `/web/facility_groups/new`
  })

  $('#swal2-content').append('<p>Do you want to create another Facility Group?</p>')

  $('.redirect-cancel').on('click', function() {
     window.document.location = `/web/facility_groups/${id}/show`
  })
})
