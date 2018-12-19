onmount('div[id="new_fulfillment_card"]', function(){
  $('#cancel_fulfillment').click(function(){
    if (confirm('You have unsaved changes. Are you sure you want to cancel?')) {
      window.location.replace($(this).attr('link_cancel'))
    }
  })
  let card_value = $('#card_value').val()

    check_line_display_value($('#display_line1').val(),'#tspan3783')
    check_line_display_value($('#line2').val(),'#tspan1083')
    check_line_display_value($('#line3').val(),'#tspan1087')
    check_line_display_value($('#line4').val(),'#tspan1091')

  if (card_value == null){
    $('#card_type_label').hide();
    $('#card_type').hide();
    $('#card_display_label').hide();
    $('#card_display').hide();
    card_value = 'EMV'
  }
  else if (card_value == 'EMV') {
    $('#card_type_label').hide();
    $('#card_type').hide();
    $('#card_display_label').hide();
    $('#card_display').hide();
  }
  else if (card_value == 'Digital' || card_value == 'Regular' ) {
    $('#card_type_label').show();
    $('#card_type').show();
    $('#card_display_label').show();
    $('#card_display').show();
  }

  $('#EMV_radio').on('click', function(){
    $('#tspan1079').text('');
    $('#tspan3783').text('');
    $('#tspan1083').text('');
    $('#tspan1087').text('');
    $('#tspan1091').text('');
    $('#card_type_label').hide();
    $('#card_type').hide();
    $('#card_display_label').hide();
    $('#card_display').hide();
    card_value = 'EMV'
    $('div').removeClass('error')
    $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
  })
  $('#Digital_radio').on('click', function(){
    $('#tspan1079').text('Premium Member');
    check_line_display_value($('#display_line1').val(),'#tspan3783')
    check_line_display_value($('#line2').val(),'#tspan1083')
    check_line_display_value($('#line3').val(),'#tspan1087')
    check_line_display_value($('#line4').val(),'#tspan1091')
    $('#card_type_label').show();
    $('#card_type').show();
    $('#card_display_label').show();
    $('#card_display').show();
    card_value = 'Digital'
  })
  $('#Regular_radio').on('click', function(){
    $('#tspan1079').text('Premium Member');
    check_line_display_value($('#display_line1').val(),'#tspan3783')
    check_line_display_value($('#line2').val(),'#tspan1083')
    check_line_display_value($('#line3').val(),'#tspan1087')
    check_line_display_value($('#line4').val(),'#tspan1091')
    $('#card_type_label').show();
    $('#card_type').show();
    $('#card_display_label').show();
    $('#card_display').show();
    card_value = 'Regular'
  })

  function check_line_display_value(id,line){
    switch(id){
      case 'MediLink Number':
        $(line).text('1168 0110 1234 5678');
        break;
      case 'Name of Member':
        $(line).text('Juan Dela Cruz');
        break;
      case 'Account Name':
        $(line).text('ABC Company');
        break;
      case 'Branch Name':
        $(line).text('ABC Company - Cubao');
        break;
      case 'Exclusive Hotline':
        $(line).text('123-4567');
        break;
    }
    if ($('#Premium_radio').attr('class').indexOf('checked') != -1){
      $('#tspan1079').text('Premium Member');
    }
    else if ($('#Platinum_radio').attr('class').indexOf('checked') != -1){
      $('#tspan1079').text('Platinum Member');
    }
    else if ($('#Platinum_Plus_radio').attr('class').indexOf('checked') != -1){
      $('#tspan1079').text('Platinum Plus Member');
    }
    else{
      if ($('#card_type_value').val() == "Premium"){
        $('#tspan1079').text('Premium Member');
      }
      if ($('#card_type_value').val() == "Platinum"){
        $('#tspan1079').text('Platinum Member');
      }
      if ($('#card_type_value').val() == "Platinum Plus"){
        $('#tspan1079').text('Platinum Plus Member');
      }
    }
  }

  $('#submit_fulfillment').on('click', function(){

    let line1 = ""
    let line2 = ""
    let line3 = ""
    let line4 = ""
    let data = ""

    line1 = $('#line1').val()
    line2 = $('#line2').val()
    line3 = $('#line3').val()
    line4 = $('#line4').val()
    let data1 = line2 + line3 + line4
    let data2 = line1 + line3 + line4
    let data3 = line1 + line2 + line4
    let data4 = line1 + line2 + line3
    $.fn.form.settings.rules.checkCarddisplay1 = function(param) {
      return data1.indexOf(param) == -1 ? true : false;
    }
    $.fn.form.settings.rules.checkCarddisplay2 = function(param) {
      return data2.indexOf(param) == -1 ? true : false;
    }
    $.fn.form.settings.rules.checkCarddisplay3 = function(param) {
      return data3.indexOf(param) == -1 ? true : false;
    }
    $.fn.form.settings.rules.checkCarddisplay4 = function(param) {
      return data4.indexOf(param) == -1 ? true : false;
    }



    if (card_value == 'EMV')
      {
        $('#new_card')
        .form({
          on: blur,
          inline: true,
          fields: {
            'fulfillment_card[product_code_name]': {
              identifier: 'fulfillment_card[product_code_name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter Plan Code/Name'
                }
              ]
            },
            'fulfillment_card[transmittal_listing]': {
              identifier: 'fulfillment_card[transmittal_listing]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please Select Transmittal Listing'
                }
              ]
            },
            'fulfillment_card[packaging_style]': {
              identifier: 'fulfillment_card[packaging_style]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'please select packaging style'
                }
              ]
            }
          }
        })
      }
      else if(card_value == 'Digital' || card_value == 'Regular')
        {
          $('#new_card')
          .form({
            on: blur,
            inline: true,
            fields: {
              'fulfillment_card[product_code_name]': {
                identifier: 'fulfillment_card[product_code_name]',
                rules: [
                  {
                    type: 'empty',
                    prompt: 'Please enter Plan Code/Name'
                  }
                ]
              },
            'fulfillment_card[transmittal_listing]': {
              identifier: 'fulfillment_card[transmittal_listing]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please Select Transmittal Listing'
                }
              ]
            },
            'fulfillment_card[packaging_style]': {
              identifier: 'fulfillment_card[packaging_style]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'please select packaging style'
                }
              ]
            },
              'fulfillment_card[card_display_line1]': {
                identifier: 'fulfillment_card[card_display_line1]',
                rules: [
                  {
                    type: 'empty',
                    prompt: 'Please select display'
                  },
                  {
                    type: 'checkCarddisplay1[param]',
                    prompt: 'Please change display'
                  }
                ]
              },
              'fulfillment_card[card_display_line2]': {
                identifier: 'fulfillment_card[card_display_line2]',
                rules: [
                  {
                    type: 'empty',
                    prompt: 'Please select display'
                  },
                  {
                    type: 'checkCarddisplay2[param]',
                    prompt: 'Please change display'
                  }
                ]
              },
              'fulfillment_card[card_display_line3]': {
                identifier: 'fulfillment_card[card_display_line3]',
                rules: [
                  {
                    type: 'empty',
                    prompt: 'Please select display'
                  },
                  {
                    type: 'checkCarddisplay3[param]',
                    prompt: 'Please change display'
                  }
                ]
              },
              'fulfillment_card[card_display_line4]': {
                identifier: 'fulfillment_card[card_display_line4]',
                rules: [
                  {
                    type: 'empty',
                    prompt: 'Please select display'
                  },
                  {
                    type: 'checkCarddisplay4[param]',
                    prompt: 'Please change display'
                  }
                ]
              }
            }
          })
        }

  })

  $('#Premium_radio').click(function() {
    $('#tspan1079').text('Premium Member');
  })
  $('#Platinum_radio').click(function() {
    $('#tspan1079').text('Platinum Member');
  })
  $('#Platinum_Plus_radio').click(function() {
    $('#tspan1079').text('Platinum Plus Member');
  })

  $('select[name="fulfillment_card[card_display_line1]"]').change(function(){
    switch($(this).val()) {
      case 'MediLink Number':
        $('#tspan3783').text('1168 0110 1234 5678');
        break;
      case 'Name of Member':
        $('#tspan3783').text('Juan Dela Cruz');
        break;
      case 'Account Name':
        $('#tspan3783').text('ABC Company');
        break;
      case 'Branch Name':
        $('#tspan3783').text('ABC Company - Cubao');
        break;
      case 'Exclusive Hotline':
        $('#tspan3783').text('123-4567');
        break;
    }
  })
  $('select[name="fulfillment_card[card_display_line2]"]').change(function(){
    switch($(this).val()) {
      case 'MediLink Number':
        $('#tspan1083').text('1168 0110 1234 5678');
        break;
      case 'Name of Member':
        $('#tspan1083').text('Juan Dela Cruz');
        break;
      case 'Account Name':
        $('#tspan1083').text('ABC Company');
        break;
      case 'Branch Name':
        $('#tspan1083').text('ABC Company - Cubao');
        break;
      case 'Exclusive Hotline':
        $('#tspan1083').text('123-4567');
        break;
    }
  })
  $('select[name="fulfillment_card[card_display_line3]"]').change(function(){
    switch($(this).val()) {
      case 'MediLink Number':
        $('#tspan1087').text('1168 0110 1234 5678');
        break;
      case 'Name of Member':
        $('#tspan1087').text('Juan Dela Cruz');
        break;
      case 'Account Name':
        $('#tspan1087').text('ABC Company');
        break;
      case 'Branch Name':
        $('#tspan1087').text('ABC Company - Cubao');
        break;
      case 'Exclusive Hotline':
        $('#tspan1087').text('123-4567');
        break;
    }
  })
  $('select[name="fulfillment_card[card_display_line4]"]').change(function(){
    switch($(this).val()) {
      case 'MediLink Number':
        $('#tspan1091').text('1168 0110 1234 5678');
        break;
      case 'Name of Member':
        $('#tspan1091').text('Juan Dela Cruz');
        break;
      case 'Account Name':
        $('#tspan1091').text('ABC Company');
        break;
      case 'Branch Name':
        $('#tspan1091').text('ABC Company - Cubao');
        break;
      case 'Exclusive Hotline':
        $('#tspan1091').text('123-4567');
        break;
    }
  })

  $('#submit_edit_fulfillment').on('click', function(){

    let line1 = ""
    let line2 = ""
    let line3 = ""
    let line4 = ""
    let data = ""

    line1 = $('#line1').val()
    line2 = $('#line2').val()
    line3 = $('#line3').val()
    line4 = $('#line4').val()
    let data1 = line2 + line3 + line4
    let data2 = line1 + line3 + line4
    let data3 = line1 + line2 + line4
    let data4 = line1 + line2 + line3
    $.fn.form.settings.rules.checkCarddisplay1 = function(param) {
      return data1.indexOf(param) == -1 ? true : false;
    }
    $.fn.form.settings.rules.checkCarddisplay2 = function(param) {
      return data2.indexOf(param) == -1 ? true : false;
    }
    $.fn.form.settings.rules.checkCarddisplay3 = function(param) {
      return data3.indexOf(param) == -1 ? true : false;
    }
    $.fn.form.settings.rules.checkCarddisplay4 = function(param) {
      return data4.indexOf(param) == -1 ? true : false;
    }

    if (card_value == 'EMV')
      {
        $('#new_card')
        .form({
          on: blur,
          inline: true,
          fields: {
            'fulfillment_card[product_code_name]': {
              identifier: 'fulfillment_card[product_code_name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please enter Plan Code/Name'
                }
              ]
            },
            'fulfillment_card[transmittal_listing]': {
              identifier: 'fulfillment_card[transmittal_listing]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please Select Transmittal Listing'
                }
              ]
            },
            'fulfillment_card[packaging_style]': {
              identifier: 'fulfillment_card[packaging_style]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'please select packaging style'
                }
              ]
            }
          }
        })
      }
      else if(card_value == 'Digital' || card_value == 'Regular')
        {
          $('#new_card')
          .form({
            on: blur,
            inline: true,
            fields: {
              'fulfillment_card[product_code_name]': {
                identifier: 'fulfillment_card[product_code_name]',
                rules: [
                  {
                    type: 'empty',
                    prompt: 'Please enter Plan Code/Name'
                  }
                ]
              },
            'fulfillment_card[transmittal_listing]': {
              identifier: 'fulfillment_card[transmittal_listing]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Please Select Transmittal Listing'
                }
              ]
            },
            'fulfillment_card[packaging_style]': {
              identifier: 'fulfillment_card[packaging_style]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'please select packaging style'
                }
              ]
            },
              'fulfillment_card[card_display_line1]': {
                identifier: 'fulfillment_card[card_display_line1]',
                rules: [
                  {
                    type: 'empty',
                    prompt: 'Please select display'
                  },
                  {
                    type: 'checkCarddisplay1[param]',
                    prompt: 'Please change display'
                  }
                ]
              },
              'fulfillment_card[card_display_line2]': {
                identifier: 'fulfillment_card[card_display_line2]',
                rules: [
                  {
                    type: 'empty',
                    prompt: 'Please select display'
                  },
                  {
                    type: 'checkCarddisplay2[param]',
                    prompt: 'Please change display'
                  }
                ]
              },
              'fulfillment_card[card_display_line3]': {
                identifier: 'fulfillment_card[card_display_line3]',
                rules: [
                  {
                    type: 'empty',
                    prompt: 'Please select display'
                  },
                  {
                    type: 'checkCarddisplay3[param]',
                    prompt: 'Please change display'
                  }
                ]
              },
              'fulfillment_card[card_display_line4]': {
                identifier: 'fulfillment_card[card_display_line4]',
                rules: [
                  {
                    type: 'empty',
                    prompt: 'Please select display'
                  },
                  {
                    type: 'checkCarddisplay4[param]',
                    prompt: 'Please change display'
                  }
                ]
              }
            }
          })
        }
  })

});

onmount('div[id="new_fulfillment_card"]', function(){

  $('#remove_fulfillment').on('click', function(){
    let account_id = $(this).attr('accountID')
    let fulfillment_id = $(this).attr('fulfillmentID')
    console.log(account_id)
    swal({
		  title: 'Remove Fulfillment Card',
		  text: "Are you sure you want to remove this Fulfillment Card?",
		  type: 'question',
		  showCancelButton: true,
		  confirmButtonText: '<i class="send icon"></i> Remove',
		  cancelButtonText: '<i class="remove icon"></i> Cancel',
		  confirmButtonClass: 'ui blue button',
		  cancelButtonClass: 'ui button',
		  buttonsStyling: false
    }).then(function () {
      window.location.replace(`/accounts/${account_id}/card/${fulfillment_id}/delete`);
		})
  })
})

onmount('div[id="new_fulfillment_document"]', function(){

  function alert_error_file(){
    alertify.error('<i id="notification_error" class="close icon"></i><p>Invalid file type. Valid file types are PDF, JPG, JPEG, SVG, GIF, and PNG.</p>');
    alertify.defaults = {
        notifier:{
            delay:5,
            position:'top-right',
            closeButton: false
        }
    };
  }

  function alert_error_size(){
    alertify.error('<i id="notification_error" class="close icon"></i><p>Invalid File Upload you reach maximum size</p>');
    alertify.defaults = {
        notifier:{
            delay:5,
            position:'top-right',
            closeButton: false
        }
    };
  }

  function check_file_name_if_pdf_or_image(pdffile){
    if ((pdffile.name).indexOf('.pdf') >= 0 ||
        (pdffile.name).indexOf('.png') >= 0 ||
        (pdffile.name).indexOf('.jpg') >= 0 ||
        (pdffile.name).indexOf('.jpeg') >= 0 ||
        (pdffile.name).indexOf('.svg') >= 0 ||
        (pdffile.name).indexOf('.gif') >= 0){
      return true
    }else{
      return false
    }
  }




  $('#letter_upload').on('change', function(event){
    let pdffile = event.target.files[0];
    if (pdffile != undefined)
      {
        if(check_file_name_if_pdf_or_image(pdffile))
          {
            if(pdffile.size <= 8000000)
              {
                pdffile = (window.URL || window.webkitURL).createObjectURL(pdffile)
                $('#preview_letter').attr('href', pdffile);
              }
              else
                {
                  $(this).val('')
                  $('#preview_letter').removeAttr('href');
                  alert_error_size()
                }
          }
          else
            {
            if(pdffile.size <= 8000000)
              {
              let filename = pdffile.name
              var blob = new Blob([pdffile]);
              var url  = URL.createObjectURL(blob);
              $('#preview_letter').attr({ 'download': filename, 'href': url});
              }
              else
                {
                  $(this).val('')
                  $('#preview_letter').removeAttr('href');
                  alert_error_size()
                }
              $(this).val('')
              $('#preview_letter').removeAttr('href');
              alert_error_file()
            }
      }
      else
        {
          $(this).val('')
          $('#preview_letter').removeAttr('href');
        }
  })


  $('#brochure_upload').on('change', function(event){
    let pdffile = event.target.files[0];
    if (pdffile != undefined)
      {
        if(check_file_name_if_pdf_or_image(pdffile))
          {
            if(pdffile.size <= 8000000)
              {
                pdffile = (window.URL || window.webkitURL).createObjectURL(pdffile)
                $('#preview_brochure').attr('href', pdffile);
              }
              else
                {
                  $(this).val('')
                  $('#preview_brochure').removeAttr('href');
                  alert_error_size()
                }
          }
          else
            {
            if(pdffile.size <= 8000000)
              {
              let filename = pdffile.name
              var blob = new Blob([pdffile]);
              var url  = URL.createObjectURL(blob);
              $('#preview_brochure').attr({ 'download': filename, 'href': url});
              }
              else
                {
                  $(this).val('')
                  $('#preview_brochure').removeAttr('href');
                  alert_error_size()
                }
              $(this).val('')
              $('#preview_brochure').removeAttr('href');
              alert_error_file()
            }
      }
      else
        {
          $(this).val('')
          $('#preview_brochure').removeAttr('href');
        }
  })

  $('#booklet_upload').on('change', function(event){
    let pdffile = event.target.files[0];
    if (pdffile != undefined)
      {
        if(check_file_name_if_pdf_or_image(pdffile))
          {
            if(pdffile.size <= 8000000)
              {
                pdffile = (window.URL || window.webkitURL).createObjectURL(pdffile)
                $('#preview_booklet').attr('href', pdffile);
              }
              else
                {
                  $(this).val('')
                  $('#preview_booklet').removeAttr('href');
                  alert_error_size()
                }
          }
          else
            {
            if(pdffile.size <= 8000000)
              {
              let filename = pdffile.name
              var blob = new Blob([pdffile]);
              var url  = URL.createObjectURL(blob);
              $('#preview_booklet').attr({ 'download': filename, 'href': url});
              }
              else
                {
                  $(this).val('')
                  $('#preview_booklet').removeAttr('href');
                  alert_error_size()
                }
              $(this).val('')
              $('#preview_booklet').removeAttr('href');
              alert_error_file()
            }
      }
      else
        {
          $(this).val('')
          $('#preview_booklet').removeAttr('href');
        }
  })

 $('#summary_coverage_upload').on('change', function(event){
    let pdffile = event.target.files[0];
    if (pdffile != undefined)
      {
        if(check_file_name_if_pdf_or_image(pdffile))
          {
            if(pdffile.size <= 8000000)
              {
                pdffile = (window.URL || window.webkitURL).createObjectURL(pdffile)
                $('#preview_summary_coverage').attr('href', pdffile);
              }
              else
                {
                  $(this).val('')
                  $('#preview_summary_coverage').removeAttr('href');
                  alert_error_size()
                }
          }
          else
            {
            if(pdffile.size <= 8000000)
              {
              let filename = pdffile.name
              var blob = new Blob([pdffile]);
              var url  = URL.createObjectURL(blob);
              $('#preview_summary_coverage').attr({ 'download': filename, 'href': url});
              }
              else
                {
                  $(this).val('')
                  $('#preview_summary_coverage').removeAttr('href');
                  alert_error_size()
                }
              $(this).val('')
              $('#preview_summary_coverage').removeAttr('href');
              alert_error_file()
            }
      }
      else
        {
          $(this).val('')
          $('#preview_summary_coverage').removeAttr('href');
        }
  })

 $('#envelope_upload').on('change', function(event){
    let pdffile = event.target.files[0];
    if (pdffile != undefined)
      {
        if(check_file_name_if_pdf_or_image(pdffile))
          {
            if(pdffile.size <= 8000000)
              {
                pdffile = (window.URL || window.webkitURL).createObjectURL(pdffile)
                $('#preview_envelope').attr('href', pdffile);
              }
              else
                {
                  $(this).val('')
                  $('#preview_envelope').removeAttr('href');
                  alert_error_size()
                }
          }
          else
            {
            if(pdffile.size <= 8000000)
              {
              let filename = pdffile.name
              var blob = new Blob([pdffile]);
              var url  = URL.createObjectURL(blob);
              $('#preview_envelope').attr({ 'download': filename, 'href': url});
              }
              else
                {
                  $(this).val('')
                  $('#preview_envelope').removeAttr('href');
                  alert_error_size()
                }
              $(this).val('')
              $('#preview_envelope').removeAttr('href');
              alert_error_file()
            }
      }
      else
        {
          $(this).val('')
          $('#preview_envelope').removeAttr('href');
        }
  })

 $('#rlpm_upload').on('change', function(event){
   let pdffile = event.target.files[0];
    if (pdffile != undefined)
      {
        if(check_file_name_if_pdf_or_image(pdffile))
          {
            if(pdffile.size <= 8000000)
              {
                pdffile = (window.URL || window.webkitURL).createObjectURL(pdffile)
                $('#preview_rlpm').attr('href', pdffile);
              }
              else
                {
                  $(this).val('')
                  $('#preview_rlpm').removeAttr('href');
                  alert_error_size()
                }
          }
          else
            {
            if(pdffile.size <= 8000000)
              {
              let filename = pdffile.name
              var blob = new Blob([pdffile]);
              var url  = URL.createObjectURL(blob);
              $('#preview_rlpm').attr({ 'download': filename, 'href': url});
              }
              else
                {
                  $(this).val('')
                  $('#preview_rlpm').removeAttr('href');
                  alert_error_size()
                }
              $(this).val('')
              $('#preview_rlpm').removeAttr('href');
              alert_error_file()
            }
      }
      else
        {
          $(this).val('')
          $('#preview_rlpm').removeAttr('href');
        }
  })

  $('#rcd_upload').on('change', function(event){
    let pdffile = event.target.files[0];
    if (pdffile != undefined)
      {
        if(check_file_name_if_pdf_or_image(pdffile))
          {
            if(pdffile.size <= 8000000)
              {
                pdffile = (window.URL || window.webkitURL).createObjectURL(pdffile)
                $('#preview_rcd').attr('href', pdffile);
              }
              else
                {
                  $(this).val('')
                  $('#preview_rcd').removeAttr('href');
                  alert_error_size()
                }
          }
          else
            {
            if(pdffile.size <= 8000000)
              {
              let filename = pdffile.name
              var blob = new Blob([pdffile]);
              var url  = URL.createObjectURL(blob);
              $('#preview_rcd').attr({ 'download': filename, 'href': url});
              }
              else
                {
                  $(this).val('')
                  $('#preview_rcd').removeAttr('href');
                  alert_error_size()
                }
              $(this).val('')
              $('#preview_rcd').removeAttr('href');
              alert_error_file()
            }
      }
      else
        {
          $(this).val('')
          $('#preview_rcd').removeAttr('href');
        }
  })

  $('#llpm_upload').on('change', function(event){
    let pdffile = event.target.files[0];
    if (pdffile != undefined)
      {
        if(check_file_name_if_pdf_or_image(pdffile))
          {
            if(pdffile.size <= 8000000)
              {
                pdffile = (window.URL || window.webkitURL).createObjectURL(pdffile)
                $('#preview_llpm').attr('href', pdffile);
              }
              else
                {
                  $(this).val('')
                  $('#preview_llpm').removeAttr('href');
                  alert_error_size()
                }
          }
          else
            {
            if(pdffile.size <= 8000000)
              {
              let filename = pdffile.name
              var blob = new Blob([pdffile]);
              var url  = URL.createObjectURL(blob);
              $('#preview_llpm').attr({ 'download': filename, 'href': url});
              }
              else
                {
                  $(this).val('')
                  $('#preview_llpm').removeAttr('href');
                  alert_error_size()
                }
              $(this).val('')
              $('#preview_llpm').removeAttr('href');
              alert_error_file()
            }
      }
      else
        {
          $(this).val('')
          $('#preview_llpm').removeAttr('href');
        }
  })

  $('#lcd_upload').on('change', function(event){
    let pdffile = event.target.files[0];
    if (pdffile != undefined)
      {
        if(check_file_name_if_pdf_or_image(pdffile))
          {
            if(pdffile.size <= 8000000)
              {
                pdffile = (window.URL || window.webkitURL).createObjectURL(pdffile)
                $('#preview_lcd').attr('href', pdffile);
              }
              else
                {
                  $(this).val('')
                  $('#preview_lcd').removeAttr('href');
                  alert_error_size()
                }
          }
          else
            {
            if(pdffile.size <= 8000000)
              {
              let filename = pdffile.name
              var blob = new Blob([pdffile]);
              var url  = URL.createObjectURL(blob);
              $('#preview_lcd').attr({ 'download': filename, 'href': url});
              }
              else
                {
                  $(this).val('')
                  $('#preview_lcd').removeAttr('href');
                  alert_error_size()
                }
              $(this).val('')
              $('#preview_lcd').removeAttr('href');
              alert_error_file()
            }
      }
      else
        {
          $(this).val('')
          $('#preview_lcd').removeAttr('href');
        }
  })


  $('#new_document')
      .form({
        on: blur,
        inline: true,
        fields: {
          'fulfillment_card[no_years_after_issuance]': {
            identifier: 'fulfillment_card[no_years_after_issuance]',
            rules: [
              {
                type: 'empty',
                prompt: 'No. of Years After Issuance'
              }
            ]
          }
        }
      })

})

onmount('div[id="fulfillment_card_index"]', function(){

  let copy_link = ''
  let fulfillment_id
  let account_id
  $('.view_fulfillment').on('click', function(){
    let fulfillment_card = $(this).attr('fulfillment_card');
    if (fulfillment_card != 'EMV') {
    check_line_display_value($(this).attr('line1'),'#tspan3783')
    check_line_display_value($(this).attr('line2'),'#tspan1083')
    check_line_display_value($(this).attr('line3'),'#tspan1087')
    check_line_display_value($(this).attr('line4'),'#tspan1091')
    if ($(this).attr('card_type') == "Premium"){
      $('#fulfillment_view').find('#tspan1079').text('Premium Member');
    }
    if ($(this).attr('card_type') == "Platinum"){
        $('#fulfillment_view').find('#tspan1079').text('Platinum Member');
    }
    if ($(this).attr('card_type') == "Platinum Plus"){
        $('#fulfillment_view').find('#tspan1079').text('Platinum Plus Member');
    }
    }
    let photo_url = $(this).attr('photo_fulfillment')
    console.log(photo_url)
    $('#photo_modal').attr('src',photo_url)
    let transmittal_listing = $(this).attr('transmittal_listing');
    let packaging_style = $(this).attr('packaging_style');
    let code_name = $(this).attr('code_name');
    fulfillment_id = $(this).attr('fulfillment_id');
    account_id = $(this).attr('account_id');
      $('#product_code_name').text(code_name)
      $('#fulfillment_card').text(fulfillment_card)
      $('#fulfillment_transmittal_listing').text(transmittal_listing)
      $('#fulfillment_packaging_style').text(packaging_style)
      //$('#fulfillment_id_card').text(fulfillment_id)

      let edit_link = ''
      if (copy_link == ''){
        edit_link = $('#edit_fulfillment').attr('href');
        copy_link = edit_link
      }
      else
        {
          edit_link = copy_link
      }
      let link = edit_link + fulfillment_id + '/edit_card'
      $('#edit_fulfillment').attr('href', link)

      // const csrf = $('input[name="_csrf_token"]').val();
      //$.ajax({
      //url:`/fulfillments/${fulfillment_id}/get_photo`,
      //headers: {"X-CSRF-TOKEN": csrf},
      //type: 'get',
      //success: function(response){
      // const data =  JSON.parse(response)
      //  value = <%= Innerpeace.PayorLink.Web.LayoutView.image_url_for(Innerpeace.ImageUploader, data.photo,  data, :original)%>

      //},
      //   })
       const csrf = $('input[name="_csrf_token"]').val();
      $.ajax({
      url:`/fulfillments/${fulfillment_id}/get_fulfillment_files`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let name_of_file = []
        let letter_id
        let letter_name
        let brochure_id
        let brochure_name
        let booklet_id
        let booklet_name
        let summary_coverage_id
        let summary_coverage_name
        let envelope_id
        let envelope_name
        let replace_letter_pin_mailer_id
        let replace_letter_pin_mailer_name
        let replace_card_details_id
        let replace_card_details_name
        let lost_letter_pin_mailer_id
        let lost_letter_pin_mailer_name
        let lost_card_details_id
        let lost_card_details_name
        for (let data of response){
          if (data.name == 'file_letter'){
            letter_id = data.link
            letter_name = data.file_name
          }
          if (data.name == 'file_brochure'){
            brochure_id = data.link
            brochure_name = data.file_name
          }
          if (data.name == 'file_booklet'){
            booklet_id = data.link
            booklet_name = data.file_name
          }
          if (data.name == 'file_summary_coverage'){
            summary_coverage_id = data.link
            summary_coverage_name = data.file_name
          }
          if (data.name == 'file_envelope'){
            envelope_id = data.link
            envelope_name = data.file_name
          }
          if (data.name == 'file_replace_letter_pin_mailer'){
            replace_letter_pin_mailer_id = data.link
            replace_letter_pin_mailer_name = data.file_name
          }
          if (data.name == 'file_replace_card_details'){
            replace_card_details_id = data.link
            replace_card_details_name = data.file_name
          }
          if (data.name == 'file_lost_letter_pin_mailer'){
            lost_letter_pin_mailer_id = data.link
            lost_letter_pin_mailer_name = data.file_name
          }
          if (data.name == 'file_lost_card_details'){
            lost_card_details_id = data.link
            lost_card_details_name = data.file_name
          }
        }
        for (let data of response){
          name_of_file.push(data.name)
        }
        console.log(response)
        if(name_of_file.indexOf('file_letter') >= 0 || name_of_file.indexOf('file_brochure') >= 0 || name_of_file.indexOf('file_booklet') >= 0 || name_of_file.indexOf('file_summary_coverge') >= 0 || name_of_file.indexOf('file_envelope') >= 0) {
        $('#label_kit').attr('style', 'display: block;')
        if(name_of_file.indexOf('file_letter') >= 0)
          {
            $('#letter_link').attr('href', letter_id)
            $('#letter').attr('style', 'display: block;')
          }
        if(name_of_file.indexOf('file_brochure') >= 0)
          {
            $('#brochure_link').attr('href', brochure_id)
            $('#brochure').attr('style', 'display: block;')
          }
        if(name_of_file.indexOf('file_booklet') >= 0)
          {
            $('#booklet_link').attr('href', booklet_id)
            $('#booklet').attr('style', 'display: block;')
          }
        if(name_of_file.indexOf('file_summary_coverage') >= 0)
          {
            $('#summary_coverage_link').attr('href', summary_coverage_id)
            $('#summary_coverage').attr('style', 'display: block;')
          }
        if(name_of_file.indexOf('file_envelope') >= 0)
          {
            $('#envelope_link').attr('href', envelope_id)
            $('#envelope').attr('style', 'display: block;')
          }
      }
      if (name_of_file.indexOf('file_replace_letter_pin_mailer') >= 0 || name_of_file.indexOf('file_replace_card_details') >= 0)
        {
          $('#label_replacement').attr('style', 'display: block;')
        if(name_of_file.indexOf('file_replace_letter_pin_mailer') >= 0)
          {
            $('#replace_letter_pin_mailer_link').attr('href', replace_letter_pin_mailer_id)
            $('#replace_letter_pin_mailer').attr('style', 'display: block;')
          }
        if(name_of_file.indexOf('file_replace_card_details') >= 0)
          {
            $('#replace_card_details_link').attr('href', replace_card_details_id)
            $('#replace_card_details').attr('style', 'display: block;')
          }
        }
      if (name_of_file.indexOf('file_lost_letter_pin_mailer') >= 0 || name_of_file.indexOf('file_lost_card_details') >= 0)
        {
          $('#label_lost').attr('style', 'display: block;')
        if(name_of_file.indexOf('file_lost_letter_pin_mailer') >= 0)
          {
            $('#lost_letter_pin_mailer_link').attr('href', lost_letter_pin_mailer_id)
            $('#lost_letter_pin_mailer').attr('style', 'display: block;')
          }
        if(name_of_file.indexOf('file_lost_card_details') >= 0)
          {
            $('#lost_card_details_link').attr('href', lost_card_details_id)
            $('#lost_card_details').attr('style', 'display: block;')
          }
        }

    $('#fulfillment_view').modal({
      closable: false,
      autofocus: false,
      observeChanges: true,
      onHide: function() {
        $('#label_kit').attr('style', 'display: none;')
        $('#label_replacement').attr('style', 'display: none;')
        $('#label_lost').attr('style', 'display: none;')
        $('#letter').attr('style', 'display: none;')
        $('#brochure').attr('style', 'display: none;')
        $('#booklet').attr('style', 'display: none;')
        $('#summary_coverage').attr('style', 'display: none;')
        $('#envelope').attr('style', 'display: none;')
        $('#replace_letter_pin_mailer').attr('style', 'display: none;')
        $('#replace_card_details').attr('style', 'display: none;')
        $('#lost_letter_pin_mailer').attr('style', 'display: none;')
        $('#lost_card_details').attr('style', 'display: none;')

      }
    }).modal('show')

      },
         })
  function check_line_display_value(id,line){
    switch(id){
      case 'MediLink Number':
        $('#fulfillment_view').find(line).text('1168 0110 1234 5678');
        break;
      case 'Name of Member':
        $('#fulfillment_view').find(line).text('Juan Dela Cruz');
        break;
      case 'Account Name':
        $('#fulfillment_view').find(line).text('ABC Company');
        break;
      case 'Branch Name':
        $('#fulfillment_view').find(line).text('ABC Company - Cubao');
        break;
      case 'Exclusive Hotline':
        $('#fulfillment_view').find(line).text('123-4567');
        break;
    }
  }
  })

 $('#remove_fulfillment').on('click', function(){
		swal({
		  title: 'Remove Fulfillment Card',
		  text: "Are you sure you want to remove this Fulfillment Card?",
		  type: 'question',
		  showCancelButton: true,
		  confirmButtonText: '<i class="send icon"></i> Remove',
		  cancelButtonText: '<i class="remove icon"></i> Cancel',
		  confirmButtonClass: 'ui blue button',
		  cancelButtonClass: 'ui button',
		  buttonsStyling: false
    }).then(function () {
      window.location.replace(`/accounts/${account_id}/card/${fulfillment_id}/delete`);
		})
 })



});

onmount('input[id="imageUploadCard"]', function(){

  $('#imageLabel').click(function(){
    $('#imageUploadCard').click()
  })

 $('#imageUploadCard').change(function(e) {
    var photo = document.getElementById('photo');
    photoPreview(photo, '290px', '300px');
  });

 $('#uploadPhoto').change(function(e) {
    var photo = document.getElementById('photo');
    photoPreview(photo, '290px', '300px');
  });

 const photoPreview = (element, width, height) => {
    element.src = URL.createObjectURL(event.target.files[0]);
    //element.style.width = width;
    //element.style.height = height;
  }

  $('a[role="remove"]').on('click', function(e){
    $('#photo').attr("src", "/images/file-upload.png")
    $('#imageUploadCard').val("");

    let account_group_id = $('#photo').attr('accountGroupID');
    let account_id = $('#photo').attr('accountID');

    if(account_group_id != undefined){
      let csrf = $('input[name="_csrf_token"]').val();

      $.ajax({
        url:`/accounts/${account_group_id}/remove_photo`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'delete',
        success: function(response){
          location.reload()
        },
        error: function() {
          location.reload()
        },
      });
    }

    let fulfillment_id = $('#imageUploadCard').attr('fulfillmentID');
    let fulfillment_account_id = $('#imageUploadCard').attr('fulfillmentaccountID')
    let card = $('#imageUploadCard').attr('card')
    if(fulfillment_id != undefined){
      let csrf = $('input[name="_csrf_token"]').val();

      $.ajax({
        url:`/fulfillments/${fulfillment_id}/remove_photo`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        success: function(response){
          if (card == "2"){
            window.location.href=`/accounts/${fulfillment_account_id}/card/${fulfillment_id}/edit_card`;
          }
          else if (card == "1")
            {
              window.location.href=`/accounts/${fulfillment_account_id}/card/${fulfillment_id}/new_edit_card`;
            }
        },
        error: function() {
          if (card == "2"){
          window.location.href=`/accounts/${fulfillment_account_id}/card/${fulfillment_id}/edit_card`;
          }
          else if (card == "1")
            {
              window.location.href=`/accounts/${fulfillment_account_id}/card/${fulfillment_id}/new_edit_card`;
            }
        },
      });
    }
  });
});
