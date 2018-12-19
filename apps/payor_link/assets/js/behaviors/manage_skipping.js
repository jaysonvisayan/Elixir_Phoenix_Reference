onmount('div[id="skipping_hierarchy_index"]', function (){
  let valArray = []
  $('.skip_code').click(function(){
    $('.details_skipping_hierarchy').modal('show')
    let skipped_dependent = $(this).attr('skipped_dependent')
    $('#member_name_view').text($(this).attr('member'))
    $('#principal_name_view').text($(this).attr('principal'))
    $('#account_name_view').text($(this).attr('account'))
    let member_id = $(this).attr('member_id')
    let member_name = $(this).attr('member')
    let data = skipped_dependent.split(',')
    let data_skip = []
    for (let index = 0; index < data.length; index += 6) {
      let myChunk = data.slice(index, index + 6);
      // Do something if you want with the group
      data_skip.push(myChunk);
    }
    $('#skipped_dependent_table tbody tr').remove()
    for (let i=0;i<data_skip.length;i++){
      let file_name = data_skip[i][5].split('/').pop()
      console.log(file_name)
      let append_tr = `<tr>
      <td>${data_skip[i][0]}</td>
      <td>${data_skip[i][1]}</td>
      <td>${data_skip[i][2]}</td>
      <td>${data_skip[i][3]}</td>
      <td>${data_skip[i][4]}</td>
      <td><a target="_blank" href='${data_skip[i][5]}'>${file_name}</td>
      </tr>`
      $('#skipped_dependent_table tbody').append(append_tr)
    }
    $('#approve_single').click(function(){
     valArray.push(member_id)
     let user_id = $(this).attr('user_id')
     if (valArray.length > 0){
       swal({
         title: 'Approve Skipping Hierarchy?',
         text: 'The skipped dependent cannot be enrolled to the system once approved',
         type: 'question',
         showCancelButton: true,
         confirmButtonText: 'Yes, Approve Skipping',
         cancelButtonText: 'No, Review Details',
         confirmButtonClass: 'ui blue button',
         cancelButtonClass: 'ui button',
         buttonsStyling: false
       }).then(function () {
         const csrf2 = $('input[name="_csrf_token"]').val();
         $.ajax({
           url:`/api/v1/members/skipping_hierarchy/${user_id}/approve_skipping`,
           headers: {"X-CSRF-TOKEN": csrf2},
           type: 'get',
           data: {param: { "member_id" : valArray}},
           dataType: 'json',
           success: function(response){
             location.replace('/members/skipping/hierarchy?approve=true');
           }
         })
       })
     }
    })
    $('#disapprove_single').click(function(){
      valArray.push(member_id)
      let user_id = $(this).attr('user_id')
      if (valArray.length > 0){
        swal({
          title: 'Disapprove Skipping Hierarchy?',
          html: `The skipped dependent must be enrolled to the system first before enrolling ${member_name} once disapproved<br><br>Please Enter Reason`,
          input: 'text',
          type: 'question',
          showCancelButton: true,
          confirmButtonText: 'Submit',
          confirmButtonText: 'Yes, Disapprove Skipping',
          cancelButtonText: 'No, Review Details',
          confirmButtonClass: 'ui blue button',
          cancelButtonClass: 'ui button',
          preConfirm: (text) => {
            return new Promise((resolve) => {
                if (text == '') {
                  swal.showValidationError(
                    'Please enter reason.'
                  )
                  swal.enableButtons()
                }
                else
                  {
                    resolve()
                  }
            })
          },
          buttonsStyling: false,
        }).then((result) => {
          if (result != ''){
            const csrf2 = $('input[name="_csrf_token"]').val();
            $.ajax({
              url:`/api/v1/members/skipping_hierarchy/${user_id}/disapprove_skipping/${result}`,
              headers: {"X-CSRF-TOKEN": csrf2},
              type: 'get',
              data: {param: { "member_id" : valArray}},
              dataType: 'json',
              success: function(response){
                location.replace('/members/skipping/hierarchy?disapprove=true');
              }
            })
          }
        })
      }
    })
  })
  //let member_name  = ''
  $('.skip_code_view').click(function(){
    $('.details_skipping_hierarchy_view').modal('show')
    let skipped_dependent = $(this).attr('skipped_dependent')
    $('#member_name_view_processed').text($(this).attr('member'))
    $('#principal_name_view_processed').text($(this).attr('principal'))
    $('#account_name_view_processed').text($(this).attr('account'))
    let member_id = $(this).attr('member_id')
    //member_name = member_name + ',' + $(this).attr('member')

    let data = skipped_dependent.split(',')
    let data_skip = []
    for (let index = 0; index < data.length; index += 6) {
      let myChunk = data.slice(index, index + 6);
      // Do something if you want with the group
      data_skip.push(myChunk);
    }
    $('#skipped_dependent_table tbody tr').remove()
    for (let i=0;i<data_skip.length;i++){
      let file_name = data_skip[i][5].split('/').pop()
      console.log(file_name)
      let append_tr = `<tr>
      <td>${data_skip[i][0]}</td>
      <td>${data_skip[i][1]}</td>
      <td>${data_skip[i][2]}</td>
      <td>${data_skip[i][3]}</td>
      <td>${data_skip[i][4]}</td>
      <td><a target="_blank" href='${data_skip[i][5]}'>${file_name}</td>
      </tr>`
      $('#skipped_dependent_table tbody').append(append_tr)
    }
  })
  $("input:checkbox.selection").on('change', function () {
    var value = $(this).val()

    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('input[name="skipping_hierarchy[skipped_id]"]').val(valArray)
  })

  // FOR CHECK ALL
  $('#select_all').on('change', function(){
    var table = $('#procedure_table_modal').DataTable()
    var rows = table.rows({ 'search': 'applied' }).nodes();

    if ($(this).is(':checked')) {
      $('input[name="skipped_dependent[id][]"]').each(function() {
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
      console.log($(this))
      })

    } else {
      valArray.length = 0
      $('input[name="skipped_dependent[id][]"]').each(function() {
        $(this).prop('checked', false)
      })
    }
    $('input[name="skipping_hierarchy[skipped_id]"]').val(valArray)
  })

  $('#approve_many').click(function(){
    let user_id = $(this).attr('user_id')
    if (valArray.length > 0){
       swal({
         title: 'Approve Skipping Hierarchy?',
         text: 'The skipped dependent cannot be enrolled to the system once approved',
         type: 'question',
         showCancelButton: true,
         confirmButtonText: 'Yes, Approve Skipping',
         cancelButtonText: 'No, Review Details',
         confirmButtonClass: 'ui blue button',
         cancelButtonClass: 'ui button',
         buttonsStyling: false
       }).then(function () {
         const csrf2 = $('input[name="_csrf_token"]').val();
         $.ajax({
           url:`/api/v1/members/skipping_hierarchy/${user_id}/approve_skipping`,
           headers: {"X-CSRF-TOKEN": csrf2},
           type: 'get',
           data: {param: { "member_id" : valArray}},
           dataType: 'json',
           success: function(response){
              location.replace('/members/skipping/hierarchy?approve=true');
           }
         })
       })
    }
  })

  $('#disapprove_many').click(function(){
    let user_id = $(this).attr('user_id')
    if (valArray.length > 0){
      swal({
        title: 'Disapprove Skipping Hierarchy?',
        html: `The skipped dependents must be enrolled to the system first before enrolling next dependents in the hierarchy once disapproved<br><br>Please Enter Reason`,
        input: 'text',
        type: 'question',
        showCancelButton: true,
        confirmButtonText: 'Submit',
        confirmButtonText: 'Yes, Disapprove Skipping',
        cancelButtonText: 'No, Review Details',
        confirmButtonClass: 'ui blue button',
        cancelButtonClass: 'ui button',
        preConfirm: (text) => {
          return new Promise((resolve) => {
            if (text == '') {
              swal.showValidationError(
                'Please enter reason.'
              )
              swal.enableButtons()
            }
            else
              {
                resolve()
              }
          })
        },
        buttonsStyling: false,
      }).then((result) => {
        if (result != ''){
          const csrf2 = $('input[name="_csrf_token"]').val();
          $.ajax({
            url:`/api/v1/members/skipping_hierarchy/${user_id}/disapprove_skipping/${result}`,
            headers: {"X-CSRF-TOKEN": csrf2},
            type: 'get',
            data: {param: { "member_id" : valArray}},
            dataType: 'json',
            success: function(response){
              location.replace('/members/skipping/hierarchy?disapprove=true');
            }
          })
        }
      })
    }
  })

  $('#memberForm')
  .form({
    inline: true,
    fields: {
      account_code: {
        identifier: 'account_code',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Reason'
        }]
      }
    }
  })
  $('#download_skipping').click(function(){
    if ($('.tabular.menu').find('.active.item').html() == "Processed"){
      let table = $('#skip_processed').DataTable();
      let search_result = table.rows({order:'current', search: 'applied'}).data();
      let search_value =  $('#skipping_hierarchy_index').find('div[data-tab="processed"]').find('input[type="search"]').val()
      if (search_result.length > 0){
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/api/v1/members/index/skipping/processed`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {skipping_param: { "search_value" : search_value.trim()}},
          dataType: 'json',
          success: function(response){
            console.log(response)
            let utc = new Date()
            let date = moment(utc)
            date = date.format("MM-DD-YYYY")
            let filename = 'Skipping_Hierarchy_' + date + '.csv'
            // Download CSV file
            downloadCSV(response, filename);
          }
        });
      }
    }
    else{
      let table = $('#skip_pending').DataTable();
      let search_result = table.rows({order:'current', search: 'applied'}).data();
      let search_value =  $('#skipping_hierarchy_index').find('div[data-tab="pending"]').find('input[type="search"]').val()
      if (search_result.length > 0){
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/api/v1/members/index/skipping/pending`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {skipping_param: { "search_value" : search_value.trim()}},
          dataType: 'json',
          success: function(response){
            let utc = new Date()
            let date = moment(utc)
            date = date.format("MM-DD-YYYY")
            let filename = 'Skipping_Hierarchy_' + date + '.csv'
            // Download CSV file
            downloadCSV(response, filename);
          }
        });
      }
    }
  })

  function downloadCSV(csv, filename){
    var csvFile;
    var downloadLink;

    // CSV file
    csvFile = new Blob([csv], {type: "text/csv"});

    // Download link
    downloadLink = document.createElement("a");

    // File name
    downloadLink.download = filename;

    // Create a link to the file
    downloadLink.href = window.URL.createObjectURL(csvFile);

    // Hide download link
    downloadLink.style.display = "none";

    // Add the link to DOM
    document.body.appendChild(downloadLink);

    // Click download link
    downloadLink.click();
  };

})
onmount('input[id="disapprove"]', function (){
  alertify.success(`<i class="close icon"></i><p>Skipping hierarchy successfully disapproved</p>`);
})
onmount('input[id="approve"]', function (){
  alertify.success(`<i class="close icon"></i><p>Skipping hierarchy successfully approved</p>`);
})
