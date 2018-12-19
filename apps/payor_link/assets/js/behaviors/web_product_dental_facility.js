onmount('div[id="product_dental_step"]', function () {

  var datatable_fa = $(`#dentl_fa_tbl`).DataTable()
  // var datatable_lt = $(`#dentl_lt_tbl`).DataTable()

  var datatable_fa_checker = datatable_fa.rows().count()
  // var datatable_lt_checker = datatable_lt.rows().count()
  let x = $('#product_dental_group_type').val()

  if (datatable_fa_checker > 0 || x != "") {
    $('#btnAddRiskShare').removeClass('disabled')
  } else if (datatable_fa_checker == 0 || x == "")  {
    $('#btnAddRiskShare').addClass('disabled')
  }

  if($('input[value="Specific Facilities"]').is(':checked')){
    $('#product_dental_group_type').prop('disabled', true)
    $('#text-dental-type').text("Included Dental Facilities")
    append_facility_inclusion()
  }
  else if ($('input[value="All Affiliated Facilities"]').is(':checked')){
    $('#product_dental_group_type').prop('disabled', true)
    $('#text-dental-type').text("Excluded Dental Facilities")
    append_facility_exception()
  }
  else {
    $('#product_dental_group_type').prop('disabled', false)
  }

  const maskDecimal = new Inputmask("decimal", {
    allowMinus: false,
    // min: 1,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    removeMaskOnSubmit: true
  })

  const maskPercentage = new Inputmask("numeric", {
    max: 100,
    allowMinus: false,
    rightAlign: false
  })

  const maskDecimalCoi = new Inputmask("decimal", {
    allowMinus: false,
    // min: 1,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    max: 100,
    removeMaskOnSubmit: true
  })

  const get_selected_facilities = (coverage, type) => {
    let selected_ids = []

    $(`.selected_${coverage}_${type}_id`).each(function() {
      selected_ids.push($(this).text())
    })

    return selected_ids
  }

  const get_provider_access = provider_access => {
    return (provider_access == undefined) ? '' : provider_access
  }

  const initialize_lt_validation = () => {
    $('#limit-threshold-form').form({
      on: 'blur',
      inline: true,
      fields: {
        'limit-threshold-facility': {
          identifier: 'limit-threshold-facility',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a limit threshold facility.'
          }]
        },
        'limit-threshold-value': {
          identifier: 'limit-threshold-value',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a value.'
          }, {
            type: 'checkOuterLimit[param]',
            prompt: 'Inner limit is equal to outer limit.'
          }]
        }
      }
    })
  }

  $('#add_risk_share_setup').unbind('click').click(() => {
   let key = true
   let csrf = $('input[name="_csrf_token"]').val();
   $('#risk_share_setup_form').form({
     on: 'blur',
     inline: true,
     fields: {
       'product[facility_dropdown_rss]': {
         identifier: 'product[facility_dropdown_rss]',
         rules: [{
           type: 'empty',
           prompt: 'Please select Facility.'
         }]
       },
       'product[facility_risk_share_type]': {
         identifier: 'product[facility_risk_share_type]',
         rules: [{
           type: 'empty'
         }]
       }
     }
   });

    if(!$('div[id="copay_radio_rss"]').hasClass('checked') && !$('div[id="coinsurance_radio_rss"]').hasClass('checked')){
      key = false
      $('div[id="error_div"]').remove()
      $('#copay_radio_rss').find("label").css({"color":"#9F3A38","border-color":"#DB2828"})
      $('#coinsurance_radio_rss').find("label").css({"color":"#9F3A38","border-color":"#DB2828"})
      $('div[id="radio"]').append("<div id='error_div' style='background-color:#FFF6F6; color:#9F3A38'><p>Please select special risk share type</p></div>")
    } else {
      key = true
      $('div[id="error_div"]').remove()
      $('#copay_radio_rss').find("label").css({"color":"#000000","border-color":"#FFFFFF"})
      $('#coinsurance_radio_rss').find("label").css({"color":"#000000","border-color":"#FFFFFF "})
    }
    $('div[class="ui basic red pointing prompt label transition visible"]').remove();
    $('div[class="ui basic red pointing prompt label"]').remove();

  let val = $('input[name="product[facility_risk_share_type]"]:checked').val()
   if (val == "copay") {
     initialize_rss_copay_tb()
   } else if (val == "coinsurance") {
     initialize_rss_coinsurance_tb()
   } else if (val == undefined) {
      $('#risk_share_setup_form').form('validate form')
   }

   let validate_risk_share = $('#risk_share_setup_form').form('validate form')
   if (validate_risk_share) {

     let product_coverage_id = $('input[name="product[product_coverage_id]"]').val()
     let risk_share =  $('input[name="product[facility_risk_share_type]"]:checked').val()
     let risk_share_value = ""

     if (risk_share == "copay") {
       let input = document.getElementById('copay_rss')
       let unmasked = input.inputmask.unmaskedvalue()
       input.inputmask.remove()
       risk_share_value = $('#copay_rss').val(unmasked).val()
     } else {
       let input = document.getElementById('coinsurance_rss')
       let unmasked = input.inputmask.unmaskedvalue()
       input.inputmask.remove()
       risk_share_value = $('#coinsurance_rss').val(unmasked).val()
     }

     let data = {
       facility_id: $('input[name="product[facility_dropdown_rss]"]').val(),
       risk_share: risk_share,
       value: risk_share_value,
       type: $('#special_handling_dropdown_rss').dropdown('get value')

     }
     let facility_id = $('input[name="product[facility_dropdown_rss]"]').val()
     let product_id = $('input[name="product[id]"]').val()
     let pcdrs_id = $('input[name="product[pcdrs_id]"]').val()

     if(key){
     $.ajax({
       url: `/web/products/${pcdrs_id}/save_product_risk_share`,
       headers: {
         "X-CSRF-TOKEN": csrf
       },
       data: data,
       type: 'post',
       success: function (response) {
         let data = JSON.parse(response)
         let dt = $('#risk_share_dt').DataTable()
         let product_id = $('input[name="product[id]"]').val()
         let amount = formatRiskAmount(data.sdf_amount.replace(/,/g,""))

         dt.row.add([
           `<span>${data.facility_code}</span>`,
           `<span id="name${data.facility_code}">${data.facility_name}</span>`,
           `<span id="type${data.facility_code}">${data.sdf_type}</span>`,
           `<span id="amount${data.facility_code}">${amount}</span>`,
           `<span id="handling${data.facility_code}">${data.sdf_special_handling}</span>`,
            `<div class="ui dropdown" tabindex="0"> \
             <i class="ellipsis vertical icon"></i> \
             <div class="menu transition hidden"> \
             <div class="item clickable-row edit_risk_share" href="#" style="color:#00B24F"
             pcdrsf_id="${data.id}"
             facility_name="${data.facility_name}"
             facility_code="${data.facility_code}"
             facility_sdftype="${data.sdf_type}"
             facility_sftamount="${data.sdf_amount}"
             facility_s_handling="${data.sdf_special_handling}"
             facility_id="${data.facility_id}"
> \
             Edit Risk Share \
             </div> \
             <div class="item"> \
             <a href="#!" pcdrsf_id="${data.id}" product_id="${product_id}" class="remove_selected_pcdrsf"> Remove \
               <input type="hidden" name="product[dentl][pcdrsf_ids][]" value="${data.id}"> \
               <span class="selected_pcdrsf hidden">${data.id}</span> </a> \
               </div> \
               </div> \
               </div> `
         ]).draw(false)

         $('.ui.dropdown').dropdown()

         $(`[data-value="${facility_id}"]`).remove()
         $('#facility_test').dropdown('restore defaults')
         $('.modal.risk_share_setup').modal('hide')

         $('.edit_risk_share').on('click', function(e) {
     let id = $(this).attr("pcdrsf_id")
     let facility_name = $(this).attr("facility_name")
     let facility_code = $(this).attr("facility_code")
     let facility_type = $(this).attr("facility_sdftype")
     let facility_amount = $(this).attr("facility_sftamount")
     let facility_handling = $(this).attr("facility_s_handling")
     const csrf = $('input[name="_csrf_token"]').val();
     let facility_id = $(this).attr("facility_id")
     let pcdrsf= $(this).attr("pcdrsf_id")

     $('input[id="edit_s_handling"]').val(facility_handling);
    $('input[id="edit_amount_type"]').val(facility_type);
    $('input[id="edit_rs_amount"]').val(facility_amount);
    $('input[id="pcdrs_id"]').val(pcdrsf);

    $('text[id="rs_facility_code"]').text(facility_code);
    $('text[id="rs_facility_name"]').text(facility_name);

    if(facility_type == "Copay"){
      $('div[id="edit_copay_radio_rss"]').find('input').prop('checked', true);
      $('div[id="edit_coinsurance_radio_rss"]').find('input').prop('checked', false);
      $('.edit-copay-risk-share-setup-textbox').removeClass("hidden")
      $('.edit-coinsurance-risk-share-setup-text').addClass("hidden")
      $('input[id="edit_copay_rss"]').val(formatRiskAmount(facility_amount.replace(/,/g,"")))
    } else {
      $('div[id="edit_copay_radio_rss"]').find('input').prop('checked', false);
      $('div[id="edit_coinsurance_radio_rss"]').find('input').prop('checked', true);
      $('.edit-coinsurance-risk-share-setup-text').removeClass("hidden")
      $('.edit-copay-risk-share-setup-textbox').addClass("hidden")
      $('input[id="edit_coinsurance_rss"]').val(facility_amount)
    if(facility_handling == ""){
      $("#edit_special_handling_dropdown_rss").dropdown('remove selected','N/A')
    } else{
      $("#edit_special_handling_dropdown_rss").val(facility_handling).change()
    }
    $('.edit_risk_share_setup').modal({
    autofocus: false,
    closable: false,
    observeChanges: true,
    selector: {
      deny: '.deny.button',
      approve: '.approve.button'
    },
    onApprove: () => {
      var updated_type
      var updated_amount
      if($("#edit_copay_radio_rss").find('input').is(":checked")){
        updated_amount = $('input[id="edit_copay_rss"]').val()
        updated_type = "Copay"
      } else{
        updated_amount = $('input[id="edit_coinsurance_rss"]').val()
        updated_type = "Coinsurance"
      }
      let updated_handling = $("#edit_special_handling_dropdown_rss").val()
      let pcdrsf_id = $("#pcdrs_id").val()

     let data = {
       pcdrsf_id: pcdrsf_id,
       facility_id: facility_id,
       risk_share: updated_type,
       value: updated_amount.replace(/,/g,""),
       type: updated_handling
     }
     $.ajax({
       url: `/web/products/${pcdrsf_id}/update_product_risk_share`,
       headers: {
         "X-CSRF-TOKEN": csrf
       },
       data: data,
       type: 'post',
       success: function (response) {
        let data = JSON.parse(response)
        let dt = $('#risk_share_dt').DataTable()

        $(`span[id="type${facility_code}"]`).text(data.sdf_type)
        $(`span[id="amount${facility_code}"]`).text(data.sdf_amount)
        $(`span[id="handling${facility_code}"]`).text(data.sdf_special_handling)
        button.attr("facility_sdftype", data.sdf_type)
        button.attr("facility_sftamount", data.sdf_amount)
        button.attr("facility_s_handling", data.sdf_special_handling)
      }
    })
    }
          }).modal('show')
        }
})
         $('.remove_selected_pcdrsf').on('click', function(e) {
           e.preventDefault()
           let pcdrsf_id = $(this).attr('pcdrsf_id')
           let product_id = $(this).attr('product_id')
           const csrf = $('input[name="_csrf_token"]').val();
          let this_tbl = $(this)

           swal({
             title: 'Delete Risk Share?',
             type: 'question',
             showCancelButton: true,
             cancelButtonText: '<i class="remove icon"></i> No, keep Risk Share',
             confirmButtonText: '<i class="check icon"></i> Yes, delete risk Share',
             cancelButtonClass: 'ui negative button',
             confirmButtonClass: 'ui positive button',
             reverseButtons: true,
             buttonsStyling: false
           }).then(function (){
                $.ajax({
                  url: `/web/products/delete/${pcdrsf_id}/${product_id}/risk_share`,
                  headers: {
                    "X-CSRF-TOKEN": csrf
                  },
                  type: 'get',
                  success: function(response) {
                    let dt = $('#risk_share_dt').DataTable();
                    let row = this_tbl.closest('tr');

                    dt.row(row)
                    .remove()
                    .draw();
                    row.remove();
                  }
              })
           })
         })
       }
     })
   }
  }
  })

  const initialize_rs_validation_integer = () => {
    $('#risk-share-form').form({
      on: 'blur',
      inline: true,
      fields: {
        'risk-share-facility': {
          identifier: 'risk-share-facility',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a limit threshold facility.'
          }]
        },
        'risk-share': {
          identifier: 'risk-share',
          rules: [{
            type: 'empty',
            prompt: 'Please enter risk share.'
          }]
        },
        'risk-share-value': {
          identifier: 'risk-share-value',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a value.'
          }, {
            type: 'integer[1..100]',
            prompt: 'Please enter a value between 1 to 100.'
          }]
        },
        'covered-after-risk-share': {
          identifier: 'covered-after-risk-share',
          rules: [{
            type: 'empty',
            prompt: 'Please enter covered after risk share value.'
          }, {
            type: 'integer[1..100]',
            prompt: 'Please enter a covered value between 1 to 100.'
          }]
        }
      }
    })
  }

  const initialize_rs_validation_decimal = () => {
    $('#risk-share-form').form({
      on: 'blur',
      inline: true,
      fields: {
        'risk-share-facility': {
          identifier: 'risk-share-facility',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a limit threshold facility.'
          }]
        },
        'risk-share': {
          identifier: 'risk-share',
          rules: [{
            type: 'empty',
            prompt: 'Please enter risk share.'
          }]
        },
        'risk-share-value': {
          identifier: 'risk-share-value',
          rules: [{
            type: 'empty',
            prompt: 'Please enter a value.'
          }, {
            type: 'decimal',
            prompt: 'Please enter a valid decimal value.'
          }]
        },
        'covered-after-risk-share': {
          identifier: 'covered-after-risk-share',
          rules: [{
            type: 'empty',
            prompt: 'Please enter covered after risk share value.'
          }, {
            type: 'integer[1..100]',
            prompt: 'Please enter a covered value between 1 to 100.'
          }]
        }
      }
    })
  }

  const submit_lt = () => {
    let result = $('#limit-threshold-form').form('validate form')
    if (result) {
      let coverage = $('input[name="limit-threshold-coverage"]').val()
      let facility_code = $('#select-lt-facility').dropdown('get value')
      let facility_name = $('#select-lt-facility').dropdown('get text')
      let dt = $(`#${coverage}_lt_tbl`).DataTable()
      let value = $('input[name="limit-threshold-value"]').val()
      $(`input[name="product[${coverage}][limit_threshold]"]`).prop('readonly', true)

      dt.row
        .add([
          `<span class="green">${facility_code}</span>`,
          `<strong>${facility_name}</strong>`,
          `<span class="lt_value">${value}</span>`,
          `<a href="#!" class="remove_lt"><i class="green trash icon"></i></a>
                  <span class="selected_${coverage}_lt_id hidden">${facility_code}</span>
                  <input type="hidden" name="product[${coverage}][lt_data][]" value="${facility_code}-${value}">`
        ])
        .draw()

      $('.remove_lt').unbind('click').click(function () {
        let row = $(this).closest('tr')
        dt.row(row).remove().draw()
        mask_numeric2.mask($('#coinsurance_rss'));
        if (dt.rows().count() == 0) {
          $(`input[name="product[${coverage}][limit_threshold]"]`).prop('disabled', false)
        }
      })
    }

    return result
  }

  const submit_rs = () => {
    let result = $('#risk-share-form').form('validate form')
    if (result) {
      let coverage = $('input[name="risk-share-coverage"]').val()
      let facility_code = $('#select-rs-facility').dropdown('get value')
      let facility_name = $('#select-rs-facility').dropdown('get text')
      let risk_share = $('#select-rs').dropdown('get text')
      let dt = $(`#${coverage}_rs_tbl`).DataTable()
      let value = $('input[name="risk-share-value"]').val()
      let cars = $('input[name="covered-after-risk-share"]').val()
      let rs_data = `${risk_share}-${value}-${cars}`

      if (risk_share == "Copayment") {
        value = `${value} PHP`
      } else {
        value = `${value} %`
      }

      dt.row
        .add([
          `<span class="green">${facility_code}</span>`,
          `<strong>${facility_name}</strong>`,
          risk_share,
          value,
          `${cars} %`,
          `<a href="#!" class="remove_rs"><i class="green trash icon"></i></a>
           <span class="selected_${coverage}_rs_id hidden">${facility_code}</span
           <input type="hidden" name="product[${coverage}][rs_data][]" value="${facility_code}-${rs_data}">`
        ])
        .draw()

      $('.remove_rs').unbind('click').click(function () {
        let row = $(this).closest('tr')
        dt.row(row).remove().draw()
      })
    }

    return result
  }

  $.fn.form.settings.rules.checkOuterLimit = param => {
    let outer_limit = $('input[name="limit-threshold-outer-value"]').val()
    outer_limit = (outer_limit == undefined) ? 0 : outer_limit
    return outer_limit == param ? false : true
  }

  function removeDuplicateUsingFilter(arr) {
    let unique_array = arr.filter(function (elem, index, self) {
      return index == self.indexOf(elem);
    });
    return unique_array
  }

  // TODO

  $('.modal-open-risk-share').click(function () {

    maskDecimal.mask($('#copay_rss'));
    maskDecimalCoi.mask($('#coinsurance_rss'));

    let csrf = $('input[name="_csrf_token"]').val();

    $('#facility_test').dropdown('clear')
    $('input[name="product[facility_risk_share_type]"]').prop('checked', false)
    $('input[name="copay_textbox"]').val('')
    $('input[name="coinsurance_textbox"]').val('')
    $('#special_handling_dropdown_rss').dropdown('clear')

    let prod_id = $('input[name="product[id]"]').val()
    let fcodes_array = []

    $('.pcf_fac_code').each(function() {
      let code = $(this).attr('pcf_facility_code')
      fcodes_array.push(code)
    })

    // copy paste from master due to merge to conflict error

    $.ajax({
      url: `/web/products/${prod_id}/facility_risk_share`,
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      type: 'get',
      success: function (response) {

        if (response.success == false) {
          $('.ajs-message.ajs-error.ajs-visible').remove()
          alertify.error('<i class="close icon"></i>There are no available facilities for risk share setup')
        } else {
          $('.modal.risk_share_setup')
          .modal({
            autofocus: false,
            closable: false,
            // observeChanges: false,
            selector: {
              deny: '.deny.button',
              approve: '.approve.button'
            },
            onHide: () => {
              $('#facility_test').remove()
              $('.ui.grid.form').removeClass("error")
              $('.field').removeClass("error")
              $('.radio.checkbox').removeClass("checked")
              $('.copay-risk-share-setup-textbox').addClass("hidden")
              $('.coinsurance-risk-share-setup-text').addClass("hidden")
              $('#error_div').remove()
              $('.ui.basic.red.pointing.prompt').remove()
              $('#copay_radio_rss').find("label").css({"color":"#000000","border-color":"#FFFFFF"})
              $('#coinsurance_radio_rss').find("label").css({"color":"#000000","border-color":"#FFFFFF "})
            },
            onShow: () => {
              $('#facility_test').remove()
              $('#facility_dropdown').append(`
                <div class="ui search selection dropdown" id="facility_test">\
                <input name="product[facility_dropdown_rss]" type="hidden">\
                <i class="dropdown icon"></i>\
                <div class="default text">Select Facility</div>\
                <div class="menu">\
                </div>\
              </div>
              `)
              $('#facility_test').dropdown({
                apiSettings: {
                  url: `/web/products/${prod_id}/facility_risk_share`,
                  cache: false
                },
                filterRemoteData: true,
                fullTextSearch: 'exact',
                onChange: (addedValue) => {
                }
              })
            },
            onVisible: _ => {
              $('.modal.risk_share_setup')
              .modal('refresh')
            },
            onApprove: () => {
            }
          })
          .modal('show')
        }
      }
    })
  })

  // OLD JS FILE BEFORE MERGE CONFLICT

  //   $('.tiny.modal.risk_share_setup')
  //   .modal({
  //     autofocus: false,
  //     closable: false,
  //     // observeChanges: false,
  //     selector: {
  //       deny: '.deny.button',
  //       approve: '.approve.button'
  //     },
  //     onHide: () => {
  //       $('#facility_test').remove()
  //     },
  //     onShow: () => {
  //       $('#facility_test').remove()
  //       $('#facility_dropdown').append(`
  //         <div class="ui search selection dropdown" id="facility_test">\
  //           <input name="product[facility_dropdown_rss]" type="hidden">\
  //           <i class="dropdown icon"></i>\
  //           <div class="default text">Select Facility</div>\
  //           <div class="menu">\
  //           </div>\
  //         </div>
  //       `)
  //       $('#facility_test').dropdown({
  //         apiSettings: {
  //           url: `/web/products/${prod_id}/facility_risk_share`,
  //          cache: false
  //         },
  //         filterRemoteData: true,
  //         fullTextSearch: 'exact',
  //         onChange: (addedValue) => {
  //           //alert(1)
  //         }
  //       })
  //     },
  //     onVisible: _ => {
  //       $('.modal.risk_share_setup')
  //       .modal('refresh')
  //     },
  //     onApprove: () => {
  //     type: 'get',
  //     success: function (response) {

  //       if (response.success == false) {
  //         $('.ajs-message.ajs-error.ajs-visible').remove()
  //         alertify.error('<i class="close icon"></i>There are no available facilities for risk share setup')
  //       } else {
  //         $('.modal.risk_share_setup')
  //         .modal({
  //           autofocus: false,
  //           closable: false,
  //           // observeChanges: false,
  //           selector: {
  //             deny: '.deny.button',
  //             approve: '.approve.button'
  //           },
  //           onHide: () => {
  //             $('#facility_test').remove()
  //           },
  //           onShow: () => {
  //             $('#facility_test').remove()
  //             $('#facility_dropdown').append(`
  //               <div class="ui selection dropdown" id="facility_test">\
  //               <input name="product[facility_dropdown_rss]" type="hidden">\
  //               <i class="dropdown icon"></i>\
  //               <div class="default text">Select Facility</div>\
  //               <div class="menu">\
  //               </div>\
  //             </div>
  //             `)
  //             $('#facility_test').dropdown({
  //               apiSettings: {
  //                 url: `/web/products/${prod_id}/facility_risk_share`,
  //                 cache: false
  //               },
  //               onChange: (addedValue) => {
  //               }
  //             })
  //           },
  //           onVisible: _ => {
  //             $('.modal.risk_share_setup')
  //             .modal('refresh')
  //           },
  //           onApprove: () => {
  //           }
  //         })
  //         .modal('show')
  //       }
  //     }
  //   }).modal('show')
  // })





  let mask_numeric = new Inputmask("numeric", {
    allowMinus: false,
    rightAlign: false,
    max: 100
  });
  mask_numeric.mask($('#product_coinsurance'));

  let mask_numeric2 = new Inputmask("numeric", {
    allowMinus: false,
    rightAlign: false,
    max: 100
  });
  mask_numeric2.mask($('#coinsurance_rss'));

  $('.fa_rb').on('change', function () {
    let form = $(this).closest('.coverage_form')
    form.find('#funding_arrangement_type').val('true')
    form.form('validate field', 'funding_arrangement_type')
  })

  const initialize_rs_copay_tb = () => {
     $.fn.form.settings.rules.checkZeroVal = param => {
     let copay_val = $('input[name="product[copay]"]').val();
        if (copay_val == 0) {
           return false
        } else {
         return true
        }
      }
     $('.coverage_form').form({
       on: 'blur',
       inline: true,
       fields: {
         'product[copay]': {
           identifier: 'product[copay]',
           rules: [{
             type: 'empty',
             prompt: 'Please enter copay amount.'
           },
          {
            type: 'checkZeroVal[param]',
            prompt: 'Cant accept 0 amount.'
          }]
         },
         coverage_type: {
           identifier: 'coverage_type',
           rules: [{
             type: 'empty',
             prompt: 'Please enter coverage type.'
           }]
        },
        // 'product[special_handling_type]': {
        //   identifier: 'product[special_handling_type]',
        //   rules: [{
        //     type: 'empty',
        //     prompt: 'Please select special handling.'
        //   }]
        // },
         'product[dentl][type]': {
           identifier: 'product[dentl][type]',
           rules: [{
             type: 'checked',
             prompt: 'Please select facility.'
           }]
         },
         'product[dental_group_type]': {
           identifier: 'product[dental_group_type]',
           rules: [{
             type: 'empty',
             prompt: 'Please select Dental Group.'
           }]
         },
         fa_tbl: {
           identifier: 'fa_tbl',
           rules: [{
             type: 'empty',
             prompt: 'Please select atleast one facility.'
          }]
        },
      }
    })
  }

  const initialize_rs_copay_tb_disabling = () => {
     $.fn.form.settings.rules.checkZeroVal = param => {
     let copay_val = $('input[name="product[copay]"]').val();
        if (copay_val == 0) {
           return false
        } else {
         return true
        }
      }
     $('.coverage_form').form({
       on: 'blur',
       inline: true,
       fields: {
         // 'product[copay]': {
         //   identifier: 'product[copay]',
         //   rules: [{
         //     type: 'empty',
         //     prompt: 'Please enter copay amount.'
         //   },
         //  {
         //    type: 'checkZeroVal[param]',
         //    prompt: 'Cant accept 0 amount.'
         //  }]
         // },
         coverage_type: {
           identifier: 'coverage_type',
           rules: [{
             type: 'empty',
             prompt: 'Please enter coverage type.'
           }]
        },
        // 'product[special_handling_type]': {
        //   identifier: 'product[special_handling_type]',
        //   rules: [{
        //     type: 'empty',
        //     prompt: 'Please select special handling.'
        //   }]
        // },
         'product[dentl][type]': {
           identifier: 'product[dentl][type]',
           rules: [{
             type: 'checked',
             prompt: 'Please select facility.'
           }]
         },
         'product[dental_group_type]': {
           identifier: 'product[dental_group_type]',
           rules: [{
             type: 'empty',
             prompt: 'Please select Dental Group.'
           }]
         },
         fa_tbl: {
           identifier: 'fa_tbl',
           rules: [{
             type: 'empty',
             prompt: 'Please select atleast one facility.'
          }]
        },
      }
    })
  }

  const initialize_rs_coinsurance_tb = () => {
    $.fn.form.settings.rules.checkZeroVal = param => {
      let coinsurance_val = $('input[name="product[coinsurance]"]').val();
        if (coinsurance_val == 0) {
          return false
        } else {
         return true
        }
      }
     $('.coverage_form').form({
       on: 'blur',
       inline: true,
       fields: {
         'product[coinsurance]': {
           identifier: 'product[coinsurance]',
           rules: [{
             type: 'empty',
             prompt: 'Please enter coinsurance.'
           },
          {
             type: 'checkZeroVal[param]',
             prompt: 'Cant accept 0 amount.'
           }]
         },
         coverage_type: {
           identifier: 'coverage_type',
           rules: [{
             type: 'empty',
             prompt: 'Please enter coverage type.'
           }]
         },
        // 'product[special_handling_type]': {
        //   identifier: 'product[special_handling_type]',
        //   rules: [{
        //     type: 'empty',
        //     prompt: 'Please select special handling.'
        //   }]
        // },
         'product[dentl][type]': {
           identifier: 'product[dentl][type]',
           rules: [{
           type: 'checked',
           prompt: 'Please select facility.'
         }]
       },
       'product[dental_group_type]': {
         identifier: 'product[dental_group_type]',
         rules: [{
           type: 'empty',
           prompt: 'Please select Dental Group.'
         }]
       },
       fa_tbl: {
         identifier: 'fa_tbl',
         rules: [{
           type: 'empty',
           prompt: 'Please select atleast one facility.'
         }]
        },
      }
    })
  }


  const initialize_rs_coinsurance_tb_disabling = () => {
    $.fn.form.settings.rules.checkZeroVal = param => {
      let coinsurance_val = $('input[name="product[coinsurance]"]').val();
        if (coinsurance_val == 0) {
          return false
        } else {
         return true
        }
      }
     $('.coverage_form').form({
       on: 'blur',
       inline: true,
       fields: {
         // 'product[coinsurance]': {
         //   identifier: 'product[coinsurance]',
         //   rules: [{
         //     type: 'empty',
         //     prompt: 'Please enter coinsurance.'
         //   },
         //  {
         //     type: 'checkZeroVal[param]',
         //     prompt: 'Cant accept 0 amount.'
         //   }]
         // },
         coverage_type: {
           identifier: 'coverage_type',
           rules: [{
             type: 'empty',
             prompt: 'Please enter coverage type.'
           }]
         },
        // 'product[special_handling_type]': {
        //   identifier: 'product[special_handling_type]',
        //   rules: [{
        //     type: 'empty',
        //     prompt: 'Please select special handling.'
        //   }]
        // },
         'product[dentl][type]': {
           identifier: 'product[dentl][type]',
           rules: [{
           type: 'checked',
           prompt: 'Please select facility.'
         }]
       },
       'product[dental_group_type]': {
         identifier: 'product[dental_group_type]',
         rules: [{
           type: 'empty',
           prompt: 'Please select Dental Group.'
         }]
       },
       fa_tbl: {
         identifier: 'fa_tbl',
         rules: [{
           type: 'empty',
           prompt: 'Please select atleast one facility.'
         }]
        },
      }
    })
  }


  const initialize_rss_copay_tb = () => {

    $.fn.form.settings.rules.checkZeroVal = param => {
      let copay_val = $('input[name="copay_textbox"]').val();
      if (copay_val == 0) {
        return false
      } else {
        return true
      }
    }

    $('#risk_share_setup_form').form({
      inline: true,
      fields: {
        'copay_textbox': {
          identifier: 'copay_textbox',
          rules: [
          {
            type: 'empty',
            prompt: 'Please enter risk share amount.'
          },
          {
            type: 'checkZeroVal[param]',
            prompt: 'Cant accept 0 amount.'
          }
        ]
        },
         'product[facility_dropdown_rss]': {
           identifier: 'product[facility_dropdown_rss]',
           rules: [{
             type: 'empty',
             prompt: 'Please select Facility.'
           }]
         },
      }
    })

    $('#risk_share_setup_form').form('validate form')
  }

  const initialize_rss_coinsurance_tb = () => {

    $.fn.form.settings.rules.checkZeroVal = param => {
      let coinsurance_val = $('input[name="coinsurance_textbox"]').val();
      if (coinsurance_val == 0) {
        return false
      } else {
        return true
      }
    }

    $('#risk_share_setup_form').form({
      inline: true,
      fields: {
        'coinsurance_textbox': {
          identifier: 'coinsurance_textbox',
          rules: [{
            type: 'empty',
            prompt: 'Please enter coinsurance.'
          },
          {
            type: 'checkZeroVal[param]',
            prompt: 'Cant accept 0 amount.'
          }
        ]
        },
         'product[facility_dropdown_rss]': {
           identifier: 'product[facility_dropdown_rss]',
           rules: [{
             type: 'empty',
             prompt: 'Please select Facility.'
           }]
         },
      }
    })

    $('#risk_share_setup_form').form('validate form')
  }

  maskDecimal.mask($('#product_copay'));

  var state = false;
  var prevVal;
  var val;
  var isChecked;
  var isChecked2;

  $('.riskshare_type_radio').on('mousedown', function(e) {
    prevVal = $('input[name="product[copay_rss]"]:checked').val();
    val = $(this).find('input').val();
    isChecked = $('#copay_b').find('input').is(':checked')
    isChecked2 = $('#coinsurance_b').find('input').is(':checked')
  })

  $('.riskshare_type_radio').on('click', function() {

    let copay = $('#product_copay').val();
    let coinsurance = $('#product_coinsurance').val();
    let s_handling = $('#product_special_handling_type option:selected').val();

    if (copay == "" && coinsurance == "" && s_handling == "") {
      initialize_special_handling_validation_dropdown()
     } else {
      disabling_special_handling_validation_dropdown()
     }

    if (state == false && val == "Copay") {
      $('#copay_b').find('input').prop('checked', true)
      state = true;

      initialize_special_handling_validation_dropdown()
      $('input[name="product[copay]"]').prop('disabled', false)
      $('.field.copay-type.error').show()
      $('.field.copay-type').show()
      $('.copay-type').removeClass('error')
      $('.copay-type').parent().find('.prompt').remove()
      $('input[name="product[copay]"]').val('')
    }
    else if (state == true && val == "Copay") {

      disabling_special_handling_validation_rs_copay()
      $('#copay_b').find('input').prop('checked', false)
      $('#copay_b').removeClass('checked')
      $('.field.copay-type.error').show()
      state = false;
      $('.copay-type').addClass('hidden')
      $('input[name="product[copay]"]').val('')
      $('input[name="product[copay]"]').prop('disabled', true)
      $('.icon.selection').parent().removeClass('error')
      $('.icon.selection').parent().find('.prompt').remove()
      // $('#product_special_handling_type').dropdown('clear')
      $('#coinsurance_b').removeClass('checked')
      $('.copay-type').removeClass('error')
      $('.copay-type').parent().find('.prompt').remove()
    }
    else if (state == false && val == "Coinsurance") {
      $('#coinsurance_b').find('input').prop('checked', true)
      state = true;
      $('input[name="product[coinsurance]"]').prop('disabled', false)
      $('.field.coninsurance-type.error').show()
      $('.field.coninsurance-type').show()
      $('.coninsurance-type').removeClass('error')
      $('.coninsurance-type').parent().find('.prompt').remove()
      $('input[name="product[coinsurance]"]').val('')
    }
    else if (state == true && val == "Coinsurance") {
      disabling_special_handling_validation_rs_copay()
      $('#coinsurance_b').find('input').prop('checked', false)
      $('#coinsurance_b').removeClass('checked')
      state = false;
      $('.coninsurance-type').addClass('hidden')
      $('input[name="product[coinsurance]"]').val('')
      $('input[name="product[coinsurance]"]').prop('disabled', true)
      $('.icon.selection').parent().removeClass('error')
      $('.icon.selection').parent().find('.prompt').remove()
      // $('#product_special_handling_type').dropdown('clear')
      $('#copay_b').removeClass('checked')
      $('.coninsurance-type').removeClass('error')
      $('.coninsurance-type').parent().find('.prompt').remove()
      $('.field.coninsurance-type').show()
    }

    if (prevVal == "Coinsurance" && val == "Copay" && state == false && isChecked == false) {
      $('#copay_b').find('input').prop('checked', true)
      state = true;
      $('.copay-type').removeClass('hidden')
      $('input[name="product[copay]"]').prop('disabled', false)
      initialize_special_handling_validation_dropdown()
    }

    if (prevVal == "Copay" && val == "Coinsurance" && state == false && isChecked2 == false) {
      $('#coinsurance_b').find('input').prop('checked', true)
      state = true;
      $('.coninsurance-type').removeClass('hidden')
      $('input[name="product[coinsurance]"]').prop('disabled', false)
      initialize_special_handling_validation_dropdown()
    }
    $('#error_div').remove()
    $('#copay_b').find("label").css({"color":"#000000","border-color":"#FFFFFF"})
    $('#coinsurance_b').find("label").css({"color":"#000000","border-color":"#FFFFFF "})
  })

  // var state_rss = false;
  // var prevVal_rss;
  // var val_rss;
  // var isChecked_rss;
  // var isChecked_rss2;

  // $('.risk_share_setup_type').on('mousedown', function(e) {
  //   prevVal_rss = $('input[name="product[facility_risk_share_type]"]:checked').val();
  //   val_rss = $(this).find('input').val();
  //   isChecked_rss = $('#copay_radio_rss').find('input').is(':checked')
  //   isChecked_rss2 = $('#coinsurance_radio_rss').find('input').is(':checked')
  // })

  // $('.risk_share_setup_type').on('click', function () {

  //   if(state_rss == false && val_rss == "copay") {
  //     $('#copay_radio_rss').find('input').prop('checked', true)
  //     state_rss = true;
  //     $('input[name="copay_textbox"]').prop('disabled', false)
  //   } else if (state_rss == true && val_rss == "copay") {
  //     $('#copay_radio_rss').find('input').prop('checked', false)
  //     $('#copay_radio_rss').removeClass('checked')
  //     state_rss = false;
  //     $('.copay-risk-share-setup-textbox').addClass('hidden')
  //     $('input[name="copay_textbox"]').val('')
  //     $('.copay-risk-share-setup-textbox').parent().removeClass('error')
  //     $('.copay-risk-share-setup-textbox').parent().find('.prompt').remove()
  //     $('input[name="copay_textbox"]').prop('disabled', true)
  //   } else if (state_rss == false && val_rss == "coinsurance") {
  //     $('#coinsurance_radio_rss').find('input').prop('checked', true)
  //     state_rss = true;
  //     $('input[name="coinsurance_textbox"]').prop('disabled', false)
  //   } else if (state_rss == true && val_rss == "coinsurance") {
  //     $('#coinsurance_radio_rss').find('input').prop('checked', false)
  //     $('#coinsurance_radio_rss').removeClass('checked')
  //     state_rss = false;
  //     $('.coinsurance-risk-share-setup-text').addClass('hidden')
  //     $('input[name="coinsurance_textbox"]').val('')
  //     $('.coinsurance-risk-share-setup-text').parent().removeClass('error')
  //     $('.coinsurance-risk-share-setup-text').parent().find('.prompt').remove()
  //     $('input[name="coinsurance_textbox"]').prop('disabled', true)
  //   }

  //   if(prevVal_rss == "coinsurance" && val_rss == "copay" && state_rss == false && isChecked_rss == false) {
  //     $('#copay_radio_rss').find('input').prop('checked', true)
  //     state_rss = true;
  //     $('.copay-risk-share-setup-textbox').removeClass('hidden')
  //     $('input[name="coinsurance_textbox"]').prop('disabled', true)
  //     $('input[name="copay_textbox"]').prop('disabled', false)
  //   }
  //   if(prevVal_rss == "copay" && val_rss == "coinsurance" && state_rss == false && isChecked_rss2 == false) {
  //     $('#coinsurance_radio_rss').find('input').prop('checked', true)
  //     state_rss = true;
  //     $('.coinsurance-risk-share-setup-text').removeClass('hidden')
  //     $('input[name="copay_textbox"]').prop('disabled', true)
  //     $('input[name="coinsurance_textbox"]').prop('disabled', false)
  //   }
  // })

  $('.riskshare_type_radio').on('change', function () {
    let value = $(this).find('input').val()

    if (value == "Copay") {
      $('.copay-type').removeClass('hidden')
      initialize_rs_copay_tb()

    } else {
      $('.copay-type').addClass('hidden')
      $('input[name="product[copay]"]').val('')
      $('.copay-type').parent().removeClass('error')
      $('.copay-type').parent().find('.prompt').remove()
    }

    if (value == "Coinsurance") {
      $('.coninsurance-type').removeClass('hidden')
      initialize_rs_coinsurance_tb()
    } else {
      $('.coninsurance-type').addClass('hidden')
      $('input[name="product[coinsurance]"]').val('')
      $('.coninsurance-type').parent().removeClass('error')
      $('.coninsurance-type').parent().find('.prompt').remove()
    }
  })

  $('input[name="copay_textbox"]').keydown(function (evt) {
    var value = $('input[name="copay_textbox"]').val()

    var selection = window.getSelection();
    if(evt.key == '.' || value.includes('.')) {
      if (value.length == 10 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    } else {
      if(value.length > 6 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    }
  })

  $('input[name="coinsurance_textbox"]').keydown(function (evt) {
    var value = $('input[name="coinsurance_textbox"]').val()
    if(evt.key != '.' || !value.includes('.')) {
      if (value.length == 3 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
      if(value.length == 2 && evt.key != "Backspace" && evt.key != "Delete" && evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        $('input[name="coinsurance_textbox"]').val(100)
      }
    }
  })

  $('.risk_share_setup_type').on('change', function () {
    let value = $(this).find('input').val()

    if (value == "copay") {
      $('.copay-risk-share-setup-textbox').removeClass('hidden')
      $('input[name="coinsurance_textbox"]').prop('disabled', true)
      $('input[name="copay_textbox"]').prop('disabled', false)
      $('#error_div').remove()
      $('#copay_radio_rss').find("label").css({"color":"#000000","border-color":"#FFFFFF"})
      $('#coinsurance_radio_rss').find("label").css({"color":"#000000","border-color":"#FFFFFF "})
    //  initialize_rss_copay_tb()
    } else {
      $('.copay-risk-share-setup-textbox').addClass('hidden')
      $('input[name="copay_textbox"]').val('')
      $('.copay-risk-share-setup-textbox').parent().removeClass('error')
      $('.copay-risk-share-setup-textbox').parent().find('.prompt').remove()
      $('input[name="copay_textbox"]').prop('disabled', false)
      $('#error_div').remove()
      $('#copay_radio_rss').find("label").css({"color":"#000000","border-color":"#FFFFFF"})
      $('#coinsurance_radio_rss').find("label").css({"color":"#000000","border-color":"#FFFFFF "})
    }

    if (value == "coinsurance") {
      $('.coinsurance-risk-share-setup-text').removeClass('hidden')
      $('input[name="copay_textbox"]').prop('disabled', true)
      $('input[name="coinsurance_textbox"]').prop('disabled', false)
      // initialize_rss_coinsurance_tb()
    } else {
      $('.coinsurance-risk-share-setup-text').addClass('hidden')
      $('input[name="coinsurance_textbox"]').val('')
      $('.coinsurance-risk-share-setup-text').parent().removeClass('error')
      $('.coinsurance-risk-share-setup-text').parent().find('.prompt').remove()
      $('input[name="coinsurance_textbox"]').prop('disabled', false)

    }
  })

  $('.coverage_type_radio').on('change', function () {
    let coverage = $(this).attr('coverage')
    let value = $(this).find('input').val()
    let type = $(`input[name="product[${coverage}][type]"]:checked`).val()
    let input = $(`input[name="${coverage}_is_valid_facility"]`)
    let dt_fa = $(`#${coverage}_fa_tbl`).DataTable()
    let dt_lt = $(`#${coverage}_lt_tbl`).DataTable()
    let product_id = $('input[name="product[id]"]').val()
    let csrf = $('input[name="_csrf_token"]').val();
    $('div[id="error_div2"]').remove()
    $('.coverage_type_radio').find("label").css({"color":"#000000","border-color":"#FFFFFF "})

    if (value == "All Affiliated Facilities") {
      state = false;
      $('#product_dental_group_type').prop('disabled', false)
      $('#copay_radio').prop('checked', true)
      // TODO
      $('.dental-group-type').removeClass('hidden')
      $('.dental-exclusion').removeClass('hidden')
      $('.dental-inclusion').addClass('hidden')
      $('.dental-inclusion').parents('.dataTables_wrapper').first().hide();
      $('.dental-exclusion').parents('.dataTables_wrapper').show();
      $('#text-dental-type').text("Excluded Dental Facilities")
      $('.dental-exclusion').attr('id', 'dentl_lt_tbl')
      $('.dental-exclusion').attr('role', 'datatable2')
      $('.dental-inclusion').removeAttr('role')
      $('.dental-inclusion').removeAttr('id')
      $('#copay_b').find('input').prop('checked', false)
      $('.copay-type').parent().removeClass('error')
      $('.copay-type').parent().find('.prompt').remove()
      $('.icon.selection').parent().removeClass('error')
      $('.icon.selection').parent().find('.prompt').remove()
      $('.coninsurance-type').parent().removeClass('error')
      $('.coninsurance-type').parent().find('.prompt').remove()
      $('.copay-type').addClass('hidden')
      $('.coninsurance-type').addClass('hidden')
      $('.field.coninsurance-type.error').hide()
      $('.field.copay-type.error').hide()
      $('.field.copay-type').hide()
      $('.field.coninsurance-type').hide()
      $('#product_special_handling_type').dropdown('clear')
      $('.riskshare_type_radio').removeClass('checked')
      if ($('#copay_radio:checked').val()? true: false){
        // do nothing
      }
      else{
        initialize_rs_copay_tb_disabling()
      }

      }  else {
      state = false;
      $('#product_dental_group_type').prop('disabled', true)
      $('#coinsurance_radio').prop('checked', true)
      // TODO
      $('.dental-group-type').addClass('hidden')
      $('.dental-exclusion').addClass('hidden')
      $('.dental-inclusion').removeClass('hidden')
      $('.dental-exclusion').parents('.dataTables_wrapper').first().hide();
      $('.dental-inclusion').parents('.dataTables_wrapper').show();
      $('#text-dental-type').text("Included Dental Facilities")
      $('.dental-inclusion').attr('id', 'dentl_fa_tbl')
      $('.dental-inclusion').attr('role', 'datatable2')
      $('.dental-exclusion').removeAttr('role')
      $('.dental-exclusion').removeAttr('id')
      $('.dental-group-type').removeClass('error')
      $('#location-group-field').remove()
      $('#coinsurance_b').find('input').prop('checked', false)
      // if (type == "Specific Facilities") {

      //   $('#product_dental_group_type').dropdown('clear')
      // }
      // else{
      // let test = $('#product_dental_group_type option:selected').val()
      // $('#product_dental_group_type').dropdown('set selected', test)
      // }
      $('.copay-type').parent().removeClass('error')
      $('.copay-type').parent().find('.prompt').remove()
      $('.icon.selection').parent().removeClass('error')
      $('.icon.selection').parent().find('.prompt').remove()
      $('.coninsurance-type').parent().removeClass('error')
      $('.coninsurance-type').parent().find('.prompt').remove()
      $('.copay-type').addClass('hidden')
      $('.coninsurance-type').addClass('hidden')
      $('#btnAddRiskShare').addClass('disabled')
      $('.field.coninsurance-type.error').hide()
      $('.field.copay-type.error').hide()
      $('.field.copay-type').hide()
      $('.field.coninsurance-type').hide()
      $('#product_special_handling_type').dropdown('clear')
      $('.riskshare_type_radio').removeClass('checked')
  if ($('#Coinsurance:checked').val()? true: false){
         // do nothing
       }
       else{
         initialize_rs_coinsurance_tb_disabling()
       }
    }

    let fa_checker = (dt_fa.rows().count() > 0) ? true : false
    let lt_checker = (dt_lt.rows().count() > 0) ? true : false
    let form = $(this).parents('.coverage_form')

    form.find('#coverage_type').val('true')

    $(`#${coverage}_add_fa_btn`).removeClass('disabled')
    $('#confirmation-header').text('Change Facilities?')
    $('#confirmation-description').text('All the data entered about facility access and exempted facilities in limit threshold will be deleted.')
    $('#confirmation-question').text('Do you want to proceed?')

    if (value == "All Affiliated Facilities") {
      $(`#${coverage}_add_ex_lt_btn`).removeClass('disabled')
      $(`#${coverage}_add_ex_rs_btn`).removeClass('disabled')
      input.val('true')
    } else {
      input.val('')
      // check_facility(input) // comment because undefined check_facility
    }

    if (value == "Specific Facilities") {
      $('#fa_tbl').attr('pc_type', 'inclusion')
    } else {
      $('#fa_tbl').attr('pc_type', 'exception')
      input.val('true')
    }

    if (fa_checker) {
      form.form('validate field', 'fa_tbl')
      form.form('validate field', 'coverage_type')
    }

    if (fa_checker || lt_checker) {
      $('.modal.confirmation')
      .modal({
        autofocus: false,
        closable: false,
        selector: {
          deny: '.deny.button',
          approve: '.approve.button'
        },
        onShow: () => {
          $('.modal.confirmation')
          .find('.close.icon')
          .css('display', 'none')
        },
        onVisible: _ => {
          $('.modal.confirmation').modal('refresh')
        },
        onApprove: () => {
          let selected_type;
          $.ajax({
            url: `/web/products/${product_id}/delete/product_facilities`,
            headers: {
              "X-CSRF-TOKEN": csrf
            },
            data: {"type" : selected_type},
            type: 'delete',
            success: function (response) {
              if (value == "Specific Facilities") {
                $('#text-dental-type').text("Included Dental Facilities")
                $('#dentl_lt_tbl').DataTable().clear();
                $('#dentl_lt_tbl').DataTable().destroy();
                $('#dentl_fa_tbl').DataTable().clear();
                $('#dentl_fa_tbl').DataTable().destroy();

                $('#fa_tbl').attr('pc_type', 'inclusion')
                $('#product_dental_group_type').dropdown('clear')
                selected_type = "inclusion";
                append_facility_inclusion()
              } else {
                $('#text-dental-type').text("Excluded Dental Facilities")
                $('#dentl_lt_tbl').DataTable().clear();
                $('#dentl_lt_tbl').DataTable().destroy();
                $('#dentl_fa_tbl').DataTable().clear();
                $('#dentl_fa_tbl').DataTable().destroy();
                $('#fa_tbl').attr('pc_type', 'exception')
                input.val('true')
                selected_type = "exception";
                append_facility_exception()
              }

              // dt_fa.clear().draw()
              // dt_lt.clear().draw()
              $('#risk_share_dt').DataTable().clear()
              $('#risk_share_dt').DataTable().destroy()
              // $('#btnAddRiskShare').addClass('distababled')
            }
          })

        },
        onDeny: () => {
          confirmation_fa(value, coverage)
        }
      })
      .modal('show')
    }

    if (value == "All Affiliated Facilities") {
      $('#dentl_lt_tbl').DataTable().clear();
      $('#dentl_lt_tbl').DataTable().destroy();
      $('#dentl_fa_tbl').DataTable().clear();
      $('#dentl_fa_tbl').DataTable().destroy();
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('#product_dental_group_type').prop('disabled', false)
      $('#copay_radio').prop('checked', true)
      $('.dental-group-type').removeClass('hidden')
      $('#text-dental-type').text("Excluded Dental Facilities")
      $('#copay_b').find('input').prop('checked', false)

      append_facility_exception()

      state = false;
      $('#product_dental_group_type').prop('disabled', false)
      $('#copay_radio').prop('checked', true)
      // TODO
      $('.dental-group-type').removeClass('hidden')
      $('#text-dental-type').text("Excluded Dental Facilities")
      $('#copay_b').find('input').prop('checked', false)
      $('.field.coninsurance-type.error').hide()
      $('.field.copay-type.error').hide()
      $('.field.copay-type').hide()
      $('.field.coninsurance-type').hide()
      $('#product_special_handling_type').dropdown('clear')

    } else {
      $('#dentl_lt_tbl').DataTable().clear();
      $('#dentl_lt_tbl').DataTable().destroy();
      $('#dentl_fa_tbl').DataTable().clear();
      $('#dentl_fa_tbl').DataTable().destroy();
      $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
      $('#product_dental_group_type').prop('disabled', true)
      $('#coinsurance_radio').prop('checked', true)
      $('.dental-group-type').addClass('hidden')
      $('#text-dental-type').text("Included Dental Facilities")
      $('#location-group-field').remove()
      $('#coinsurance_b').find('input').prop('checked', false)

      append_facility_inclusion()

      $('#product_dental_group_type').prop('disabled', true)
      $('#coinsurance_radio').prop('checked', true)
      // TODO
      $('.dental-group-type').addClass('hidden')
      $('#text-dental-type').text("Included Dental Facilities")
      $('.dental-group-type').removeClass('error')
      $('#location-group-field').remove()
      $('#coinsurance_b').find('input').prop('checked', false)
      $('.field.coninsurance-type.error').hide()
      $('.field.copay-type.error').hide()
      $('.field.copay-type').hide()
      $('.field.coninsurance-type').hide()
      $('#product_special_handling_type').dropdown('clear')
    }
  })


  const confirmation_fa = (value, coverage) => {
    switch (value) {
      case "All Affiliated Facilities":
        $('#dentl_lt_tbl').DataTable().clear();
        $('#dentl_lt_tbl').DataTable().destroy();
        $('#dentl_fa_tbl').DataTable().clear();
        $('#dentl_fa_tbl').DataTable().destroy();
        $('#text-dental-type').text("Excluded Dental Facilities")

        $('input[value="Specific Facilities"]').prop('checked', true)
        $('input[value="Specific Facilities"]').parent().addClass('checked')
        $('input[value="All Affiliated Facilities"]').parent().removeClass('checked')
        $('.dental-group-type').addClass('hidden')

        append_facility_exception()
        //
        break
      case "Specific Facilities":
      // $('#product_dental_group_type').dropdown('restore defaults')
        $('#dentl_lt_tbl').DataTable().clear();
        $('#dentl_lt_tbl').DataTable().destroy();
        $('#dentl_fa_tbl').DataTable().clear();
        $('#dentl_fa_tbl').DataTable().destroy();
        $('#text-dental-type').text("Included Dental Facilities")

        $('input[value="All Affiliated Facilities"]').prop('checked', true)
        $('input[value="All Affiliated Facilities"]').parent().addClass('checked')
        $('.dental-group-type').removeClass('hidden')
        $('input[value="Specific Facilities"]').parent().removeClass('checked')
        //

        $(`#${coverage}_add_ex_lt_btn`).removeClass('disabled')
        $(`#${coverage}_add_ex_rs_btn`).removeClass('disabled')

        append_facility_inclusion()
        break
    }
  }

  $('.remove_facility').on('click', function (e) {
    e.preventDefault()
    let pc_id = $(this).attr('product_coverage_id')
    let product_id = $(this).attr('product_id')
    let type = $(this).attr('pc_type')

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
      var count = $('#dental_fa_tbl>tbody>tr').length;

      if (count === 1 && type === 'inclusion') {
        alertify.error('<i class="close icon"></i>Cannot delete all facility')
      } else {
                $.ajax({
                  url: `/web/products/delete/${pcf_id}/${product_id}/product_coverage`,
                  headers: {
                    "X-CSRF-TOKEN": csrf
                  },
                  type: 'get',
                  success: function(response) {
                    let dt = $('#dentl_lt_tbl').DataTable();
                    let row = $(this).closest('tr')

                    dt.row(row)
                    .remove()
                    .draw()
                    row.remove()
                  }
              })
       }

    })
  })

   $('.edit_risk_share').on('click', function(e) {
     let id = $(this).attr("pcdrsf_id")
     let facility_name = $(this).attr("facility_name")
     let facility_code = $(this).attr("facility_code")
     let facility_type = $(this).attr("facility_sdftype")
     let facility_amount = $(this).attr("facility_sftamount")
     let facility_handling = $(this).attr("facility_s_handling")
     const csrf = $('input[name="_csrf_token"]').val();
     let facility_id = $(this).attr("facility_id")
     let pcdrsf= $(this).attr("pcdrsf_id")
     let button = $(this)

     $('input[id="edit_s_handling"]').val(facility_handling);
    $('input[id="edit_amount_type"]').val(facility_type);
    $('input[id="edit_rs_amount"]').val(facility_amount);
    $('input[id="pcdrs_id"]').val(pcdrsf);

    $('text[id="rs_facility_code"]').text(facility_code);
    $('text[id="rs_facility_name"]').text(facility_name);

    if(facility_type == "Copay"){
      $('div[id="edit_copay_radio_rss"]').find('input').prop('checked', true);
      $('div[id="edit_coinsurance_radio_rss"]').find('input').prop('checked', false);
      $('.edit-copay-risk-share-setup-textbox').removeClass("hidden")
      $('.edit-coinsurance-risk-share-setup-text').addClass("hidden")
      $('input[id="edit_copay_rss"]').val(formatRiskAmount(facility_amount.replace(/,/g,"")))
    } else {
      $('div[id="edit_copay_radio_rss"]').find('input').prop('checked', false);
      $('div[id="edit_coinsurance_radio_rss"]').find('input').prop('checked', true);
      $('.edit-coinsurance-risk-share-setup-text').removeClass("hidden")
      $('.edit-copay-risk-share-setup-textbox').addClass("hidden")
      $('input[id="edit_coinsurance_rss"]').val(facility_amount)
    }
    if(facility_handling == ""){
      $("#edit_special_handling_dropdown_rss").dropdown('set selected','')
  } else{
      $("#edit_special_handling_dropdown_rss").val(facility_handling).change()
    }
    $('.edit_risk_share_setup').modal({
    autofocus: false,
    closable: false,
    observeChanges: true,
    selector: {
      deny: '.deny.button',
      approve: '.approve.button'
    },
    onApprove: () => {
      var updated_type
      var updated_amount
      if($("#edit_copay_radio_rss").find('input').is(":checked")){
        updated_amount = $('input[id="edit_copay_rss"]').val()
        updated_type = "Copay"
      } else{
        updated_amount = $('input[id="edit_coinsurance_rss"]').val()
        updated_type = "Coinsurance"
      }
      let updated_handling = $("#edit_special_handling_dropdown_rss").val()
      let pcdrsf_id = $("#pcdrs_id").val()

     let data = {
       pcdrsf_id: pcdrsf_id,
       facility_id: facility_id,
       risk_share: updated_type,
       value: updated_amount.replace(/,/g,""),
       type: updated_handling
     }
     $.ajax({
       url: `/web/products/${pcdrsf_id}/update_product_risk_share`,
       headers: {
         "X-CSRF-TOKEN": csrf
       },
       data: data,
       type: 'post',
       success: function (response) {
        let data = JSON.parse(response)
        let dt = $('#risk_share_dt').DataTable()

        $(`span[id="type${facility_code}"]`).text(data.sdf_type)
        $(`span[id="amount${facility_code}"]`).text(data.sdf_amount)
        $(`span[id="handling${facility_code}"]`).text(data.sdf_special_handling)
        button.attr("facility_sdftype", data.sdf_type)
        button.attr("facility_sftamount", data.sdf_amount)
        button.attr("facility_s_handling", data.sdf_special_handling)
      }
    })
    },
    onHide: () => {
      $('input[id="edit_coinsurance_rss"]').val('')
     $('input[id="edit_s_handling"]').val('');
    $('input[id="edit_amount_type"]').val('');
    $('input[id="edit_rs_amount"]').val('');
    $('input[id="pcdrs_id"]').val('');
    $('text[id="rs_facility_code"]').text('');
    $('text[id="rs_facility_name"]').text('');
      $("#edit_special_handling_dropdown_rss").dropdown('clear')
    }
    }).modal('show')

})
  $('.remove_selected_pcdrsf').on('click', function () {
    let pcdrsf_id = $(this).attr('pcdrsf_id')
    let product_id = $(this).attr('product_id')
           const csrf = $('input[name="_csrf_token"]').val();
    let this_tbl = $(this)

    swal({
      title: 'Delete Risk Share?',
      type: 'question',
      showCancelButton: true,
      cancelButtonText: '<i class="remove icon"></i> No, keep Risk Share',
      confirmButtonText: '<i class="check icon"></i> Yes, delete risk Share',
      cancelButtonClass: 'ui negative button',
      confirmButtonClass: 'ui positive button',
      reverseButtons: true,
      buttonsStyling: false
    }).then(function () {
                $.ajax({
                  url: `/web/products/delete/${pcdrsf_id}/${product_id}/risk_share`,
                  headers: {
                    "X-CSRF-TOKEN": csrf
                  },
                  type: 'get',
                  success: function(response) {
                    let dt = $('#risk_share_dt').DataTable();
                    let row = this_tbl.closest('tr')

                    dt.row(row)
                    .remove()
                    .draw()
                    row.remove()
                  }
              })
        // window.location.replace(`/web/products/delete/${pcdrsf_id}/${product_id}/risk_share`);
    })
  })
  // $('.remove_facility')
  //   .unbind('click')
  //   .click(function () {
  //     let row = $(this).parents('tr')
  //     let current_dt = $(this).parents('table').DataTable()

  //     $('.modal.confirmation')
  //     .modal({
  //       autofocus: false,
  //       closable: false,
  //       selector: {
  //         deny: '.deny.button',
  //         approve: '.approve.button'
  //       },
  //       onShow: () => {
  //         $('.modal.confirmation')
  //           .find('.close.icon')
  //           .css('display', 'none')

  //         $('#confirmation-header').text('Remove Facility?')
  //         $('#confirmation-description').text('Facility shall be removed from Facility Details and user shall be redirected to Facility Step if YES button is clicked.')
  //         $('#confirmation-question').text('Do you want to proceed?')
  //       },
  //       onVisible: _ => {
  //         $('.modal.confirmation').modal('refresh')
  //       },
  //       onApprove: () => {
  //         current_dt
  //           .row(row)
  //           .remove()
  //           .draw()

  //         let count = current_dt.rows().count()
  //         if (count == 0) {
  //           let input = $(`input[name="dentl_is_valid_facility"]`)
  //           input.val('')
  //           check_facility(input)
  //         }
  //       }
  //     })
  //     .modal('show')
  //   })

  $('.modal-open-lt').click(function () {
    let coverage = $(this).attr('coverage')
    let outer_limit = $(`input[name="product[${coverage}][limit_threshold]"]`).val()
    let type = $(`input[name="product[${coverage}][type]"]:checked`).val()
    let selected_fa_ids = get_selected_facilities(coverage, "fa")
    let selected_lt_codes = get_selected_facilities(coverage, "lt")
    let provider_access = get_provider_access($(this).attr('providerAccess'))

    $('#limit-threshold-form').form('reset')
    $(`.modal.limit-threshold`)
    .modal({
      autofocus: false,
      closable: false,
      selector: {
        deny: '.cancel.button',
        approve: '.add.button'
      },
      onApprove: () => {
        return submit_lt()
      },
      onShow: () => {
        $('input[name="limit-threshold-outer-value"]').val(outer_limit)
        $('input[name="limit-threshold-coverage"]').val(coverage)

        $('#lt_dropdown').html(`
          <label class="label-title">Facility</label>
          <div class="ui fluid selection dropdown" id="select-lt-facility">
            <input type="hidden" name="limit-threshold-facility">
            <i class="dropdown icon"></i>
            <div class="default text">Select Facility</div>
            <div class="menu">
            </div>
          </div>
        `)

        initialize_lt_validation()

        $('#select-lt-facility').dropdown({
          apiSettings: {
            url: `/web/products/load_dropdown_facilities?type=${type}&facilities=${selected_fa_ids}&provider_access=${provider_access}&selected_lt_codes=${selected_lt_codes}`
          }
        })
      }
    })
    .modal('show')
  })

  $('.modal-open-rs').click(function () {
    let coverage = $(this).attr('coverage')
    let type = "All Affiliated Facilities"
    let fa_ids = []
    let selected_rs_codes = get_selected_facilities(coverage, "rs")
    let provider_access = get_provider_access($(this).attr('providerAccess'))

    $(`.modal.risk-share`)
    .modal({
      autofocus: false,
      closable: false,
      selector: {
        deny: '.cancel.button',
        approve: '.add.button'
      },
      onApprove: () => {
        return submit_rs()
      },
      onShow: () => {
        $('input[name="risk-share-coverage"]').val(coverage)
        $('#risk-share-form').form('clear')

        $('#rs_dropdown').html(`
          <label class="label-title">Facility</label>
          <div class="ui fluid selection dropdown" id="select-rs-facility">
            <input type="hidden" name="risk-share-facility">
            <i class="dropdown icon"></i>
            <div class="default text">Select Facility</div>
            <div class="menu">
            </div>
          </div>
        `)

        $('#select-rs-facility').dropdown({
          apiSettings: {
            url: `/web/products/load_dropdown_facilities?type=${type}&facilities=${fa_ids}&provider_access=${provider_access}&selected_lt_codes=${selected_rs_codes}`
          }
        })

        initialize_rs_validation_integer()
      }
    })
    .modal('show')

    $('#select-rs').dropdown({
      onChange: (value, text, $choice) => {
        if (value == "copayment") {
          $('#lbl-risk-share-value').text('PHP')
          initialize_rs_validation_decimal()
        } else if (value == "coinsurance") {
          $('#lbl-risk-share-value').text('%')
          initialize_rs_validation_integer()
        }
      }
    })
  })

  $('#select-rs').dropdown({
    onChange: (value, text, $choice) => {
      if (value == "copayment") {
        $('#lbl-risk-share-value').text('PHP')
        initialize_rs_validation_decimal()
      } else if (value == "coinsurance") {
        $('#lbl-risk-share-value').text('%')
        initialize_rs_validation_integer()
      }
    }
  })

  $('.coverage_form').form({
    on: 'blur',
    inline: true,
    fields: {
      // limit_threshold: {
      //   identifier: 'limit_threshold',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter a limit threshold facility.'
      //   }]
      // },
      // af_rs: {
      //   identifier: 'af_rs',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter a risk share.'
      //   }]
      // },
      // af_value: {
      //   identifier: 'af_value',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter a risk share value.'
      //   }]
      // },
      // af_cars: {
      //   identifier: 'af_cars',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter coverage after risk share value.'
      //   }]
      // },
      // naf_rs: {
      //   identifier: 'naf_rs',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter a risk share.'
      //   }]
      // },
      // naf_value: {
      //   identifier: 'naf_value',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter a risk share value.'
      //   }]
      // },
      // naf_cars: {
      //   identifier: 'naf_cars',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter coverage after risk share value.'
      //   }]
      // },
      // naf_reimbursable: {
      //   identifier: 'naf_reimbursable',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter reimbursable value.'
      //   }]
      // },
      coverage_type: {
        identifier: 'coverage_type',
        rules: [{
          type: 'empty',
          prompt: 'Please enter coverage type.'
        }]
      },
      fa_tbl: {
        identifier: 'fa_tbl',
        rules: [{
          type: 'empty',
          prompt: 'Please select atleast one facility.'
        }]
      },

      funding_arrangement_type: {
        identifier: 'funding_arrangement_type',
        rules: [{
          type: 'empty',
          prompt: 'Please enter funding arrangement type.'
        }]
      },
      // 'product[copay_rss]': {
      //   identifier: 'product[copay_rss]',
      //   rules: [{
      //     type: 'checked',
      //     prompt: 'Select risk share type.'
      //   }]
      // },
      // 'product[special_handling_type]': {
      //   identifier: 'product[special_handling_type]',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please select special handling.'
      //   }]
      // },
      'product[dentl][type]': {
        identifier: 'product[dentl][type]'
        // rules: [{
        //   type: 'checked',
        //   prompt: 'Please select facility.'
        // }]
       },
      'product[dental_group_type]': {
        identifier: 'product[dental_group_type]',
        rules: [{
          type: 'empty',
          prompt: 'Please select Dental Group.'
        }]
      }
    }
  })

  const initialize_special_handling_validation_rs_coinsurance = () => {
    $.fn.form.settings.rules.checkZeroVal = param => {
   let coinsurance_val = $('input[name="product[coinsurance]"]').val();
   if (coinsurance_val == 0) {
          return false
        } else {
         return true
        }
      }
    $('.coverage_form').form({
      on: 'blur',
      inline: true,
      fields: {
       'product[copay_rss]': {
        identifier: 'product[copay_rss]',
        rules: [
          {
            type   : 'checked',
            prompt : 'Please select an option'
          }
        ]
       },
       'product[dentl][type]': {
        identifier: 'product[dentl][type]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please select facility.'
          }
        ]
       },
       'product[coinsurance]': {
        identifier: 'product[coinsurance]',
        rules: [{
            type: 'empty',
             prompt: 'Please enter coinsurance.'
           },
          {
             type: 'checkZeroVal[param]',
             prompt: 'Cant accept 0 amount.'
           }]
        },
         fa_tbl: {
        identifier: 'fa_tbl',
        rules: [{
          type: 'empty',
          prompt: 'Please select atleast one facility.'
        }]
      }
      }
    })
  }

  const initialize_special_handling_validation_rs_copay = () => {
   $.fn.form.settings.rules.checkZeroVal = param => {
     let copay_val = $('input[name="product[copay]"]').val();
  if (copay_val == 0) {
           return false
        } else {
         return true
        }
      }
    $('.coverage_form').form({
      on: 'blur',
      inline: true,
      fields: {
       'product[copay_rss]': {
        identifier: 'product[copay_rss]'
        // rules: [
        //   {
        //     type   : 'checked',
        //     prompt : 'Please select an option'
        //   }
        // ]
       },
       'product[dentl][type]': {
        identifier: 'product[dentl][type]'
        // rules: [
        //   {
        //     type: 'checked',
        //     prompt: 'Please select facility.'
        //   }
        // ]
       },
       'product[copay]': {
           identifier: 'product[copay]',
           rules: [{
             type: 'empty',
             prompt: 'Please enter copay amount.'
           },
          {
            type: 'checkZeroVal[param]',
            prompt: 'Cant accept 0 amount.'
          }]
         },
         fa_tbl: {
        identifier: 'fa_tbl',
        rules: [{
          type: 'empty',
          prompt: 'Please select atleast one facility.'
        }]
      }
      }
    })
  }

  const initialize_special_handling_validation_dropdown = () => {
    $('.coverage_form').form({
      on: 'blur',
      inline: true,
      fields: {
       'product[special_handling_type]': {
        identifier: 'product[special_handling_type]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please select one Special handling'
          }
        ]
       }
      }
    })
  }

  const disabling_special_handling_validation_dropdown = () => {
     $.fn.form.settings.rules.returnTrue = param => {
        return true;
      }

    $('.coverage_form').form({
      on: 'blur',
      inline: true,
      fields: {
       'product[special_handling_type]': {
        identifier: 'product[special_handling_type]',
        rules: [
          {
            type   : 'returnTrue[param]',
            prompt : 'Please select one Special handling'
          }
        ]
       }
      }
    })
  }

 const disabling_special_handling_validation_rs_copay = () => {
 $.fn.form.settings.rules.returnTrue = param => {
        return true;
      }
    $('.coverage_form').form({
      on: 'blur',
      inline: true,
      fields: {
       'product[copay_rss]': {
        identifier: 'product[copay_rss]',
        rules: [
          {
            type   : 'returnTrue[param]',
            prompt : 'Please select an option'
          }]
        }
      },
      'product[copay_rss]': {
        identifier: 'product[copay_rss]',
        rules: [
          {
            type   : 'checked',
            prompt : 'Please select an option'
          }
        ]
       }
    })
  }


  $('.btn_submit').click(function () {
    let key = true
    let key2 = true
    if ($('#product_special_handling_type option:selected').val() != "") {
    if ($('input[name="product[copay_rss]"]:checked').val() === "Coinsurance") {
     initialize_special_handling_validation_rs_coinsurance()
    } else {
     initialize_special_handling_validation_rs_copay()
      if(!$('input[name="product[copay_rss]"]').is(':checked')){
        key = false
        $('div[id="error_div"]').remove()
        $('#copay_b').find("label").css({"color":"#9F3A38","border-color":"#DB2828"})
        $('#coinsurance_b').find("label").css({"color":"#9F3A38","border-color":"#DB2828"})
        $('div[id="radio_rs"]').append("<div id='error_div' style='background-color:#FFF6F6; color:#9F3A38'><p>Please select special risk share type</p></div>")
      } else {
        key = true
        $('div[id="error_div"]').remove()
        $('#copay_b').find("label").css({"color":"#000000","border-color":"#FFFFFF"})
        $('#coinsurance_b').find("label").css({"color":"#000000","border-color":"#FFFFFF "})
      }
    }
  }
    let dental_grp = $('div[id="dental_grp"]').attr('class')
    let dental_fclt = $('div[id="dental_fclt"]').attr('class')
      if(!dental_fclt.includes("checked") && !dental_grp.includes("checked")){
        key2 = false
        $('div[id="error_div2"]').remove()
        $('.coverage_type_radio').find("label").css({"color":"#9F3A38","border-color":"#DB2828"})
        $('div[id="radio_df"]').append("<div id='error_div2' style='background-color:#FFF6F6; color:#9F3A38'><p>Please select dental facilities</p></div>")
      } else {
        key2 = true
        $('div[id="error_div2"]').remove()
        $('.coverage_type_radio').find("label").css({"color":"#000000","border-color":"#FFFFFF "})
      }


    if ($('#asdf_type').val().includes("Copay")){
      if ($('.coverage_type_radio').find('input:checked').val() == "Specific Facilities"){
        var coverage = ($('.coverage_type_radio').attr('coverage'))
        let table = $('#dentl_fa_tbl').DataTable()
        if(table.data().count() == 0 ){
          $(`#fa_tbl`).val('')
        }
      }
    }

    else if ($('#asdf_type').val().includes("Coinsurance")){
      if ($('.coverage_type_radio').find('input:checked').val() == "Specific Facilities"){
        var coverage = ($('.coverage_type_radio').attr('coverage'))
        let table = $('#dentl_fa_tbl').DataTable()
        if(table.data().count() == 0 ){
          $(`#fa_tbl`).val('')
        }
      }
    }

    if ($('#fa_tbl').attr('pc_type') == "exception") {
      $('#fa_tbl').val('true')
    }

    let validation_result = $('.coverage_form').form('validate form')

    if (Array.isArray(validation_result)) {
      if (jQuery.inArray(false, validation_result) == -1) {
        $('#product_coverage_form').submit()
      } else {
        alertify.error('Please fill-up all missing fields')
      }
    } else {
      if (validation_result && key) {
        $('#product_coverage_form').submit()
      }
    }
  })

  $('.risk_share_type').on('change', function () {
    let value = $(this).dropdown('get value')
    let coverage = $(this).find('select').attr('coverage')
    $(`#${coverage}_rs_value`).prop('readonly', false)

    switch (value) {
      case "Copay":
        maskDecimal.mask(`#${coverage}_rs_value`)
        $(`#${coverage}_rs_value_sign`).text("PHP")
        break
      case "CoInsurance":
        maskPercentage.mask(`#${coverage}_rs_value`)
        $(`#${coverage}_rs_value_sign`).text("%")
        break
      default:
        maskPercentage.mask(`#${coverage}_rs_value`)
        $(`#${coverage}_rs_value_sign`).text("%")
        break
    }
  })

  $('.ui.modal.sf')
  .modal({
    autofocus: false,
    closable: false,
    selector: {
      deny: '.cancel.button',
      approve: '.add.button'
    }
  })
  .modal('attach events', '.modal-open-rsf')

  $('.ui.modal.af')
  .modal({
    autofocus: false,
    closable: false,
    selector: {
      deny: '.cancel.button',
      approve: '.add.button'
    }
  })
  .modal('attach events', '.modal-open-raf')

  if ($('#asdf_type').val().includes("Copay")){
    $('#copay_radio').prop("checked", true)
    $('.copay-type').removeClass('hidden')
  }

  if ($('#asdf_type').val().includes("Coinsurance")){
    $('#coinsurance_radio').prop("checked", true)
    $('.coninsurance-type').removeClass('hidden')
  }


  $('input[id="edit_copay_rss"]').keydown(function (evt) {
    var value = $('input[id="edit_copay_rss"]').val()

    var selection = window.getSelection();
    if(evt.key == '.' || value.includes('.')) {
      if (value.length == 13 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    } else {
      if(value.length > 9 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    }
  })

  $('input[id="edit_coinsurance_rss"]').keydown(function (evt) {
    var value = $('input[id="edit_coinsurance_rss"]').val()
    if(evt.key != '.' || !value.includes('.')) {
      if (value.length == 3 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Backspace" && evt.key != "Delete" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
      if(value.length == 2 && evt.key != "Backspace" && evt.key != "Delete" && evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        $('input[id="edit_coinsurance_rss"]').val(100)
      }
    }
  })

  maskDecimal.mask($("#edit_copay_rss"))

  $('input[id="product_copay"]').keydown(function (evt) {
    var value = $('input[id="product_copay"]').val()

    var selection = window.getSelection();
    if(evt.key == '.' || value.includes('.')) {
      if (value.length == 10 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    } else {
      if(value.length > 6 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
    }
  })

  $('input[id="product_coinsurance"]').keydown(function (evt) {
    var value = $('input[id="product_coinsurance"]').val()
    if(evt.key != '.' || !value.includes('.')) {
      if (value.length == 3 || evt.key == "-") {
        if(evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        }
      }
      if(value.length == 2 && evt.key != "Backspace" && evt.key != "Delete" && evt.key!="ArrowLeft" && evt.key != "ArrowRight" && evt.key != "Control" && evt.key != "a" && window.getSelection().toString() == ""){
          evt.preventDefault();
        $('input[id="product_coinsurance"]').val(100)
      }
    }
  })


  $('#product_dental_group_type').change(function () {
    let loc_group = $('#product_dental_group_type').val();

    if (loc_group == "") {
      $('#btnAddRiskShare').addClass('disabled')
    } else {
      $('#btnAddRiskShare').removeClass('disabled')
    }
  })

  // $('.edit_risk_share').click(function () {

  //   let facility_id = $(this).attr("facility_id")
  //   let facility_code = $(this).attr("facility_code")
  //   let facility_name = $(this).attr("facility_name")
  //   let facility_sdftype = $(this).attr("facility_sdftype")
  //   let facility_sftamount = $(this).attr("facility_sftamount")
  //   let facility_s_handling = $(this).attr("facility_s_handling")
  //   let pcdrs_id2 = $(this).attr("pcdrs_id")

  //   let f_code_name = facility_code + " " + facility_name;

  //   if (facility_s_handling == "") {
  //     facility_s_handling = 'N/A'
  //   } else {
  //     facility_s_handling
  //   }

  //   let f_code = $(`span[class="${facility_code}"]`).text()
  //   let f_name = $(`span[class="${facility_name}"]`).text()
  //   let f_sdftype = $(`span[class="${facility_code}${facility_sdftype}"]`).text().trim()
  //   let f_sftamount = $(`span[class="${facility_code}${facility_sftamount}"]`).text().trim()
  //   let f_s_handling = $(`span[class="s_handling_${facility_code}${facility_s_handling}"]`).text().replace(/ /g,'')

  //   if (f_s_handling == "") {
  //     f_s_handling = $(`span[class="s_handling_${facility_code}"]`).text('N/A')
  //   } else {
  //     f_s_handling
  //   }

  //   $('text[id="rs_facility_code"]').text(f_code_name);
  //   $("input[id='edit_s_handling']").val(f_s_handling)
  //   $("input[id='edit_amount_type']").val(f_sdftype)
  //   $("select[id='edit_special_handling_dropdown_rss'] option:selected").val(f_s_handling).change();
  //   $("input[name='product[edit_facility_risk_share_type]']:checked"). val(f_sdftype);
  //   $('input[name="edit_copay_textbox"]').val(f_sftamount)
  //   $('input[id="edit_rs_amount"]').val(f_sftamount)

  //   $('.modal.edit_risk_share_setup').modal({
  //     autofocus: false,
  //     closable: false,
  //     observeChanges: true,
  //     selector: {
  //       deny: '.deny.button',
  //       approve: '.approve.button'
  //     },
  //     onApprove: () => {

  //       $(`span[class="${facility_code}${facility_sdftype}"]`).text("")
  //       $(`span[class="s_handling_${facility_code}"]`).text("")
  //       $(`span[class="${facility_code}${facility_sftamount}"]`).text("")
  //       $(`span[class="s_handling_${facility_code}${facility_s_handling}"]`).text("")
  //       $(`span[class="${facility_code}_rows selected_ben_rows hidden"]`).val("")

  //       let updated_rs_amount_copay = $('input[name="edit_copay_textbox"]').val().replace(/,/g,"");
  //       let updated_rs_amount_coinsurance = $('input[name="edit_coinsurance_textbox"]').val().replace(/,/g,"");
  //       let update_rs_type = $("input[name='product[edit_facility_risk_share_type]']:checked").val()
  //       let update_s_handling = $("select[id='edit_special_handling_dropdown_rss'] option:selected").val();

  //       $(`span[class="${facility_code}${facility_sdftype}"]`).text(update_rs_type)

  //       if(update_rs_type == "Copay") {
  //         $(`span[class="${facility_code}${facility_sftamount}"]`).text(updated_rs_amount_copay)
  //       } else if(update_rs_type == "Coinsurance") {
  //         $(`span[class="${facility_code}${facility_sftamount}"]`).text(updated_rs_amount_coinsurance)
  //       }

  //       if (update_s_handling == '[object Object]') {
  //         $(`span[class="s_handling_${facility_code}"]`).text('N/A')
  //       } else {
  //         $(`span[class="s_handling_${facility_code}"]`).text(update_s_handling)
  //       }

  //       $(`span[class="s_handling_${facility_code}${facility_s_handling}"]`).text(update_s_handling)

  //       if(update_rs_type == "Copay") {
  //         $(`span[class="${facility_code}_rows selected_ben_rows hidden"]`).text(`${facility_id}|${updated_rs_amount_copay}|${update_rs_type}|${update_s_handling}`)
  //       } else if(update_rs_type == "Coinsurance") {
  //         $(`span[class="${facility_code}_rows selected_ben_rows hidden"]`).text(`${facility_id}|${updated_rs_amount_coinsurance}|${update_rs_type}|${update_s_handling}`)
  //       }

  //       var table = $('#risk-share-dt').DataTable()
  //       var rows = table.rows({'search': 'applied'}).nodes();

  //       let selected_ben_rows = [];

  //       $('.selected_ben_rows', rows).each(function (){
  //         selected_ben_rows.push($(this).text())
  //       })

  //       $('input[name="product[risk_share_datas][]"]').val(Array.from(new Set(selected_ben_rows)))

  //       let selected_facility_ids = [];

  //       $('.selected_pcdrsf', rows).each(function() {
  //         selected_facility_ids.push($(this).text())
  //       })

  //       $('input[name="product[facility_ids_rs][]"]').val(Array.from(new Set(selected_facility_ids)))


  //       let pcdrs_id = $('input[name="product[pcdrs_id]"]').val()

  //       let validate_form = $('#coverage-facility').form('validate form')
  //       if (validate_form){
  //         $('#coverage-facility').submit()
  //       }

  //       if (update_rs_type == "Copay") {
  //         var data = {
  //           fac_id: facility_id,
  //           fac_sdftype: update_rs_type,
  //           fac_sftamount: updated_rs_amount_copay,
  //           fac_s_handling: update_s_handling,
  //        }
  //       } else if (update_rs_type == "Coinsurance") {
  //         var data = {
  //           fac_id: facility_id,
  //           fac_sdftype: update_rs_type,
  //           fac_sftamount: updated_rs_amount_coinsurance,
  //           fac_s_handling: update_s_handling,
  //        }
  //       }

  //       $.ajax({
  //         url:`/web/products/${pcdrs_id2}/update_product_risk_share`,
  //         data: data,
  //         type: 'put',
  //         success: function(response){
  //           alert('ok')
  //         }
  //       });

  //       $('#edit_risk_share_form').form('validate form')

  //     },
  //     onVisible: _ => {
  //       $('.modal.edit_risk_share_setup')
  //       .modal('refresh')
  //     }
  //   }).modal('show')

  // })

  $('.radio_edit_risk_share_setup').on('change', function () {
    let value = $(this).find('input').val()

    if (value == "Copay") {
      $('.edit-copay-risk-share-setup-textbox').removeClass('hidden')
      $('input[name="edit_coinsurance_textbox"]').prop('disabled', true)
      $('input[name="edit_copay_textbox"]').prop('disabled', false)

    } else {

      $('.edit-copay-risk-share-setup-textbox').addClass('hidden')
      $('input[name="edit_copay_textbox"]').val('')
      $('.edit-copay-risk-share-setup-textbox').parent().removeClass('error')
      $('.edit-copay-risk-share-setup-textbox').parent().find('.prompt').remove()
      $('input[name="edit_copay_textbox"]').prop('disabled', false)

    }

    if (value == "Coinsurance") {

      $('.edit-coinsurance-risk-share-setup-text').removeClass('hidden')
      $('input[name="edit_copay_textbox"]').prop('disabled', true)
      $('input[name="edit_coinsurance_textbox"]').prop('disabled', false)

    } else {

      $('.edit-coinsurance-risk-share-setup-text').addClass('hidden')
      $('input[name="edit_coinsurance_textbox"]').val('')
      $('.edit-coinsurance-risk-share-setup-text').parent().removeClass('error')
      $('.edit-coinsurance-risk-share-setup-text').parent().find('.prompt').remove()
      $('input[name="edit_coinsurance_textbox"]').prop('disabled', false)

    }

  })

  $('#edit_risk_share_form').form({
    on: 'blur',
    inline: true,
    fields: {
      'edit_copay_textbox': {
        identifier: 'edit_copay_textbox',
        rules: [
          {
            type: 'empty',
            prompt: 'Enter risk share amount.'
          }
        ]
      },
      'edit_coinsurance_textbox': {
        identifier: 'edit_coinsurance_textbox',
        rules: [
          {
            type: 'empty',
            prompt: 'Enter risk share amount.'
          }
        ]
      }
    }
  })

});

let location_group_id;
onmount('a[id="backDental"]', function () {
  $('#backDental').on('click', function () {
    $('input[name="product[backButtonFacility]"]').val('true')
    location_group_id = $('#product_dental_group_type').dropdown('get value')
    $('input[name="product[location_group_id]"]').val(location_group_id)
    $('#product_coverage_form').form()
    $('#product_coverage_form').submit()
  })
});

onmount('button[id="btnDraft"]', function () {
  if ($('input[name="product[dentl][type]"]').is(':checked') == false) {
    $('#dentl_add_fa_btn').addClass('disabled')
  }
});

// onmount('div[id="coverage-facility"]', function(){
//   let im = new Inputmask("numeric", {
//     radixPoint: ".",
//     groupSeparator: ",",
//     digits: 2,
//     autoGroup: true,
//     rightAlign: false
//     // oncleared: function () {
//     // self.Value('');
//     // }
//   })
//   // document.getElementById('product_limit_amt').setAttribute("maxLength","10")
//   im.mask($('span[role="mask-decimal"]'));
//   // im.mask($('#capitation_fee'));
// });


// START OF APPEND FACILITY INCLUSION
function append_facility_inclusion() {
  $('#dentl_fa_tbl').remove()
  $('#dentl_fa_tbl_wrapper').remove()
  $('#dentl_lt_tbl').remove()
  $('#dentl_lt_tbl_wrapper').remove()
  $('#append-facility-inclusion').append('<table class="full-width ui celled striped table dental-inclusion" id="dentl_fa_tbl">\
      <thead>\
        <tr>\
          <th width="15%">Code</th>\
          <th>Name</th>\
          <th>Address</th>\
          <th>Group</th>\
          <th></th>\
        </tr>\
      </thead>\
      <tbody>\
      </tbody>\
    </table>')

  let product_id = $('#product_id').val()
  let datatable = $('#dentl_fa_tbl')
  let ajax = `/web/products/dental_facility/data?product_id=${product_id}`

    const csrf = $('input[name="_csrf_token"]').val();
    datatable.DataTable({
      "dom":
        "<'ui grid'"+
          "<'row'"+
            "<'three wide column'f>"+
            "<'eight wide column'i>"+
          ">"+
          "<'row dt-table'"+
            "<'sixteen wide column'tr>"+
          ">"+
          "<'row'"+
            "<'nine wide column'l>"+
            "<'right aligned four wide column'p>"+
          ">"+
        ">",
      "ajax": {
        "url": ajax,
        "headers": { "X-CSRF-TOKEN": csrf },
        "type": "get"
      },
      "renderer": 'semanticUI',
      "pagingType": "full_numbers",
      "language": {
        "emptyTable":     "No records found",
        "zeroRecords":    "No records found",
        "info": "_TOTAL_",
        "infoEmpty": "",
        "lengthMenu": "Show: _MENU_",
        "search": "",
        "paginate": {
          "previous": "<i class='angle single left icon'></i>",
          "next": "<i class='angle single right icon'></i>",
        }
      },
        "drawCallback": function () {
        add_search(this)
        var table = datatable.DataTable();
        var info = table.page.info();
          append_jump_inclusion(info.page, info.pages)

        $('.remove_facility').on('click', function (e) {
          e.preventDefault()
          let pcf_id = $(this).attr('product_coverage_facility_id')
          let product_id = $(this).attr('product_id')
          let type = $(this).attr('pc_type')

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
            var count = $('#dental_fa_tbl>tbody>tr').length;

            if (count === 1 && type === 'inclusion') {
              $('.ajs-message.ajs-error.ajs-visible').remove()
              alertify.error('<i class="close icon"></i>Cannot delete all facility')
            } else {
                $.ajax({
                  url: `/web/products/delete/${pcf_id}/${product_id}/product_coverage`,
                  headers: {
                    "X-CSRF-TOKEN": csrf
                  },
                  type: 'get',
                  success: function(response) {
                    let dt = $('#dentl_fa_tbl').DataTable();
                    let row = $(this).closest('tr')

                    dt.row(row)
                    .remove()
                    .draw()
                    row.remove()
                  }
              })
            }
          })
        })
        $(document).unbind('change').on('change', '#jump3', function(){
          let page = $('#jump3_search > div > div.text').html()
          var table = datatable.DataTable();
          let no = parseInt(page) -1
          table.page( no ).draw( 'page' );
        })
      },
        "processing": true,
        "serverSide": true,
        "deferRender": true
    });

    function append_jump_inclusion(page, pages){
      let results = $(`#dentl_fa_tbl >tbody >tr`).length
      $('.table > tbody  > tr').each(function(){
        $(this).attr('style', 'height:50px')
      })
      $('#dentl_fa_tbl_first').hide()
      $('#dentl_fa_tbl_last').hide()
      $('#jump3_page').remove()
      $('#jump3_search').remove()
      $('#show2').remove()

      $('#dentl_fa_tbl_length').find('label').before(`<span id="show2" style="margin-right:30px"> Showing ${results} results</span>`)
      $("#dentl_fa_tbl_paginate").parent().parent().append(
      `<div class="right aligned two wide column inline field" id="jump3_page" style="padding-top:10px"> Jump to page: </div>\
      <div class="right aligned one wide column inline field" id="jump3_search">\
        <select class="ui fluid search dropdown" id="jump3">\
        </select>\
      </div>`
      )

      let results1 = $(`#dentl_fa_tbl >tbody >tr`).length
      $('.table > tbody  > tr').each(function(){

         if(results1 == 1){
           if($(`#dentl_fa_tbl >tbody >tr >td.dataTables_empty`).length > 0){
            $('#show2').text('Showing 0 results');
           }
          else{
            $('#show2').text(`Showing ${results1} results`);
           }
          }
          else{
            $('#show2').text(`Showing ${results1} results`);
          }
        $(this).attr('style', 'height:50px')
      })


      var select = $('#jump3')
      var options = []
      for(var x = 1; x < parseInt(pages) + 1; x++){
          options.push(`<option value='${x}'>${x}</option>`)
      }
      select.append(String(options.join('')))
      $('.ui.fluid.search.dropdown').dropdown()
      $('#jump3').dropdown('set selected', page + 1)

      $(document).find('input[class="search"]').keypress(function(evt) {
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

    function remove_datatable(){
      $('#dentl_fa_tbl_info').hide()
      $('#dentl_fa_tbl_paginate').hide()
      $('#dentl_fa_tbl_length').hide()
    }
}

// END OF APPEND FACILITY INCLUSION

// START OF APPEND FACILITY EXCEPTION
function append_facility_exception() {
  $('#dentl_fa_tbl').remove()
  $('#dentl_fa_tbl_wrapper').remove()
  $('#dentl_lt_tbl').remove()
  $('#dentl_lt_tbl_wrapper').remove()

  $('#append-facility-exclusion').append('<table class="full-width ui celled striped table dental-exclusion" id="dentl_lt_tbl">\
      <thead>\
        <tr>\
          <th width="15%">Code</th>\
          <th>Name</th>\
          <th>Address</th>\
          <th>Group</th>\
          <th></th>\
        </tr>\
      </thead>\
      <tbody>\
      </tbody>\
    </table>')

  let product_id = $('#product_id').val()
  let datatable = $('#dentl_lt_tbl')
  let ajax = `/web/products/dental_facility/data?product_id=${product_id}`

    const csrf = $('input[name="_csrf_token"]').val();
    datatable.DataTable({
      "dom":
        "<'ui grid'"+
          "<'row'"+
            "<'three wide column'f>"+
            "<'eight wide column'i>"+
          ">"+
          "<'row dt-table'"+
            "<'sixteen wide column'tr>"+
          ">"+
          "<'row'"+
            "<'nine wide column'l>"+
            "<'right aligned four wide column'p>"+
          ">"+
        ">",
      "ajax": {
        "url": ajax,
        "headers": { "X-CSRF-TOKEN": csrf },
        "type": "get"
      },
      "renderer": 'semanticUI',
      "pagingType": "full_numbers",
      "language": {
        "emptyTable":     "No records found",
        "zeroRecords":    "No records found",
        "info": "_TOTAL_",
        "infoEmpty": "",
        "lengthMenu": "Show: _MENU_",
        "search": "",
        "paginate": {
          "previous": "<i class='angle single left icon'></i>",
          "next": "<i class='angle single right icon'></i>",
        }
      },
        "drawCallback": function () {
        add_search(this)
        var table = datatable.DataTable();
        var info = table.page.info();
        append_jump_exception(info.page, info.pages)

        $('.remove_facility').on('click', function (e) {
          e.preventDefault()
          let pcf_id = $(this).attr('product_coverage_facility_id')
          let product_id = $(this).attr('product_id')
          let type = $(this).attr('pc_type')

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
            var count = $('#dental_fa_tbl>tbody>tr').length;


            if (count === 1 && type === 'inclusion') {
              $('.ajs-message.ajs-error.ajs-visible').remove()
              alertify.error('<i class="close icon"></i>Cannot delete all facility')
            } else {
                $.ajax({
                  url: `/web/products/delete/${pcf_id}/${product_id}/product_coverage`,
              // window.location.replace(`/web/products/delete/${pcf_id}/${product_id}/product_coverage`);
                  headers: {
                    "X-CSRF-TOKEN": csrf
                  },
                  type: 'get',
                  success: function(response) {
                    let dt = $('#dentl_lt_tbl').DataTable();
                    let row = $(this).closest('tr')

                    dt.row(row)
                    .remove()
                    .draw()
                    row.remove()
                  }
              })
            }
          })
        })

        $(document).unbind('change').on('change', '#jump3', function(){
          let page = $('#jump3_search > div > div.text').html()
          var table = datatable.DataTable();
          let no = parseInt(page) -1
          table.page( no ).draw( 'page' );
        })

        function remove_datatable(){
          $('#dentl_lt_tbl_info').hide()
          $('#dentl_lt_tbl_paginate').hide()
          $('#dentl_lt_tbl_length').hide()
        }
      },
        "processing": true,
        "serverSide": true,
        "deferRender": true
    });

    function append_jump_exception(page, pages){
      $('#dentl_lt_tbl_first').hide()
      $('#dentl_lt_tbl_last').hide()
      $('#jump3_page').remove()
      $('#jump3_search').remove()
      $('#show2').remove()

      $('#dentl_lt_tbl_length').find('label').before(`<span id="show2" style="margin-right:30px"> Showing ${results} results</span>`)
      $("#dentl_lt_tbl_paginate").parent().parent().append(
      `<div class="right aligned two wide column inline field" id="jump3_page" style="padding-top:10px"> Jump to page: </div>\
      <div class="right aligned one wide column inline field" id="jump3_search">\
        <select class="ui fluid search dropdown" id="jump3">\
        </select>\
      </div>`
      )

      let results = $(`#dentl_lt_tbl >tbody >tr`).length
      $('.table > tbody  > tr').each(function(){

         if(results == 1){
           if($(`#dentl_lt_tbl >tbody >tr >td.dataTables_empty`).length > 0){
            $('#show2').text('Showing 0 results');
           }
          else{
            $('#show2').text(`Showing ${results} results`);
           }
          }
          else{
            $('#show2').text(`Showing ${results} results`);
          }
        $(this).attr('style', 'height:50px')
      })

      var select = $('#jump3')
      var options = []
      for(var x = 1; x < parseInt(pages) + 1; x++){
          options.push(`<option value='${x}'>${x}</option>`)
      }
      select.append(String(options.join('')))
      $('.ui.fluid.search.dropdown').dropdown()
      $('#jump3').dropdown('set selected', page + 1)

      $(document).find('input[class="search"]').keypress(function(evt) {
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
}
// END OF APPEND FACILITY EXCEPTION

function add_search(table){
  let id = table[0].getAttribute("id")
  let value = $(`#${id}_filter`).val()
  let results = $(`#${id} >tbody >tr`).length
  let total = $(`#${id}_info`).html()

  if(results == 1){
    if($(`#${id} >tbody >tr >td.dataTables_empty`).length > 0){
      $(`#${id}_info`).html(`Showing 0 out of 0 results`)
    }
    else{
      $(`#${id}_info`).html(`Showing ${results} out of ${total} results`)
    }
  }
  else{
    $(`#${id}_info`).html(`Showing ${results} out of ${total} results`)
  }

  if(value != 1){
    $(`#${id}_filter`).addClass('ui left icon input')
    $(`#${id}_filter`).find('label').after('<i class="search icon"></i>')
    $(`#${id}_filter`).find('input[type="search"]').unwrap()
    $(`#${id}_filter`).find('input[type="search"]').attr("placeholder", `Search Facility`)
    $(`#${id}_filter`).find('input[type="search"]').append(`</div>`)
    $(`#${id}_filter`).val(1)
  }
}
function formatRiskAmount(n){
    var c = isNaN(c = Math.abs(c)) ? 2 : c,
    d = d == undefined ? "." : d,
    t = t == undefined ? "," : t,
    s = n < 0 ? "-" : "",
    i = String(parseInt(n = Math.abs(Number(n) || 0).toFixed(c))),
    j = (j = i.length) > 3 ? j % 3 : 0;

    return s + (j ? i.substr(0, j) + t : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : "");
}
