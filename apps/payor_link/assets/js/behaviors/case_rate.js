onmount('#CaseRateValidation', function () {

  $.fn.form.settings.rules.checkHierarchy1 = function(param) {
    let hierarchy1 = $('input[name="case_rate[hierarchy1]"]').is(':checked')
    let hierarchy2 = $('input[name="case_rate[hierarchy2]"]').is(':checked')

    if (hierarchy1 || hierarchy2){
      return true
    }else{
      return false
    }
  }

  $.fn.form.settings.rules.checkHierarchy2 = function(param) {
    let hierarchy1 = $('input[name="case_rate[hierarchy1]"]').is(':checked')
    let hierarchy2 = $('input[name="case_rate[hierarchy2]"]').is(':checked')

    if (hierarchy1 || hierarchy2){
      return true
    }else{
      return false
    }
  }

  $('#form_case_rate')
  .form({
    on: blur,
    inline: true,
    fields: {
      'case_rate[description]': {
        identifier: 'case_rate[description]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter case rate description'
          }
        ]
      },
      'case_rate[diagnosis_id]': {
        identifier: 'case_rate[diagnosis_id]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please select case rate code'
          }
        ]
      },
      'case_rate[hierarchy1]': {
        identifier: 'case_rate[hierarchy1]',
        rules: [{
          type: 'checkHierarchy1[param]',
          prompt: 'Please choose a hierarchy'
        }]
      },
      'case_rate[hierarchy2]': {
        identifier: 'case_rate[hierarchy2]',
        rules: [{
          type: 'checkHierarchy2[param]',
          prompt: 'Please choose a hierarchy'
        }]
      },
      'case_rate[amount_up_to]': {
        identifier: 'case_rate[amount_up_to]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter amount'
        }]
      }
      ,
      'case_rate[amount_up_to]': {
        identifier: 'case_rate[amount_up_to]',
        rules: [{
          type: 'decimal',
          prompt: 'Please enter amount'
        }]
      }
    }
  });

  $('#case_rate_diagnosis_ruv_id').change(function(){
    let selected_value = $("#case_rate_diagnosis_ruv_id option:selected").text();
    $('#case_rate_code').val(selected_value)
  })

  $("#case_rate_amount_up_to").keypress(function (evt)
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

  $("#case_rate_type").change(function () {
    $('div').removeClass('error')
    $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
     var val = this.value;
     if(val == "ICD")
     {
        $('#select_icd').show()
        $('#select_ruv').hide()

        $('#form_case_rate')
        .form({
          on: blur,
          inline: true,
          fields: {
            'case_rate[description]': {
              identifier: 'case_rate[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter case rate description'
                }
              ]
            },
            'case_rate[diagnosis_id]': {
              identifier: 'case_rate[diagnosis_id]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please select case rate code'
                }
              ]
            }
          }
        });
     }
     else
     {
        $('#select_icd').hide()
        $('#select_ruv').show()

        $('#form_case_rate')
        .form({
          on: blur,
          inline: true,
          fields: {
            'case_rate[description]': {
              identifier: 'case_rate[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter case rate description'
                }
              ]
            },
            'case_rate[ruv_id]': {
              identifier: 'case_rate[ruv_id]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please select case rate code'
                }
              ]
            }
          }
        });
     }
  });

})

onmount('#CaseRateIndex', function() {
  $('#case_rate_modal').modal('attach events', '.case_rate_code', 'show')

  function decodeCharEntity(value){
    let parser = new DOMParser;
    let dom = parser.parseFromString(value, 'text/html')
    return dom.body.textContent;
  }

  $('.case_rate_code').on('click', function(){
    let case_rate_id = $(this).attr('case_rate_id')
    let case_rate_code = $(this).attr('case_rate_code')
    let code_description = $(this).attr('code_description')
    let case_rate_type = $(this).closest('tr').find('td[field="case_rate_type"]').html()
    let case_rate_description = $(this).closest('tr').find('td[field="case_rate_description"]').html()
    let case_rate_hierarchy = $(this).closest('tr').find('td[field="case_rate_hierarchy"]').html()
    let case_rate_discount_percentage = $(this).closest('tr').find('td[field="case_rate_discount_percentage"]').html()
    let case_rate_amount_up_to = $(this).closest('tr').find('td[field="case_rate_amount_up_to"]').html()
    $('#case_rate_modal').find('#code_description').text(code_description)
    $('#case_rate_modal').find('#case_rate_code').text(case_rate_code)
    $('#case_rate_modal').find('#case_rate_type').text(case_rate_type)
    $('#case_rate_modal').find('#case_rate_description').text(decodeCharEntity(case_rate_description))
    $('#case_rate_modal').find('#case_rate_hierarchy').text(case_rate_hierarchy)
    $('#case_rate_modal').find('#case_rate_discount_percentage').text(case_rate_discount_percentage)
    $('#case_rate_modal').find('#case_rate_amount_up_to').text(case_rate_amount_up_to)
    

    let btnCaseRateEdit = document.getElementById('case_rates_edit');
    btnCaseRateEdit.href = "case_rates/" + case_rate_id + "/update"

    $('#case_rate_remove').on('click', function(){
      swal({
        title: 'Delete Case Rate?',
        type: 'question',
        showCancelButton: true,
        cancelButtonText: '<i class="remove icon"></i> No, keep case rate',
        confirmButtonText: '<i class="check icon"></i> Yes, delete case rate',
        cancelButtonClass: 'ui negative button',
        confirmButtonClass: 'ui positive button',
        reverseButtons: true,
        buttonsStyling: false
      }).then(function () {
          window.location.replace(`/case_rates/${case_rate_id}/delete_case_rate`);
      })
    })

    $.ajax({
      url:`/case_rates/${case_rate_id}/logs`,
      type: 'GET',
      success: function(obj){
        // let obj = JSON.parse(response)
        $("#case_rate_logs_table tbody").html('')
        if (jQuery.isEmptyObject(obj)) {
          let no_log =
          `NO LOGS FOUND`
          $("#timeline").removeClass('feed timeline')
          $("#case_rate_logs_table tbody").append(no_log)
        }
        else  {
          for (let case_rate_logs of obj.case_rate_logs) {
            let new_row =
            `<div class="ui feed"> \
             <div class="event row_logs"> \
             <div class="label"> \
             <i class="blue circle icon"></i> \
             </div> \
              <div class="content"> \
              <div class="summary"> \
             <p class="case_rate_log_date">${case_rate_logs.inserted_at}</p>\
             </div> \
             <div class="extra text"> \
             ${case_rate_logs.message}\
             </div> \
             </div> \
             </div> \
             </div> \
             </tr>`
          $("#timeline").addClass('feed timeline')
          $("#case_rate_logs_table tbody").append(new_row)
          }
        }
        $('p[class="case_rate_log_date"]').each(function(){
          let date = $(this).html();
          $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
        })
      }
    })

    $('#btnSearchLogs').on('click', function(){

      let message = $('input[name="case_rate[search]"]').val();

      if (message == "" || message == null)
      {
        $('.row_logs').remove();
        $('p[role="append_logs"]').text(" ")
        $.ajax({
          url:`/case_rates/${case_rate_id}/logs`,
          type: 'GET',
          success: function(response){
            let obj = JSON.parse(response)
            $("#case_rate_logs_table tbody").html('')
            if (jQuery.isEmptyObject(obj)) {
              let no_log =
              `NO LOGS FOUND`
              $("#timeline").removeClass('feed timeline')
              $("#case_rate_logs_table tbody").append(no_log)
            }
            else  {
              for (let case_rate_logs of obj) {
                let new_row =
                `<div class="ui feed"> \
                 <div class="event row_logs"> \
                 <div class="label"> \
                 <i class="blue circle icon"></i> \
                 </div> \
                  <div class="content"> \
                  <div class="summary"> \
                 <p class="case_rate_log_date">${case_rate_logs.inserted_at}</p>\
                 </div> \
                 <div class="extra text"> \
                 ${case_rate_logs.message}\
                 </div> \
                 </div> \
                 </div> \
                 </div> \
                 </tr>`
              $("#timeline").addClass('feed timeline')
              $("#case_rate_logs_table tbody").append(new_row)
              }
            }
            $('p[class="case_rate_log_date"]').each(function(){
              let date = $(this).html();
              $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
            })
          }
        })
      }
      else
      {
        $('.row_logs').remove();
        $('p[role="append_logs"]').text(" ")
        $.ajax({
          url:`/case_rates/${case_rate_id}/${message}/logs`,
          type: 'GET',
          success: function(response){
            let obj = JSON.parse(response)
            $("#case_rate_logs_table tbody").html('')
            if (jQuery.isEmptyObject(obj)) {
              let no_log =
              `NO LOGS FOUND`
              $("#timeline").removeClass('feed timeline')
              $("#case_rate_logs_table tbody").append(no_log)
            }
            else  {
              for (let case_rate_logs of obj) {
                let new_row =
                `<div class="ui feed"> \
                 <div class="event row_logs"> \
                 <div class="label"> \
                 <i class="blue circle icon"></i> \
                 </div> \
                  <div class="content"> \
                  <div class="summary"> \
                 <p class="case_rate_log_date">${case_rate_logs.inserted_at}</p>\
                 </div> \
                 <div class="extra text"> \
                 ${case_rate_logs.message}\
                 </div> \
                 </div> \
                 </div> \
                 </div> \
                 </tr>`
              $("#timeline").addClass('feed timeline')
              $("#case_rate_logs_table tbody").append(new_row)
              }
            }
            $('p[class="case_rate_log_date"]').each(function(){
              let date = $(this).html();
              $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
            })
          }
        })
      }
   })
  })
})

onmount('div[id="CaseRateLogsModal"]', function(){

  $(this).modal({
    closable: false
  })
  .modal('attach events', '#case_rate_logs', 'show')

  $('div[id="log_message"]').each(function(){
    var $this = $(this);
    var t = $this.text();
    $this.html(t.replace('&lt','<').replace('&gt', '>'));
  })

})
