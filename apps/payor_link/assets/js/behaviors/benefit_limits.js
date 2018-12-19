onmount('div[id="benefit_limits"]', function() {
  let acu_checker = $('#acu_checker').val()

  $.fn.form.settings.rules.checkPeso = function(param) {
    if (param < 1) {
      return false
    } else{
      return true
    }
  }

  $.fn.form.settings.rules.check_value = function(param) {
    if (param != "") {
      if(param < 1) {
        return false
      } else {
        return true
      }
    } else{
      return false
    }
  }

  let enable_save = () => {
    $("#edit_save_btn").removeClass('disabled')
  }

  $('#edit_amount').on('keyup', function() {
    enable_save()
  })

  $("#limitClassificationPT, #limitClassificationPCP").on('change', function() {
    enable_save()
  })

  if(acu_checker == "true") {
    $('#add_modal_acu').modal('attach events', '.add.button', 'show')
    $('#edit_modal_acu').modal({
      autofocus: false
    }).modal('attach events', '.edit_limit', 'show')

    $(".edit_limit").click(function() {
      $(".amount").removeClass('error')
      $(".coverages").removeClass('error')

      let id = $(this).attr('blid')
      let type = $(this).closest('tr').find('td[field="type"]').text()
      let amount = $(this).closest('tr').find('.la').val()
      let session = $(this).closest('tr').find('.ls').val()
      let classification = $(this).closest('tr').find('td[field="classification"]').text()

      $('input[id="edit_amount"]').val(amount)
      $('input[name="benefit[benefit_limit_id]"]').val(id)
      if (classification == "Per Coverage Period") {
        $("#limitClassificationPCP").prop("checked", true)
      } else {
        $("#limitClassificationPT").prop("checked", true)
      }
    })

    let mask_decimal = new Inputmask("decimal", {
      radixPoint: ".",
      groupSeparator: ",",
      digits: 2,
      autoGroup: true,
      // prefix: '₱ ',
      allowMinus:false,
      rightAlign: false,
      max: 1000000
    });

    mask_decimal.mask($('#benefit_amount'));
    mask_decimal.mask($('#edit_amount'));
  } else {
    $('#add_modal').modal('attach events', '.add.button', 'show')
    $('#edit_modal').modal({
      autofocus: false
    }).modal('attach events', '.edit_limit', 'show')

    $(".edit_limit").click(function() {
      $(".amount").removeClass('error')
      $(".coverages").removeClass('error')
      $('#coverage_items').html('')
      let coverage_list = $('#coverage_list').val()
      let coverage_list_name = $('#coverage_list_name').val()
      let id = $(this).attr('blid')
      let coverages = $(this).closest('tr').find('a[field="coverages"]').attr('codes')
      let coverages_array = coverages.split(", ")
      let coverage_names = $(this).closest('tr').find('a[field="coverages"]').text()
      let coverage_names_array = coverage_names.split(", ")
      let coverage_list_array = coverage_list.split(", ")
      let coverage_names_list_array = coverage_list_name.split(", ")
      let type = $(this).closest('tr').find('td[field="type"]').text()
      let amount = $(this).closest('tr').find('td[field="amount"]').text()
      let classification = $(this).closest('tr').find('td[field="classification"]').text()
      let coverage_tuples = []


      for(var y = 0; y < coverages_array.length; y++){
        var coverage_tuple = {name: coverage_names_array[y], code: coverages_array[y]}
        coverage_tuples.push(coverage_tuple)
      }

      for (let coverage of coverage_tuples) {
        $('#coverage_items').append(`<div class="item" data-value="${coverage.code}">${coverage.name}</div>`)
      }



      for(var y = 0; y < coverage_list_array.length; y++){
        var coverage_tuple = {name: coverage_names_list_array[y], code: coverage_list_array[y]}
        coverage_tuples.push(coverage_tuple)
      }
      for (let coverage of coverage_tuples) {
        $('#coverage_items').append(`<div class="item" data-value="${coverage.code}">${coverage.name}</div>`)
      }

      var remaining_list = $(coverages_array).not(coverage_list_array).get();

      // remove currently added items from dropdown list
      for (let coverage of remaining_list) {
        $('#edit_coverages').dropdown('remove selected', coverage)
      }

      $('#edit_coverages').dropdown('refresh')
      $('#edit_coverages').dropdown('set selected', coverages_array)
      $('input[id="edit_amount"]').val(amount)
      $('#edit_limit_type').dropdown('set selected', type)
      $('input[name="benefit[benefit_limit_id]"]').val(id)
      if (classification == "Per Coverage Period") {
        $("#limitClassificationPCP").prop("checked", true)
      } else {
        $("#limitClassificationPT").prop("checked", true)
      }
    })

    $("#benefit_limit_type").change(function() {
      let limit_type = $(this).val()
      $('#benefit_amount').val("")
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

    $("#edit_limit_type").change(function() {
      let limit_type = $(this).val()
      if (limit_type == "Peso") {
        $("#editLimitAmountIcon").html('PHP')
        validate_edit_peso()
      } else if (limit_type == "Sessions") {
        $("#editLimitAmountIcon").html('Sessions')
        validate_edit_sessions()
      } else {
        $("#editLimitAmountIcon").html('%')
        validate_edit_percentage()
      }
    })
  }

  $("#remove_button").click(function() {
    $('#modalDeleteBenefitLimit').modal('show')
  })

  $("#confirmDeleteBenefitLimit").click(function() {
    delete_benefit_limit()
  })

  function delete_benefit_limit(){
    let id = $('input[name="benefit[benefit_limit_id]"]').val()
    let csrf = $('input[name="_csrf_token"]').val()

    $.ajax({
      url: `/delete_benefit_limit/${id}`,
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      type: 'delete',
      success: function(response) {
        window.location.reload()
      },
      error: function(error) {
        alert("invalid benefit limit id")
      },
    })
  }

  // Use peso validation on page load
  validate_peso()

  function validate_percentage() {
    $('#add_form')
      .form({
        inline: true,
        fields: {
          amount: {
            identifier: 'amount',
            rules: [{
              type: 'integer[1..100]',
              prompt: 'Invalid percentage range enter a number from 1-100'
            }]
          },
          coverages: {
            identifier: 'coverages',
            rules: [{
              type: 'empty',
              prompt: 'Please select coverage'
            }]
          }
        }
      })
  }


  function validate_peso() {
    $('#add_form')
      .form({
        inline: true,
        fields: {
          amount: {
            identifier: 'amount',
            rules: [
              {
                type: 'check_value[param]',
                prompt: 'Please enter a limit amount.'
              }
            ]
          },
          coverages: {
            identifier: 'coverages',
            rules: [{
              type: 'empty',
              prompt: 'Please select coverage'
            }]
          }
        }
      })
  }

  function validate_sessions() {
    $('#add_form')
      .form({
        inline: true,
        fields: {
          amount: {
            identifier: 'amount',
            rules:
            [
              {
                type: 'integer',
                prompt: 'Invalid number of sessions. Please enter a valid number.'
              },
              {
                type: 'checkPeso[param]',
                prompt: 'Sessions must be greater than 0.'
              }
            ]
          },
          coverages: {
            identifier: 'coverages',
            rules: [{
              type: 'empty',
              prompt: 'Please select coverage'
            }]
          }
        }
      })
  }

  function validate_edit_percentage() {
    $('#edit_form')
      .form({
        inline: true,
        fields: {
          amount: {
            identifier: 'edit_amount',
            rules: [{
              type: 'integer[1..100]',
              prompt: 'Invalid percentage range enter a number from 1-100'
            }]
          },
          coverages: {
            identifier: 'edit_coverages',
            rules: [{
              type: 'empty',
              prompt: 'Please select coverage'
            }]
          }
        }
      })
  }

  function validate_edit_peso() {
    $('#edit_form')
      .form({
        inline: true,
        fields: {
          amount: {
            identifier: 'edit_amount',
            rules: [
              {
                type: 'check_value[param]',
                prompt: 'Please enter a limit amount.'
              }
            ]
          }
        }
      })
  }

  function validate_edit_sessions() {
    $('#edit_form')
      .form({
        inline: true,
        fields: {
          amount: {
            identifier: 'edit_amount',
            rules:
            [
              {
                type: 'integer',
                prompt: 'Invalid number of sessions. Please enter a valid number.'
              },
              {
                type: 'checkPeso[param]',
                prompt: 'Sessions must be greater than 0.'
              }
            ]
          },
          coverages: {
            identifier: 'edit_coverages',
            rules: [{
              type: 'empty',
              prompt: 'Please select coverage'
            }]
          }
        }
      })
  }

});
