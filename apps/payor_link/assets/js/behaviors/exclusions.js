onmount('button[id="deleteExclusion"]', function () {

  const csrf = $('input[name="_csrf_token"]').val()

  $('#deleteExclusion').on('click', function() {
    let exclusionID = $(this).attr('exclusionID')
    swal({
      title: 'Delete Exclusion?',
      text: "Deleting this Exclusion will permanently remove it from the system.",
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Exclusion',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Exclusion',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false
    }).then(function() {

      $.ajax({
        url:`/exclusions/${exclusionID}`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'DELETE',
        success: function(response){
          window.location.href = '/exclusions'
        },
        error: function(){
          alert("Erorr deleting exclusion!")
        }
      })

    }).catch(swal.noop)
  })

})

onmount('table[id="edit_duration_table"]', function() {
  $('button#empty_duration').on('click', function() {
    $('div[id="message_add_duration_form"]').remove()
    $('p[role="append_duration_form"]').append('<div id="message_add_duration_form" class="ui negative message">  At least one duration must be added. </div>')
  })

  $('button#empty_disease_pre_existing').on('click', function() {
    $('div[id="message_add_disease_form"]').remove()
    $('p[role="append_duration_form"]').append('<div id="message_add_disease_form" class="ui negative message">  At least one disease must be added in the Diseases tab. </div>')
  })

  $('#save_duration').on('click', function() {
   alertify.success('<i class="close icon"></i>Pre-existing Condition successfully updated')
  })
  $('#DurationModal').modal('attach events', '#add_duration', 'show')
  $('#DeleteModal').modal('attach events', '.delete', 'show')
  $(".delete").click(function() {
    let exclusion_id = $(this).attr('exclusion_id')
    let duration_id = $(this).attr('duration_id')
    let exclusion_type = $(this).closest('tr').find('td[field="exclusion_type"]').html()
    let exclusion_duration = $(this).closest('tr').find('td[field="exclusion_duration"]').html()
    let exclusion_percentage = $(this).closest('tr').find('td[field="exclusion_percentage"]').html()
    $('label#exclusion_type').text(exclusion_type)
    $('label#exclusion_duration').text(exclusion_duration)
    $('label#exclusion_percentage').text(exclusion_percentage)
    if (exclusion_type == "Dreaded") {
      $('a#delete_duration').attr("data-to", "/exclusions/" + exclusion_id + "/edit_duration_dreaded/" + duration_id)
      $('#last_duration').attr("role", "dreaded")
    }
    if (exclusion_type == "Non-Dreaded") {
      $('a#delete_duration').attr("data-to", "/exclusions/" + exclusion_id + "/edit_duration_non_dreaded/" + duration_id)
      $('#last_duration').attr("role", "non_dreaded")
    }

    $('#DeleteConfirmDreadedModal').modal('attach events', '#last_duration[role="dreaded"]', 'show')
    $('#DeleteConfirmNonDreadedModal').modal('attach events', '#last_duration[role="non_dreaded"]', 'show')

  })
  $.fn.form.settings.rules.greaterThan = function(inputValue, validationValue) {
    return inputValue > validationValue;
  }

  var Inputmask = require('inputmask');
  $('#covered_after_duration').change(function(e){
    if($(this).val() == 'Percentage'){
      $('#cad_value_label').text('%');

      var im = new Inputmask("numeric", {
        min: '1',
        allowMinus:false,
        max: 100,
        rightAlign: false
      });
      im.mask('#cad_value');

      $('#exclusion_duration_form')
      .form({
        inline: true,
        on: 'blur',
        fields: {
          'exclusion[disease_type]': {
            identifier: 'exclusion[disease_type]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter disease type'
            }]
          },
          'exclusion[duration]': {
            identifier: 'exclusion[duration]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter duration'
            }, {
              type: 'greaterThan[0]',
              prompt: 'Duration must be at least 1 month'
            }]
          },
          'exclusion[cad_value]': {
            identifier: 'exclusion[cad_value]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter percentage covered after duration'
            }, {
              type: 'integer[1..100]',
              prompt: 'Percentage must be 1 - 100'
            }]
          }
        }
      })

    }
    else{
      $('#cad_value_label').text('php');

      var im = new Inputmask("decimal", {
        min: '1',
        allowMinus:false,
        radixPoint: ".",
        groupSeparator: ",",
        digits: 2,
        autoGroup: true,
        // prefix: '₱ ',
        rightAlign: false,
        oncleared: function () { self.Value(''); }
      });
      im.mask('#cad_value');

      $('#exclusion_duration_form')
      .form({
        inline: true,
        on: 'blur',
        fields: {
          'exclusion[disease_type]': {
            identifier: 'exclusion[disease_type]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter disease type'
            }]
          },
          'exclusion[duration]': {
            identifier: 'exclusion[duration]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter duration'
            }, {
              type: 'greaterThan[0]',
              prompt: 'Duration must be at least 1 month'
            }]
          },
          'exclusion[cad_value]': {
            identifier: 'exclusion[cad_value]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter amount covered after duration'
            }]
          }
        },
        onSuccess: function(event, fields){
          var input = document.getElementById('cad_value');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          var test = $('#cad_value').val(unmasked)
        }
      })

    }
  })

  $('#cad_value_label').text('php');
  var im = new Inputmask("decimal", {
    min: '1',
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('#cad_value'));

  $('#exclusion_duration_form')
  .form({
    inline: true,
    on: 'blur',
    fields: {
      'exclusion[disease_type]': {
        identifier: 'exclusion[disease_type]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter disease type'
        }]
      },
      'exclusion[duration]': {
        identifier: 'exclusion[duration]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter duration'
        }, {
          type: 'greaterThan[0]',
          prompt: 'Duration must be at least 1 month'
        }]
      },
      'exclusion[cad_value]': {
        identifier: 'exclusion[cad_value]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter amount covered after duration'
        }]
      }
    },
    onSuccess: function(event, fields){
      var input = document.getElementById('cad_value');
      var unmasked = input.inputmask.unmaskedvalue()
      input.inputmask.remove()
      var test = $('#cad_value').val(unmasked)
    }
  })

})

onmount('table[id="duration_table"]', function() {

  $('#empty_duration').on('click', function() {
    $('div[id="message_add_duration_form"]').remove()
    $('p[role="append_duration_form"]').append('<div id="message_add_duration_form" class="ui negative message">  At least one duration must be added. </div>')
  })

  $('#DurationModal').modal('attach events', '#add_duration', 'show')
  $('#DeleteModal').modal('attach events', '.delete', 'show')
  $(".delete").click(function() {
    let exclusion_id = $(this).attr('exclusion_id')
    let duration_id = $(this).attr('duration_id')
    let exclusion_type = $(this).closest('tr').find('td[field="exclusion_type"]').html()
    let exclusion_duration = $(this).closest('tr').find('td[field="exclusion_duration"]').html()
    let exclusion_percentage = $(this).closest('tr').find('td[field="exclusion_percentage"]').html()
    $('label#exclusion_type').text(exclusion_type)
    $('label#exclusion_duration').text(exclusion_duration)
    $('label#exclusion_percentage').text(exclusion_percentage)
    if (exclusion_type == "Dreaded") {
      $('a#delete_duration').attr("data-to", "/exclusions/" + exclusion_id + "/duration_dreaded/" + duration_id)
      $('#last_duration').attr("role", "dreaded")
    }
    if (exclusion_type == "Non-Dreaded") {
    $('a#delete_duration').attr("data-to", "/exclusions/" + exclusion_id + "/duration_non_dreaded/" + duration_id)
      $('#last_duration').attr("role", "non_dreaded")
    }

    $('#DeleteConfirmDreadedModal').modal('attach events', '#last_duration[role="dreaded"]', 'show')
    $('#DeleteConfirmNonDreadedModal').modal('attach events', '#last_duration[role="non_dreaded"]', 'show')
  })

  $.fn.form.settings.rules.greaterThan = function(inputValue, validationValue) {
    return inputValue > validationValue;
  }

  var Inputmask = require('inputmask');
  $('#covered_after_duration').change(function(e){
    if($(this).val() == 'Percentage'){
      $('#cad_value_label').text('%');

      var im = new Inputmask("numeric", {
        min: '1',
        allowMinus:false,
        max: 100,
        rightAlign: false
      });
      im.mask('#cad_value');

      $('#exclusion_duration_form')
      .form({
        inline: true,
        on: 'blur',
        fields: {
          'exclusion[disease_type]': {
            identifier: 'exclusion[disease_type]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter disease type'
            }]
          },
          'exclusion[duration]': {
            identifier: 'exclusion[duration]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter duration'
            }, {
              type: 'greaterThan[0]',
              prompt: 'Duration must be at least 1 month'
            }]
          },
          'exclusion[cad_value]': {
            identifier: 'exclusion[cad_value]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter percentage covered after duration'
            }, {
              type: 'integer[1..100]',
              prompt: 'Percentage must be 1 - 100'
            }]
          }
        }
      })

    }
    else{
      $('#cad_value_label').text('php');

      var im = new Inputmask("decimal", {
        min: '1',
        allowMinus:false,
        radixPoint: ".",
        groupSeparator: ",",
        digits: 2,
        autoGroup: true,
        // prefix: '₱ ',
        rightAlign: false,
        oncleared: function () { self.Value(''); }
      });
      im.mask('#cad_value');

      $('#exclusion_duration_form')
      .form({
        inline: true,
        on: 'blur',
        fields: {
          'exclusion[disease_type]': {
            identifier: 'exclusion[disease_type]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter disease type'
            }]
          },
          'exclusion[duration]': {
            identifier: 'exclusion[duration]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter duration'
            }, {
              type: 'greaterThan[0]',
              prompt: 'Duration must be at least 1 month'
            }]
          },
          'exclusion[cad_value]': {
            identifier: 'exclusion[cad_value]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter amount covered after duration'
            }]
          }
        },
        onSuccess: function(event, fields){
          var input = document.getElementById('cad_value');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          var test = $('#cad_value').val(unmasked)
        }
      })

    }
  })

  $('#cad_value_label').text('php');
  var im = new Inputmask("decimal", {
    min: '1',
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('#cad_value'));

  $('#exclusion_duration_form')
  .form({
    inline: true,
    on: 'blur',
    fields: {
      'exclusion[disease_type]': {
        identifier: 'exclusion[disease_type]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter disease type'
        }]
      },
      'exclusion[duration]': {
        identifier: 'exclusion[duration]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter duration'
        }, {
          type: 'greaterThan[0]',
          prompt: 'Duration must be at least 1 month'
        }]
      },
      'exclusion[cad_value]': {
        identifier: 'exclusion[cad_value]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter amount covered after duration'
        }]
      }
    },
    onSuccess: function(event, fields){
      var input = document.getElementById('cad_value');
      var unmasked = input.inputmask.unmaskedvalue()
      input.inputmask.remove()
      var test = $('#cad_value').val(unmasked)
    }
  })


})

onmount('table[id="disease_table"]', function() {

  $('#empty_disease').on('click', function() {
    $('div[id="message_add_disease_form"]').remove()
    $('p[role="append_disease_form"]').append('<div id="message_add_disease_form" class="ui negative message">  At least one disease must be added. </div>')
  })

  $('#DeleteModal').modal('attach events', '.delete', 'show')

  $(".delete").click(function() {
    let coverage = $(this).attr('coverage')
    let exclusion_id = $(this).attr('exclusion_id')
    let disease_id = $(this).attr('disease_id')
    let exclusion_code = $(this).closest('tr').find('td[field="exclusion_code"]').html()
    let exclusion_description = $(this).closest('tr').find('td[field="exclusion_description"]').html()
    $('label#exclusion_code').text(exclusion_code)
    $('label#exclusion_description').text(exclusion_description)
    if (coverage == "General Exclusion") {
      $('a#delete_disease').attr("data-to", "/exclusions/" + exclusion_id + "/setup?step=2.2&exclusion[disease_id]=" + disease_id)
    } else if (coverage == "Pre-existing Condition") {
      $('a#delete_disease').attr("data-to", "/exclusions/" + exclusion_id + "/setup?step=3.2&exclusion[disease_id]=" + disease_id)
    }
  })
})

onmount('table[id="edit_disease_table"]', function() {

  $('#save_disease_pre_existing').on('click', function() {
   alertify.success('<i class="close icon"></i>Pre-existing Condition successfully updated')
  })

  $('#save_disease_exclusion').on('click', function() {
   alertify.success('<i class="close icon"></i>General Exclusion successfully updated')
  })
  $('button#empty_disease').on('click', function() {
    $('div[id="message_add_disease_form"]').remove()
    $('p[role="append_disease_form"]').append('<div id="message_add_disease_form" class="ui negative message"> Atleast one disease or one procedure must be added. </div>')
  })
  $('button#empty_disease_pre_existing').on('click', function() {
    $('div[id="message_add_disease_form"]').remove()
    $('p[role="append_disease_form"]').append('<div id="message_add_disease_form" class="ui negative message"> Atleast one disease must be added. </div>')
  })

  $('#DeleteModal').modal('attach events', '.delete', 'show')

  $(".delete").click(function() {
    let exclusion_id = $(this).attr('exclusion_id')
    let disease_id = $(this).attr('disease_id')
    let exclusion_code = $(this).closest('tr').find('td[field="exclusion_code"]').html()
    let exclusion_description = $(this).closest('tr').find('td[field="exclusion_description"]').html()
    $('label#exclusion_code').text(exclusion_code)
    $('label#exclusion_description').text(exclusion_description)
    $('a#delete_disease').attr("data-to", "/exclusions/" + exclusion_id + "/disease/" + disease_id)

  })
})

onmount('table[id="procedure_table"]', function() {

  $('#empty_procedure').on('click', function() {
    $('div[id="message_add_procedure_form"]').remove()
    $('p[role="append_procedure_form"]').append('<div id="message_add_procedure_form" class="ui negative message">Atleast one procedure or one disease must be added.</div>')
  })

  $('#DeleteModal').modal('attach events', '.delete', 'show')
  $(".delete").click(function() {
    let exclusion_id = $(this).attr('exclusion_id')
    let procedure_id = $(this).attr('procedure_id')
    let exclusion_code = $(this).closest('tr').find('td[field="exclusion_code"]').html()
    let exclusion_description = $(this).closest('tr').find('td[field="exclusion_description"]').html()
    $('label#exclusion_code').text(exclusion_code)
    $('label#exclusion_description').text(exclusion_description)
    $('a#delete_procedure').attr("data-to", "/exclusions/" + exclusion_id + "/setup?step=3.1&exclusion[procedure_id]=" + procedure_id)
  })
})

onmount('table[id="edit_procedure_table"]', function() {

  $('#save_procedure').on('click', function() {
   alertify.success('<i class="close icon"></i>General Exclusion successfully updated')
  })

  $('button#empty_procedure').on('click', function() {
    $('div[id="message_add_procedure_form"]').remove()
    $('p[role="append_procedure_form"]').append('<div id="message_add_procedure_form" class="ui negative message">Atleast one procedure or one disease must be added.</div>')
  })

  $('#DeleteModal').modal('attach events', '.delete', 'show')
  $(".delete").click(function() {
    let exclusion_id = $(this).attr('exclusion_id')
    let procedure_id = $(this).attr('procedure_id')
    let exclusion_code = $(this).closest('tr').find('td[field="exclusion_code"]').html()
    let exclusion_description = $(this).closest('tr').find('td[field="exclusion_description"]').html()
    $('label#exclusion_code').text(exclusion_code)
    $('label#exclusion_description').text(exclusion_description)
    $('a#delete_procedure').attr("data-to", "/exclusions/" + exclusion_id + "/procedure/" + procedure_id)
  })
})

onmount('div[id="exclusion_form"]', function() {

  let exclusion_code = $('#exclusion_code').val()
  let exclusion_name = $('#exclusion_name').val()
  let pre_existing_code = $('#pre_existing_code').val()
  let pre_existing_name = $('#pre_existing_name').val()
  var tabActive = $('div[role="benefits"] > .active.item').attr("data-tab")
  if (tabActive == "exclusion") {
    $('#pre_existing_code').removeAttr('name')
    $('#pre_existing_name').removeAttr('name')
    $('#exclusion_code').attr('name', 'exclusion[code]')
    $('#exclusion_name').attr('name', 'exclusion[name]')
    $('#pre_existing_code').val('')
    $('#pre_existing_name').val('')
  } else if (tabActive == "pre_existing") {
    $('#exclusion_code').removeAttr('name')
    $('#exclusion_name').removeAttr('name')
    $('#pre_existing_code').attr('name', 'exclusion[code]')
    $('#pre_existing_name').attr('name', 'exclusion[name]')
    $('#exclusion_code').val('')
    $('#exclusion_name').val('')
  }

  $('div[role="benefits"] > .item').on('click', function() {
    var tabActive = $(this).attr("data-tab");
    if (tabActive == "exclusion") {
      $('#pre_existing_code').removeAttr('name')
      $('#pre_existing_name').removeAttr('name')
      $('#exclusion_code').attr('name', 'exclusion[code]')
      $('#exclusion_name').attr('name', 'exclusion[name]')
      $('.ui.form').find('.ui.error.message ul').remove();
      $('.ui.form').find('.error').removeClass('error').find('.prompt').remove();
      $('#exclusion_code').val(exclusion_code)
      $('#exclusion_name').val(exclusion_name)
      $('#pre_existing_code').val() == ""
      $('#pre_existing_name').val() == ""
    } else if (tabActive == "pre_existing") {
      $('#exclusion_code').removeAttr('name')
      $('#exclusion_name').removeAttr('name')
      $('#pre_existing_code').attr('name', 'exclusion[code]')
      $('#pre_existing_name').attr('name', 'exclusion[name]')
      $('#pre_existing_code').val(pre_existing_code)
      $('#pre_existing_name').val(pre_existing_name)
      $('#exclusion_code').val() == ""
      $('#exclusion_name').val() == ""
      $('.ui.form').find('.ui.error.message ul').remove();
      $('.ui.form').find('.error').removeClass('error').find('.prompt').remove();
    }
  })

})

onmount('div[id="pre_existing_form"]', function() {
  var im = new Inputmask("numeric", {
    allowMinus:false,
    min: 1,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false
  });
  im.mask($('#exclusion_limit_amount'))
  im.mask($('#exclusion_limit_percentage'))

  $('div[role="benefits"] > .item').on('click', function() {
    var tabActive = $(this).attr("data-tab")
    if (tabActive == "exclusion") {
      $('#pre_existing_code').removeData()
      $('#pre_existing_name').removeData()
    } else if (tabActive == "pre_existing") {
      $('#exclusion_code').removeData()
      $('#exclusion_name').removeData()
    }
  })

  $('#exclusion_limit_type').change(function(){
    let limit_type = $(this).val()
    $('#exclusion_limit_amount').val("")
    $('#exclusion_limit_percentage').val("")
    if (limit_type == "Peso") {
      $("#limitAmountIcon").html('PHP')
      validate_peso()
    } else if (limit_type == "Sessions") {
      $("#limitAmountIcon").html('Sessions')
      validate_sessions()
    } else {
      $("#limitAmountIcon").html('%')
      validate_percentage()
    }
  })

  $.fn.form.settings.rules.checkPeso = function(param) {
     let unmasked_val = param.replace(/,/g, '')
    if (unmasked_val < 1 || unmasked_val > 100000.00) {
      return false
    } else{
      return true
    }
  }

  $.fn.form.settings.rules.checkSession = function(param) {
     let unmasked_val = param.replace(/,/g, '')
    if (unmasked_val < 1 || unmasked_val > 100) {
      return false
    } else{
      return true
    }
  }

  // Use peso validation on page load
  if($('#limitAmountIcon').html().includes('PHP')){
    validate_peso()
  }else if($('#limitAmountIcon').html().includes('%')){
    validate_percentage()
  }else{
    validate_sessions()
  }

  function validate_percentage() {
    $('#pre_existing_form')
      .form({
        inline: true,
        fields: {
          amount: {
            identifier: 'amount',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter PEC limit amount'
            },
            {
              type: 'integer[1..100]',
              prompt: 'Invalid percentage range enter a number from 1-100'
            }
           ]
          }
        },
       onSuccess: function(event, fields){
        var input = document.getElementById('exclusion_limit_amount');
        var unmasked = input.inputmask.unmaskedvalue()
        input.inputmask.remove()
        $('#exclusion_limit_amount').val(unmasked)
       }
      })
  }


  function validate_peso() {
    $('#pre_existing_form')
      .form({
        inline: true,
        fields: {
          amount: {
            identifier: 'amount',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter PEC limit amount'
              },
              {
                type: 'checkPeso[param]',
                prompt: 'Maximum PEC limit amount is up to Php 100,000.00 only'
              }
            ]
        }
       },
       onSuccess: function(event, fields){
        var input = document.getElementById('exclusion_limit_amount');
        var unmasked = input.inputmask.unmaskedvalue()
        console.log(unmasked)
        input.inputmask.remove()
        $('#exclusion_limit_amount').val(unmasked)
       }
      })
  }

  function validate_sessions() {
    $('#pre_existing_form')
      .form({
        inline: true,
        fields: {
          amount: {
            identifier: 'amount',
            rules:
            [
              {
              type: 'empty',
              prompt: 'Please enter PEC limit amount'
              },
              {
                type: 'integer[1..100]',
                prompt: 'Maximum PEC limit amount is up to 100 Sessions only'
              }
            ]
          }
        },
       onSuccess: function(event, fields){
        var input = document.getElementById('exclusion_limit_amount');
        var unmasked = input.inputmask.unmaskedvalue()
        input.inputmask.remove()
        $('#exclusion_limit_amount').val(unmasked)
       }
      })
  }
})

onmount('div[id="exclusion_diseases"]', function() {

  $('#add_disease').modal({
    autofocus: false,
    observeChanges: true
  }).modal('attach events', '.add.button', 'show')
  var valArray = []

  $('input:checkbox.selection').on('change', function() {
    var value = $(this).val()

    if (this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value)

      if (index >= 0) {
        valArray.splice(index, 1)
      }
    }
    $('input[name="exclusion[disease_ids_main]"]').val(valArray)
  })


  $('#select_all').on('change', function() {
    var table = $('#disease_table_modal').DataTable()
    var rows = table.rows({ 'search': 'applied' }).nodes();

    if ($(this).is(':checked')) {
      $('input[type="checkbox"]', rows).each(function() {
        var value = $(this).val()

        if (this.checked) {
          valArray.push(value)
        } else {
          var index = valArray.indexOf(value);

          if (index >= 0) {
            valArray.splice(index, 1)
          }
          valArray.push(value)
        }
        $(this).prop('checked', true)
      })

    } else {
      valArray.length = 0
      $('input[type="checkbox"]', rows).each(function() {
        $(this).prop('checked', false)
      })
    }
    $('input[name="exclusion[disease_ids_main]"]').val(valArray)
  })

})

  onmount('div[id="edit"]', function() {

  $('#disease_modal').modal('attach events', '#edit_disease_button', 'show')

  var valArray1 = []

  $('input:checkbox.selection').on('change', function() {
    var value = $(this).val()

    if (this.checked) {
      valArray1.push(value)
    } else {
      var index = valArray1.indexOf(value)

      if (index >= 0) {
        valArray1.splice(index, 1)
      }
    }
    $('input[name="exclusion[disease_ids_main]"]').val(valArray1)
  })

  $('#select_all').on('change', function() {
    var table = $('#disease_table_modal').DataTable()
    var rows = table.rows({ 'search': 'applied' }).nodes();

    if ($(this).is(':checked')) {
      $('input[type="checkbox"]', rows).each(function() {
        var value = $(this).val()

        if (this.checked) {
          valArray.push(value)
        } else {
          var index = valArray.indexOf(value);

          if (index >= 0) {
            valArray.splice(index, 1)
          }
          valArray.push(value)
        }
        $(this).prop('checked', true)
      })

    } else {
      valArray.length = 0
      $('input[type="checkbox"]', rows).each(function() {
        $(this).prop('checked', false)
      })
    }
    $('input[name="exclusion[disease_ids_main]"]').val(valArray)
  })

  $('#procedure_modal').modal('attach events', '#edit_procedure_button', 'show');

  var valArray2 = []

  $('input:checkbox.selection').on('change', function() {
    var value = $(this).val()
    if (this.checked) {
      valArray2.push(value)
    } else {
      var index = valArray2.indexOf(value)

      if (index >= 0) {
        valArray2.splice(index, 1)
      }
    }
    $('input[name="exclusion[procedure_ids_main]"]').val(valArray2)
  })


  $('#select_allp').on('change', function() {
    var table = $('#procedure_table_modal').DataTable()
    var rows = table.rows({ 'search': 'applied' }).nodes();

    if ($(this).is(':checked')) {
      $('input[type="checkbox"]', rows).each(function() {
        var value = $(this).val()

        if (this.checked) {
          valArray2.push(value)
        } else {
          var index = valArray2.indexOf(value);

          if (index >= 0) {
            valArray2.splice(index, 1)
          }
          valArray2.push(value)
        }
        $(this).prop('checked', true)
      })

    } else {
      valArray2.length = 0
      $('input[type="checkbox"]', rows).each(function() {
        $(this).prop('checked', false)
      })
    }
    $('input[name="exclusion[procedure_ids_main]"]').val(valArray2)
  })
})

onmount('div[id="exclusion_procedures"]', function() {

  $('#procedure_modal').modal({
    autofocus: false,
    observeChanges: true
  }).modal('attach events', '.add.button', 'show')

  var valArray = []

  $('input:checkbox.selection').on('change', function() {
    var value = $(this).val()
    if (this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value)

      if (index >= 0) {
        valArray.splice(index, 1)
      }
    }
    $('input[name="exclusion[procedure_ids_main]"]').val(valArray)
  })

  $('#select_allp').on('change', function() {
    var table = $('#procedure_table_modal').DataTable()
    var rows = table.rows({ 'search': 'applied' }).nodes();

    if ($(this).is(':checked')) {
      $('.selection', rows).each(function() {
        var value = $(this).val()

        if (this.checked) {
          valArray.push(value)
        } else {
          var index = valArray.indexOf(value);

          if (index >= 0) {
            valArray.splice(index, 1)
          }
          valArray.push(value)
        }
        $(this).prop('checked', true)
      })

    } else {
      valArray.length = 0
      $('.selection', rows).each(function() {
        $(this).prop('checked', false)
      })
    }
    console.log(valArray)
    $('input[name="exclusion[procedure_ids_main]"]').val(valArray)
  })

})

onmount('div[id="exclusions_step1"]', function() {

  $('#step1_tab .item').on('click', function() {
    var tabActive = $(this).attr("data-tab");
    if (tabActive == "exclusion") {
      $("div#step_pre_existing").css("display", "none")
      $("div#step_exclusion").css("display", "")
      $("p#exclusion_section").html("Add Exclusion")
    } else if (tabActive == "pre_existing") {
      $("div#step_pre_existing").css("display", "")
      $("div#step_exclusion").css("display", "none")
      $("p#exclusion_section").html("Add Pre-existing Condition")
    }

  })

  const csrf = $('input[name="_csrf_token"]').val();
  const exclusion_code = $('input[name="exclusion[code]"]').attr("value")

  $.ajax({
    url: `/get_all_exclusion_code`,
    headers: {
      "X-CSRF-TOKEN": csrf
    },
    type: 'get',
    success: function(response) {
      const data = JSON.parse(response)
      const array = $.map(data, function(value, index) {
        return [value.code]
      });

      if (exclusion_code != undefined) {
        array.splice($.inArray(exclusion_code, array), 1)
      }

      $.fn.form.settings.rules.checkExclusionCode = function(param) {
        return array.indexOf(param) == -1 ? true : false
      }

      $('#general_exclusion')
        .form({
          inline: true,
          on: 'blur',
          fields: {
            'exclusion[name]': {
              identifier: 'exclusion[name]',
              rules: [{
                type: 'empty',
                prompt: 'Please enter exclusion name'
              }]
            },
            'exclusion[code]': {
              identifier: 'exclusion[code]',
              rules: [{
                type: 'empty',
                prompt: 'Please enter exclusion code'
              }, {
                type: 'checkExclusionCode[param]',
                prompt: 'Exclusion Code is already taken!'
              }]
            }
          }
        })

      $('#general_pre_existing')
        .form({
          inline: true,
          on: 'blur',
          fields: {
            'exclusion[name]': {
              identifier: 'exclusion[name]',
              rules: [{
                type: 'empty',
                prompt: 'Please enter exclusion name'
              }]
            },
            'exclusion[code]': {
              identifier: 'exclusion[code]',
              rules: [{
                type: 'empty',
                prompt: 'Please enter exclusion code'
              }, {
                type: 'checkExclusionCode[param]',
                prompt: 'Exclusion Code is already taken!'
              }]
            },
            'exclusion[limit_amount]': {
              identifier: 'exclusion[limit_amount]',
              rules: [{
                type: 'empty',
                prompt: 'Please enter PEC limit amount'
              }]
            }
          }
        })
    },
    error: function() {
      console.log("error")
    }
  })

});

onmount('div[id="show_tab"]', function() {
  $('.tabular.menu .item').tab();
});

onmount('div[id="editGeneral"]', function() {
  $('.form2')
    .form({
      inline: true,
      on: 'blur',
      fields: {
        'exclusion[name]': {
          identifier: 'exclusion[name]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter exclusion name'
          }]
        },
        'exclusion[code]': {
          identifier: 'exclusion[code]',
          rules: [{
            type: 'empty',
            prompt: 'Please enter enter exclusion code'
          }]
        }
      }
    })
})

onmount('#exclusion_show_dt', function () {
let datatable_dedatatable = $('#diagnosis_exclusion_table')

  const csrf = $('input[name="_csrf_token"]').val();
  datatable_dedatatable.DataTable({
    "dom":
      "<'ui grid'"+
        "<'row'"+
          "<'two wide column'f>"+
          "<'eight wide column'i>"+
        ">"+
        "<'row dt-table'"+
          "<'sixteen wide column'tr>"+
        ">"+
        "<'row'"+
          "<'right aligned ten wide column'l>"+
          "<'right aligned four wide column'p>"+
        ">"+
      ">",
    "renderer": 'semanticUI',
    "pagingType": "full_numbers",
    "language": {
      "emptyTable":     "No Diagnosis found",
      "zeroRecords":    "No Diagnosis matched your search",
      "info": "Showing _END_ out of _MAX_ results",
      "infoEmpty": "Showing 0 out of 0 result",
      "infoFiltered": "",
      "lengthMenu": "Show: _MENU_",
      "search":         "",
      "paginate": {
        "previous": "<i class='angle single left icon'></i>",
        "next": "<i class='angle single right icon'></i>",
      }
    },
     "drawCallback": function () {
      var table = datatable_dedatatable.DataTable();
      var info = table.page.info();
      append_jump_exclusion_show(info.page, info.pages)
      add_search(this)
    },
      "deferRender": true
  });

  $(document).on('change', '.ui.fluid.search.dropdown.exclusion', function(){
    let page = $(this).find($('.text')).html()
    var table = datatable_dedatatable.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  let exclusion_search_id = $('#diagnosis_exclusion_table_wrapper')

  exclusion_search_id.find('.dataTables_info').attr("style", "margin-left: 1rem;")


  function append_jump_exclusion_show(page, pages){
    let exclusion_search_id = $('#diagnosis_exclusion_table_wrapper')
    let results;

    if (results = exclusion_search_id.find('.table > tbody  > tr').html().includes("matched your search")) {
      results = 0
    }
    else {
      results = exclusion_search_id.find('.table > tbody  > tr').length
    }
    exclusion_search_id.find('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    exclusion_search_id.find(".first.paginate_button, .last.paginate_button").hide()
    exclusion_search_id.find('.one.wide').remove()
    exclusion_search_id.find('.show').remove()
    exclusion_search_id.find('#diagnosis_exclusion_table_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
    exclusion_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
    exclusion_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
    `<div class="right aligned one wide column inline field"> Jump to page: </div>\
    <div class="right aligned one wide column inline field" id="jump_search">\
      <select class="ui fluid search dropdown exclusion" id="jump_exclusion_show">\
      </select>\
    </div>`
    )
    var select = $('#jump_exclusion_show')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
       options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
    exclusion_search_id.find('.ui.fluid.search.dropdown').dropdown()
    exclusion_search_id.find('#jump_exclusion_show').dropdown('set selected', page + 1)

    exclusion_search_id.find(document).find('input[class="search"]').keypress(function(evt) {
        evt = (evt) ? evt : window.event
        var charCode = (evt.which) ? evt.which : evt.keyCode
        if (charCode == 8) {
            return true
        } else if (charCode == 46) {
            return false
        } else if (charCode == 37) {
            return false
        }  else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
            return false
        } else if (this.value.length == 0 && evt.which == 48) {
            return false
        } else if (parseInt(this.value + String.fromCharCode(charCode)) > pages){
            return false
        }
        return true
    })
  }
})

onmount('#exclusion_show2_dt', function () {
let datatable_depdatatable = $('#procedure_exclusion_table')

  const csrf = $('input[name="_csrf_token"]').val();
  datatable_depdatatable.DataTable({
    "dom":
      "<'ui grid'"+
        "<'row'"+
          "<'two wide column'f>"+
          "<'eight wide column'i>"+
        ">"+
        "<'row dt-table'"+
          "<'sixteen wide column'tr>"+
        ">"+
        "<'row'"+
          "<'right aligned ten wide column'l>"+
          "<'right aligned four wide column'p>"+
        ">"+
      ">",
    "renderer": 'semanticUI',
    "pagingType": "full_numbers",
    "language": {
      "emptyTable":     "No Procedures found",
      "zeroRecords":    "No Procedures matched your search",
      "info": "Showing _END_ out of _MAX_ results",
      "infoEmpty": "Showing 0 out of 0 result",
      "infoFiltered": "",
      "lengthMenu": "Show: _MENU_",
      "search":         "",
      "paginate": {
        "previous": "<i class='angle single left icon'></i>",
        "next": "<i class='angle single right icon'></i>",
      }
    },
     "drawCallback": function () {
      var table = datatable_depdatatable.DataTable();
      var info = table.page.info();
      append_jump_exclusion_procedure_show(info.page, info.pages)
      add_search(this)
    },
      "deferRender": true
  });

  $(document).on('change', '.ui.fluid.search.dropdown.exclusion_procedure', function(){
    let page = $(this).find($('.text')).html()
    var table = datatable_depdatatable.DataTable();
    let no = parseInt(page) -1
    table.page( no ).draw( 'page' );
  })

  let exclusion_search_id = $('#procedure_exclusion_table_wrapper')

  exclusion_search_id.find('.dataTables_info').attr("style", "margin-left: 1rem;")


  function append_jump_exclusion_procedure_show(page, pages){
    let exclusion_search_id = $('#procedure_exclusion_table_wrapper')
    let results;

    if (results = exclusion_search_id.find('.table > tbody  > tr').html().includes("matched your search")) {
      results = 0
    }
    else {
      results = exclusion_search_id.find('.table > tbody  > tr').length
    }
    exclusion_search_id.find('.table > tbody  > tr').each(function(){
      $(this).attr('style', 'height:50px')
    })
    exclusion_search_id.find(".first.paginate_button, .last.paginate_button").hide()
    exclusion_search_id.find('.one.wide').remove()
    exclusion_search_id.find('.show').remove()
    exclusion_search_id.find('#procedure_exclusion_table_length').find('label').before(`<span class="show" style="margin-right:30px"> Showing ${results} results</span>`)
    exclusion_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().attr('style', 'margin-left:100px')
    exclusion_search_id.find(".dataTables_paginate.paging_full_numbers").parent().parent().append(
    `<div class="right aligned one wide column inline field"> Jump to page: </div>\
    <div class="right aligned one wide column inline field" id="jump_search">\
      <select class="ui fluid search dropdown exclusion" id="jump_exclusion_procedure_show">\
      </select>\
    </div>`
    )
    var select = $('#jump_exclusion_procedure_show')
    var options = []
    for(var x = 1; x < parseInt(pages) + 1; x++){
       options.push(`<option value='${x}'>${x}</option>`)
    }
    select.append(String(options.join('')))
    exclusion_search_id.find('.ui.fluid.search.dropdown').dropdown()
    exclusion_search_id.find('#jump_exclusion_procedure_show').dropdown('set selected', page + 1)

    exclusion_search_id.find(document).find('input[class="search"]').keypress(function(evt) {
        evt = (evt) ? evt : window.event
        var charCode = (evt.which) ? evt.which : evt.keyCode
        if (charCode == 8) {
            return true
        } else if (charCode == 46) {
            return false
        } else if (charCode == 37) {
            return false
        }  else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
            return false
        } else if (this.value.length == 0 && evt.which == 48) {
            return false
        } else if (parseInt(this.value + String.fromCharCode(charCode)) > pages){
            return false
        }
        return true
    })
  }
})

function add_search(table){
  let id = table[0].getAttribute("id")
  let value = $(`#${id}_filter`).val()

  if(value != 1){
    $(`#${id}_filter`).addClass('ui left icon input')
    $(`#${id}_filter`).find('label').after('<i class="search icon"></i>')
    $(`#${id}_filter`).find('input[type="search"]').unwrap()
    $(`#${id}_filter`).find('input[type="search"]').attr("placeholder", `Search`)
    $(`#${id}_filter`).find('input[type="search"]').append(`</div>`)
    $(`#${id}_filter`).val(1)
  }
}
