onmount('div[id="product_facilities"]', function () {

  let f_array = [];
  let v_array = [];
  let aaf_array = [];
  let sf_array = [];
  let region_array = [];

  let last_c_id = $('#last_coverage_id').val();
  let last_opened_modal_id = '#coverage_type_' + last_c_id;
  let last_opened_modal = $(last_opened_modal_id).val();

  function indicate(coverage_id, inclusion){
    let table_id = '#product_facility_table_' + coverage_id;
    let table_condition = table_id + ' tr:contains("No Records Found!")';
    let fp_tbl = $(table_condition).length;
    let aaf_id = 'aaf_' + coverage_id;
    let sf_id = 'sf_' + coverage_id;
    let text_id = '#modal_button_label_' + coverage_id;
    if(inclusion == 'exception'){
      document.getElementById(aaf_id).checked = true;
      $(text_id).text('EXCEPTION');
    } else if(inclusion == 'inclusion'){
      document.getElementById(sf_id).checked = true;
      $(text_id).text('INCLUSION');
    }
  }

  indicate(last_c_id, last_opened_modal);

  const unique_value = (array) => {
    return array.filter((v, i, a) => a.indexOf(v) === i)
  }

  $('#confirmation_cancel').click(function(){
    let c_id = $('#confirmation_coverage_id').val();
    let indicator_id = '.indicator_' + c_id;
    let inclusion = $(indicator_id).first().text();
    indicate(c_id, inclusion);
  });

  $('#confirmation_submit').click(function(){
    let product_coverage_id = $('#confirmation_product_coverage_id').val();
    let product_id = $('#confirmation_product_id').val();
    let coverage_id = $('#confirmation_coverage_id').val();
    let last_active = $('#confirmation_last_active').val();
    let csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/products/${product_coverage_id}/deleting_product_facilities/`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'DELETE',
      success: function(response){
        let obj = JSON.parse(response)
        location.reload()
      }
    });

    if(last_active == 'aaf'){
      saveCoverageType(product_coverage_id, csrf, "exception", product_id, coverage_id);
    } else if(last_active == 'sf'){
      saveCoverageType(product_coverage_id, csrf, "inclusion", product_id, coverage_id);
    }
  });

  $('#facility_submit').click(function(){
    let selected_facility = $('input[name="product[facility_ids_main]').val();
    if(selected_facility == ""){
      $('#p_facilities').modal({autofocus: false}).modal('show');
    }
  });

  $('#product_facility_modal_submit').click(function(){
    $('#confirmation_facility').modal('show');
  });

  $('#confirmation_submit_facility').click(function(){
    let product_facility_id = $('#product_facility_id').val();
    let csrf = $('input[name="_csrf_token"]').val();
    let array = [];

    $.ajax({
     url:`/products/${product_facility_id}/deleting_product_facility`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'DELETE',
      success: function(response){
        let obj = JSON.parse(response)
        location.reload();
      }
    });
  });

  $('#confirmation_cancel_facility').click(function(){
    $("#product_facility_modal").modal('show')
  });

  $('a[name="view_facility"]').on('click', function(){
    $('#product_facility_modal').modal('show');
    let product_id = $(this).attr('productID');
    let product_facility_id = $(this).attr('productFacilityID');
    let csrf = $('input[name="_csrf_token"]').val();

    let array = [];

    $.ajax({
      url:`/products/${product_facility_id}/get_product_facilities`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let obj = JSON.parse(response)
        let selector = 'div[role="edit"]';
        let categories;
        if(obj.category == null){
          categories = "";
        } else {
          categories = obj[0].facility.category.text;
        }

        let location_group_name = []
        if(obj[0].facility.facility_location_groups.length > 0) {
          obj[0].facility.facility_location_groups.forEach(function(location_group) {
            location_group_name.push(location_group.location_group.name)
          });
        }

        $(selector).find('#product_facility_id').val(product_facility_id);
        $(selector).find('#code').text(obj[0].facility.code)
        $(selector).find('#name').text(obj[0].facility.name)
        $(selector).find('#type').text(obj[0].facility.type.text)
        $(selector).find('#region').text(obj[0].facility.region)
        $(selector).find('#category').text(obj[0].facility.category.text)
        $(selector).find('#location_group').text(location_group_name.toString())
      }
    });
  });

  $('.aaf').change(function(){
    let product_id = $(this).attr('productID');
    let product_coverage_id = $(this).attr('productCoverageID');
    let coverage_id = $(this).val();
    let table_id = '#product_facility_table_' + coverage_id;
    let table_condition = table_id + ' tr:contains("No Records Found!")';
    let fp_tbl = $(table_condition).length;
    let text_id = '#modal_button_label_' + coverage_id;
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${product_coverage_id}/check_pclt`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let obj = JSON.parse(response)
        console.log(obj)
        let result = obj.result
        if(result != "no_lt"){
          if(result == "has_data"){
            $('#confirmation').modal('show');
            $('#confirmation_product_coverage_id').val(product_coverage_id);
            $('#confirmation_product_id').val(product_id);
            $('#confirmation_coverage_id').val(coverage_id);
            $('#confirmation_last_active').val('aaf');
            $('#confirmation_message').text('Changing of Facility will permanently delete your current selection and all added values in Limit Threshold of Conditions Step.')
          } else {
            if(fp_tbl == 0){
              $('#confirmation').modal('show');
              $('#confirmation_product_coverage_id').val(product_coverage_id);
              $('#confirmation_product_id').val(product_id);
              $('#confirmation_coverage_id').val(coverage_id);
              $('#confirmation_last_active').val('aaf');
              $('#confirmation_message').text('Changing of Facility will permanently delete your current selection.')
            }
          }
        } else {
          if(fp_tbl == 0){
            $('#confirmation').modal('show');
            $('#confirmation_product_coverage_id').val(product_coverage_id);
            $('#confirmation_product_id').val(product_id);
            $('#confirmation_coverage_id').val(coverage_id);
            $('#confirmation_last_active').val('aaf');
            $('#confirmation_message').text('Changing of Facility will permanently delete your current selection.')
          }
        }
      }
    })
    $(text_id).text('EXCEPTION');
    if(this.checked) {
      v_array.push(coverage_id);
      if(fp_tbl != 0){
        saveCoverageType(product_coverage_id, csrf, "exception", product_id, coverage_id);
      }
    }
    $('#coverage_list').val(v_array);
  });

  $('.sf').change(function(){
    let product_id = $(this).attr('productID');
    let product_coverage_id = $(this).attr('productCoverageID');
    let coverage_id = $(this).val();
    let table_id = '#product_facility_table_' + coverage_id;
    let table_condition = table_id + ' tr:contains("No Records Found!")';
    let fp_tbl = $(table_condition).length;
    let text_id = '#modal_button_label_' + coverage_id;
    let csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/products/${product_coverage_id}/check_pclt`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let obj = JSON.parse(response)
        console.log(obj)
        let result = obj.result
        if(result != "no_lt"){
          if(result == "has_data"){
            $('#confirmation').modal('show');
            $('#confirmation_product_coverage_id').val(product_coverage_id);
            $('#confirmation_product_id').val(product_id);
            $('#confirmation_coverage_id').val(coverage_id);
            $('#confirmation_last_active').val('sf');
            $('#confirmation_message').text('Changing of Facility will permanently delete your current selection and all added values in Limit Threshold of Conditions Step.')
          } else {
            if(fp_tbl == 0){
              $('#confirmation').modal('show');
              $('#confirmation_product_coverage_id').val(product_coverage_id);
              $('#confirmation_product_id').val(product_id);
              $('#confirmation_coverage_id').val(coverage_id);
              $('#confirmation_last_active').val('sf');
              $('#confirmation_message').text('Changing of Facility will permanently delete your current selection.')
            }
          }
        } else {
            if(fp_tbl == 0){
              $('#confirmation').modal('show');
              $('#confirmation_product_coverage_id').val(product_coverage_id);
              $('#confirmation_product_id').val(product_id);
              $('#confirmation_coverage_id').val(coverage_id);
              $('#confirmation_last_active').val('sf');
              $('#confirmation_message').text('Changing of Facility will permanently delete your current selection.')
            }
        }
      }
    })
    $(text_id).text('INCLUSION');
    let value = $(this).val();

    if(this.checked) {
      let index = v_array.indexOf(value);
      if (index >= 0) {
        v_array.splice( index, 1)
      }
      if(fp_tbl != 0){
        saveCoverageType(product_coverage_id, csrf, "inclusion", product_id, coverage_id);
      }
    }
    $('#coverage_list').val(v_array);
  });


  function filterRegionACU(product_coverage_id, facilities_array, fa_title, params, f_array, modal_selector, coverage_id){
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${product_coverage_id}/get_pcf_by_region`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      data: {regions: params},
      success: function(response){
        let result = response.result
        let dataSet = []
        for(let facility of result){
          let data_array = []
          data_array.push('<div class="for_input_acu"><input class="inputFacility_acu" style="width:20px;height:20px" type="checkbox" facilityID="' + facility.id + '" name="product[facility_ids][]" value="' + facility.id + '" region="'+ facility.location_group +'" /></div>')
          data_array.push(facility.code)
          data_array.push(facility.name)
          data_array.push(facility.type)
          data_array.push(facility.region)
          data_array.push(facility.category)
          if(facility.location_group.length == 0){
            data_array.push("")
          } else {
            let location_group_name = []
            facility.location_group.forEach(function(location_group) {
              location_group_name.push(location_group.location_group.name)
            });
            data_array.push(location_group_name.toString())
          }
          dataSet.push(data_array)
        }
        $("#modal_pcf_tbl_acu").DataTable( {
          destroy: true,
          data: dataSet,
          "columns": [
            { "title": '<input type="checkbox" style="width:20px;height:20px" id="facility_select_acu" value="false"/>'},
            { "title": "Facility"},
            { "title": "Facility Name"},
            { "title": "Type"},
            { "title": "Region"},
            { "title": "Category"},
            { "title": "Location Group"},
          ]
        });

        let facility_array_ids = '#facilities_' + coverage_id;
        let facilities = $(facility_array_ids).val();
        let facilities_selected_array = facilities.split(',');

        let f_id_array = []
        let current_val = []
        if(params.length == 0){
          modal_selector.find(".inputFacility_acu").each(function () {
            let value = $(this).val();
            current_val.push(value)
          })
          f_id_array = facilities_selected_array.filter(function(n){ return n != ""})
          modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
        } else {
          modal_selector.find(".inputFacility_acu").each(function () {
            let value = $(this).val();
            //if(f_array.includes(value)){
            $(this).prop('checked', true);
            //}
            current_val.push(value)
            facilities_selected_array.push(value)
            f_id_array = facilities_selected_array.filter(function(n){ return n != ""})
            modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
          })
        }

        /*if (current_val.length == 0){
          modal_selector.find('#facility_submit').prop("disabled", true)
        } else{
          modal_selector.find('#facility_submit').prop("disabled", false)
        }*/

        /*let facilities_array = f_array.filter(function(n){ return n != ""})
        let f_id_array = [];
        modal_selector.find(".inputFacility_acu").each(function () {
          let value = $(this).val();
          if($(this).is(':checked') == true){
            f_id_array = facilities_array.concat([value])
          } else {}
          f_id_array = f_id_array.filter(function(n){ return current_val.includes(n) })
          f_id_array = facilities_selected_array.concat(f_id_array)
          f_id_array = f_id_array.filter(function(n){ return n != ""})
          modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
        })*/

        $('.ui.checkbox').checkbox()
        $.each(facilities_array, function(key, value){
          if(value != ""){
            f_array.push(value);
          }
        });

        modal_selector.on('mouseover', function(){
          modal_selector.find(".inputFacility_acu").on('change', function () {
            let value = $(this).val();
            f_array = modal_selector.find('input[name="product[facility_ids_main]"]').val()
            f_array = f_array.split(',')
            if(this.checked) {
              f_array.push(value);
            } else {
              let index = f_array.indexOf(value);
              if (index >= 0) {
                f_array.splice( index, 1)
              }
            }

            //f_array = f_array.filter(function(n){ return current_val.includes(n) })
            //f_array = facilities_selected_array.concat(f_array)
            f_array = f_array.filter(function(n){ return n != ""})
            modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_array));
          });
        })

        /*modal_selector.find("#facility_select_acu").on('change', function () {
          modal_selector.find('input[name="product[facility_ids_main]"]').val("");
          if($(this).is(':checked') == true){
            $(".inputFacility_acu").each(function () {
              $(this).prop('checked', true);
            })
            f_array = facilities_selected_array.concat(f_array)
            f_array = unique_value(f_array)
            modal_selector.find('input[name="product[facility_ids_main]"]').val(f_array);
          } else {
            $(".inputFacility_acu").each(function () {
              let value = $(this).val()
              $(this).prop('checked', false);
            })
            f_array = facilities_selected_array
            f_array = f_array.filter(function(n){ return n != ""})
            f_array = unique_value(f_array)
            modal_selector.find('input[name="product[facility_ids_main]"]').val(f_array);
          }
        }); */
        $(".dimmer_container").removeClass('active')
      }
    })

    modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(facilities_array));
    modal_selector.find('input[name="product[product_coverage_id]"]').val(product_coverage_id);
  }

  function filterRegion(product_coverage_id, facilities_array, fa_title, params, f_array, modal_selector, coverage_id){
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${product_coverage_id}/get_pcf_by_region`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      data: {regions: params},
      success: function(response){
        let result = response.result
        let dataSet = []
        for(let facility of result){
          let data_array = []
          data_array.push('<div class="for_input"><input class="inputFacility" style="height:20px;width:20px" type="checkbox" facilityID="' + facility.id + '" name="product[facility_ids][]" value="' + facility.id + '" region="'+ facility.location_group +'" /></div>')
          data_array.push(facility.code)
          data_array.push(facility.name)
          data_array.push(facility.type)
          data_array.push(facility.region)
          data_array.push(facility.category)
          if(facility.location_group.length == 0){
            data_array.push("")
          } else {
            let location_group_name = []
            facility.location_group.forEach(function(location_group) {
              location_group_name.push(location_group.location_group.name)
            });
            data_array.push(location_group_name.toString())
          }
          dataSet.push(data_array)
        }
        $("#modal_pcf_tbl").DataTable( {
          destroy: true,
          data: dataSet,
          "columns": [
            { "title": '<input type="checkbox" style="width:20px;height:20px" id="facility_select" value="false"/>'},
            { "title": "Facility"},
            { "title": "Facility Name"},
            { "title": "Type"},
            { "title": "Region"},
            { "title": "Category"},
            { "title": "Location Group"},
          ]
        });
        let facility_array_ids = '#facilities_' + coverage_id;
        let facilities = $(facility_array_ids).val();
        let facilities_selected_array = facilities.split(',');

        let f_id_array = []
        let current_val = []
        if(params.length == 0){
          modal_selector.find(".inputFacility").each(function () {
            let value = $(this).val();
            current_val.push(value)
          })
          f_id_array = facilities_selected_array.filter(function(n){ return n != ""})
          modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
        } else {
          modal_selector.find(".inputFacility").each(function () {
            let value = $(this).val();
            //if(f_array.includes(value)){
            $(this).prop('checked', true);
            //}
            current_val.push(value)
            facilities_selected_array.push(value)
            f_id_array = facilities_selected_array.filter(function(n){ return n != ""})
            modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
          })
        }

        /*if (current_val.length == 0){
          modal_selector.find('#facility_submit').prop("disabled", true)
        } else{
          modal_selector.find('#facility_submit').prop("disabled", false)
        }*/

        /*let facilities_array = f_array.filter(function(n){ return n != ""})
        let f_id_array = [];
        modal_selector.find(".inputFacility").each(function () {
          let value = $(this).val();
          if($(this).is(':checked') == true){
            f_id_array = facilities_array.concat([value])
          } else {}
          f_id_array = f_id_array.filter(function(n){ return current_val.includes(n) })
          f_id_array = facilities_selected_array.concat(f_id_array)
          f_id_array = f_id_array.filter(function(n){ return n != ""})
          modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
        })*/

          $('.ui.checkbox').checkbox()
          f_array = []
          $.each(facilities_array, function(key, value){
            if(value != ""){
              f_array.push(value);
            }
          });

        modal_selector.on('mouseover', function(){
          $(document).on('change', '.inputFacility', function () {
            let value = $(this).val();
            f_array = modal_selector.find('input[name="product[facility_ids_main]"]').val()
            f_array = f_array.split(',')

            if(this.checked) {
              f_array.push(value);
            } else {
              let index = f_array.indexOf(value);
              if (index >= 0) {
                f_array.splice( index, 1)
              }
            }
            //f_array = f_array.filter(function(n){ return current_val.includes(n) })
            //f_array = facilities_selected_array.concat(f_array)
            f_array = f_array.filter(function(n){ return n != ""})
            f_array = _.uniq(f_array)
            modal_selector.find('input[name="product[facility_ids_main]"]').val(f_array);
          });
        });

        /*$(document).on('change', '#facility_select', function () {
          if($(this).is(':checked') == true){
            modal_selector.find(".inputFacility").each(function () {
              $(this).prop('checked', true);
              f_array.push($(this).val());
            })
            modal_selector.find('input[name="product[facility_ids_main]"]').val(f_array);
          } else {
            modal_selector.find(".inputFacility").each(function () {
              let value = $(this).val()
              $(this).prop('checked', false);
              let index = f_array.indexOf(value);
              if (index >= 0)         //f_array = []
 {
                f_array.splice( index, 1)
              }
            })
            let f_array = f_array.filter(function(n){ return n != ""})
            modal_selector.find('input[name="product[facility_ids_main]"]').val(f_array);
          }
        });*/

        $("#modal_pcf_tbl").DataTable()
        $(".dimmer_container").removeClass('active')
      }
    })
    modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(facilities_array));
    modal_selector.find('input[name="product[product_coverage_id]"]').val(product_coverage_id);
  }

  loadModal()

  function loadModal() {
    $(".dimmer_container").addClass('active')
    let product_coverage_id = $(".title.facility_accordion.active").attr("productCoverageID")
    if(typeof(product_coverage_id) != "undefined") {
      let coverage_id = $(".title.facility_accordion.active").attr("coverageID")
      let fa_title = $("#fa_title_" + coverage_id).text()
      let facilities_array_ids = $("#facilities_" + coverage_id).val()
      let facilities_array = facilities_array_ids.split(',');
      if(fa_title == "ACU") {
        openFacilityACU(product_coverage_id, facilities_array, fa_title)
      } else {

        // $('#modal_pcf_tbl').prop('id', `modal_pcf_tbl_${product_coverage_id}`)
        //haha
        openFacilityNormal(product_coverage_id, facilities_array, fa_title)
      }
    }
  }

  function openFacilityACU(product_coverage_id, facilities_array, fa_title, coverage_id){
    let modal_selector = $('div[modalID="'+ product_coverage_id +'"]')
    modal_selector.find('#facility_submit').prop("disabled", false)
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${product_coverage_id}/get_pcf`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      success: function(response){
        let result = response.result
        let dataSet = []
        for(let facility of result){
          let data_array = []
          data_array.push('<div class="for_input_acu"><input class="inputFacility_acu" style="width:20px;height:20px" type="checkbox" facilityID="' + facility.id + '" name="product[facility_ids][]" value="' + facility.id + '" region="'+ facility.location_group +'" /></div>')
          data_array.push(facility.code)
          data_array.push(facility.name)
          data_array.push(facility.type)
          data_array.push(facility.region)
          data_array.push(facility.category)
          if(facility.location_group.length == 0){
            data_array.push("")
          } else {
            let location_group_name = []
            facility.location_group.forEach(function(location_group) {
              location_group_name.push(location_group.location_group.name)
            });
            data_array.push(location_group_name.toString())
          }
          dataSet.push(data_array)
        }
       let table_acu =  $("#modal_pcf_tbl_acu").DataTable( {
          destroy: true,
          data: dataSet,
          "columns": [
            { "title": '<input type="checkbox" style="width:20px;height:20px" id="facility_select_acu" value="false"/>'},
            { "title": "Facility"},
            { "title": "Facility Name"},
            { "title": "Type"},
            { "title": "Region"},
            { "title": "Category"},
            { "title": "Location Group"},
          ]
        });

        let facilities_selected_array;
        let facility_array_ids = '#facilities_' + coverage_id;
        let facilities = $(facility_array_ids).val();
        if (facilities == undefined){
          facilities_selected_array = [];
        } else {
          facilities_selected_array = facilities.split(',');
        }

        $('.ui.checkbox').checkbox()
        f_array = []
        $.each(facilities_array, function(key, value){
          if(value != ""){
            f_array.push(value);
          }
        });

        modal_selector.on('mouseover', function(){
          modal_selector.find('.inputFacility_acu').on('change', function () {
            f_array = unique_value(f_array)
            let value = $(this).val();

            if(this.checked) {
              f_array.push(value);
            } else {
              let index = f_array.indexOf(value);
              if (index >= 0) {
                f_array.splice( index, 1)
              }
            }
            modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_array));
          });

          $(document).on('change', '#facility_select_acu', function () {
            if($(this).is(':checked') == true){
              $(".inputFacility_acu").each(function () {
                $(this).prop('checked', true);
                f_array.push($(this).val());
              })
              modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_array));
            } else {
              $(".inputFacility_acu").each(function () {
                let value = $(this).val()
                $(this).prop('checked', false);
              })
              f_array = facilities_selected_array.filter(function(n){ return n != ""})
              modal_selector.find('input[name="product[facility_ids_main]"]').val(f_array);
            }
          });
          $(".dimmer_container").removeClass('active')
        });

        modal_selector.find('select[name="product[facility_region_acu][]"]').on('change', function () {
          let f_array_copy = modal_selector.find('input[name="product[facility_ids_main]"]').val().split(',');
          f_array_copy = unique_value(f_array_copy)
          let location_group = $(this).val()
          location_group = location_group.filter((v, i, a) => a.indexOf(v) === i)
          filterRegionACU(
            product_coverage_id,
            facilities_array,
            fa_title,
            location_group,
            f_array_copy,
            modal_selector,
            coverage_id)
        });

        $('#modal_pcf_tbl_acu_filter > label > input[type="search"]').on('keyup', function(){
          let temp_param = $(this).val().trim()
          delay(function(){
            facility_modal_acu_search(product_coverage_id, facilities_array, fa_title, coverage_id, temp_param, table_acu )
          }, 2500 );
        })

        let info
        table_acu.on('page', function(){
          let search_params = $(`#modal_pcf_tbl_acu_filter > label > input[type="search"]`).val()
          info = table_acu.page.info();
          facility_modal_acu_pagination(product_coverage_id, facilities_array, fa_title, coverage_id, search_params, table_acu, info)
        })

      }
    })

    modal_selector.find('input[name="product[facility_ids_main]"]').val(facilities_array);
    modal_selector.find('input[name="product[product_coverage_id]"]').val(product_coverage_id);
  }

  var delay = (function(){
    var timer = 0;
    return function(callback, ms){
      clearTimeout (timer);
      timer = setTimeout(callback, ms);
    };
  })();

  function facility_location_group(facility){
    if(facility.location_group.length == 0){
      return ""
    }
    else {
      let location_group_name = []
      facility.location_group.forEach(function(location_group) {
        location_group_name.push(location_group.location_group.name)
      });
      return location_group_name.toString()
    }
  }

  function facility_modal_acu_search(product_coverage_id, facilities_array, fa_title, coverage_id, search_param, table_acu){
    let modal_selector = $('div[modalID="'+ product_coverage_id +'"]')
    modal_selector.find('#facility_submit').prop("disabled", false)
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${product_coverage_id}/get_pcf_by_search`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      data: {datatable_params: { "search_value" : search_param, "offset" : 0}},
      dataType: 'json',
      success: function(response){

      /////////////////////////////////////////////////////////////////////////

        table_acu.clear()
        let result = response.result
        console.log(response.result)

        for (let facility of result) {
          table_acu.row.add( [
            '<div class="for_input_acu"><input class="inputFacility_acu" style="width:20px;height:20px" type="checkbox" facilityID="' + facility.id + '" name="product[facility_ids][]" value="' + facility.id + '" region="'+ facility.location_group +'" /></div>',
            facility.code,
            facility.name,
            facility.type,
            facility.region,
            facility.category,
            facility_location_group(facility)
          ] ).draw();

        }


        /////////////////////////////////////////////////////////////////////////

        let facility_array_ids = '#facilities_' + coverage_id;
        let facilities = $(facility_array_ids).val();
        let facilities_selected_array = facilities.split(',');

        let f_id_array = []
        let current_val = []
        // if(params.length == 0){
        //   modal_selector.find(".inputFacility_acu").each(function () {
        //     let value = $(this).val();
        //     current_val.push(value)
        //   })
        //   f_id_array = facilities_selected_array.filter(function(n){ return n != ""})
        //   modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
        // } else {
        //   modal_selector.find(".inputFacility_acu").each(function () {
        //     let value = $(this).val();
        //     //if(f_array.includes(value)){
        //     $(this).prop('checked', true);
        //     //}
        //     current_val.push(value)
        //     facilities_selected_array.push(value)
        //     f_id_array = facilities_selected_array.filter(function(n){ return n != ""})
        //     modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
        //   })
        // }


        $('.ui.checkbox').checkbox()
        $.each(facilities_array, function(key, value){
          if(value != ""){
            f_array.push(value);
          }
        });

        modal_selector.on('mouseover', function(){
          modal_selector.find(".inputFacility_acu").on('change', function () {
            let value = $(this).val();
            f_array = modal_selector.find('input[name="product[facility_ids_main]"]').val()
            f_array = f_array.split(',')
            if(this.checked) {
              f_array.push(value);
            } else {
              let index = f_array.indexOf(value);
              if (index >= 0) {
                f_array.splice( index, 1)
              }
            }
            f_array = f_array.filter(function(n){ return n != ""})
            modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_array));
          });
        })

        $(".dimmer_container").removeClass('active')
      }
    })

    modal_selector.find('input[name="product[facility_ids_main]"]').val(facilities_array);
    modal_selector.find('input[name="product[product_coverage_id]"]').val(product_coverage_id);

  }

  function facility_modal_acu_pagination(product_coverage_id, facilities_array, fa_title, coverage_id, search_param, table_acu, info){
    if (info.pages - info.page == 1){
      let modal_selector = $('div[modalID="'+ product_coverage_id +'"]')
      modal_selector.find('#facility_submit').prop("disabled", false)
      let csrf = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/products/${product_coverage_id}/get_pcf_by_search`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        data: {datatable_params: { "search_value" : search_param, "offset" : info.recordsTotal}},
        dataType: 'json',
        success: function(response){

          /////////////////////////////////////////////////////////////////////////

          let result = response.result
          console.log(response.result)

          for (let facility of result) {
            table_acu.row.add( [
              '<div class="for_input_acu"><input class="inputFacility_acu" style="width:20px;height:20px" type="checkbox" facilityID="' + facility.id + '" name="product[facility_ids][]" value="' + facility.id + '" region="'+ facility.location_group +'" /></div>',
              facility.code,
              facility.name,
              facility.type,
              facility.region,
              facility.category,
              facility_location_group(facility)
            ] ).draw(false);

          }


          /////////////////////////////////////////////////////////////////////////

          let facility_array_ids = '#facilities_' + coverage_id;
          let facilities = $(facility_array_ids).val();
          let facilities_selected_array = facilities.split(',');

          let f_id_array = []
          let current_val = []

          $('.ui.checkbox').checkbox()
          $.each(facilities_array, function(key, value){
            if(value != ""){
              f_array.push(value);
            }
          });

          modal_selector.on('mouseover', function(){
            modal_selector.find(".inputFacility_acu").on('change', function () {
              let value = $(this).val();
              f_array = modal_selector.find('input[name="product[facility_ids_main]"]').val()
              f_array = f_array.split(',')
              if(this.checked) {
                f_array.push(value);
              } else {
                let index = f_array.indexOf(value);
                if (index >= 0) {
                  f_array.splice( index, 1)
                }
              }
              f_array = f_array.filter(function(n){ return n != ""})
              modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_array));
            });
          })

          $(".dimmer_container").removeClass('active')
        }
      })

      modal_selector.find('input[name="product[facility_ids_main]"]').val(facilities_array);
      modal_selector.find('input[name="product[product_coverage_id]"]').val(product_coverage_id);

    }

  }

  function facility_modal_search(product_coverage_id, facilities_array, fa_title, coverage_id, search_param, table_normal){
    let modal_selector = $('div[modalID="'+ product_coverage_id +'"]')
    modal_selector.find('#facility_submit').prop("disabled", false)
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${product_coverage_id}/get_pcf_by_search`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      data: {datatable_params: { "search_value" : search_param, "offset" : 0}},
      dataType: 'json',
      success: function(response){

      /////////////////////////////////////////////////////////////////////////

        table_normal.clear()
        let result = response.result
        console.log(response.result)

        for (let facility of result) {
          table_normal.row.add( [
            '<div class="for_input_acu"><input class="inputFacility_acu" style="width:20px;height:20px" type="checkbox" facilityID="' + facility.id + '" name="product[facility_ids][]" value="' + facility.id + '" region="'+ facility.location_group +'" /></div>',
            facility.code,
            facility.name,
            facility.type,
            facility.region,
            facility.category,
            facility_location_group(facility)
          ] ).draw();

        }


        /////////////////////////////////////////////////////////////////////////

        let facility_array_ids = '#facilities_' + coverage_id;
        let facilities = $(facility_array_ids).val();
        let facilities_selected_array = facilities.split(',');

        let f_id_array = []
        let current_val = []
        // if(params.length == 0){
        //   modal_selector.find(".inputFacility_acu").each(function () {
        //     let value = $(this).val();
        //     current_val.push(value)
        //   })
        //   f_id_array = facilities_selected_array.filter(function(n){ return n != ""})
        //   modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
        // } else {
        //   modal_selector.find(".inputFacility_acu").each(function () {
        //     let value = $(this).val();
        //     //if(f_array.includes(value)){
        //     $(this).prop('checked', true);
        //     //}
        //     current_val.push(value)
        //     facilities_selected_array.push(value)
        //     f_id_array = facilities_selected_array.filter(function(n){ return n != ""})
        //     modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
        //   })
        // }


        $('.ui.checkbox').checkbox()
        $.each(facilities_array, function(key, value){
          if(value != ""){
            f_array.push(value);
          }
        });

        modal_selector.on('mouseover', function(){
          modal_selector.find(".inputFacility_acu").on('change', function () {
            let value = $(this).val();
            f_array = modal_selector.find('input[name="product[facility_ids_main]"]').val()
            f_array = f_array.split(',')
            if(this.checked) {
              f_array.push(value);
            } else {
              let index = f_array.indexOf(value);
              if (index >= 0) {
                f_array.splice( index, 1)
              }
            }
            f_array = f_array.filter(function(n){ return n != ""})
            modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_array));
          });
        })

        $(".dimmer_container").removeClass('active')
      }
    })

    modal_selector.find('input[name="product[facility_ids_main]"]').val(facilities_array);
    modal_selector.find('input[name="product[product_coverage_id]"]').val(product_coverage_id);

  }

  function facility_modal_pagination(product_coverage_id, facilities_array, fa_title, coverage_id, search_param, table_normal, info){
    if (info.pages - info.page == 1){
    let modal_selector = $('div[modalID="'+ product_coverage_id +'"]')
    modal_selector.find('#facility_submit').prop("disabled", false)
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${product_coverage_id}/get_pcf_by_search`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      data: {datatable_params: { "search_value" : search_param, "offset" : info.recordsTotal}},
      dataType: 'json',
      success: function(response){

      /////////////////////////////////////////////////////////////////////////

        // table_normal.clear()
        let result = response.result
        console.log(response.result)

        for (let facility of result) {
          table_normal.row.add( [
            '<div class="for_input_acu"><input class="inputFacility_acu" style="width:20px;height:20px" type="checkbox" facilityID="' + facility.id + '" name="product[facility_ids][]" value="' + facility.id + '" region="'+ facility.location_group +'" /></div>',
            facility.code,
            facility.name,
            facility.type,
            facility.region,
            facility.category,
            facility_location_group(facility)
          ] ).draw(false);

        }


        /////////////////////////////////////////////////////////////////////////

        let facility_array_ids = '#facilities_' + coverage_id;
        let facilities = $(facility_array_ids).val();
        let facilities_selected_array = facilities.split(',');

        let f_id_array = []
        let current_val = []
        // if(params.length == 0){
        //   modal_selector.find(".inputFacility_acu").each(function () {
        //     let value = $(this).val();
        //     current_val.push(value)
        //   })
        //   f_id_array = facilities_selected_array.filter(function(n){ return n != ""})
        //   modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
        // } else {
        //   modal_selector.find(".inputFacility_acu").each(function () {
        //     let value = $(this).val();
        //     //if(f_array.includes(value)){
        //     $(this).prop('checked', true);
        //     //}
        //     current_val.push(value)
        //     facilities_selected_array.push(value)
        //     f_id_array = facilities_selected_array.filter(function(n){ return n != ""})
        //     modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_id_array))
        //   })
        // }


        $('.ui.checkbox').checkbox()
        $.each(facilities_array, function(key, value){
          if(value != ""){
            f_array.push(value);
          }
        });

        modal_selector.on('mouseover', function(){
          modal_selector.find(".inputFacility_acu").on('change', function () {
            let value = $(this).val();
            f_array = modal_selector.find('input[name="product[facility_ids_main]"]').val()
            f_array = f_array.split(',')
            if(this.checked) {
              f_array.push(value);
            } else {
              let index = f_array.indexOf(value);
              if (index >= 0) {
                f_array.splice( index, 1)
              }
            }
            f_array = f_array.filter(function(n){ return n != ""})
            modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_array));
          });
        })

        $(".dimmer_container").removeClass('active')
      }
    })

    modal_selector.find('input[name="product[facility_ids_main]"]').val(facilities_array);
    modal_selector.find('input[name="product[product_coverage_id]"]').val(product_coverage_id);

    }

  }

  function openFacilityNormal(product_coverage_id, facilities_array, fa_title, coverage_id) {
    let modal_selector = $('div[modalID="'+ product_coverage_id +'"]')
    modal_selector.find('#facility_submit').prop("disabled", false)
    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${product_coverage_id}/get_pcf`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      dataType: 'json',
      success: function(response){
        let result = response.result
        let dataSet = []
        for(let facility of result){
          let data_array = []
          data_array.push('<div class="for_input"><input class="inputFacility" style="height:20px;width:20px" type="checkbox" facilityID="' + facility.id + '" name="product[facility_ids][]" value="' + facility.id + '" region="'+ facility.location_group +'" /></div>')
          data_array.push(facility.code)
          data_array.push(facility.name)
          data_array.push(facility.type)
          data_array.push(facility.region)
          data_array.push(facility.category)
          if(facility.location_group.length == 0){
            data_array.push("")
          } else {
            let location_group_name = []
            facility.location_group.forEach(function(location_group) {
              location_group_name.push(location_group.location_group.name)
            });
            data_array.push(location_group_name.toString())
          }
          dataSet.push(data_array)
        }
        let normal_tbl = $(`#modal_pcf_tbl_${product_coverage_id}`).DataTable( {
          destroy: true,
          data: dataSet,
          "columns": [
            { "title": '<input type="checkbox" style="width:20px;height:20px" id="facility_select" value="false"/>'},
            { "title": "Facility"},
            { "title": "Facility Name"},
            { "title": "Type"},
            { "title": "Region"},
            { "title": "Category"},
            { "title": "Location Group"},
          ]
        });

        let facilities_selected_array;
        let facility_array_ids = '#facilities_' + coverage_id;
        let facilities = $(facility_array_ids).val();
        if (facilities == undefined){
          facilities_selected_array = [];
        } else {
          facilities_selected_array = facilities.split(',');
        }

        $('.ui.checkbox').checkbox()
        f_array = []
        $.each(facilities_array, function(key, value){
          if(value != ""){
            f_array.push(value);
          }
        });

        modal_selector.on('mouseover', function(){
          modal_selector.find('.inputFacility').on('change', function () {
            let value = $(this).val();

            if(this.checked) {
              f_array.push(value);
            } else {
              let index = f_array.indexOf(value);
              if (index >= 0) {
                f_array.splice( index, 1)
              }
            }
            modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_array));
          });

          $(document).on('change', '#facility_select', function () {
            if($(this).is(':checked') == true){
              $(".inputFacility").each(function () {
                $(this).prop('checked', true);
                f_array.push($(this).val());
              })
              modal_selector.find('input[name="product[facility_ids_main]"]').val(unique_value(f_array));
            } else {
              $(".inputFacility").each(function () {
                let value = $(this).val()
                $(this).prop('checked', false);
              })
              f_array = facilities_selected_array.filter(function(n){ return n != ""})
              modal_selector.find('input[name="product[facility_ids_main]"]').val(f_array);
            }
          });
        });

        modal_selector.find('select[name="product[facility_region][]"]').on('change', function () {
          let f_array_copy = modal_selector.find('input[name="product[facility_ids_main]"]').val().split(',');
          let location_group = $(this).val()
          f_array_copy = unique_value(f_array_copy)
          location_group = location_group.filter((v, i, a) => a.indexOf(v) === i)
          filterRegion(
            product_coverage_id,
            facilities_array,
            fa_title,
            location_group,
            f_array_copy,
            modal_selector,
            coverage_id)
        });

        $(document).on('keyup', `#modal_pcf_tbl_${product_coverage_id}_filter > label > input[type="search"]`, function () {
          let temp_param = $(this).val().trim()
          delay(function(){
            facility_modal_search(product_coverage_id, facilities_array, fa_title, coverage_id, temp_param, normal_tbl)
          }, 2500 );
        })

        let info
        normal_tbl.on('page', function(){
          let search_params = $(`#modal_pcf_tbl_${product_coverage_id}_filter > label > input[type="search"]`).val()
          info = normal_tbl.page.info();
          facility_modal_pagination(product_coverage_id, facilities_array, fa_title, coverage_id, search_params, normal_tbl, info)
        })


        $(".dimmer_container").removeClass('active')
      }
    })
    modal_selector.find('input[name="product[facility_ids_main]"]').val(facilities_array);
    modal_selector.find('input[name="product[product_coverage_id]"]').val(product_coverage_id);

  }

  function openFacilitiesModal(product_coverage_id, facilities_array, fa_title, coverage_id){
    if(fa_title == " ACU"){
      $('#facilities_acu').modal({autofocus: false, closable: false, observeChanges: true, onShow: function() {$(this).attr("modalID", product_coverage_id)}}).modal('show');
      $("#modal_pcf_tbl_acu").css("width", "100%")
      openFacilityACU(product_coverage_id, facilities_array, fa_title, coverage_id)
    }
    else {

      if (dt_id != undefined){
        // alert('may laman na')
        // alert(dt_id)
        $('#' + dt_id).prop('id', `modal_pcf_tbl_${product_coverage_id}`)
        dt_id = `modal_pcf_tbl_${product_coverage_id}`
        // alert(dt_id)

      }
      else{
        // alert('hands up')
        // alert(dt_id)
        $('#modal_pcf_tbl').prop('id', `modal_pcf_tbl_${product_coverage_id}`)
        dt_id = `modal_pcf_tbl_${product_coverage_id}`
        // alert(dt_id)
      }

      $('#p_facilities').modal({destroy_on_hide: true, autofocus: false, closable: false, observeChanges: true, onShow: function(){$(this).attr("modalID", product_coverage_id)}}).modal('show');
      $("#modal_pcf_tbl").css("width", "100%")
      openFacilityNormal(product_coverage_id, facilities_array, fa_title, coverage_id)
    }
  }

  if ($('input[id="open_modal_facilities_v2"]').val() == "show") {
    let selector = $('.title.facility_accordion.active')
    let product_coverage_id = selector.attr('productCoverageID');
    let coverage_id = selector.attr('coverageID');
    $('input[name="product[product_coverage_id]"]').val(product_coverage_id);
    let aaf_id = '#aaf_' + coverage_id;
    let sf_id = '#sf_' + coverage_id;
    let aaf = $(aaf_id)[0];
    let sf = $(sf_id)[0];
    let facility_array_ids = '#facilities_' + coverage_id;
    let facilities = $(facility_array_ids).val();
    let facilities_array = facilities.split(',');
    let fat = "#fa_title_" + coverage_id;
    let fa_title = $(fat).text();

    if(aaf.checked){
      openFacilitiesModal(product_coverage_id, facilities_array, fa_title, coverage_id)
    } else if(sf.checked){
      openFacilitiesModal(product_coverage_id, facilities_array, fa_title, coverage_id)
    } else {
      $('#optionValidation').removeClass('hidden');
    }
  }

  let dt_id

  $('.add.button').click(function(){
    $(".dimmer_container").addClass('active')
    let product_coverage_id = $(this).attr('productCoverageID');
    let coverage_id = $(this).attr('coverageID');
    let aaf_id = '#aaf_' + coverage_id;
    let sf_id = '#sf_' + coverage_id;
    let aaf = $(aaf_id)[0];
    let sf = $(sf_id)[0];
    let facility_array_ids = '#facilities_' + coverage_id;
    let facilities = $(facility_array_ids).val();
    let facilities_array = facilities.split(',');
    let fat = "#fa_title_" + coverage_id;
    let fa_title = $(fat).text();

    console.log({
      "product_coverage_id": product_coverage_id,
      "coverage_id": coverage_id,
      "aaf_id": aaf_id,
      "sf_id": sf_id,
      "aaf": aaf,
      "sf": sf,
      "facility_array_ids": facility_array_ids,
      "facilities": facilities,
      "facilities_array": facilities_array,
      "fat": fat,
      "fa_title": fa_title
    })

    $('.multiple').dropdown("clear")

    if(aaf.checked){
      openFacilitiesModal(product_coverage_id, facilities_array, fa_title, coverage_id)
    } else if(sf.checked){
      openFacilitiesModal(product_coverage_id, facilities_array, fa_title, coverage_id)
    } else {
      $('#optionValidation').removeClass('hidden');
    }
  });

  $(".inputFacility_acu").on('change', function () {
    let value = $(this).val();

    if(this.checked) {
      f_array.push(value);
    } else {
      let index = f_array.indexOf(value);
      if (index >= 0) {
        f_array.splice( index, 1)
      }
    }
    $('input[name="product[facility_ids_main]"]').val(f_array);
  });


  $('#delete_draft').click(function(){
    let id = $(this).attr('productID');
    $('#dp_product_id').val(id);

    $('#delete_product_confirmation').modal('show');
  });

  $('#dp_cancel').click(function(){
    $('#delete_product_confirmation').modal('hide');
  });

  $('#dp_submit').click(function(){
    let id = $('#dp_product_id').val();

    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/products/${id}/delete_all`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.replace('/products')
      }
    });
  });

  $('.title.facility_accordion').click(function(){
    let coverage_id = $(this).attr('coverageID');
    let product_coverage_id = $(this).attr('productCoverageID');
    let coverage_type = $(this).attr('coverageType');
    let indicator_id = '#indicator_' + coverage_id;
    let inclusion = $(indicator_id).text();

    let product_id = $(this).attr('productID');
    let last_coverage_id = $('#last_coverage_id').val()
    let content_id = '#content_' + last_coverage_id;
    let csrf = $('input[name="_csrf_token"]').val();


    $(content_id).removeClass('active');
    $.ajax({
      url:`/products/${product_id}/update_product_coverage/${coverage_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'put',
      success: function(response){
        let obj = JSON.parse(response)
      }
    });
    indicate(coverage_id, coverage_type);
  });


  $('#closeSFV').click(function(){
    $('#specificFacilityValidation').addClass('hidden');
  });

  $('.facility_item_edit').on('click', function(){
    let product_id = $(this).attr('productID');
    let indicator = false;
    let indicator_option = false;
    let member_type = $(this).attr('memberType');
    let coverage_name_array_i = [];
    let coverage_name_array_io = [];
    let nxtStep = $(this).attr('nxt_step')
    let link = $(this).attr('link')


    aaf_array = [];
    $('.c_type').each(function(){
      let coverage_type = $(this).val();
      let coverage = $(this).attr('coverageID');
      let coverageName = $(this).attr('coverageName')
      let f = '#facilities_' + coverage;
      let facilities = $(f).val();

      if(coverage_type == ''){
        indicator_option = true;
        coverage_name_array_io.push(coverageName)
      } else {
        if(coverage_type == 'inclusion'){
          if(facilities == ''){
            indicator = true;
            coverage_name_array_i.push(coverageName)
          }
        }
      }
    });

    let coverage_list_io = ''

    for(let i = 0; i < coverage_name_array_io.length; i++){
      if(coverage_list_io == ''){
        coverage_list_io = '<div class="item">' + coverage_name_array_io[i] + '</div>'
      } else {
        coverage_list_io = coverage_list_io + '<div class="item">' + coverage_name_array_io[i] + '</div>'
      }
    }

    let ov_message = `
      Please select if all facilities will be included or it will be specified in these coverage:\
          <div class="ui bulleted list">\
            ` + coverage_list_io  +  `\
          </div>`

    let coverage_list_i = ''

    for(let i = 0; i < coverage_name_array_i.length; i++){
      if(coverage_list_i == ''){
        coverage_list_i = '<div class="item">' + coverage_name_array_i[i] + '</div>'
      } else {
        coverage_list_i = coverage_list_i + '<div class="item">' + coverage_name_array_i[i] + '</div>'
      }
    }

    let sfv_message = `
      Facilities must be added in the following coverage:\
          <div class="ui bulleted list">\
            ` + coverage_list_i  +  `\
          </div>`

    if(indicator_option == true){
      $('#optionValidation').removeClass('hidden');
      $('#ov_error_message').html(ov_message)
    }
    else {
      if(indicator == true){
        $('#optionValidation').addClass('hidden');
        $('#specificFacilityValidation').removeClass('hidden');
        $('#sfv_error_message').html(sfv_message)
      }
      else {
        if (member_type == ""){
          $('#member_type_is_nil').removeClass('hidden');
        } else {
          let result = "/products/" + product_id  + "/edit?tab=" + link
          window.location.replace(result);
        }
      }
    }
  });

  $('#step4_next').on('click', function(){
    let product_id = $(this).attr('productID');
    let indicator = false;
    let indicator_option = false;
    let member_type = $(this).attr('memberType');
    let coverage_name_array_i = [];
    let coverage_name_array_io = [];
    let nxtStep = $(this).attr('nxt_step')


    aaf_array = [];
    $('.c_type').each(function(){
      let coverage_type = $(this).val();
      let coverage = $(this).attr('coverageID');
      let coverageName = $(this).attr('coverageName')
      let f = '#facilities_' + coverage;
      let facilities = $(f).val();

      if(coverage_type == ''){
        indicator_option = true;
        coverage_name_array_io.push(coverageName)
      } else {
        if(coverage_type == 'inclusion'){
          if(facilities == ''){
            indicator = true;
            coverage_name_array_i.push(coverageName)
          }
        }
      }
    });

    let coverage_list_io = ''

    for(let i = 0; i < coverage_name_array_io.length; i++){
      if(coverage_list_io == ''){
        coverage_list_io = '<div class="item">' + coverage_name_array_io[i] + '</div>'
      } else {
        coverage_list_io = coverage_list_io + '<div class="item">' + coverage_name_array_io[i] + '</div>'
      }
    }

    let ov_message = `
      Please select if all facilities will be included or it will be specified in these coverage:\
          <div class="ui bulleted list">\
            ` + coverage_list_io  +  `\
          </div>`

    let coverage_list_i = ''

    for(let i = 0; i < coverage_name_array_i.length; i++){
      if(coverage_list_i == ''){
        coverage_list_i = '<div class="item">' + coverage_name_array_i[i] + '</div>'
      } else {
        coverage_list_i = coverage_list_i + '<div class="item">' + coverage_name_array_i[i] + '</div>'
      }
    }

    let sfv_message = `
      Facilities must be added in the following coverage:\
          <div class="ui bulleted list">\
            ` + coverage_list_i  +  `\
          </div>`

    if(indicator_option == true){
      $('#optionValidation').removeClass('hidden');
      $('#ov_error_message').html(ov_message)
    }
    else {
      if(indicator == true){
        $('#optionValidation').addClass('hidden');
        $('#specificFacilityValidation').removeClass('hidden');
        $('#sfv_error_message').html(sfv_message)
      }
      else {
        if (member_type == ""){
          $('#member_type_is_nil').removeClass('hidden');
        } else {
          let csrf = $('input[name="_csrf_token"]').val();
          $.ajax({
            url:`/products/${product_id}/next_btn/${nxtStep}`,
            headers: {"X-CSRF-TOKEN": csrf},
            type: 'GET',
            success: function(response){
              let obj = JSON.parse(response)
              window.location.replace('/products/' + product_id + '/setup?step=' + nxtStep)
            }
          });
        }
      }
    }
  });

  function saveCoverageType(id, csrf, type, product_id, coverage_id){
    console.log(id)
    console.log(csrf)
    console.log(type)
    console.log(product_id)
    console.log(coverage_id)
    $.ajax({
      url:`/products/${id}/insert_coverage_type/${type}/${product_id}/${coverage_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'put',
      success: function(response){
        let obj = JSON.parse(response);
        let c_type = $('#coverage_type_' + coverage_id).val(type);
      }
    });
  }
});
