onmount('div[id="health_form"]', function() {

let health_code = $('#health_code').val()
let riders_code = $('#riders_code').val()

  var tabActive = $('div[role="benefits"] > .active.item').attr("data-tab");
  if (tabActive == "health_plan"){
    $('#riders_code').removeAttr('name')
    $('#health_code').attr('name', 'benefit[code]')
    $('#riders_code').val('')

  }
  else if (tabActive == "riders"){
    $('#health_code').removeAttr('name')
    $('#riders_code').attr('name', 'benefit[code]')
    $('#health_code').val('')
  }

$('div[role="benefits"] > .item').on('click', function() {
  var tabActive = $(this).attr("data-tab");
  if (tabActive == "health_plan"){
    $('#riders_code').removeAttr('name')
    $('#health_code').attr('name', 'benefit[code]')

        $('#health_code').val(health_code)
            $('#riders_code').val('')
  }
  else if (tabActive == "riders"){
    $('#health_code').removeAttr('name')
    $('#riders_code').attr('name', 'benefit[code]')
    $('#riders_code').val(riders_code)
    $('#health_code').val() == ""
  }
})

  $('#health_coverage_others').find('option').each(function(i) {
    $(this).attr('id', 'option_' + i)
  })

  $('#others').hide()

  if ($('#health_coverage').val() == 'Others') {
    $('#others').show()
    $('#op2').append($('#health_coverage_others option[id="option_2"]').clone()).html()
    $('#health_coverage_others option[id="option_2"]').remove()
  }

  $('#health_coverage').on('change', function() {
    let option_selected = $('#health_coverage option:selected').val()
    $('#op2').append($('#health_coverage_others option[id="option_2"]').clone()).html()

    if (option_selected == "Others") {
      $('#others').show()
      $('#health_coverage_others').dropdown('clear')
      $('#health_coverage_others option[id="option_2"]').remove()

    } else if (option_selected == "OP Consult") {
      $('#others').hide()
      $('#health_coverage_others').dropdown('clear')
      $('#health_coverage_others option[id="option_2"]').remove()
      $('#health_coverage_others').append($('#option_2').clone()).html()

    }

    $('#health_submit').on('click', function() {
      $(this).submit()
      if (option_selected == "OP Consult") {
        $('#health_coverage_others').dropdown('set selected', 'OP Consult')
      }
    })
  })
});

onmount('div[id="riders_form"]', function() {

  $('#health_code').keyup(function(e) {
    const csrf = $('input[name="_csrf_token"]').val();
    let code = $('#health_code').val()

    if(code != ""){
      $.ajax({
        url: `/get_benefit/code/${code}`,
        headers: {
          "X-CSRF-TOKEN": csrf
        },
        type: 'get',
        success: function(response) {
          if(response == "true"){
            $('#health_code_field').removeClass('error')
            $('#health_code_field').find('.prompt').remove()
            $('#health_submit').attr('type', 'submit')
          }
          else{
            $('#health_code_field').removeClass('error')
            $('#health_code_field').find('.prompt').remove()
            $('#health_code_field').addClass('error')
            $('#health_code_field').append(`<div class="ui basic red pointing prompt label transition visible">Benefit code already exist!</div>`)
            $('#health_submit').attr('type', 'button')
          }
        }
      })
    }
  })

  $('div[role="benefits"] > .item').on('click', function() {
    var tabActive = $(this).attr("data-tab");
    if (tabActive == "health_plan") {
      $('#riders_code').removeData()
    } else if (tabActive == "riders") {
      $('#health_code').removeData()
    }
  })

  // const csrf = $('input[name="_csrf_token"]').val();
  // const benefit_code = $('input[name="benefit[code]"]').attr("value")

  // $.ajax({
  //   url: `/get_all_benefit_code`,
  //   headers: {
  //     "X-CSRF-TOKEN": csrf
  //   },
  //   type: 'get',
  //   success: function(response) {
      // const data = JSON.parse(response)
      // const array = $.map(data, function(value, index) {
      //   return [value.code]
      // });

      // if (benefit_code != undefined) {
      //   array.splice($.inArray(benefit_code, array), 1)
      // }

      // $.fn.form.settings.rules.checkBenefitCode = function(param) {
      //   return array.indexOf(param) == -1 ? true : false
      // }
      $('#health_submit').on('click', function() {
        if($(this).attr('type') != 'button'){
        let health_coverage = $('#health_coverage :selected').text()
        if (health_coverage == "Others") {
          $('#form_health')
            .form({
              inline: true,
              on: 'blur',
              fields: {
                'health_coverage_others': {
                  identifier: 'health_coverage_others',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select Benefit Coverage/s'
                  }]
                },
                'benefit[code]': {
                  identifier: 'benefit[code]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Code'
                  }
                  // , {
                  //   type: 'checkBenefitCode[param]',
                  //   prompt: 'Benefit Code already exist!'
                  // }
                  ]
                },
                'benefit[name]': {
                  identifier: 'benefit[name]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Name'
                  }]
                },
              }
            })
        } else {
          $('#form_health')
            .form({
              inline: true,
              on: 'blur',
              fields: {
                'benefit[coverage_picker]': {
                  identifier: 'benefit[coverage_picker]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select Benefit Coverage'
                  }]
                },
                'benefit[code]': {
                  identifier: 'benefit[code]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Code'
                  }
                  // {
                  //   type: 'checkBenefitCode[param]',
                  //   prompt: 'Benefit Code already exist!'
                  // }
                  ]
                },
                'benefit[name]': {
                  identifier: 'benefit[name]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Name'
                  }]
                }
              }
            })
        }
      }
      })

      let riders_coverage = $('#riders_coverage :selected').text()
      if (riders_coverage == "Maternity") {
        $("#maternity").removeClass('hidden')
        $("#maternity").addClass('field')
      } else if (riders_coverage == "ACU") {
        $("#acu").removeClass('hidden')
        $("#acu").addClass('three fields')
      }

      $('#riders_coverage').on('change', function() {
        let riders_coverage = $('#riders_coverage :selected').text()
        if (riders_coverage == "Maternity") {
          $('.form2').find('.ui.error.message ul').remove()
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#maternity").removeClass('hidden')
          $("#maternity").addClass('field')
          $("#acu").removeClass('two fields')
          $("#acu").addClass('hidden')
        } else if (riders_coverage == "ACU") {
          $('.form2').find('.ui.error.message ul').remove();
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#acu").removeClass('hidden')
          $("#acu").addClass('two fields')
          $("#maternity").removeClass('field')
          $("#maternity").addClass('hidden')
        } else {
          $('.form2').find('.ui.error.message ul').remove();
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#maternity").removeClass('field')
          $("#maternity").addClass('hidden')
          $("#acu").removeClass('three fields')
          $("#acu").addClass('hidden')
        }
      })

      let riders_coverage_enrollees = $('#riders_coverage :selected').text()
      if (riders_coverage == "Maternity_enrollees") {
        $("#maternity_enrollees").removeClass('hidden')
        $("#maternity_enrollees").addClass('field')
      } else if (riders_coverage == "ACU") {
        $("#acu").removeClass('hidden')
        $("#acu").addClass('three fields')
      }

      $('#riders_coverage').on('change', function() {
        check_covered_enrollees()
      })

      function check_covered_enrollees() {
        let riders_coverage = $('#riders_coverage :selected').text()
        if (riders_coverage == "Maternity") {
          $('.form2').find('.ui.error.message ul').remove()
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#maternity_enrollees").removeClass('hidden')
          $("#maternity_enrollees").addClass('field')
          $("#acu").removeClass('two fields')
          $("#acu").addClass('hidden')
        } else if (riders_coverage == "ACU") {
          $('.form2').find('.ui.error.message ul').remove();
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#acu").removeClass('hidden')
          $("#acu").addClass('two fields')
          $("#maternity_enrollees").removeClass('field')
          $("#maternity_enrollees").addClass('hidden')
        } else {
          $('.form2').find('.ui.error.message ul').remove();
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#maternity_enrollees").removeClass('field')
          $("#maternity_enrollees").addClass('hidden')
          $("#acu").removeClass('three fields')
          $("#acu").addClass('hidden')
        }
      }

 let radio_button = $('#riders_coverage :selected').text()
      if (riders_coverage == "waiting_period") {
        $("#waiting_period").removeClass('hidden')
        $("#waiting_period").addClass('field')
      } else if (riders_coverage == "ACU") {
        $("#acu").removeClass('hidden')
        $("#acu").addClass('three fields')
      }
 function check_waiting_period() {
        let riders_coverage = $('#riders_coverage :selected').text()
        if (riders_coverage == "Maternity") {
          $('.form2').find('.ui.error.message ul').remove()
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#waiting_period").removeClass('hidden')
          $("#waiting_period").addClass('field')
          $("#acu").removeClass('two fields')
          $("#acu").addClass('hidden')
        } else if (riders_coverage == "ACU") {
          $('.form2').find('.ui.error.message ul').remove();
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#acu").removeClass('hidden')
          $("#acu").addClass('two fields')
          $("#waiting_period").removeClass('field')
          $("#waiting_period").addClass('hidden')
        } else {
          $('.form2').find('.ui.error.message ul').remove();
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#waiting_period").removeClass('field')
          $("#waiting_period").addClass('hidden')
          $("#acu").removeClass('three fields')
          $("#acu").addClass('hidden')
        }
 }

      $('#riders_coverage').on('change', function() {
      check_waiting_period()
      })

      // let hide_condition_headers = $('#riders_coverage :selected').text()
      // if (riders_coverage == "condition") {
      //   $("#condition_header").removeClass('left floated left aligned six wide column')
      //   $("#condition_header").addClass('hidden')
      // } else if (riders_coverage == "ACU") {
      //   $("#acu").removeClass('hidden')
      //   $("#acu").addClass('three fields')
      // }
      // function hide_condition_header() {
      //   let riders_coverage = $('#riders_coverage :selected').text()
      //   if (riders_coverage == "PEME") {
      //     $('.form2').find('.ui.error.message ul').remove()
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     // $("#condition_header").removeClass('left floated left aligned six wide column')
      //     // $("#condition_header").addClass('hidden')
      //     $("#condition_header").attr('style', 'display:none;')
      //     // $('.ui divider mrg1T mrg1B').attr('style', 'display:none;')
      //     $("#acu").removeClass('two fields')
      //     $("#acu").addClass('hidden')
      //   } else if (riders_coverage == "ACU") {
      //     $('.form2').find('.ui.error.message ul').remove();
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     $("#acu").removeClass('hidden')
      //     $("#acu").addClass('two fields')
      //     // $("#condition_header").removeClass('left floated left aligned six wide column')
      //     // $("#condition_header").addClass('hidden')
      //   } else {
      //     $('.form2').find('.ui.error.message ul').remove();
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     // $("#condition_header").removeClass('hidden')
      //     // $("#condition_header").removeClass('left floated left aligned six wide column')
      //     $("#condition_header").attr('style', '')
      //     // $('.ui divider mrg1T mrg1B').attr('style', '')
      //     $("#acu").removeClass('three fields')
      //     $("#acu").addClass('hidden')
      //   }
      // }

      // hide_condition_header()
      // $('#riders_coverage').on('change', function() {
      //   hide_condition_header()
      // })

      // let hide_dividers = $('#riders_coverage :selected').text()
      // if (riders_coverage == "condition") {
      //   $("#condition_header").removeClass('left floated left aligned six wide column')
      //   $("#condition_header").addClass('hidden')
      // } else if (riders_coverage == "ACU") {
      //   $("#acu").removeClass('hidden')
      //   $("#acu").addClass('three fields')
      // }
      // function hide_divider() {
      //   let riders_coverage = $('#riders_coverage :selected').text()
      //   if (riders_coverage == "PEME") {
      //     $('.form2').find('.ui.error.message ul').remove()
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     // $("#condition_header").removeClass('left floated left aligned six wide column')
      //     // $("#condition_header").addClass('hidden')
      //     // $("#condition_header").attr('style', 'display:none;')
      //     // $('.ui divider mrg1T mrg1B').attr('style', 'display:none;')
      //     $("#divider").attr('style', 'display:none;')
      //     $("#acu").removeClass('two fields')
      //     $("#acu").addClass('hidden')
      //   } else if (riders_coverage == "ACU") {
      //     $('.form2').find('.ui.error.message ul').remove();
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     $("#acu").removeClass('hidden')
      //     $("#acu").addClass('two fields')
      //     // $("#condition_header").removeClass('left floated left aligned six wide column')
      //     // $("#condition_header").addClass('hidden')
      //   } else {
      //     $('.form2').find('.ui.error.message ul').remove();
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     // $("#condition_header").removeClass('hidden')
      //     // $("#condition_header").removeClass('left floated left aligned six wide column')
      //     // $("#condition_header").attr('style', '')
      //     // $('.ui divider mrg1T mrg1B').attr('style', '')
      //     $("#divider").attr('style', '')
      //     $("#acu").removeClass('three fields')
      //     $("#acu").addClass('hidden')
      //   }
      // }

      //   hide_divider()
      // $('#riders_coverage').on('change', function() {
      //   hide_divider()
      // })



      // let hide_radio_checkbox_condition_1 = $('#riders_coverage :selected').text()
      // if (riders_coverage == "condition") {
      //   $("#condition_1").removeClass('field')
      //   $("#condition_1").addClass('hidden')
      // } else if (riders_coverage == "ACU") {
      //   $("#acu").removeClass('hidden')
      //   $("#acu").addClass('three fields')
      // }
      // function hide_condition_1() {
      //   let riders_coverage = $('#riders_coverage :selected').text()
      //   if (riders_coverage == "PEME") {
      //     $('.form2').find('.ui.error.message ul').remove()
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     $("#condition_1").removeClass('field')
      //     $("#condition_1").addClass('hidden')
      //     $("#acu").removeClass('two fields')
      //     $("#acu").addClass('hidden')
      //   } else if (riders_coverage == "ACU") {
      //     $('.form2').find('.ui.error.message ul').remove();
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     $("#acu").removeClass('hidden')
      //     $("#acu").addClass('two fields')
      //     // $("#condition_1").removeClass('field')
      //     // $("#condition_1").addClass('hidden')
      //   } else {
      //     $('.form2').find('.ui.error.message ul').remove();
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     $("#condition_1").removeClass('hidden')
      //     $("#condition_1").addClass('field')
      //     $("#acu").removeClass('three fields')
      //     $("#acu").addClass('hidden')
      //   }
      // }

      // hide_condition_1()
      // $('#riders_coverage').on('change', function() {
      //   hide_condition_1()
      // })

    // let hide_radio_checkbox_condition_2 = $('#riders_coverage :selected').text()
      // if (riders_coverage == "condition") {
      //   $("#condition_2").removeClass('field')
      //   $("#condition_2").addClass('hidden')
      // } else if (riders_coverage == "ACU") {
      //   $("#acu").removeClass('hidden')
      //   $("#acu").addClass('three fields')
      // }
      // function hide_condition_2() {
      //   let riders_coverage = $('#riders_coverage :selected').text()
      //   if (riders_coverage == "PEME") {
      //     $('.form2').find('.ui.error.message ul').remove()
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     $("#condition_2").removeClass('field')
      //     $("#condition_2").addClass('hidden')
      //     $("#acu").removeClass('two fields')
      //     $("#acu").addClass('hidden')
      //   } else if (riders_coverage == "ACU") {
      //     $('.form2').find('.ui.error.message ul').remove();
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     $("#acu").removeClass('hidden')
      //     $("#acu").addClass('two fields')
      //     // $("#condition_2").removeClass('field')
      //     // $("#condition_2").addClass('hidden')
      //   } else {
      //     $('.form2').find('.ui.error.message ul').remove();
      //     $('.form2').find('.error').removeClass('error').find('.prompt').remove()
      //     $("#condition_2").removeClass('hidden')
      //     $("#condition_2").addClass('field')
      //     $("#acu").removeClass('three fields')
      //     $("#acu").addClass('hidden')
      //   }
      // }

      // hide_condition_2()
      // $('#riders_coverage').on('change', function() {
      //   hide_condition_2()
      // })


      check_waiting_period()
      check_covered_enrollees()

      $('#riders_submit').on('click', function() {
        let selected_type = $('#riders_coverage').find('option:selected').text()
        if (selected_type == "Maternity") {
          $('#form_riders')
            .form({
              inline: true,
              on: 'blur',
              fields: {
                'benefit[coverage_id]': {
                  identifier: 'benefit[coverage_id]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select Benefit Coverage'
                  }]
                },
                'benefit[code]': {
                  identifier: 'benefit[code]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Code'
                  }
                  // {
                  //   type: 'checkBenefitCode[param]',
                  //   prompt: 'Benefit Code already exist!'
                  // }
                  ]
                },
                'benefit[name]': {
                  identifier: 'benefit[name]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Name'
                  }]
                },
                'benefit[maternity_type]': {
                  identifier: 'benefit[maternity_type]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select Maternity Type'
                  }]
                },
                'benefit[waiting_period]': {
                  identifier: 'benefit[waiting_period]',
                  rules: [{
                    type: 'checked',
                    prompt: 'Please select Waiting Period'
                  }]
                },
                'benefit[covered_enrollees]': {
                  identifier: 'benefit[covered_enrollees]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select Covered Enrollees'
                  }]
                }
              }
            })

        }else if (selected_type == "PEME") {
          $('#form_riders')
          .form({
            inline: true,
            on: 'blur',
            fields: {
              'benefit[coverage_id]': {
                identifier: 'benefit[coverage_id]',
                rules: [{
                  type: 'empty',
                  prompt: 'Please select Benefit Coverage'
                }]
              },
              'benefit[code]': {
                identifier: 'benefit[code]',
                rules: [{
                  type: 'empty',
                  prompt: 'Please enter Benefit Code'
                }
                // {
                //   type: 'checkBenefitCode[param]',
                //   prompt: 'Benefit Code already exist!'
                // }
                ]
              },
              'benefit[name]': {
                identifier: 'benefit[name]',
                rules: [{
                  type: 'empty',
                  prompt: 'Please enter Benefit Name'
                }]
              }
            }
          })
        }  else if (selected_type == "ACU") {
          $('#form_riders')
          .form({
            inline: true,
              on: 'blur',
              fields: {
                'benefit[coverage_id]': {
                  identifier: 'benefit[coverage_id]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select Benefit Coverage'
                  }]
                },
                'benefit[code]': {
                  identifier: 'benefit[code]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Code'
                  }
                  // {
                  //   type: 'checkBenefitCode[param]',
                  //   prompt: 'Benefit Code already exist!'
                  // }
                  ]
                },
                'benefit[name]': {
                  identifier: 'benefit[name]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Name'
                  }]
                },
                'benefit[acu_type]': {
                  identifier: 'benefit[acu_type]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select ACU Type'
                  }]
                },
                'benefit[acu_coverage]': {
                  identifier: 'benefit[acu_coverage]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select ACU Coverage'
                  }]
                },
                'benefit[provider_access]': {
                  identifier: 'benefit[provider_access]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select at least one Provider Type'
                  }]
                }
              }
            })
        } else {
          $('#form_riders')
            .form({
              inline: true,
              on: 'blur',
              fields: {
                'benefit[coverage_id]': {
                  identifier: 'benefit[coverage_id]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select Benefit Coverage'
                  }]
                },
                'benefit[code]': {
                  identifier: 'benefit[code]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Code'
                  }
                  // {
                  //   type: 'checkBenefitCode[param]',
                  //   prompt: 'Benefit Code already exist!'
                  // }
                  ]
                },
                'benefit[name]': {
                  identifier: 'benefit[name]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Name'
                  }]
                },
              }
            })
        }
      })
    // },
    // error: function() {
    //   console.log("error")
    // }
  // })

      $('input[type=checkbox]').on('change', function() {
        // if ($('#hospital').prop('checked') == true && $('#mobile').prop('checked') == false) {
        //   $('#provider_access_value').val("Hospital/Clinic")
        if ($('#clinic').prop('checked') == true && $('#hospital').prop('checked') == true && $('#mobile').prop('checked') == true) {
          $('#provider_access_value').val("Clinic and Hospital and Mobile")
        }  else if ($('#clinic').prop('checked') == true && $('#hospital').prop('checked') == true) {
          $('#provider_access_value').val("Clinic and Hospital")
        } else if ($('#hospital').prop('checked') == true && $('#mobile').prop('checked') == true && $('#clinic').prop('checked') == false) {
          $('#provider_access_value').val("Hospital and Mobile")
        } else if ($('#clinic').prop('checked') == true && $('#mobile').prop('checked') == true && $('#hospital').prop('checked') == false) {
          $('#provider_access_value').val("Clinic and Mobile")
        } else if ($('#clinic').prop('checked') == true && $('#hospital').prop('checked') == false && $('#mobile').prop('checked') == false) {
          $('#provider_access_value').val("Clinic")
        } else if ($('#hospital').prop('checked') == true && $('#clinic').prop('checked') == false && $('#mobile').prop('checked') == false) {
          $('#provider_access_value').val("Hospital")
        } else if ($('#mobile').prop('checked') == true && $('#clinic').prop('checked') == false && $('#hospital').prop('checked') == false) {
          $('#provider_access_value').val("Mobile")
        } else {
          $('#provider_access_value').val("")
        }
      })

      if ($('#provider_access_value').val() == "Clinic and Hospital and Mobile") {
        $('#clinic').prop('checked', true)
        $('#hospital').prop('checked', true)
        $('#mobile').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Clinic and Hospital") {
        $('#clinic').prop('checked', true)
        $('#hospital').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Clinic and Mobile") {
        $('#clinic').prop('checked', true)
        $('#mobile').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Hospital and Mobile") {
        $('#hospital').prop('checked', true)
        $('#mobile').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Clinic") {
        $('#clinic').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Hospital") {
        $('#hospital').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Mobile") {
        $('#mobile').prop('checked', true)
      }




  // $('input[type=checkbox]').on('change', function() {
  //   if ($('#hospital').prop('checked') == true && $('#clinic').prop('checked') == false && $('#mobile').prop('checked') == false) {
  //     $('#provider_access_value').val("Hospital")
  //   } else if ($('#hospital').prop('checked') == true && $('#clinic').prop('checked') == true && $('#mobile').prop('checked') == false) {
  //     $('#provider_access_value').val("Hospital and Clinic")
  //   } else if ($('#hospital').prop('checked') == true && $('#clinic').prop('checked') == false && $('#mobile').prop('checked') == true) {
  //     $('#provider_access_value').val("Hospital and Mobile")
  //   } else if ($('#hospital').prop('checked') == true && $('#clinic').prop('checked') == true && $('#mobile').prop('checked') == true) {
  //     $('#provider_access_value').val("Hospital, Clinic and Mobile")
  //   } else if ($('#clinic').prop('checked') == true && $('#hospital').prop('checked') == false && $('#mobile').prop('checked') == false) {
  //     $('#provider_access_value').val("Clinic")
  //   } else if ($('#clinic').prop('checked') == true && $('#mobile').prop('checked') == true && $('#hospital').prop('checked') == false) {
  //     $('#provider_access_value').val("Clinic and Mobile");
  //   } else if ($('#mobile').prop('checked') == true && $('#clinic').prop('checked') == false && $('#hospital').prop('checked') == false) {
  //     $('#provider_access_value').val("Mobile")
  //   } else {
  //     $('#provider_access_value').val("")
  //   }
  // })

  // if ($('#provider_access_value').val() == "Hospital") {
  //   $('#hospital').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Clinic") {
  //   $('#clinic').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Mobile") {
  //   $('#mobile').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Hospital and Clinic") {
  //   $('#hospital').prop('checked', true)
  //   $('#clinic').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Hospital and Mobile") {
  //   $('#hospital').prop('checked', true)
  //   $('#mobile').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Clinic and Mobile") {
  //   $('#clinic').prop('checked', true)
  //   $('#mobile').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Hospital, Clinic and Mobile") {
  //   $('#hospital').prop('checked', true)
  //   $('#clinic').prop('checked', true)
  //   $('#mobile').prop('checked', true)
  // }



  let selected_type = $('#acu_type').find('option:selected').text();
  if (selected_type == "Regular") {
    $('#acu_coverage option[value="Inpatient"]').remove()
    $('.acu_type').removeClass('disabled')
    $('.acu_type').dropdown("set selected", "Outpatient")
    $('#acu_select').removeAttr('disabled')
  } else if (selected_type == "Executive") {
    $('.acu_type').removeClass('disabled')
    $('#acu_select').removeAttr('disabled')
  }

  if($('#acu_type').dropdown("get value") != "") {
    $('.acu_type').removeClass('disabled')
  }

  $('#acu_type').on('change', function() {
    let selected_type = $('#acu_type').find('option:selected').text();
    $('#acu_coverage option[value="Inpatient"]').remove()
    if (selected_type == "Regular") {
      $('#acu_select').dropdown('restore defaults')
      $('.acu_type').removeClass('disabled')
      $('.acu_type').dropdown("set selected", "Outpatient")
      $('#acu_select').removeAttr('disabled')
    } else if (selected_type == "Executive") {
      $('#acu_select').dropdown('restore defaults')
      $("#acu_select").append('<option value="Inpatient">Inpatient</option>')
      $('.acu_type').removeClass('disabled')
      $('#acu_select').removeAttr('disabled')
    }
  })
})

onmount('div[id="editGeneral"]', function() {

  // const csrf = $('input[name="_csrf_token"]').val();
  // const benefit_code = $('input[name="benefit[code]"]').attr("value")

  // $.ajax({
  //   url: `/get_all_benefit_code`,
  //   headers: {
  //     "X-CSRF-TOKEN": csrf
  //   },
  //   type: 'get',
  //   success: function(response) {
  //     const data = JSON.parse(response)
  //     const array = $.map(data, function(value, index) {
  //       return [value.code]
  //     });

  //     if (benefit_code != undefined) {
  //       array.splice($.inArray(benefit_code, array), 1)
  //     }

      // $.fn.form.settings.rules.checkBenefitCode = function(param) {
      //   return array.indexOf(param) == -1 ? true : false
      // }

      $('#edit_riders_submit').on('click', function() {
        $('#edit_riders_form')
          .form({
            inline: true,
            on: 'blur',
            fields: {
              'benefit[code]': {
                identifier: 'benefit[code]',
                rules: [{
                  type: 'empty',
                  prompt: 'Please enter Benefit Code'
                }
                // {
                //   type: 'checkBenefitCode[param]',
                //   prompt: 'Benefit Code already exist!'
                // }
                ]
              },
              'benefit[name]': {
                identifier: 'benefit[name]',
                rules: [{
                  type: 'empty',
                  prompt: 'Please enter benefit name'
                }]
              }
            }
          }), $(this).submit()
      })

      $('#edit_riders_acu_submit').on('click', function() {
        $('#edit_riders_form')
          .form({
            inline: true,
            on: 'blur',
            fields: {
              'benefit[code]': {
                identifier: 'benefit[code]',
                rules: [{
                  type: 'empty',
                  prompt: 'Please enter Benefit Code'
                }
                // {
                //   type: 'checkBenefitCode[param]',
                //   prompt: 'Benefit Code already exist!'
                // }
                ]
              },
              'benefit[name]': {
                identifier: 'benefit[name]',
                rules: [{
                  type: 'empty',
                  prompt: 'Please enter benefit name'
                }]
              },
              'benefit[provider_access]': {
                identifier: 'benefit[provider_access]',
                rules: [{
                  type: 'empty',
                  prompt: 'Please select at least one Provider Type'
                }]
              }
            }
          }), $(this).submit()
      })


      $('#edit_riders_mt_submit').on('click', function() {
        $('#edit_riders_form')
          .form({
            inline: true,
            on: 'blur',
              fields: {
                'benefit[coverage_id]': {
                  identifier: 'benefit[coverage_id]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select Benefit Coverage'
                  }]
                },
                'benefit[code]': {
                  identifier: 'benefit[code]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Code'
                  }
                  // {
                  //   type: 'checkBenefitCode[param]',
                  //   prompt: 'Benefit Code already exist!'
                  // }
                  ]
                },
                'benefit[name]': {
                  identifier: 'benefit[name]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please enter Benefit Name'
                  }]
                },
                'benefit[maternity_type]': {
                  identifier: 'benefit[maternity_type]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select Maternity Type'
                  }]
                },
                'benefit[waiting_period]': {
                  identifier: 'benefit[waiting_period]',
                  rules: [{
                    type: 'checked',
                    prompt: 'Please select Waiting Period'
                  }]
                },
                'benefit[covered_enrollees]': {
                  identifier: 'benefit[covered_enrollees]',
                  rules: [{
                    type: 'empty',
                    prompt: 'Please select Covered Enrollees'
                  }]
                }
              }
          }), $(this).submit()
      })

      $('#edit_health_submit').on('click', function() {
        $('#edit_health_form')
          .form({
            inline: true,
            on: 'blur',
            fields: {
              'benefit[code]': {
                identifier: 'benefit[code]',
                rules: [{
                  type: 'empty',
                  prompt: 'Please enter Benefit Code'
                }
                // {
                //   type: 'checkBenefitCode[param]',
                //   prompt: 'Benefit Code already exist!'
                // }
                ]
              },
              'benefit[name]': {
                identifier: 'benefit[name]',
                rules: [{
                  type: 'empty',
                  prompt: 'Please enter benefit name'
                }]
              }
            }
          }), $(this).submit()
      })
    // },
    // error: function() {
      // console.log("error")
    // }
  // })


  let riders_coverage = $('#riders_coverage :selected').text()
  if (riders_coverage == "Maternity") {
    $("#maternity").removeClass('hidden')
    $("#maternity").addClass('field')
  } else if (riders_coverage == "ACU") {
    $("#acu").removeClass('hidden')
    $("#acu").addClass('three fields')
  }

 let riders_coverage_enrollees = $('#riders_coverage :selected').text()
      if (riders_coverage == "Maternity_enrollees") {
        $("#maternity_enrollees").removeClass('hidden')
        $("#maternity_enrollees").addClass('field')
      } else if (riders_coverage == "ACU") {
        $("#acu").removeClass('hidden')
        $("#acu").addClass('three fields')
      }

      $('#riders_coverage').on('change', function() {
        check_covered_enrollees()
      })

      function check_covered_enrollees() {
        let riders_coverage = $('#riders_coverage :selected').text()
        if (riders_coverage == "Maternity") {
          $('.form2').find('.ui.error.message ul').remove()
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#maternity_enrollees").removeClass('hidden')
          $("#maternity_enrollees").addClass('field')
          $("#acu").removeClass('two fields')
          $("#acu").addClass('hidden')
        } else if (riders_coverage == "ACU") {
          $('.form2').find('.ui.error.message ul').remove();
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#acu").removeClass('hidden')
          $("#acu").addClass('two fields')
          $("#maternity_enrollees").removeClass('field')
          $("#maternity_enrollees").addClass('hidden')
        } else {
          $('.form2').find('.ui.error.message ul').remove();
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#maternity_enrollees").removeClass('field')
          $("#maternity_enrollees").addClass('hidden')
          $("#acu").removeClass('three fields')
          $("#acu").addClass('hidden')
        }
      }

      let radio_button = $('#riders_coverage :selected').text()
      if (riders_coverage == "waiting_period") {
        $("#waiting_period").removeClass('hidden')
        $("#waiting_period").addClass('field')
      } else if (riders_coverage == "ACU") {
        $("#acu").removeClass('hidden')
        $("#acu").addClass('three fields')
      }
      function check_waiting_period() {
        let riders_coverage = $('#riders_coverage :selected').text()
        if (riders_coverage == "Maternity") {
          $('.form2').find('.ui.error.message ul').remove()
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#waiting_period").removeClass('hidden')
          $("#waiting_perion").addClass('field')
          $("#acu").removeClass('two fields')
          $("#acu").addClass('hidden')
        } else if (riders_coverage == "ACU") {
          $('.form2').find('.ui.error.message ul').remove();
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#acu").removeClass('hidden')
          $("#acu").addClass('two fields')
          $("#waiting_period").removeClass('field')
          $("#waiting_perion").addClass('hidden')
        } else {
          $('.form2').find('.ui.error.message ul').remove();
          $('.form2').find('.error').removeClass('error').find('.prompt').remove()
          $("#waiting_period").removeClass('field')
          $("#waiting_period").addClass('hidden')
          $("#acu").removeClass('three fields')
          $("#acu").addClass('hidden')
        }
      }
      $('#riders_coverage').on('change', function() {
        check_waiting_period()
      })


      check_waiting_period()
      check_covered_enrollees()


      $('input[type=checkbox]').on('change', function() {
        if ($('#clinic').prop('checked') == true && $('#hospital').prop('checked') == true && $('#mobile').prop('checked') == true) {
          $('#provider_access_value').val("Clinic and Hospital and Mobile")
        }  else if ($('#clinic').prop('checked') == true && $('#hospital').prop('checked') == true) {
          $('#provider_access_value').val("Clinic and Hospital")
        } else if ($('#hospital').prop('checked') == true && $('#mobile').prop('checked') == true && $('#clinic').prop('checked') == false) {
          $('#provider_access_value').val("Hospital and Mobile")
        } else if ($('#clinic').prop('checked') == true && $('#mobile').prop('checked') == true && $('#hospital').prop('checked') == false) {
          $('#provider_access_value').val("Clinic and Mobile")
        } else if ($('#clinic').prop('checked') == true && $('#hospital').prop('checked') == false && $('#mobile').prop('checked') == false) {
          $('#provider_access_value').val("Clinic")
        } else if ($('#hospital').prop('checked') == true && $('#clinic').prop('checked') == false && $('#mobile').prop('checked') == false) {
          $('#provider_access_value').val("Hospital")
        } else if ($('#mobile').prop('checked') == true && $('#clinic').prop('checked') == false && $('#hospital').prop('checked') == false) {
          $('#provider_access_value').val("Mobile")
        } else {
          $('#provider_access_value').val("")
        }
      })

      if ($('#provider_access_value').val() == "Clinic and Hospital and Mobile") {
        $('#clinic').prop('checked', true)
        $('#hospital').prop('checked', true)
        $('#mobile').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Clinic and Hospital") {
        $('#clinic').prop('checked', true)
        $('#hospital').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Clinic and Mobile") {
        $('#clinic').prop('checked', true)
        $('#mobile').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Hospital and Mobile") {
        $('#hospital').prop('checked', true)
        $('#mobile').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Clinic") {
        $('#clinic').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Hospital") {
        $('#hospital').prop('checked', true)
      } else if ($('#provider_access_value').val() == "Mobile") {
        $('#mobile').prop('checked', true)
      }

  // $('input[type=checkbox]').on('change', function() {
  //   if ($('#hospital').prop('checked') == true && $('#clinic').prop('checked') == false && $('#mobile').prop('checked') == false) {
  //     $('#provider_access_value').val("Hospital")
  //   } else if ($('#hospital').prop('checked') == true && $('#clinic').prop('checked') == true && $('#mobile').prop('checked') == false) {
  //     $('#provider_access_value').val("Hospital and Clinic")
  //   } else if ($('#hospital').prop('checked') == true && $('#clinic').prop('checked') == false && $('#mobile').prop('checked') == true) {
  //     $('#provider_access_value').val("Hospital and Mobile")
  //   } else if ($('#hospital').prop('checked') == true && $('#clinic').prop('checked') == true && $('#mobile').prop('checked') == true) {
  //     $('#provider_access_value').val("Hospital, Clinic and Mobile")
  //   } else if ($('#clinic').prop('checked') == true && $('#hospital').prop('checked') == false && $('#mobile').prop('checked') == false) {
  //     $('#provider_access_value').val("Clinic")
  //   } else if ($('#clinic').prop('checked') == true && $('#mobile').prop('checked') == true && $('#hospital').prop('checked') == false) {
  //     $('#provider_access_value').val("Clinic and Mobile");
  //   } else if ($('#mobile').prop('checked') == true && $('#clinic').prop('checked') == false && $('#hospital').prop('checked') == false) {
  //     $('#provider_access_value').val("Mobile")
  //   } else {
  //     $('#provider_access_value').val("")
  //   }
  // })

  // if ($('#provider_access_value').val() == "Hospital") {
  //   $('#hospital').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Clinic") {
  //   $('#clinic').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Mobile") {
  //   $('#mobile').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Hospital and Clinic") {
  //   $('#hospital').prop('checked', true)
  //   $('#clinic').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Hospital and Mobile") {
  //   $('#hospital').prop('checked', true)
  //   $('#mobile').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Clinic and Mobile") {
  //   $('#clinic').prop('checked', true)
  //   $('#mobile').prop('checked', true)
  // } else if ($('#provider_access_value').val() == "Hospital, Clinic and Mobile") {
  //   $('#hospital').prop('checked', true)
  //   $('#clinic').prop('checked', true)
  //   $('#mobile').prop('checked', true)
  // }

  let selected_type = $('#acu_type').find('option:selected').text();
  if (selected_type == "Regular") {
    $('#acu_coverage option[value="Inpatient"]').remove()
    $('.acu_type').dropdown("set selected", "Outpatient")
  }

  if($('#acu_type').dropdown("get value") != "") {
    $('.acu_type').removeClass('disabled')
  }

  $('#acu_type').on('change', function() {
    let selected_type = $('#acu_type').find('option:selected').text();
    $('#acu_coverage option[value="Inpatient"]').remove()
    if (selected_type == "Regular") {
      $('#acu_select').dropdown('restore defaults')
      $('.acu_type').dropdown("set selected", "Outpatient")
    } else if (selected_type == "Executive") {
      $('#acu_select').dropdown('restore defaults')
      $("#acu_select").append('<option value="Inpatient">Inpatient</option>')
    }
  })
});
