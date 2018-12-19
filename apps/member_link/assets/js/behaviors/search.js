onmount('div[id="search_app"]', function() {
  const locale = $('#locale').val();

  initMapOnLoad()
  open_drawer()
  select_dropdown()
  hospital_intellisense()
  check_coverage('acu')
  $('#search_specialization').closest('div').addClass('disabled')
  $('#search_all_button').unbind("click").on('click', function() {
    $('#search_name_facility').val('')
    $('#search_address').val('')
    $('#search_specialization').dropdown('restore defaults');
    $('#list_detail').removeClass('active')
    $('#search_all_button').attr('class','ui button active')
    $('#search_doctor_button').attr('class','ui button')
    $('#search_hospital_button').attr('class','ui button')
    $('#search_all_button').addClass('disabled')
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/${locale}/search/all/${0}`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      dataType: 'json',
      beforeSend: function(){
        $('.item.doctor-affiliated.facility').remove()
      },
      success: function(response){
        $('.item.doctor-affiliated.facility').remove()
        for (let i=0;i<response.length;i++){
            let data = `<div class="item doctor-affiliated facility" facility_id="${response[i].id}" doctor_count="${response[i].practitioner.length}">
          <div class="right floated content">
          <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].practitioner.length}"></i></p>
          <div class="ui button mini request request-hospital clickable">REQUEST</div>
          </div>
          <i class="hospital icon"></i>
          <div class="content">
          <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
          <div class="description">
          <p>${response[i].facility_address1}</p>
          <p>${response[i].facility_address2}</p>

          <div class="list-footer">
          <span>${response[i].facility_phone_no}</span>
          <a href="#" class="get_direction" name="get_location" facility_id="${response[i].id}"><i class="location arrow icon"></i>Get Direction</a>
          <div class="ui dropdown">
          <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
          <div class="menu">
          <div class="item">Uber</div>
          <div class="item">Call Grab</div>
          </div>
          </div>
          </div>
          </div>
          </div>
          </div>`
          $('#append_here_head').append(data)
        }
        open_drawer()
      $('#search_all_button').removeClass('disabled')
      $('#search_doctor_button').removeClass('disabled')
      $('#search_hospital_button').removeClass('disabled')
      }
    })
  })

  $('.doctors-list').scroll(function(event){
    let total_preview = $('.item.doctor-affiliated.facility').length
    let element = event.target

    if (element.scrollHeight - element.scrollTop === element.clientHeight && total_preview != 0)
      {
        let current_active = $('.ui.button.search.active').text()
        $('#search_all_button').addClass('disabled')
        $('#search_doctor_button').addClass('disabled')
        $('#search_hospital_button').addClass('disabled')
        let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
        if(loa_value == 'Request ACU' || loa_value == '請求Acu'){
        if ($('#search_doctor_button').attr('class').indexOf('active') != -1){
          if ($('#search_name_facility').val() != "" || $('#search_specialization option:selected').val() != "" || $('#search_address').val() != ""){
            const csrf2 = $('input[name="_csrf_token"]').val();
            $.ajax({
              url:`/${locale}/search/submit/all/${current_active}/${total_preview}`,
              headers: {"X-CSRF-TOKEN": csrf2},
              type: 'get',
              data: {search_param: {name: $('#search_name_facility').val(), address: $('#search_address').val(), specialization: $('#search_specialization option:selected').val(), loa_type: "acu"}},
              dataType: 'json',
              success: function(response){
                for (let i=0;i<response.length;i++){
                  let data = ``
                  let schedule = ``
                  for (let s=0;s<response[i].schedule.length;s++)
                  {
                    schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
                  }
                  if (schedule == ``) {
                    schedule = `Schedule: None`
                  }
                  data = `<div class="item doctor-affiliated facility" id="try_append">
                  <div class="right floated content">
                  <div class="ui button mini request request-hospital clickable" practitionerID="${response[i].practitioner_id}" facilityID="${response[i].facility_id}" f_status="${response[i].f_status}" p_status="${response[i].p_status}" status="${response[i].status}">REQUEST</div>
                  </div>
                  <i class="doctor icon"></i>
                  <div class="content">
                  <div class="header">${response[i].practitioner_name} <span>${response[i].status}</span></div>
                  <div class="description">
                  <p class="mb_zero">${response[i].specialization}, <span>${response[i].facility_name} </span></p>
                  ${schedule}
                  <p>Disclaimer: Please call the doctor's clinic prior to your consultation. Schedule of doctors are subject to change without prior notice.</p>
                  </div>
                  </div>
                  </div>`

                  $('#append_here_head').append(data)
                }
                $('#search_all_button').removeClass('disabled')
                $('#search_doctor_button').removeClass('disabled')
                $('#search_hospital_button').removeClass('disabled')
              }
            })
          }else{
            const csrf2 = $('input[name="_csrf_token"]').val();
            $.ajax({
              url:`/${locale}/search/doctors/all/${total_preview}`,
              headers: {"X-CSRF-TOKEN": csrf2},
              type: 'get',
              data: {loa_type: 'acu'},
              dataType: 'json',
              success: function(response){
                for (let i=0;i<response.length;i++){
                  let data = ``
                  let schedule = ``
                  for (let s=0;s<response[i].schedule.length;s++)
                  {
                    schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
                  }
                  if (schedule == ``) {
                    schedule = `Schedule: None`
                  }
                  data = `<div class="item doctor-affiliated facility" id="try_append">
                  <div class="right floated content">
                  <div class="ui button mini request request-hospital clickable" practitionerID="${response[i].practitioner_id}" facilityID="${response[i].facility_id}" f_status="${response[i].f_status}" p_status="${response[i].p_status}" status="${response[i].status}">REQUEST</div>
                  </div>
                  <i class="doctor icon"></i>
                  <div class="content">
                  <div class="header">${response[i].practitioner_name} <span>${response[i].status}</span></div>
                  <div class="description">
                  <p class="mb_zero">${response[i].specialization}, <span>${response[i].facility_name} </span></p>
                  ${schedule}
                  <p>Disclaimer: Please call the doctor's clinic prior to your consultation. Schedule of doctors are subject to change without prior notice.</p>
                  </div>
                  </div>
                  </div>`

                  $('#append_here_head').append(data)
                }
                $('#search_all_button').removeClass('disabled')
                $('#search_doctor_button').removeClass('disabled')
                $('#search_hospital_button').removeClass('disabled')
              }
            })
          }
        }
        if ($('#search_hospital_button').attr('class').indexOf('active') != -1){
          if ($('#search_name_facility').val() != "" || $('#search_address').val() != "" || $('#search_facility_type option:selected').val() != ""){
            const csrf2 = $('input[name="_csrf_token"]').val();
            $.ajax({
              url:`/${locale}/search/submit/all/${current_active}/${total_preview}`,
              headers: {"X-CSRF-TOKEN": csrf2},
              type: 'get',
              data: {search_param: {name: $('#search_name_facility').val(), address: $('#search_address').val(), specialization: $('#search_specialization option:selected').val(), type: $('#search_facility_type option:selected').val(), loa_type: "acu"}},
              dataType: 'json',
              success: function(response){
                for (let i=0;i<response.length;i++){
                  let data = `<div class="item doctor-affiliated facility" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}">
                  <div class="right floated content">
                  <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}"></i></p>
                  </div>
                  <i class="hospital icon"></i>
                  <div class="content">
                  <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
                  <div class="description">
                  <p>${response[i].facility_address1}</p>
                  <p>${response[i].facility_address2}</p>

                  <div class="list-footer">
                  <span>${response[i].facility_phone_no}</span>
                  <a href="#" class="get_direction" name="get_location" facility_id="${response[i].id}"><i class="location arrow icon"></i>Get Direction</a>
                  <div class="ui dropdown">
                  <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
                  <div class="menu">
                  <div class="item">Uber</div>
                  <div class="item">Call Grab</div>
                  </div>
                  </div>
                  </div>
                  </div>
                  </div>
                  </div>`
                  $('#append_here_head').append(data)
                }
                $('#search_all_button').removeClass('disabled')
                $('#search_doctor_button').removeClass('disabled')
                $('#search_hospital_button').removeClass('disabled')
                open_drawer()
              }
            })
          }else{
            const csrf2 = $('input[name="_csrf_token"]').val();
            $.ajax({
              url:`/${locale}/search/all/${total_preview}`,
              headers: {"X-CSRF-TOKEN": csrf2},
              type: 'get',
              data: {loa_type: 'acu'},
              dataType: 'json',
              success: function(response){
                for (let i=0;i<response.length;i++){
                  let data = `<div class="item doctor-affiliated facility" facility_id="${response[i].id}" doctor_count="${response[i].practitioner.length}">
                  <div class="right floated content">
                  <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].practitioner.length}"></i></p>
                  </div>
                  <i class="hospital icon"></i>
                  <div class="content">
                  <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
                  <div class="description">
                  <p>${response[i].facility_address1}</p>
                  <p>${response[i].facility_address2}</p>

                  <div class="list-footer">
                  <span>${response[i].facility_phone_no}</span>
                  <a href="#" class="get_direction" name="get_location" facility_id="${response[i].id}"><i class="location arrow icon"></i>Get Direction</a>
                  <div class="ui dropdown">
                  <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
                  <div class="menu">
                  <div class="item">Uber</div>
                  <div class="item">Call Grab</div>
                  </div>
                  </div>
                  </div>
                  </div>
                  </div>
                  </div>`
                  $('#append_here_head').append(data)
                }
                $('#search_all_button').removeClass('disabled')
                $('#search_doctor_button').removeClass('disabled')
                $('#search_hospital_button').removeClass('disabled')
                open_drawer()
              }
            })
          }
        }
        }else{
        if ($('#search_doctor_button').attr('class').indexOf('active') != -1){
          if ($('#search_name_facility').val() != "" || $('#search_specialization option:selected').val() != "" || $('#search_address').val() != ""){
            const csrf2 = $('input[name="_csrf_token"]').val();
            $.ajax({
              url:`/${locale}/search/submit/all/${current_active}/${total_preview}`,
              headers: {"X-CSRF-TOKEN": csrf2},
              type: 'get',
              data: {search_param: {name: $('#search_name_facility').val(), address: $('#search_address').val(), specialization: $('#search_specialization option:selected').val()}},
              dataType: 'json',
              success: function(response){
                for (let i=0;i<response.length;i++){
                  let data = ``
                  let schedule = ``
                  for (let s=0;s<response[i].schedule.length;s++)
                  {
                    schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
                  }
                  if (schedule == ``) {
                    schedule = `Schedule: None`
                  }
                  data = `<div class="item doctor-affiliated facility" id="try_append">
                  <div class="right floated content">
                  <div class="ui button mini request request-hospital clickable" practitionerID="${response[i].practitioner_id}" facilityID="${response[i].facility_id}" f_status="${response[i].f_status}" p_status="${response[i].p_status}" status="${response[i].status}">REQUEST</div>
                  </div>
                  <i class="doctor icon"></i>
                  <div class="content">
                  <div class="header">${response[i].practitioner_name} <span>${response[i].status}</span></div>
                  <div class="description">
                  <p class="mb_zero">${response[i].specialization}, <span>${response[i].facility_name} </span></p>
                  ${schedule}
                  <p>Disclaimer: Please call the doctor's clinic prior to your consultation. Schedule of doctors are subject to change without prior notice.</p>
                  </div>
                  </div>
                  </div>`

                  $('#append_here_head').append(data)
                }
                $('#search_all_button').removeClass('disabled')
                $('#search_doctor_button').removeClass('disabled')
                $('#search_hospital_button').removeClass('disabled')
              }
            })
          }else{
            const csrf2 = $('input[name="_csrf_token"]').val();
            $.ajax({
              url:`/${locale}/search/doctors/all/${total_preview}`,
              headers: {"X-CSRF-TOKEN": csrf2},
              type: 'get',
              dataType: 'json',
              success: function(response){
                for (let i=0;i<response.length;i++){
                  let data = ``
                  let schedule = ``
                  for (let s=0;s<response[i].schedule.length;s++)
                  {
                    schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
                  }
                  if (schedule == ``) {
                    schedule = `Schedule: None`
                  }
                  data = `<div class="item doctor-affiliated facility" id="try_append">
                  <div class="right floated content">
                  <div class="ui button mini request request-hospital clickable" practitionerID="${response[i].practitioner_id}" facilityID="${response[i].facility_id}" f_status="${response[i].f_status}" p_status="${response[i].p_status}" status="${response[i].status}">REQUEST</div>
                  </div>
                  <i class="doctor icon"></i>
                  <div class="content">
                  <div class="header">${response[i].practitioner_name} <span>${response[i].status}</span></div>
                  <div class="description">
                  <p class="mb_zero">${response[i].specialization}, <span>${response[i].facility_name} </span></p>
                  ${schedule}
                  <p>Disclaimer: Please call the doctor's clinic prior to your consultation. Schedule of doctors are subject to change without prior notice.</p>
                  </div>
                  </div>
                  </div>`

                  $('#append_here_head').append(data)
                }
                $('#search_all_button').removeClass('disabled')
                $('#search_doctor_button').removeClass('disabled')
                $('#search_hospital_button').removeClass('disabled')
              }
            })
          }
        }
        if ($('#search_hospital_button').attr('class').indexOf('active') != -1){
          if ($('#search_name_facility').val() != "" || $('#search_address').val() != "" || $('#search_facility_type option:selected').val() != ""){
            const csrf2 = $('input[name="_csrf_token"]').val();
            $.ajax({
              url:`/${locale}/search/submit/all/${current_active}/${total_preview}`,
              headers: {"X-CSRF-TOKEN": csrf2},
              type: 'get',
              data: {search_param: {name: $('#search_name_facility').val(), address: $('#search_address').val(), specialization: $('#search_specialization option:selected').val(), type: $('#search_facility_type option:selected').val()}},
              dataType: 'json',
              success: function(response){
                for (let i=0;i<response.length;i++){
                  let data = `<div class="item doctor-affiliated facility" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}">
                  <div class="right floated content">
                  <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}"></i></p>
                  </div>
                  <i class="hospital icon"></i>
                  <div class="content">
                  <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
                  <div class="description">
                  <p>${response[i].facility_address1}</p>
                  <p>${response[i].facility_address2}</p>

                  <div class="list-footer">
                  <span>${response[i].facility_phone_no}</span>
                  <a href="#" class="get_direction" name="get_location" facility_id="${response[i].id}"><i class="location arrow icon"></i>Get Direction</a>
                  <div class="ui dropdown">
                  <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
                  <div class="menu">
                  <div class="item">Uber</div>
                  <div class="item">Call Grab</div>
                  </div>
                  </div>
                  </div>
                  </div>
                  </div>
                  </div>`
                  $('#append_here_head').append(data)
                }
                $('#search_all_button').removeClass('disabled')
                $('#search_doctor_button').removeClass('disabled')
                $('#search_hospital_button').removeClass('disabled')
                open_drawer()
              }
            })
          }else{
            const csrf2 = $('input[name="_csrf_token"]').val();
            $.ajax({
              url:`/${locale}/search/all/${total_preview}`,
              headers: {"X-CSRF-TOKEN": csrf2},
              type: 'get',
              dataType: 'json',
              success: function(response){
                for (let i=0;i<response.length;i++){
                  let data = `<div class="item doctor-affiliated facility" facility_id="${response[i].id}" doctor_count="${response[i].practitioner.length}">
                  <div class="right floated content">
                  <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].practitioner.length}"></i></p>
                  </div>
                  <i class="hospital icon"></i>
                  <div class="content">
                  <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
                  <div class="description">
                  <p>${response[i].facility_address1}</p>
                  <p>${response[i].facility_address2}</p>

                  <div class="list-footer">
                  <span>${response[i].facility_phone_no}</span>
                  <a href="#" class="get_direction" name="get_location" facility_id="${response[i].id}"><i class="location arrow icon"></i>Get Direction</a>
                  <div class="ui dropdown">
                  <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
                  <div class="menu">
                  <div class="item">Uber</div>
                  <div class="item">Call Grab</div>
                  </div>
                  </div>
                  </div>
                  </div>
                  </div>
                  </div>`
                  $('#append_here_head').append(data)
                }
                $('#search_all_button').removeClass('disabled')
                $('#search_doctor_button').removeClass('disabled')
                $('#search_hospital_button').removeClass('disabled')
                open_drawer()
              }
            })
          }
        }
      }
      }
  })

  $('#search_doctor_button').click(function(){
    doctor_intellisense()
    $('.results.name').removeClass('transition visible')
    $('.results.name').attr('style', '')
    $('.results.name').find('.result').remove()
    $('.results.name').find('.message.empty').remove()
    $('.results.address').removeClass('transition visible')
    $('.results.address').attr('style', '')
    $('.results.address').find('.result').remove()
    $('.results.address').find('.message.empty').remove()
    $('#search_name_facility').val('')
    $('#search_address').val('')
    $('#search_specialization').closest('div').removeClass('disabled')
    $('#search_specialization').dropdown('restore defaults');
    $('#search_facility_type').dropdown('clear');
    $('#search_facility_type').closest('div').attr('style', 'display: none;')
    $('#list_detail').removeClass('active')
    $('#search_all_button').attr('class','ui button')
    $('#search_doctor_button').attr('class','ui button search active')
    $('#search_hospital_button').attr('class','ui button')
    $('#search_doctor_button').addClass('disabled')
    let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
    if(loa_value == 'Request ACU' || loa_value == '請求Acu'){
      doctor_acu_ajax(function(handleData){})
    }else{
      doctor_ajax()
    }
  })

  $('#search_hospital_button').unbind("click").on('click', function() {
    hospital_intellisense()
    $('.results.name').removeClass('transition visible')
    $('.results.name').attr('style', '')
    $('.results.name').find('.result').remove()
    $('.results.name').find('.message.empty').remove()
    $('.results.address').removeClass('transition visible')
    $('.results.address').attr('style', '')
    $('.results.address').find('.result').remove()
    $('.results.address').find('.message.empty').remove()
    $('#search_name_facility').val('')
    $('#search_address').val('')
    $('#search_specialization').dropdown('restore defaults')
    $('#search_specialization').closest('div').addClass('disabled')
    $('#search_facility_type').dropdown('clear')
    $('#search_facility_type').closest('div').attr('style', '')
    $('#list_detail').removeClass('active')
    $('#search_all_button').attr('class','ui button')
    $('#search_doctor_button').attr('class','ui button')
    $('#search_hospital_button').attr('class','ui button search active')
    $('#search_hospital_button').addClass('disabled')
    initMapOnLoad()
    let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
    if(loa_value == 'Request ACU' || loa_value == '請求Acu'){
      hospital_acu_ajax(function(handleData){})
    }else{
      hospital_ajax()
    }
  })

  $('#search_box_button').click(function (){
    $('#list_detail').removeClass('active')
    let current_active = $('.ui.button.search.active').text()
    let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
    if(loa_value == 'Request ACU' || loa_value == '請求Acu'){
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/${locale}/search/submit/all/${current_active}/${0}`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      data: {search_param: {name: $('#search_name_facility').val(), address: $('#search_address').val(), specialization: $('#search_specialization option:selected').val(), type: $('#search_facility_type option:selected').val(), loa_type: "acu"}},
      dataType: 'json',
      beforeSend: function(){
        $('.item.doctor-affiliated.facility').remove()
      },
      success: function(response){
        $('.item.doctor-affiliated.facility').remove()
        if (response.length == 0 ){
          $('#append_here_head').append(`<div class="item doctor-affiliated facility" style="width: 500px; text-align:center; !important">
            <div class="content">
              <div class="header">No Results Found</div>
            </div>
            </div>`)
        }
        if (current_active == "All" || current_active == "Hospitals" || current_active == "所有" || current_active == "醫院"){
          for (let i=0;i<response.length;i++){
            let data = `<div class="item doctor-affiliated facility" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}">
            <div class="right floated content">
            <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}"></i></p>
            </div>
            <i class="hospital icon"></i>
            <div class="content">
            <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
            <div class="description">
            <p>${response[i].facility_address1}</p>
            <p>${response[i].facility_address2}</p>
            <div class="list-footer">
            <span>${response[i].facility_phone_no}</span>
            <a href="#" class="get_direction" name="get_location" facility_id="${response[i].id}"><i class="location arrow icon"></i>Get Direction</a>
            <div class="ui dropdown">
            <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
            <div class="menu">
            <div class="item">Uber</div>
            <div class="item">Call Grab</div>
            </div>
            </div>
            </div>
            </div>
            </div>
            </div>`
            $('#append_here_head').append(data)
          }
          open_drawer()
          select_dropdown()
        }
        if (current_active == "Doctors" || current_active == "醫生"){
          for (let i=0;i<response.length;i++){
            let data = ``
            let schedule = ``
            for (let s=0;s<response[i].schedule.length;s++)
            {
              schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
            }
            if (schedule == ``) {
              schedule = `Schedule: None`
            }
            data = `<div class="item doctor-affiliated facility" id="try_append">
            <div class="right floated content">
            <div class="ui button mini request request-hospital clickable" practitionerID="${response[i].practitioner_id}" facilityID="${response[i].facility_id}" f_status="${response[i].f_status}" p_status="${response[i].p_status}" status="${response[i].status}">REQUEST</div>
            </div>
            <i class="doctor icon"></i>
            <div class="content">
            <div class="header" doctor_name='${response[i].practitioner_name}'>${response[i].practitioner_name} <span>${response[i].status}</span></div>
            <div class="description">
                <p class="mb_zero" doctor_specialization='${response[i].specialization}' doctor_facility='${response[i].facility_name}' doctor_phone='${response[i].phones}'>${response[i].specialization}, <span>${response[i].facility_name} </span></p>
            ${schedule}
            <p>Disclaimer: Please call the doctor's clinic prior to your consultation. Schedule of doctors are subject to change without prior notice.</p>
            </div>
            </div>
            </div>`

            $('#append_here_head').append(data)
          }
          request_loa()
          select_dropdown()
        }
      }
    })

    }else{
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/${locale}/search/submit/all/${current_active}/${0}`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      data: {search_param: {name: $('#search_name_facility').val(), address: $('#search_address').val(), specialization: $('#search_specialization option:selected').val(), type: $('#search_facility_type option:selected').val()}},
      dataType: 'json',
      beforeSend: function(){
        $('.item.doctor-affiliated.facility').remove()
      },
      success: function(response){
        $('.item.doctor-affiliated.facility').remove()
        if (response.length == 0 ){
          $('#append_here_head').append(`<div class="item doctor-affiliated facility" style="width: 500px; text-align:center; !important">
            <div class="content">
              <div class="header">No Results Found</div>
            </div>
            </div>`)
        }
        if (current_active == "All" || current_active == "Hospitals" || current_active == "所有" || current_active == "醫院"){
          for (let i=0;i<response.length;i++){
            let data = `<div class="item doctor-affiliated facility" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}">
            <div class="right floated content">
            <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}"></i></p>
            </div>
            <i class="hospital icon"></i>
            <div class="content">
            <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
            <div class="description">
            <p>${response[i].facility_address1}</p>
            <p>${response[i].facility_address2}</p>
            <div class="list-footer">
            <span>${response[i].facility_phone_no}</span>
            <a href="#" class="get_direction" name="get_location" facility_id="${response[i].id}"><i class="location arrow icon"></i>Get Direction</a>
            <div class="ui dropdown">
            <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
            <div class="menu">
            <div class="item">Uber</div>
            <div class="item">Call Grab</div>
            </div>
            </div>
            </div>
            </div>
            </div>
            </div>`
            $('#append_here_head').append(data)
          }
          open_drawer()
          select_dropdown()
          google.maps.event.addDomListener(window, 'load', initMapAllFacility(response));
        }
        if (current_active == "Doctors" || current_active == "醫生"){
          for (let i=0;i<response.length;i++){
            let data = ``
            let schedule = ``
            for (let s=0;s<response[i].schedule.length;s++)
            {
              schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
            }
            if (schedule == ``) {
              schedule = `Schedule: None`
            }
            data = `<div class="item doctor-affiliated facility" id="try_append" facility="${response[i]}">
            <div class="right floated content">
            <div class="ui button mini request request-hospital clickable" practitionerID="${response[i].practitioner_id}" facilityID="${response[i].facility_id}" f_status="${response[i].f_status}" p_status="${response[i].p_status}" status="${response[i].status}" specialization_id="${response[i].specialization_id}">REQUEST</div>
            </div>
            <i class="doctor icon"></i>
            <div class="content">
            <div class="header" doctor_name='${response[i].practitioner_name}'>${response[i].practitioner_name} <span>${response[i].status}</span></div>
            <div class="description">
                <p class="mb_zero" doctor_specialization='${response[i].specialization}' doctor_facility='${response[i].facility_name}' doctor_phone='${response[i].phones}'>${response[i].specialization}, <span>${response[i].facility_name} </span></p>
            ${schedule}
            <p>Disclaimer: Please call the doctor's clinic prior to your consultation. Schedule of doctors are subject to change without prior notice.</p>
            </div>
            </div>
            </div>`

            $('#append_here_head').append(data)
          }
          request_loa()
          select_dropdown()
          google.maps.event.addDomListener(window, 'load', initMapAllFacility(response));
        }
      }
    })
    }
  })

  function get_all_procedures_in_request_acu(){
    $('.request_acu_procedures').find('.mod_label').remove()
    $('.request_acu_procedures').find('p').remove()
    $('#search_app').append(`<div class="ui active inverted dimmer"><div class="ui loader"></div></div>`)
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/${locale}/search/request_acu/procedures`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      data: {loa_type: 'acu'},
      dataType: 'json',
      success: function(response){
        if (response.length != 0){
          for (let i=0;i<response.length;i++){
            $('.request_acu_procedures').append(`<p>${response[i].procedure}</p>`)
          }
        }else{
          $('.request_acu_procedures').append(`<label class="mod_label"><b>No procedures</b></label>`)
        }
        $('#request_acu_e-voucher').modal('show')
          $('#search_app').find('.ui.active.dimmer').remove()
      },
      error: function(){
        $('.request_acu_procedures').append(`<label class="mod_label"><b>No procedures</b></label>`)
        $('#request_acu_e-voucher').modal('show')
        $('#search_app').find('.ui.active.dimmer').remove()
      }
    })
  }

  function select_dropdown(){
    let previous = ''
    $('.ui.primary.dropdown.basic.button.request_loa').focus(function(){
      previous = $(this).find('.text').text()
    }).dropdown('setting', 'onChange', function(val){
      $('.ui.warning.message.absolute-label-message').remove()
      $('.append_single_hospital').find('hr').remove()
      $('.append_single_hospital').find('h3').remove()
      $('.append_single_hospital').find('.grey.light').remove()
      $('#view_facilities_button').remove()
      let current_active = $('.ui.button.search.active').text()
      let locale = $('#locale').val()
      if (val == "request acu") {
      let path = window.location.pathname
      if (path.indexOf('search') == -1){
            $('.ui.dropdown.button.request_loa').dropdown('set text', 'REQUEST LOA')
            $('.ui.dropdown.button.request_loa').dropdown('set value', '')
      }
        check_acu_authorization(function(return_data){
          if (return_data == false){
            if (current_active == "Hospitals"){
              hospital_acu_ajax(function(return_data){
                if (return_data == "No Results Found"){
                  $('.append_single_hospital').append(`
                    <hr>
                    <h3>
                      No Results Found
                    </h3>
                    <h3 class="light">
                      No Results Found
                    </h3>
                    <div class="grey light">
                      Credit and Collection / Billing Department / Accounting Department / Industrial Health Clinic
                    </div>
                    `)
                }else{
                  $('.map-holder').append(`<div class="ui warning message absolute-label-message">
                  Showing all affiliated hospitals. <a href="#" id="e-voucher"><u>Click here to view e-voucher</u></a></div>`)
                  if (return_data.indexOf($('#MemberID').val()) == -1){
                  $('.append_single_hospital').append(`
                    <hr>
                    <h3>
                      ${return_data[0]}
                    </h3>
                    <h3 class="light">
                      ${return_data[1]}
                    </h3>
                    <div class="grey light">
                      Credit and Collection / Billing Department / Accounting Department / Industrial Health Clinic
                    </div>
                    `)
                  }else{
                    $('#top_table').prepend(`
                      <tr class="vtop" id="view_facilities_button">
                      <td align="right" colspan="2">
                        <a href="${return_data}" target="_blank" class="ui button" style="margin-bottom: 2rem;">View affiliated Hospitals/Clinics</a>
                      </td>
                      </tr>
                    `)
                  }
              $('#e-voucher').click(function(){
                get_all_procedures_in_request_acu()
                $('.evoucher_number').text($('#MemberEvoucher').val())
                $('#member_e_voucher_qr_code').find('canvas').remove()
                $('#member_e_voucher_qr_code').qrcode({
                  width: 110,
                  height: 110,
                  text: $('#MemberQRcode').val()
                })
              })
                }
              })
              hospital_intellisense()
            }else if(current_active == "Doctors"){
              doctor_acu_ajax(function(return_data){
                if (return_data == "No Results Found"){
                  $('.append_single_hospital').append(`
                    <hr>
                    <h3>
                      No Results Found
                    </h3>
                    <h3 class="light">
                      No Results Found
                    </h3>
                    <div class="grey light">
                      Credit and Collection / Billing Department / Accounting Department / Industrial Health Clinic
                    </div>
                    `)
                }else{
                  $('.map-holder').append(`<div class="ui warning message absolute-label-message">
                  Showing all affiliated hospitals. <a href="#" id="e-voucher"><u>Click here to view e-voucher</u></a></div>`)
                  if (return_data.indexOf($('#MemberID').val()) == -1){
                  $('.append_single_hospital').append(`
                    <hr>
                    <h3>
                      ${return_data[0]}
                    </h3>
                    <h3 class="light">
                      ${return_data[1]}
                    </h3>
                    <div class="grey light">
                      Credit and Collection / Billing Department / Accounting Department / Industrial Health Clinic
                    </div>
                    `)
                  }else{
                    $('#top_table').prepend(`
                      <tr class="vtop">
                      <td align="right" colspan="2">
                        <a href="${return_data}" target="_blank" class="ui button" style="margin-bottom: 2rem;">View affiliated Hospitals/Clinics</a>
                      </td>
                      </tr>
                    `)
                  }
              $('#e-voucher').click(function(){
                get_all_procedures_in_request_acu()
                $('#member_e_voucher_qr_code').find('canvas').remove()
                $('#member_e_voucher_qr_code').qrcode({
                  width: 110,
                  height: 110,
                  text: $('#MemberQRcode').val()
                })
              })
                }
              })
              doctor_intellisense()
            }
          }else{
            $('.ui.dropdown.button.request_loa').dropdown('set text', 'REQUEST LOA')
            $('.ui.dropdown.button.request_loa').dropdown('set value', '')
            $('.ajs-message.ajs-error.ajs-visible').remove()
            alertify.error('ACU has been consumed already.<i id="notification_error" class="close icon"></i>');
            alertify.defaults = {
              notifier:{
                delay:5,
                position:'top-right',
                closeButton: false
              }
            };
            if (current_active == "Hospitals"){
              hospital_ajax()
              hospital_intellisense()
            }else if (current_active == "Doctors"){
              doctor_ajax()
            }
          }
        })
      }else{
        $('.ui.warning.message.absolute-label-message').remove()
        if (previous == 'Request ACU'){
          if (current_active == "Hospitals"){
            hospital_ajax()
            hospital_intellisense()
          }else if (current_active == "Doctors"){
            doctor_ajax()
          }
        }
      }
    });
  }

  function check_acu_authorization(handleData){
          const csrf2 = $('input[name="_csrf_token"]').val();
          $.ajax({
            url:`/${locale}/search/request_acu/check_authorization`,
            headers: {"X-CSRF-TOKEN": csrf2},
            type: 'get',
            dataType: 'json',
            success: function(response){
              handleData(response.acu)
            }
          })
  }
  function hospital_acu_ajax(handleData){
          const csrf2 = $('input[name="_csrf_token"]').val();
          $.ajax({
            url:`/${locale}/search/hospitals/${0}`,
            headers: {"X-CSRF-TOKEN": csrf2},
            type: 'get',
            data: {loa_type: 'acu'},
            dataType: 'json',
            beforeSend: function(){
              $('.item.doctor-affiliated.facility').remove()
            },
            success: function(response){
              $('.item.doctor-affiliated.facility').remove()
              if (response.length == 0 ){
                $('#append_here_head').append(`<div class="item doctor-affiliated facility" style="width: 500px; text-align:center; !important">
                <div class="content">
                  <div class="header">No Results Found</div>
                </div>
                </div>`)
                handleData('No Results Found')
              }else{
              for (let i=0;i<response.length;i++){
                let data = `<div class="item doctor-affiliated facility" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}">
                <div class="right floated content">
                <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}"></i></p>
                </div>
                <i class="hospital icon"></i>
                <div class="content">
                <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
                <div class="description">
                <p>${response[i].facility_address1}</p>
                <p>${response[i].facility_address2}</p>

                <div class="list-footer">
                <span>${response[i].facility_phone_no}</span>
                <a href="#" class="get_direction" name="get_location" facility_id="${response[i].id}"><i class="location arrow icon"></i>Get Direction</a>
                <div class="ui dropdown">
                <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
                <div class="menu">
                <div class="item">Uber</div>
                <div class="item">Call Grab</div>
                </div>
                </div>
                </div>
                </div>
                </div>
                </div>`
                $('#append_here_head').append(data)
              }
              open_drawer()
              select_dropdown()
              if (response.length == 1){
                handleData([response[0].facility_name, response[0].facility_address1 + ' ' +response[0].facility_address2])
              }else{
                handleData(`affiliated_facility/${$('#MemberID').val()}`)
              }
              }
              $('#search_hospital_button').removeClass('disabled')
            }
          })
  }
  function hospital_ajax(){
          const csrf2 = $('input[name="_csrf_token"]').val();
          $.ajax({
            url:`/${locale}/search/hospitals/${0}`,
            headers: {"X-CSRF-TOKEN": csrf2},
            type: 'get',
            dataType: 'json',
            beforeSend: function(){
              $('.item.doctor-affiliated.facility').remove()
            },
            success: function(response){
              $('.item.doctor-affiliated.facility').remove()
              if (response.length == 0 ){
                $('#append_here_head').append(`<div class="item doctor-affiliated facility" style="width: 500px; text-align:center; !important">
                <div class="content">
                  <div class="header">No Results Found</div>
                </div>
                </div>`)
              }
              for (let i=0;i<response.length;i++){
                let data = `<div class="item doctor-affiliated facility" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}">
                <div class="right floated content">
                <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].pf_count}"></i></p>
                </div>
                <i class="hospital icon"></i>
                <div class="content">
                <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
                <div class="description">
                <p>${response[i].facility_address1}</p>
                <p>${response[i].facility_address2}</p>

                <div class="list-footer">
                <span>${response[i].facility_phone_no}</span>
                <a href="#" class="get_direction" name="get_location" facility_id="${response[i].id}"><i class="location arrow icon"></i>Get Direction</a>
                <div class="ui dropdown">
                <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
                <div class="menu">
                <div class="item">Uber</div>
                <div class="item">Call Grab</div>
                </div>
                </div>
                </div>
                </div>
                </div>
                </div>`
                $('#append_here_head').append(data)
              }
              open_drawer()
              select_dropdown()
              $('#search_hospital_button').removeClass('disabled')
            }
          })
  }
  function doctor_acu_ajax(handleData){
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/search/doctors/all/${0}`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {loa_type: 'acu'},
        dataType: 'json',
        beforeSend: function(){
          $('.item.doctor-affiliated.facility').remove()
        },
        success: function(response){
          $('.item.doctor-affiliated.facility').remove()
          if (response.length == 0 ){
            $('#append_here_head').append(`<div class="item doctor-affiliated facility" style="width: 500px; text-align:center; !important">
              <div class="content">
                <div class="header">No Results Found</div>
              </div>
            </div>`)
             handleData('No Results Found')
          }else{
          for (let i=0;i<response.length;i++){
            let data = ``
            let schedule = ``
            for (let s=0;s<response[i].schedule.length;s++)
            {
              schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
            }
            if (schedule == ``) {
              schedule = `Schedule: None`
            }
            data = `<div class="item doctor-affiliated facility" id="try_append">
            <div class="right floated content">
            <div class="ui button mini request request-hospital clickable" practitionerID="${response[i].practitioner_id}" facilityID="${response[i].facility_id}" f_status="${response[i].f_status}" p_status="${response[i].p_status}" status="${response[i].status}" specialization_id="${response[i].specialization_id}">REQUEST</div>
            </div>
            <i class="doctor icon"></i>
            <div class="content">
            <div class="header" doctor_name='${response[i].practitioner_name}'>${response[i].practitioner_name} <span>${response[i].status}</span></div>
            <div class="description">
            <p class="mb_zero" doctor_specialization='${response[i].specialization}' doctor_facility='${response[i].facility_name}' doctor_phone='${response[i].phones}'>${response[i].specialization}, <span>${response[i].facility_name} </span></p>
            ${schedule}
            <p>Disclaimer: Please call the doctor's clinic prior to your consultation. Schedule of doctors are subject to change without prior notice.</p>
            </div>
            </div>
            </div>`

            $('#append_here_head').append(data)
          }
            $('#search_hospital_button').removeClass('disabled')
            if (response.length == 1){
                handleData([response[0].facility_name, response[0].facility_address1 + ' ' +response[0].facility_address2])
            }else{
              handleData(`affiliated_facility/${$('#MemberID').val()}`)
            }
          }
          $('#search_doctor_button').removeClass('disabled')
          request_loa()
          select_dropdown()
        }
      })

  }
  function doctor_ajax(){
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/search/doctors/all/${0}`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        dataType: 'json',
        beforeSend: function(){
          $('.item.doctor-affiliated.facility').remove()
        },
        success: function(response){
          $('.item.doctor-affiliated.facility').remove()
          if (response.length == 0 ){
            $('#append_here_head').append(`<div class="item doctor-affiliated facility" style="width: 500px; text-align:center; !important">
              <div class="content">
                <div class="header">No Results Found</div>
              </div>
            </div>`)
          }
          let fac_arr = []
          for (let i=0;i<response.length;i++){
            let data = ``
            let schedule = ``
            for (let s=0;s<response[i].schedule.length;s++)
            {
              schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
            }
            if (schedule == ``) {
              schedule = `Schedule: None`
            }
            data = `<div class="item doctor-affiliated facility" id="try_append" index="${i}">
            <div class="right floated content">
            <div class="ui button mini request request-hospital clickable" practitionerID="${response[i].practitioner_id}" facilityID="${response[i].facility_id}" f_status="${response[i].f_status}" p_status="${response[i].p_status}" status="${response[i].status}" specialization_id="${response[i].specialization_id}">REQUEST</div>
            </div>
            <i class="doctor icon"></i>
            <div class="content">
            <div class="header" doctor_name='${response[i].practitioner_name}'>${response[i].practitioner_name} <span>${response[i].status}</span></div>
            <div class="description">
            <p class="mb_zero" doctor_specialization='${response[i].specialization}' doctor_facility='${response[i].facility_name}' doctor_phone='${response[i].phones}'>${response[i].specialization}, <span>${response[i].facility_name} </span></p>
            ${schedule}
            <p>Disclaimer: Please call the doctor's clinic prior to your consultation. Schedule of doctors are subject to change without prior notice.</p>
            </div>
            </div>
            </div>`
            $('#append_here_head').append(data)
          fac_arr.push(response[i])

          }
    $('div[id="try_append"]').on('click', function(){
      let response = $(this).attr("index")
      response = fac_arr[response]
      google.maps.event.addDomListener(window, 'load', initMap2(response));
    })
          $('#search_doctor_button').removeClass('disabled')
          request_loa()
          select_dropdown()
        }
      })
  }
  function hospital_intellisense(){
    let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
    if(loa_value == 'Request ACU' || loa_value == '請求Acu'){
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
        url:`/${locale}/search/intellisense/Hospitals`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {loa_type: "acu"},
        dataType: 'json',
        success: function(response){
          let content_name = []
          let content_address = []
          for(let i=0;i<response.length;i++){
          content_name.push({
              title: response[i].name
            })
          content_address.push(response[i].facility_address1 +' '+ response[i].facility_address2)
          }
          let filter_content_address = []
          content_address = $.unique(content_address)
          for (let i=0;i<content_address.length;i++){
            filter_content_address.push({
              title: content_address[i]
            })
          }
        $('#search_facility').search({
          fulltextsearch: 'exact',
          source: content_name,
          maxresults: 10,
          cache: false
        })
        $('.ui.search.address').search({
          fulltextsearch: 'exact',
          source: filter_content_address,
          maxresults: 10,
          cache: false
        })
      }
    })
    }else{
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
        url:`/${locale}/search/intellisense/Hospitals`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        dataType: 'json',
        success: function(response){
          let content_name = []
          let content_address = []
          for(let i=0;i<response.length;i++){
          content_name.push({
              title: response[i].name
            })
          content_address.push(response[i].facility_address1 +' '+ response[i].facility_address2)
          }
          let filter_content_address = []
          content_address = $.unique(content_address)
          for (let i=0;i<content_address.length;i++){
            filter_content_address.push({
              title: content_address[i]
            })
          }
        $('#search_facility').search({
          source: content_name,
          maxresults: 10,
          cache: false
        })
        $('.ui.search.address').search({
          source: filter_content_address,
          maxresults: 10,
          cache: false
        })
      }
    })
    }
  }
  function doctor_intellisense(){
    let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
    if(loa_value == 'Request ACU' || loa_value == '請求Acu'){
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
        url:`/${locale}/search/intellisense/Doctors`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {loa_type: "acu"},
        dataType: 'json',
        success: function(response){
          let content_name = []
          let content_address = []
          for(let i=0;i<response.length;i++){
          content_name.push(response[i].name)
          content_address.push(response[i].facility_address1 +' '+ response[i].facility_address2)
          }
          let filter_content_name = []
          let filter_content_address = []
          content_address = $.unique(content_address)
          content_name = $.unique(content_name)
          for (let i=0;i<content_name.length;i++){
            filter_content_name.push({
              title: content_name[i]
            })
          }
          for (let i=0;i<content_address.length;i++){
            filter_content_address.push({
              title: content_address[i]
            })
          }
        $('#search_facility').search({
          source: filter_content_name,
          maxResults: 10,
          cache: false
        })
        $('.ui.search.address').search({
          source: filter_content_address,
          maxResults: 10,
          cache: false
        })
      }
    })
    }else{
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
        url:`/${locale}/search/intellisense/Doctors`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        dataType: 'json',
        success: function(response){
          let content_name = []
          let content_address = []
          for(let i=0;i<response.length;i++){
          content_name.push(response[i].name)
          content_address.push(response[i].facility_address1 +' '+ response[i].facility_address2)
          }
          let filter_content_name = []
          let filter_content_address = []
          content_address = $.unique(content_address)
          content_name = $.unique(content_name)
          for (let i=0;i<content_name.length;i++){
            filter_content_name.push({
              title: content_name[i]
            })
          }
          for (let i=0;i<content_address.length;i++){
            filter_content_address.push({
              title: content_address[i]
            })
          }
        $('#search_facility').search({
          source: filter_content_name,
          maxResults: 10,
          cache: false
        })
        $('.ui.search.address').search({
          source: filter_content_address,
          maxResults: 10,
          cache: false
        })
      }
    })
    }
  }
          let ef_date = $('#member_effectivity_date').val()
          let ex_date = $('#member_expiry_date').val()
          $('.member_log_date').html(`${moment(ef_date).format('DD-MMM-YYYY')} to ${moment(ex_date).format('DD-MMM-YYYY')} `);
  /*
  $('#search_all').click(function() {
    if ($(this).attr('class') != 'ui button active'){
      $('#search_all').attr('class','ui button active')
      $('#search_doctor').attr('class','ui button')
      $('#search_hospital').attr('class','ui button')
      $('.item.doctor-affiliated.facility').remove()
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/search/all`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        dataType: 'json',
        success: function(response){
          if (locale == 'zh') {

            $('#append_here_head').append(
   `<div class="item doctor-affiliated facility">
              <div class="right floated content">
                <p class="text aligned right"><i class="doctor icon"></i>1<i class="caret right icon" facility_id="48243845-6a22-4869-8c39-e98f0d71ddbb" doctor_count="1"></i></p>
                <div class="ui button mini request request-hospital clickable">請求</div>
              </div>
              <i class="hospital icon"></i>
              <div class="content">
                <div class="header">MAKATI医疗中心<span>附属</span></div>
                <div class="description">
                  <p id="line1">1234567 1234568</p>
                  <p id="line2">Makati 1206 马尼拉大都会</p>

                  <div class="list-footer">
                    <span>7656734</span>
                    <a href="#" class="get_direction" name="get_location"><i class="location arrow icon"></i>得到指引</a>
                    <div class="ui dropdown" tabindex="0">
                      <div class="get_direction clickable"><i class="icon car"></i> 叫一輛出租車</div>
                      <div class="menu" tabindex="-1">
                        <div class="item">Uber</div>
                        <div class="item">呼叫 Grab</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
              <div class="item doctor-affiliated facility">
                <div class="right floated content">
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
                </div>
                <i class="doctor icon"></i>
                <div class="content">
                  <div class="header">弗洛伊德，西格蒙德<span>附属</span></div>
                  <div class="description">
                    <p class="mb_zero">Dermatology, <span>MAKATI医疗中心 </span></p>

                      <p class="mb_zero">時間表: 辰, 1, 12:00:00 - 15:00:00</p>

                  </div>
                </div>
              </div>


            <div class="item doctor-affiliated facility">
              <div class="right floated content">
                <p class="text aligned right"><i class="doctor icon"></i>1<i class="caret right icon" facility_id="f303e498-c3dd-4f02-8891-a56e8adbcea2" doctor_count="1"></i></p>
                <div class="ui button mini request request-hospital clickable">請求</div>
              </div>
              <i class="hospital icon"></i>
              <div class="content">
                <div class="header">中文综合医院和医疗中心<span>附属</span></div>
                <div class="description">
                  <p id="line1">1234567 1234568</p>
                  <p id="line2">Makati 1211 马尼拉大都会</p>

                  <div class="list-footer">
                    <span>7656734</span>
                    <a href="#" class="get_direction" name="get_location"><i class="location arrow icon"></i>得到指引</a>
                    <div class="ui dropdown" tabindex="0">
                      <div class="get_direction clickable"><i class="icon car"></i> 叫一輛出租車</div>
                      <div class="menu" tabindex="-1">
                        <div class="item">Uber</div>
                        <div class="item">呼叫 Grab</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
              <div class="item doctor-affiliated facility">
                <div class="right floated content">
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
                </div>
                <i class="doctor icon"></i>
                <div class="content">
                  <div class="header">荣格，卡尔<span>附属</span></div>
                  <div class="description">
                    <p class="mb_zero">General Surgery, <span>中文综合医院和医疗中心 </span></p>

                      <p class="mb_zero">時間表: 辰, 1, 12:00:00 - 15:00:00</p>

                  </div>
                </div>
              </div>

            <div class="item doctor-affiliated facility">
              <div class="right floated content">
                <p class="text aligned right"><i class="doctor icon"></i>1<i class="caret right icon" facility_id="c0127c0b-e498-4ab8-a55e-e3316326e826" doctor_count="1"></i></p>
                <div class="ui button mini request request-hospital clickable">請求</div>
              </div>
              <i class="hospital icon"></i>
              <div class="content">
                <div class="header">MYHEALTH诊所 - SM 北EDSA<span>附属</span></div>
                <div class="description">
                  <p id="line1">1234567 1234568</p>
                  <p id="line2">Quezon 1200 马尼拉大都会</p>

                  <div class="list-footer">
                    <span>7656734</span>
                    <a href="#" class="get_direction" name="get_location"><i class="location arrow icon"></i>得到指引</a>
                    <div class="ui dropdown" tabindex="0">
                      <div class="get_direction clickable"><i class="icon car"></i> 叫一輛出租車</div>
                      <div class="menu" tabindex="-1">
                        <div class="item">Uber</div>
                        <div class="item">呼叫 Grab</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
              <div class="item doctor-affiliated facility">
                <div class="right floated content">
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
                </div>
                <i class="doctor icon"></i>
                <div class="content">
                  <div class="header">索里亚诺, 德摩斯梯尼<span>附属</span></div>
                  <div class="description">
                    <p class="mb_zero">Otolaryngology-Head and Neck Surgery, <span>MYHEALTH诊所 - SM 北EDSA </span></p>

                      <p class="mb_zero">時間表: 辰, 1, 12:00:00 - 15:00:00</p>

                  </div>
                </div>
              </div>`
            )
          }

          else
            {

          for (let i=0;i<response.length;i++){
            let data = ``
            //   data = `<div class="item doctor-affiliated facility">
            //   <div class="right floated content">
            //   <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].practitioner.length}"></i></p>
            //   <div class="ui button mini request request-hospital clickable">請求</div>
            //   </div>
            //   <i class="hospital icon"></i>
            //   <div class="content">
            //   <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
            //   <div class="description">
            //   <p>${response[i].facility_address1}</p>
            //   <p>${response[i].facility_address2}</p>

            //   <div class="list-footer">
            //   <span>${response[i].facility_phone_no}</span>
            //   <a href="#" class="get_direction"><i class="location arrow icon"></i>Get Direction</a>
            //   <div class="ui dropdown">
            //   <div class="get_direction clickable"><i class="icon car"></i> 叫一輛出租車</div>
            //   <div class="menu">
            //   <div class="item">Uber</div>
            //   <div class="item">Call Grab</div>
            //   </div>
            //   </div>
            //   </div>
            //   </div>
            //   </div>
            //   </div>`
            // }
            // else{
              data = `<div class="item doctor-affiliated facility">
              <div class="right floated content">
              <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id} doctor_count="${response[i].practitioner.length}"></i></p>
              <div class="ui button mini request request-hospital clickable">REQUEST</div>
              </div>
              <i class="hospital icon"></i>
              <div class="content">
              <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
              <div class="description">
              <p>${response[i].facility_address1}</p>
              <p>${response[i].facility_address2}</p>

              <div class="list-footer">
              <span>${response[i].facility_phone_no}</span>
              <a href="#" class="get_direction"><i class="location arrow icon"></i>Get Direction</a>
              <div class="ui dropdown">
              <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
              <div class="menu">
              <div class="item">Uber</div>
              <div class="item">Call Grab</div>
              </div>
              </div>
              </div>
              </div>
              </div>
              </div>`
              // }
            $('#append_here_head').append(data)
            let practitioner = response[i].practitioner
            for (let a=0;a<practitioner.length;a++){
              let schedule = ``
              let data = ``
            if (locale == 'zh') {
              for (let s=0;s<practitioner[a].schedule.length;s++)
              {
                schedule = schedule + `<p class="mb_zero">時間表: ${practitioner[a].schedule[s].day}, ${practitioner[a].schedule[s].room}, ${practitioner[a].schedule[s].time_from} - ${practitioner[a].schedule[s].time_to}</p>`
              }
              if (schedule == ``) {
                schedule = `時間表: None`
              }
              data = `<div class="item doctor-affiliated facility" id="try_append">
              <div class="right floated content">
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
              </div>
              <i class="doctor icon"></i>
              <div class="content">
              <div class="header">${practitioner[a].practitioner_name} <span>${practitioner[a].status}</span></div>
              <div class="description">
              <p class="mb_zero">${practitioner[a].specialization.name}, <span>${practitioner[a].facility_name} </span></p>
              ${schedule}
              </div>
              </div>
              </div>`
            }
            else{
              for (let s=0;s<practitioner[a].schedule.length;s++)
              {
                schedule = schedule + `<p class="mb_zero">Schedule: ${practitioner[a].schedule[s].day}, ${practitioner[a].schedule[s].room}, ${practitioner[a].schedule[s].time_from} - ${practitioner[a].schedule[s].time_to}</p>`
              }
              if (schedule == ``) {
                schedule = `Schedule: None`
              }
              data = `<div class="item doctor-affiliated facility" id="try_append">
              <div class="right floated content">
              <div class="ui button mini request request-hospital clickable">REQUEST</div>
              </div>
              <i class="doctor icon"></i>
              <div class="content">
              <div class="header">${practitioner[a].practitioner_name} <span>${practitioner[a].status}</span></div>
              <div class="description">
              <p class="mb_zero">${practitioner[a].specialization.name}, <span>${practitioner[a].facility_name} </span></p>
              ${schedule}
              </div>
              </div>
              </div>`
              }
              $('#append_here_head').append(data)
              $('.item.doctor-affiliated.facility').find('.button.request-hospital.clickable').click(function(){
                let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
                if(loa_value == 'Request Consultant' || loa_value == '請求實驗室')
                  {
                    $('#facility_id').val($(this).attr('facilityID'))
                    $('#practitioner_id').val($(this).attr('practitionerID'))
                    $('#request_form').modal('show');
                    $('#doctor_name').text($(this).closest('#try_append').find('.header').attr('doctor_name'))
                    $('#doctor_specialization').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_specialization'))
                    $('#doctor_facility').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_facility'))
                    $('#doctor_phone_no').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_phone'))
                  }
                  else if(loa_value == 'Request Lab' || loa_value == '請求顧問')
                    {
                      $('#request_form_lab').modal('show');
                    }
              })
            }
          }
            }
            open_drawer()
        }
      })
    }
  })
  $('#search_doctor').click(function(){
    if ($(this).attr('class') != 'ui button active'){
      $('#search_doctor').attr('class','ui button active')
      $('#search_all').attr('class','ui button')
      $('#search_hospital').attr('class','ui button')
      $('.item.doctor-affiliated.facility').remove()
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/search/doctors`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        dataType: 'json',
        success: function(response){
          if (locale == 'zh') {

            $('#append_here_head').append(
           ` <div class="item doctor-affiliated facility" id="try_append">
              <div class="right floated content">
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
              </div>
              <i class="doctor icon"></i>
              <div class="content">
              <div class="header">弗洛伊德，西格蒙德<span>附属</span></div>
              <div class="description">
              <p class="mb_zero">Dermatology, <span>MAKATI医疗中心 </span></p>
              <p class="mb_zero">時間表: 辰, 1, 12:00:00 - 15:00:00</p>
              </div>
              </div>
              </div><div class="item doctor-affiliated facility" id="try_append">
              <div class="right floated content">
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
              </div>
              <i class="doctor icon"></i>
              <div class="content">
              <div class="header">荣格，卡尔<span>附属</span></div>
              <div class="description">
              <p class="mb_zero">General Surgery, <span>中文综合医院和医疗中心 </span></p>

              <p class="mb_zero">時間表: 辰, 1, 12:00:00 - 15:00:00</p>
              </div>
              </div>
              </div><div class="item doctor-affiliated facility" id="try_append">
              <div class="right floated content">
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
              </div>
              <i class="doctor icon"></i>
              <div class="content">
              <div class="header">索里亚诺, 德摩斯梯尼<span>附属</span></div>
              <div class="description">
              <p class="mb_zero">Otolaryngology-Head and Neck Surgery, <span>MYHEALTH诊所 - SM 北EDSA </span></p>

              <p class="mb_zero">時間表: 辰, 1, 12:00:00 - 15:00:00</p>
              </div>
              </div>
              </div>`
            )
          }
          else{
          for (let i=0;i<response.length;i++){
            let schedule = ``
            let data = ``

            //    for (let s=0;s<response[i].schedule.length;s++)
            //    {
            //      schedule = schedule + `<p class="mb_zero">時間表: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
            //    }
            //    if (schedule == ``) {
            //      schedule = `時間表: None`
            //    }
            //    data = `<div class="item doctor-affiliated facility" id="try_append">
            //    <div class="right floated content">
            //    <div class="ui button mini request request-hospital clickable">請求</div>
            //    </div>
            //    <i class="doctor icon"></i>
            //    <div class="content">
            //    <div class="header">${response[i].practitioner_name} <span>${response[i].status}</span></div>
            //    <div class="description">
            //    <p class="mb_zero">${response[i].specialization.name}, <span>${response[i].facility_name} </span></p>
            //    ${schedule}
            //    </div>
            //    </div>
            //    </div>`

              for (let s=0;s<response[i].schedule.length;s++)
              {
                schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
              }
              if (schedule == ``) {
                schedule = `Schedule: None`
              }
              data = `<div class="item doctor-affiliated facility" id="try_append">
              <div class="right floated content">
              <div class="ui button mini request request-hospital clickable">REQUEST</div>
              </div>
              <i class="doctor icon"></i>
              <div class="content">
              <div class="header">${response[i].practitioner_name} <span>${response[i].status}</span></div>
              <div class="description">
              <p class="mb_zero">${response[i].specialization.name}, <span>${response[i].facility_name} </span></p>
              ${schedule}
              </div>
              </div>
              </div>`

            $('#append_here_head').append(data)
            $('.item.doctor-affiliated.facility').find('.button.request-hospital.clickable').click(function(){
              let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
              if(loa_value == 'Request Consultant' || loa_value == '請求實驗室')
                {
                  $('#facility_id').val($(this).attr('facilityID'))
                  $('#practitioner_id').val($(this).attr('practitionerID'))
                  $('#request_form').modal('show');
                  $('#doctor_name').text($(this).closest('#try_append').find('.header').attr('doctor_name'))
                  $('#doctor_specialization').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_specialization'))
                  $('#doctor_facility').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_facility'))
                  $('#doctor_phone_no').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_phone'))
                }
                else if(loa_value == 'Request Lab' || loa_value == '請求顧問')
                  {
                    $('#request_form_lab').modal('show');
                  }
            })
          }

          }
        }
      })
    }
  })
  $('#search_hospital').click(function(){
    if ($(this).attr('class') != 'ui button active'){
      $('#search_hospital').attr('class','ui button active')
      $('#search_all').attr('class','ui button')
      $('#search_doctor').attr('class','ui button')
      $('.item.doctor-affiliated.facility').remove()
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/search/all`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        dataType: 'json',
        success: function(response){
          if (locale == 'zh'){

            $('#append_here_head').append(
              `
                <div class="item doctor-affiliated facility">
              <div class="right floated content">
              <p class="text aligned right"><i class="doctor icon"></i>1<i class="caret right icon" facility_id="48243845-6a22-4869-8c39-e98f0d71ddbb" doctor_count="1"></i></p>
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
              </div>
              <i class="hospital icon"></i>
              <div class="content">
              <div class="header">MAKATI医疗中心<span>附属</span></div>
              <div class="description">
              <p id="line1">1234567 1234568</p>
              <p id="line2">Makati 1206 马尼拉大都会</p>

              <div class="list-footer">
              <span>7656734</span>
              <a href="#" class="get_direction" name="get_location"><i class="location arrow icon"></i>得到指引</a>
              <div class="ui dropdown" tabindex="0">
              <div class="get_direction clickable"><i class="icon car"></i> 叫一輛出租車</div>
              <div class="menu" tabindex="-1">
              <div class="item">Uber</div>
              <div class="item">呼叫 Grab</div>
              </div>
              </div>
              </div>
              </div>
              </div>
              </div><div class="item doctor-affiliated facility">
              <div class="right floated content">
              <p class="text aligned right"><i class="doctor icon"></i>1<i class="caret right icon" facility_id="c0127c0b-e498-4ab8-a55e-e3316326e826" doctor_count="1"></i></p>
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
              </div>
              <i class="hospital icon"></i>
              <div class="content">
              <div class="header">MYHEALTH诊所 - SM 北EDSA<span>附属</span></div>
              <div class="description">
              <p id="line1">1234567 1234568</p>
              <p id="line2">Quezon 1200 马尼拉大都会</p>

              <div class="list-footer">
              <span>7656734</span>
              <a href="#" class="get_direction" name="get_location"><i class="location arrow icon"></i>得到指引</a>
              <div class="ui dropdown" tabindex="0">
              <div class="get_direction clickable"><i class="icon car"></i> 叫一輛出租車</div>
              <div class="menu" tabindex="-1">
              <div class="item">Uber</div>
              <div class="item">呼叫 Grab</div>
              </div>
              </div>
              </div>
              </div>
              </div>
              </div><div class="item doctor-affiliated facility">
              <div class="right floated content">
              <p class="text aligned right"><i class="doctor icon"></i>1<i class="caret right icon" facility_id="f303e498-c3dd-4f02-8891-a56e8adbcea2" doctor_count="1"></i></p>
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
              </div>
              <i class="hospital icon"></i>
              <div class="content">
              <div class="header">中文综合医院和医疗中心<span>附属</span></div>
              <div class="description">
              <p id="line1">1234567 1234568</p>
              <p id="line2">Makati 1211 马尼拉大都会</p>

              <div class="list-footer">
              <span>7656734</span>
              <a href="#" class="get_direction" name="get_location"><i class="location arrow icon"></i>得到指引</a>
              <div class="ui dropdown" tabindex="0">
              <div class="get_direction clickable"><i class="icon car"></i> 叫一輛出租車</div>
              <div class="menu" tabindex="-1">
              <div class="item">Uber</div>
              <div class="item">呼叫 Grab</div>
              </div>
              </div>
              </div>
              </div>
              </div>
              </div>
              `
            )
          }
          else{
            for (let i=0;i<response.length;i++){
              let data = ``
              data = `<div class="item doctor-affiliated facility">
              <div class="right floated content">
              <p class="text aligned right"><i class="doctor icon"></i>${response[i].pf_count}<i class="caret right icon" facility_id="${response[i].id}" doctor_count="${response[i].practitioner.length}"></i></p>
              <div class="ui button mini request request-hospital clickable">REQUEST</div>
              </div>
              <i class="hospital icon"></i>
              <div class="content">
              <div class="header">${response[i].facility_name}<span>${response[i].facility_status}</span></div>
              <div class="description">
              <p>${response[i].facility_address1}</p>
              <p>${response[i].facility_address2}</p>

              <div class="list-footer">
              <span>${response[i].facility_phone_no}</span>
              <a href="#" class="get_direction"><i class="location arrow icon"></i>Get Direction</a>
              <div class="ui dropdown">
              <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
              <div class="menu">
              <div class="item">Uber</div>
              <div class="item">Call Grab</div>
              </div>
              </div>
              </div>
              </div>
              </div>
              </div>`
              $('#append_here_head').append(data)
              $('.item.doctor-affiliated.facility').find('.button.request-hospital.clickable').click(function(){
                let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
                if(loa_value == 'Request Consultant' || loa_value == '請求實驗室')
                  {
                    $('#facility_id').val($(this).attr('facilityID'))
                    $('#practitioner_id').val($(this).attr('practitionerID'))
                    $('#request_form').modal('show');
                    $('#doctor_name').text($(this).closest('#try_append').find('.header').attr('doctor_name'))
                    $('#doctor_specialization').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_specialization'))
                    $('#doctor_facility').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_facility'))
                    $('#doctor_phone_no').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_phone'))
                  }
                  else if(loa_value == 'Request Lab' || loa_value == '請求顧問')
                    {
                      $('#request_form_lab').modal('show');
                    }
              })
            }
          }

          open_drawer()
        }
      })
    }
  })
*/
  function open_drawer(){
    $('.ui.dropdown').dropdown();
    let clicked_location = false
    $('a[name="get_location"]').unbind("click").on('click', function(){
      $('.item.doctor-affiliated.details').remove()
      if ('active'.indexOf($('#list_detail').attr('class'))){
        const locale = $('#locale').val();
        let facility_id = $(this).attr('facility_id')
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/${locale}/search/get_direction/${facility_id}`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          dataType: 'json',
          success: function(response){
            $('#list_detail').removeClass('active')
            google.maps.event.addDomListener(window, 'load', initMap2(response));
          }
        })
      }
      clicked_location = true
    });
    $('.item.doctor-affiliated.facility').unbind("click").on('click', function(e) {
      if (clicked_location == false){
        if ($('#list_detail').attr('class').indexOf('active') < 0 && parseInt($(this).attr('doctor_count')) > 0 ){
          $('#list_detail').addClass('active')
          let facility_id = $(this).attr('facility_id')
          $('.item.doctor-affiliated.details').remove()
          const csrf2 = $('input[name="_csrf_token"]').val();
          $.ajax({
            url:`/${locale}/search/doctors/${facility_id}`,
            headers: {"X-CSRF-TOKEN": csrf2},
            type: 'get',
            dataType: 'json',
            success: function(response){
              for (let i=0;i<response.length;i++){
                let schedule = ``
                let data = ``
                if (locale == 'zh'){
                  for (let s=0;s<response[i].schedule.length;s++)
                  {
                    schedule = schedule + `<p class="mb_zero">時間表: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
                  }
                  if (schedule == ``) {
                    schedule = `時間表: None`
                  }
                  data = `<div class="item doctor-affiliated details" id="try_append">
                  <div class="right floated content">
                  <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}" f_status="${response[i].f_status}" p_status="${response[i].p_status}" status="${response[i].status}" specialization_id="${response[i].specialization_id}">請求</div>
                  </div>
                  <i class="doctor icon"></i>
                  <div class="content">
                  <div class="header" doctor_name='${response[i].practitioner_name}'>${response[i].practitioner_name} <span>${response[i].status}</span></div>
                  <div class="description">
                  <p class="mb_zero" doctor_specialization='${response[i].specialization}' doctor_facility='${response[i].facility_name}' doctor_phone='${response[i].phones}'>${response[i].specialization}, <span>${response[i].facility_name} </span></p>
                  ${schedule}
                  </div>
                  </div>
                  </div>`
                }
                else{
                  for (let s=0;s<response[i].schedule.length;s++)
                  {
                    schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
                  }
                  if (schedule == ``) {
                    schedule = `Schedule: None`
                  }
                  data = `<div class="item doctor-affiliated details" id="try_append">
                  <div class="right floated content">
                  <div class="ui button mini request request-lab" practitionerID="${response[i].practitioner_id}" facilityID="${response[i].facility_id}" f_status="${response[i].f_status}" p_status="${response[i].p_status}" status="${response[i].status}" specialization_id="${response[i].specialization_id}">REQUEST</div>
                  </div>
                  <i class="doctor icon"></i>
                  <div class="content">
                  <div class="header" doctor_name='${response[i].practitioner_name}'>${response[i].practitioner_name} <span>${response[i].status}</span></div>
                  <div class="description">
                  <p class="mb_zero" doctor_specialization='${response[i].specialization}' doctor_facility='${response[i].facility_name}' doctor_phone='${response[i].phones}'>${response[i].specialization}, <span>${response[i].facility_name} </span></p>
                  ${schedule}
                  <p>Disclaimer: Please call the doctor's clinic prior to your consultation. Schedule of doctors are subject to change without prior notice.</p>
                  </div>
                  </div>
                  </div>`
                }
                $('#append_here_tail').append(data)
              }
              request_loa()
            }
          })
        }else
          {
            $('#list_detail').removeClass('active')
          }
      }
      clicked_location = false
    })
  }

  function check_coverage(coverage){
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/${locale}/search/request_loa_consult/check_coverage`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      dataType: 'json',
      success: function(response){
        let op_con = response.consult
        let op_lab = response.lab
        let acu = response.acu
        if (coverage == 'acu'){
          $('.ui.button.request_loa').find('.menu').find('.item').each(function(){
            if (acu == false && $(this).text() == 'Request ACU'){
              $(this).remove()
            }
          })
        }else{
        if (coverage == "consult"){
          if (op_con == true){
            $('#request_form').modal('show');
          }
          else{
            $('.ajs-message.ajs-error.ajs-visible').remove()
            alertify.error('You have no benefit for this coverage.<i id="notification_error" class="close icon"></i>');
            alertify.defaults = {
              notifier:{
                delay:5,
                position:'top-right',
                closeButton: false
              }
            };
          }
        }
        else if (coverage == "laboratory"){
          if (op_lab == true){
            $('#request_form_lab').modal('show');
          }
          else{
            $('.ajs-message.ajs-error.ajs-visible').remove()
            alertify.error('You have no benefit for this coverage.<i id="notification_error" class="close icon"></i>');
            alertify.defaults = {
              notifier:{
                delay:5,
                position:'top-right',
                closeButton: false
              }
            };
          }
        }
        else{
            $('.ajs-message.ajs-error.ajs-visible').remove()
          alertify.error('Please select a Coverage.<i id="notification_error" class="close icon"></i>');
          alertify.defaults = {
            notifier:{
              delay:5,
              position:'top-right',
              closeButton: false
            }
          };
        }
        }
      }
    })
  }

  function request_loa(){
    $('.item.doctor-affiliated.facility').find('.button.request-hospital.clickable').click(function(){
      let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
      if(loa_value == 'Request Consultation' || loa_value == '請求實驗室')
        {
          $('#facility_id').val($(this).attr('facilityid'))
          $('#practitioner_id').val($(this).attr('practitionerid'))
          $('#specialization_id').val($(this).attr('specialization_id'))
          //if ($(this).attr('f_status') == "Affiliated"){
          // if ($(this).attr('status') == "Affiliated"){
              check_coverage('consult')
              $('#doctor_name').text($(this).closest('.doctor-affiliated').find('.header').attr('doctor_name'))
              $('#doctor_specialization').text($(this).closest('.doctor-affiliated').find('.mb_zero').attr('doctor_specialization'))
              $('#doctor_facility').text($(this).closest('.doctor-affiliated').find('.mb_zero').attr('doctor_facility'))
              $('#doctor_phone_no').text($(this).closest('.doctor-affiliated').find('.mb_zero').attr('doctor_phone'))
            // }
              /*else{
              alertify.error('Please select affiliated Doctor.<i id="notification_error" class="close icon"></i>');
              alertify.defaults = {
                notifier:{
                  delay:5,
                  position:'top-right',
                  closeButton: false
                }
              };
              }*/
              // }
          /* else{
            alertify.error('You have no access to  this Hospital.<i id="notification_error" class="close icon"></i>');
            alertify.defaults = {
              notifier:{
                delay:5,
                position:'top-right',
                closeButton: false
              }
            };
            }*/
        }
        else if(loa_value == 'Request Lab' || loa_value == '請求顧問')
          {
              check_coverage('laboratory')
          }
          else{
              check_coverage('null')
          }
    })

    $('.doctor-affiliated.details').find('.button.mini.request-lab').click(function(){
      let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
      if(loa_value == 'Request Consultation' || loa_value == '請求實驗室')
        {
          $('#facility_id').val($(this).attr('facilityID'))
          $('#specialization_id').val($(this).attr('specialization_id'))
          $('#practitioner_id').val($(this).attr('practitionerID'))
          // if ($(this).attr('f_status') == "Affiliated"){
          //  if ($(this).attr('status') == "Affiliated"){
              check_coverage('consult')
              $('#doctor_name').text($(this).closest('#try_append').find('.header').attr('doctor_name'))
              $('#doctor_specialization').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_specialization'))
              $('#doctor_facility').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_facility'))
              $('#doctor_phone_no').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_phone'))
              // }
              /* else{
              alertify.error('Please select affiliated Doctor.<i id="notification_error" class="close icon"></i>');
              alertify.defaults = {
                notifier:{
                  delay:5,
                  position:'top-right',
                  closeButton: false
                }
              };
              }*/
              //}
              /* else{
            alertify.error('You have no access to  this Hospital.<i id="notification_error" class="close icon"></i>');
            alertify.defaults = {
              notifier:{
                delay:5,
                position:'top-right',
                closeButton: false
              }
            };
            }*/
        }
        else if(loa_value == 'Request Lab' || loa_value == '請求顧問')
          {
            check_coverage('laboratory')
          }
          else{
            check_coverage('null')
          }
    })
  }

  let today = new Date()

  Date.shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  function short_months(dt)
  {
    return Date.shortMonths[dt.getMonth()];
  }
  function date_day(i){
    let day = i
    if (day == 1) {
      day = i + "st";
    } else if (day == 2) {
      day = i + "nd"
    } else if (day == 3) {
      day = i + "rd"
    }else{
      day = i + "th"
    }
    return i
  }
  let date_today = short_months(today) + ' ' + date_day(today.getDate()) + ', ' + today.getFullYear()

  $('#date_now').text(date_today)
  $('#check_confirm').change(function(){
    if ($('#check_confirm:checkbox:checked').length > 0 && $('#text_complaint').val() != ""){
      $('.big.ui.blue.button').removeClass('disabled')
    }else{
      $('.big.ui.blue.button').addClass('disabled')
    }
  })
  $('#text_complaint').keyup(function(){
    if ($('#check_confirm:checkbox:checked').length > 0 && $('#text_complaint').val() != ""){
      $('.big.ui.blue.button').removeClass('disabled')
    }else{
      $('.big.ui.blue.button').addClass('disabled')
    }
  })
  $('.big.ui.blue.button').click(function(){
    let data = {'admission_datetime': $('#availment_date').dropdown('get value'),
      'chief_complaint' : $('#text_complaint').val()
    };
    let facility_id = $('#facility_id').val()
    let practitioner_id = $('#practitioner_id').val()
    let specialization_id = $('#specialization_id').val();
    const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/search/request_loa_consult/${practitioner_id}/${facility_id}/${specialization_id}`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: data,
        dataType: 'json',
        success: function(response){
          $('#request_form').modal('hide')
          alertify.success('Successfully requested LOA! Transaction ID: ' + response.transaction_id + '<i id="notification_success" class="close icon"></i>');
          alertify.defaults = {
            notifier:{
              delay:10,
              position:'top-right',
              closeButton: false
            }
          };
        }
      })
  })

  $('#request_form').modal({
    closable  : false,
    onHide : function(){
      $('#text_complaint').val('')
      $('#check_confirm').prop('checked', false);
      $('.big.ui.blue.button').addClass('disabled')
    }
  });

//  function get_location(){
//  }

  function initMapOnLoad(){
    if($('#search_hospital_button').hasClass('active')){
          const csrf2 = $('input[name="_csrf_token"]').val();
          $.ajax({
            url:`/${locale}/search/hospitals/${0}`,
            headers: {"X-CSRF-TOKEN": csrf2},
            type: 'get',
            dataType: 'json',
            success: function(response){
              google.maps.event.addDomListener(window, 'load', initMapAllFacility(response));
          }
        })
    }
  }
});

/*onmount('div[id="search_app"]', function() {
  const locale = $('#locale').val();
  $('#search_doctors_and_hospitals').on('input', function(){
    const csrf2 = $('input[name="_csrf_token"]').val();
    let name = $('input[id="search_doctors_and_hospitals"]').val();
    let specialization = $('input[id="search_specialization"]').val();
    let address = $('input[id="search_address"]').val();
    let shows = $('.ui.button.active').text();
    let data = {'name': name,
      'specialization' : specialization,
    'address' : address
    };

    if (name.length > 3){

      if (shows != "Doctors"){
      $.ajax({
        url:`/${locale}/search/text/all_hospital`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: data,
        dataType: 'json',
        success: function(response){
          $('.item.doctor-affiliated.facility').remove()
          $.each(response, function(index, value){
            let facility_name = value.facility_name;
            let facility_phone_no = value.facility_phone_no;
            let facility_status = value.facility_status;
            let facility_address2 = value.facility_address2;
            let facility_address1 = value.facility_address1;
            let pf_count = value.pf_count;
            let facility_id = value.id
            $('div[id="append_here_head"]').append(`<div class="item doctor-affiliated facility">
                                                  <div class="right floated content">
                                                  <p class="text aligned right">
                                                    <i class="doctor icon"></i>`+ pf_count +`<i class="caret right icon" facility_id="`+ facility_id +`" doctor_count="`+ pf_count +`"></i></p>
                                                    <div class="ui button mini request request-hospital clickable">REQUEST</div>
                                                  </div>
                                                  <i class="hospital icon"></i>
                                                  <div class="content">
                                                    <div class="header">`+ facility_name +`<span>`+ facility_status +`</span></div>
                                                    <div class="description">
                                                      <p id="line1">`+ facility_address1 +`</p>
                                                      <p id="line2">`+ facility_address2 +`</p>
                                                      <div class="list-footer">
                                                        <span>`+ facility_phone_no +`</span>
                                                        <a href="#" class="get_direction" name="get_location"><i class="location arrow icon"></i>Get Direction</a>
                                                        <div class="ui dropdown" tabindex="0">
                                                          <div class="get_direction clickable"><i class="icon car"></i> Call a cab</div>
                                                          <div class="menu" tabindex="-1">
                                                            <div class="item">Uber</div>
                                                            <div class="item">Call Grab</div>
                                                          </div>
                                                        </div>
                                                      </div>
                                                    </div>
                                                  </div>
                                                  </div>`);
          })

     open_drawer();
        },
        error: function(response){
          console.log("yea")
        }
      })
      }

      if (shows != "Hospitals"){
      $.ajax({
        url:`/${locale}/search/text/all`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: data,
        dataType: 'json',
        success: function(response){
          if (shows != "Doctors" || shows == "Doctors"){
            $('.item.doctor-affiliated.facility').remove()
          }
          $.each(response, function(index, value){
            let name = value.practitioner_name;
            let facility_name = value.facility_name;
            let status = value.status;
            let specialization = value.specialization.name;
            let schedule = ``;

            $.each(value.schedule, function(index, sched_val){
              schedule = schedule + `<p class="mb_zero">Schedule: `+ sched_val.day + ` ` + sched_val.room + `  ` + sched_val.time_from + `  ` + sched_val.time_to
            })

            $('div[id="append_here_head"]').append(`<div class="item doctor-affiliated facility">
                                                      <div class="right floated content">
                                                        <div class="ui button mini request request-hospital clickable">REQUEST</div>
                                                        </div>
                                                        <i class="doctor icon"></i>
                                                        <div class="content">
                                                          <div class="header">`+ name +`<span>`+ status +`</span></div>
                                                          <div class="description">
                                                          <p class="mb_zero"> `+ specialization +`, <span>`+ facility_name +`</span></p>
                                                          ${schedule}
                                                          </p>
                                                          </div>
                                                      </div>
                                                   </div>`)
          })
        },
        error: function(response){
          console.log("yea")
        }
      })
      }

     }
  });

    $('.ui.dropdown').dropdown();
    $('.caret.right.icon').on('click', function() {
      if ($('#list_detail').attr('class').indexOf('active') < 0 && parseInt($(this).attr('doctor_count')) > 0 ){
        $('#list_detail').addClass('active')
        let facility_id = $(this).attr('facility_id')
        $('.item.doctor-affiliated.details').remove()
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/${locale}/search/doctors/${facility_id}`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          dataType: 'json',
          success: function(response){
            for (let i=0;i<response.length;i++){
              let schedule = ``
              let data = ``
              if (locale == 'zh'){
                for (let s=0;s<response[i].schedule.length;s++)
                {
                  schedule = schedule + `<p class="mb_zero">時間表: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
                }
                if (schedule == ``) {
                  schedule = `時間表: None`
                }
                data = `<div class="item doctor-affiliated details" id="try_append">
                <div class="right floated content">
                <div class="ui button mini request request-lab" practitionerid="${response[i].practitioner_id}" facilityid="${response[i].facility_id}">請求</div>
                </div>
                <i class="doctor icon"></i>
                <div class="content">
                <div class="header">${response[i].practitioner_name} <span>${response[i].status}</span></div>
                <div class="description">
                <p class="mb_zero">${response[i].specialization.name}, <span>${response[i].facility_name} </span></p>
                ${schedule}
                </div>
                </div>
                </div>`
              }
              else{
                for (let s=0;s<response[i].schedule.length;s++)
                {
                  schedule = schedule + `<p class="mb_zero">Schedule: ${response[i].schedule[s].day}, ${response[i].schedule[s].room}, ${response[i].schedule[s].time_from} - ${response[i].schedule[s].time_to}</p>`
                }
                if (schedule == ``) {
                  schedule = `Schedule: None`
                }
                data = `<div class="item doctor-affiliated details" id="try_append">
                <div class="right floated content">
                <div class="ui button mini request request-lab">REQUEST</div>
                </div>
                <i class="doctor icon"></i>
                <div class="content">
                <div class="header">${response[i].practitioner_name} <span>${response[i].status}</span></div>
                <div class="description">
                <p class="mb_zero">${response[i].specialization.name}, <span>${response[i].facility_name} </span></p>
                ${schedule}
                </div>
                </div>
                </div>`
              }
              $('#append_here_tail').append(data)
              $('.doctor-affiliated.details').find('.button.mini.request-lab').click(function(){
                let loa_value = $('.ui.primary.dropdown.basic.button').find('.text').text()
                if(loa_value == 'Request Consultant' || loa_value == '請求實驗室')
                  {
                    $('#facility_id').val($(this).attr('facilityID'))
                    $('#practitioner_id').val($(this).attr('practitionerID'))
                    $('#request_form').modal('show');
                    $('#doctor_name').text($(this).closest('#try_append').find('.header').attr('doctor_name'))
                    $('#doctor_specialization').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_specialization'))
                    $('#doctor_facility').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_facility'))
                    $('#doctor_phone_no').text($(this).closest('#try_append').find('.mb_zero').attr('doctor_phone'))
                  }
                  else if(loa_value == 'Request Lab' || loa_value == '請求顧問')
                    {
                      $('#request_form_lab').modal('show');
                    }
              })
            }
          }

        })

      }else
        {
          $('#list_detail').removeClass('active')
        }
    })
  }

})*/

