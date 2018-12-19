onmount('div[id="membersGeneral"]', function() {
  let employee_number_array = []
  let single_dependent_hierarchy = []
  let single_parent_dependent_hierarchy = []
  let married_dependent_hierarchy = []
  let account_principals = []
  let hierarchy = []
  let dependents_to_skip = []
  let skip_counter = 0
  let pwd_arr = []
  let senior_arr = []
  let csrf = $('input[name="_csrf_token"]').val()

  const member_id = $('#memberID').val()
  const principal_id = $('#memberPrincipalID').val()
  const principal_product_id = $('#memberPrincipalProductID').val()

  const checkPwdId = () => {
    $.ajax({
      url:`/members/pwd_id/all`,
        headers: {"x-csrf-token": csrf},
        type: 'get',
        datatype: 'json',
        success: function(response){
          let obj = JSON.parse(response)
          pwd_arr.push(obj)
        }
    });
  }
  checkPwdId()

  $.fn.form.settings.rules.checkEmpNumber = function(param) {
    return employee_number_array.indexOf(param) == -1 ? true : false;
  }

  $.fn.form.settings.rules.checkPWDID = function(param) {
    // let copy = $('input[id="member_pwd_id_copy"]').val();
    // let position = $.inArray(copy, pwd_arr[0]);
    // if ( ~position ) pwd_arr[0].splice(position, 1);

    if(pwd_arr[0].includes(param)){
      return false
    } else{
      return true
    }
  }

  const checkSeniorId = () => {
    $.ajax({
      url:`/members/senior_id/all`,
        headers: {"x-csrf-token": csrf},
        type: 'get',
        datatype: 'json',
        success: function(response){
          let obj = JSON.parse(response)
          senior_arr.push(obj)
        }
    });
  }
  checkSeniorId()

  $.fn.form.settings.rules.checkSeniorID = function(param) {
    // let copy = $('input[id="member_senior_id_copy"]').val();
    // let position = $.inArray(copy, senior_arr[0]);
    // if ( ~position ) senior_arr[0].splice(position, 1);

    if(senior_arr[0].includes(param)){
      return false
    } else{
      return true
    }
  }

  $.fn.form.settings.rules.checkIfSenior = function(param) {
    let birthdate = $('input[id="member_birthdate"]').val()
    birthdate = birthdate.split("-", 1)
    let today_date = new Date()
    let total_age = today_date.getFullYear() - parseInt(birthdate[0])
    if (birthdate == ""){
      return false
    }
    else if (total_age < 60){
      return false
    }
    else{
      return true
    }
  }

  $.fn.form.settings.rules.customLength = function(param) {
    if (param == '') {
      return true
    } else {
      if(param.length == 12) {
        return true
      } else{
        return false
      }
    }
  }

  $('#imageUploadCard').on('change', function(event){
    let pdffile = event.target.files[0]

    if (pdffile != undefined){
      if((pdffile.name).indexOf('.jpg') >= 0 || (pdffile.name).indexOf('.png') >= 0 || (pdffile.name).indexOf('.jpeg') >= 0){
        if(pdffile.size > 5242880){
          $(this).val('')
          alert_error_size()
          $('#photo').attr('src', '/images/file-upload.png')
        }
      }
      else{
        $(this).val('')
        alert_error_file()
        $('#photo').attr('src', '/images/file-upload.png')
      }
    }
    else{
      $(this).val('')
    }
  })


  function alert_error_file(){
    alertify.error('Invalid file type. Valid file types are JPG, JPEG, and PNG.<i id="notification_error" class="close icon"></i>');
    alertify.defaults = {
      notifier:{
        delay:5,
        position:'top-right',
        closeButton: false
      }
    };
  }

  function alert_error_size(){
    alertify.error('Maxium image file size is 5 megabytes <i id="notification_error" class="close icon"></i>');
    alertify.defaults = {
      notifier:{
        delay:8,
        position:'top-right',
        closeButton: false
      }
    };
  }

  $('input[name="member[philhealth_type]"]').change(function() {
    if ($(this).val() == "Not Covered") {
      $('input[name="member[philhealth]"]').closest('.field').removeClass('error')
      $('input[name="member[philhealth]"]').closest('.field').find('.prompt').remove()
      $('input[name="member[philhealth]"]').prop('disabled', true)
      $('input[name="member[philhealth]"]').val('')
    } else {
      $('input[name="member[philhealth]"]').prop('disabled', false)
    }
  })

  if ($('input[name="member[philhealth_type]"]:checked').val() == "Not Covered") {
    $('input[name="member[philhealth]"]').prop('disabled', true)
    $('input[name="member[philhealth]"]').val('')
  } else {
    $('input[name="member[philhealth]"]').prop('disabled', false)
  }

  $('select[name="member[account_code]"]').change(function() {
    let account_group_code = $(this).val()

    $.ajax({
      url:`/api/v1/accounts/${account_group_code}/get_an_account_by_code`,
      type: 'GET',
      success: function(response){
        // set dependent hierarchies of returned account
        single_dependent_hierarchy.length = 0
        single_parent_dependent_hierarchy.length = 0
        married_dependent_hierarchy.length = 0
        $.map(response.dependent_hierarchy, function(dependent_hierarchy, index) {
          if (dependent_hierarchy.hierarchy_type == "Single Employee") {
            single_dependent_hierarchy.push(dependent_hierarchy.dependent)
          }
          if (dependent_hierarchy.hierarchy_type == "Single Parent Employee") {
            single_parent_dependent_hierarchy.push(dependent_hierarchy.dependent)
          }
          if (dependent_hierarchy.hierarchy_type == "Married Employee") {
            married_dependent_hierarchy.push(dependent_hierarchy.dependent)
          }
        })

        // get employee numbers within the selected account
        employee_number_array.length = 0
        $.map(response.members, function(member, index) {
          if (member.employee_no != null && member.id != member_id){
            employee_number_array.push(member.employee_no)
          }
        })

        // get principal IDs within the selected account
        account_principals.length = 0
        $('#principalID').html('')
        $('#principalID').append('<option value="">Select Principal ID</option>')
        for (let member of response.members) {
          if ((member.type == "Principal" || member.type == "Guardian") && member.id != member_id && member.status == "Active") {
            account_principals.push(member)
            $('#principalID').append(`<option value="${member.id}">${member.id} - ${member.first_name} ${member.last_name}</option>`)
          }
        }
        $('#principalID').dropdown('clear')
        $('#principalID').dropdown()
        $('#relationship').html('')
        $('#relationship').dropdown('clear')
      }
    })
  })

  $('select[name="member[principal_id]"]').change(function() {
    if ($(this).val() != "") {
      let selected_principal = account_principals.find(principal => principal.id == $(this).val())
      let spouse_count = dependent_count(selected_principal, "Spouse")
      let parent_count = dependent_count(selected_principal, "Parent")
      let sibling_count = dependent_count(selected_principal, "Sibling")
      let child_count = dependent_count(selected_principal, "Child")
      let current_tier = 0
      $('#member_gender_Male').attr('disabled', false)
      $('#member_gender_Female').attr('disabled', false)
      $('#skipContainer').html('')

      $('#principalProductID').html('')
      $('#principalProductID').append('<option value="">Select Principal ID</option>')
      for (let member_product of selected_principal.products) {
        $('#principalProductID').append(`<option waiver="${member_product.hierarchy_waiver}" prodCode ="${member_product.code}" value="${member_product.id}">${member_product.code} - ${member_product.hierarchy_waiver}</option>`)
      }
      $('#principalProductID').dropdown('clear')
      $('#principalProductID').dropdown()

      if (selected_principal.civil_status == "Single") {
        hierarchy = single_dependent_hierarchy
      } else if (selected_principal.civil_status == "Single Parent") {
        hierarchy = single_parent_dependent_hierarchy
      } else if (selected_principal.civil_status == "Married") {
        hierarchy = married_dependent_hierarchy
      }

      if (principal_product_id != "") {
        setTimeout(function () {
          $('#principalProductID').dropdown('set selected', principal_product_id)
        }, 1)
      }

      for (let relationship of hierarchy) {
        if (relationship == "Spouse") {
          if (spouse_count > 0 ) {
            current_tier = hierarchy.indexOf("Spouse") + 1
          }
        }
        if (relationship == "Parent") {
          if (parent_count > 0 ) {
            current_tier = hierarchy.indexOf("Parent") + 1
          }
        }
        if (relationship == "Child") {
          if (child_count > 0 ) {
            current_tier = hierarchy.indexOf("Child") + 1
          }
        }
        if (relationship == "Sibling") {
          if (sibling_count > 0 ) {
            current_tier = hierarchy.indexOf("Sibling") + 1
          }
        }
      }

      $('#relationship').html('')
      $('#relationship').dropdown('clear')
      $('#relationship').append('<option value="">Select Relationship</option>')
      for (var i = 0; i < hierarchy.length; i++) {
        if (i >= current_tier) {
          $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
        }
        else {
          if (hierarchy[i] == "Parent" && hierarchy.indexOf("Parent") == current_tier-1 && parent_count < 2) {
            $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
          }
          else if (hierarchy[i] == "Child" && hierarchy.indexOf("Child") == current_tier-1) {
            $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
          }
          else if (hierarchy[i] == "Sibling" && hierarchy.indexOf("Sibling") == current_tier-1) {
            $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}" >${hierarchy[i]}</option>`)
          }
          else {
            $('#relationship').append(`<option disabled="true" value="${hierarchy[i]}">${hierarchy[i]}</option>`)
          }
        }
      }

      $('#relationship').dropdown('refresh')

      $('#effectiveDate').calendar({
        type: 'date',
        startMode: 'day',
        minDate: new Date(selected_principal.effectivity_date),
        maxDate: new Date(selected_principal.expiry_date),
        formatter: {
          date: function(date, settings) {
             var monthNames = [
              "Jan", "Feb", "Mar",
              "Apr", "May", "Jun", "Jul",
              "Aug", "Sep", "Oct",
              "Nov", "Dec"
             ];
             var day = date.getDate();
             var monthIndex = date.getMonth();
             var year = date.getFullYear();

             return monthNames[monthIndex] + ' ' + day + ', ' + year
          }
        }
      })

      $('#expiryDate').calendar({
        type: 'date',
        startMode: 'day',
        startCalendar: $('#effectiveDate'),
        maxDate: new Date(selected_principal.expiry_date),
        formatter: {
          date: function(date, settings) {
             var monthNames = [
              "Jan", "Feb", "Mar",
              "Apr", "May", "Jun", "Jul",
              "Aug", "Sep", "Oct",
              "Nov", "Dec"
             ];
             var day = date.getDate();
             var monthIndex = date.getMonth();
             var year = date.getFullYear();

             return monthNames[monthIndex] + ' ' + day + ', ' + year
          }
        }
      })

      setTimeout(function () {
        $('#relationship').dropdown('set selected', $('#memberRelationship').val())
        if (selected_principal.id == principal_id){
          let relationship = $('select#relationship option:selected').attr('id')
          for (let a=1;a<relationship;a++){
            let val = $('select#relationship').find(`#${a}`).val()
            $('select#relationship').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).addClass('disabled')
          }
        }
      }, 1)

      $('#hierarchy_data tr').remove()

      for (let dependent of selected_principal.dependents) {
        if (dependent.id == member_id){
          for (let data of dependent.skipped_dependents){
            let name = ''
            if (data.suffix == null && data.middle_name != null) {
              name = data.first_name + ' ' + data.middle_name + ' ' + data.last_name
            }
            if (data.suffix != null && data.middle_name == null) {
              name = data.first_name + ' ' + data.last_name + ' ' + data.suffix
            }
            if (data.middle_name == null && data.suffix == null){
              name = data.first_name + ' ' + data.last_name
            }
            if (data.middle_name != null && data.suffix != null){
              name = data.first_name + ' ' + data.middle_name + ' ' + data.last_name + ' ' + data.suffix
            }
            let relationship_data = data.relationship
            let gender = data.gender
            let birthdate = data.birthdate
            let reason = data.reason
            let supporting_file = data.supporting_document
            let skipped_id = data.id

            let data_row = `<tr>
            <td id="table_relationship" class="relationship" skip_id="${skipped_id}">${relationship_data}</td>
            <td>${name}</td>
            <td id="table_gender">${gender}</td>
            <td>${birthdate}</td>
            <td>${reason}</td>
            <td>${supporting_file}</td>
            <td class="remove_skip_icon"><i class="trash icon"></i></td>
            </tr>`
            $('#hierarchy_data').append(data_row)
            $('.remove_skip_icon').on('click', function(){
              let this_class = $(this)
              swal({
                title: 'Remove Skipping Hierarchy',
                text: "Are you sure you want to remove this Skipping Hierarchy?",
                type: 'question',
                showCancelButton: true,
                cancelButtonText: '<i class="remove icon"></i> Cancel',
                confirmButtonText: '<i class="trash icon"></i> Remove',
                cancelButtonClass: 'ui button',
                confirmButtonClass: 'ui blue button',
                buttonsStyling: false
              }).then(function () {

                let relationship = this_class.closest('td').closest('tr').find('.relationship').html()

                if (dependents_to_skip.indexOf(relationship) == -1) {
                  dependents_to_skip.push(relationship)
                }
                this_class.closest('td').closest('tr').remove();
                //$('#addDependentSkip').removeClass('disabled')
                let relationship_table = []
                $('#hierarchy_table tbody tr').each(function(){
                  relationship_table.push($(this).find('#table_relationship').html())
                })
                if (relationship_table.length == 0){
                  let relationship_dropdown = $('select#relationship option:selected').attr('id')
                  for (let a=1;a<relationship_dropdown;a++){
                    let val = $('select#relationship').find(`#${a}`).val()
                    $('select#relationship').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).removeClass('disabled')
                  }
                }
                if (dependents_to_skip.length != 0){
                  $('#addDependentSkip').removeClass('disabled')
                }
              })
            })
          }
        }
      }
    }
  })

  $('select[name="member[principal_product_id]"]').change(function() {
    $('#hierarchy_data tr').remove()
    $('#addDependentSkip').addClass('disabled')
    let principal_id = $('select[name="member[principal_id]"]').val()
    let selected_principal = account_principals.find(principal => principal.id == principal_id)
    let spouse_count = dependent_count(selected_principal, "Spouse")
    let parent_count = dependent_count(selected_principal, "Parent")
    let sibling_count = dependent_count(selected_principal, "Sibling")
    let child_count = dependent_count(selected_principal, "Child")
    let current_tier = 0

    for (let relationship of hierarchy) {
      if (relationship == "Spouse") {
        if (spouse_count > 0 ) {
          current_tier = hierarchy.indexOf("Spouse") + 1
        }
      }
      if (relationship == "Parent") {
        if (parent_count > 0 ) {
          current_tier = hierarchy.indexOf("Parent") + 1
        }
      }
      if (relationship == "Child") {
        if (child_count > 0 ) {
          current_tier = hierarchy.indexOf("Child") + 1
        }
      }
      if (relationship == "Sibling") {
        if (sibling_count > 0 ) {
          current_tier = hierarchy.indexOf("Sibling") + 1
        }
      }
    }

    $('#relationship').html('')
    $('#relationship').dropdown('clear')
    $('#relationship').append('<option value="">Select Relationship</option>')
    for (var i = 0; i < hierarchy.length; i++) {
      if (i >= current_tier) {
        $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
      }
      else {
        if (hierarchy[i] == "Parent" && hierarchy.indexOf("Parent") == current_tier-1 && parent_count < 2) {
          $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
        }
        else if (hierarchy[i] == "Child" && hierarchy.indexOf("Child") == current_tier-1) {
          $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
        }
        else if (hierarchy[i] == "Sibling" && hierarchy.indexOf("Sibling") == current_tier-1) {
          $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}" >${hierarchy[i]}</option>`)
        }
        else {
          $('#relationship').append(`<option disabled="true" value="${hierarchy[i]}">${hierarchy[i]}</option>`)
        }
      }
    }
    $('#relationship').dropdown('refresh')

   //Effective Date New Validations
    let  principal_prod_id = $(this).val();
    function to_date_string(date) {
        date = new Date(date)
        var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
        ];
        var day = date.getDate();
        var monthIndex = date.getMonth();
        var year = date.getFullYear();

        return monthNames[monthIndex] + ' ' + day + ', ' + year;
    }

    for (let member_product of selected_principal.products){
     if (member_product.id == principal_prod_id){
        if (member_product.product.mded_dependent == 'Date of Regularization'){
          $('input[name="member[effectivity_date]"]').prop('disabled', true)
         $('input[name="member[effectivity_date]"]').val(to_string_date(selected_principal.regularization_date))
        }
        else if (member_product.product.mded_dependent == 'Date of Hire'){
          $('input[name="member[effectivity_date]"]').prop('disabled', true)
         $('input[name="member[effectivity_date]"]').val(to_string_date(selected_principal.date_hired))
        }
        else if (member_product.product.mded_dependent == 'Effective Date'){
          $('input[name="member[effectivity_date]"]').prop('disabled', true)
         $('input[name="member[effectivity_date]"]').val(to_string_date(selected_principal.effective_date))
        }
        else {
          let account_code = $('select[name="member[account_code]"]').val()
          let id = '#' + account_code
          let effectiveDate = $(id).attr('effectiveDate')
          $('input[name="member[effectivity_date]"]').prop('disabled', false)
          $('input[name="member[effectivity_date]"]').val(to_string_date(selected_principal.effectivity_date))
         }
      }
    }
  })

  function dependent_count(principal, type) {
    let count = 0
    for (let dependent of principal.dependents) {
      // TEMPO
      if (dependent.id != $('#memberID').val() && dependent.status != "Disapprove") {
        if (dependent.relationship == type) {
          count++
        }
        for (let skipped_dependent of dependent.skipped_dependents) {
          if (skipped_dependent.relationship == type) {
            count++
          }
        }
      }
    }
    return count
  }

  function validate_hierarchy_skipping(waiver) {
    let principal_id = $('select[name="member[principal_id]"]').val()
    let relationship = $('select[name="member[relationship]"]').val()
    let selected_principal = account_principals.find(principal => principal.id == principal_id)
    let spouse_count = dependent_count(selected_principal, "Spouse")
    let child_count = dependent_count(selected_principal, "Child")
    let parent_count = dependent_count(selected_principal, "Parent")
    let sibling_count = dependent_count(selected_principal, "Sibling")
    dependents_to_skip.length = 0
    let hello = hierarchy.indexOf(relationship) - 1

    while (hello >= 0) {
      dependents_to_skip.push(hierarchy[hello])
      hello--
    }

    if (spouse_count != 0) {
      let index = dependents_to_skip.indexOf("Spouse")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (child_count != 0) {
      let index = dependents_to_skip.indexOf("Child")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (parent_count != 0) {
      let index = dependents_to_skip.indexOf("Parent")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (sibling_count != 0) {
      let index = dependents_to_skip.indexOf("Sibling")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    let skip_parent = 0
    let skip_spouse = 0
    let skip_child = 0
    let skip_sibling = 0

    $('.skip_relationship_data').each(function() {
      let hello = $(this).html()
      if (hello == "Parent") {skip_parent++}
      if (hello == "Spouse") {skip_spouse++}
      if (hello == "Child") {skip_child++}
      if (hello == "Sibling") {skip_sibling++}
    })

    if (dependents_to_skip.includes("Parent") && skip_parent > 0) {
      dependents_to_skip.splice(dependents_to_skip.indexOf("Parent"), 1)
    }
    if (dependents_to_skip.includes("Spouse") && skip_spouse > 0) {
      dependents_to_skip.splice(dependents_to_skip.indexOf("Spouse"), 1)
    }
    if (dependents_to_skip.includes("Child") && skip_child > 0) {
      dependents_to_skip.splice(dependents_to_skip.indexOf("Child"), 1)
    }
    if (dependents_to_skip.includes("Sibling") && skip_sibling > 0) {
      dependents_to_skip.splice(dependents_to_skip.indexOf("Sibling"), 1)
    }

    let relationship_table = []
    $('#hierarchy_table tbody tr').each(function(){
      relationship_table.push($(this).find('#table_relationship').html())
    })
    let parent_count_skip = 0
    for (let dependent of selected_principal.dependents){
      if (dependent.relationship == "Parent" && dependent.status != "Disapprove"){
        parent_count_skip += 1
      }
    }
    for (let i=0;i<relationship_table.length;i++){
      if (relationship_table[i] == "Parent"){
        if (parent_count_skip != 1){
          parent_count_skip = parent_count_skip + 1
        }
        else
          {
            let in_array = $.inArray(relationship_table[i], dependents_to_skip)
            if (in_array != '-1'){
              dependents_to_skip.splice(in_array, 1);
            }
          }
      }else{
        let in_array = $.inArray(relationship_table[i], dependents_to_skip)
        if (in_array != '-1'){
          dependents_to_skip.splice(in_array, 1);
        }
      }
    }


    if (waiver == 'Waive') {
      return true
    } else if (waiver == 'Enforce' || waiver == 'null') {
      if (dependents_to_skip.length == 0) {
        return true
      } else {
        swal({
          title: 'The relationship you selected is not allowed',
          html: `Enforce hierarchy is setup in selected principal’s product, please follow the hierarchy of dependents to proceed with the enrollment`,
          type: 'warning',
          width: '700px',
          confirmButtonText: '<i class="check icon"></i> Ok',
          confirmButtonClass: 'ui button',
          buttonsStyling: false,
          reverseButtons: true,
          allowOutsideClick: false
        }).catch(swal.noop)
        return false
      }
    } else if (waiver == 'Skip Allowed' && dependents_to_skip.length == 0) {
      let data = []
      $('#hierarchy_table tbody tr').each(function() {
        data.push($(this).find('.relationship').attr('relationship'))
        data.push($(this).find('.relationship').attr('first_name'))
        data.push($(this).find('.relationship').attr('middle_name'))
        data.push($(this).find('.relationship').attr('last_name'))
        data.push($(this).find('.relationship').attr('suffix'))
        data.push($(this).find('.relationship').attr('gender'))
        data.push($(this).find('.relationship').attr('birthdate'))
        data.push($(this).find('.relationship').attr('reason'))
        data.push($(this).find('.relationship').attr('file_name'))
        data.push($(this).find('.relationship').attr('extension'))
        data.push($(this).find('.relationship').attr('base64'))
        if (data.pop() == undefined) {
          data.push($(this).find('.relationship').attr('skip_id'))
        } else {
          data.push($(this).find('.relationship').attr('base64'))
        }
      })
      $('#skipping_hierarchy_data_value').val(data)
      return true
    } else {
      let error_message = dependents_to_skip.join('<br>')
      let relationship_table = []
      check_if_skipping(selected_principal, relationship)
      $('#hierarchy_table tbody tr').each(function(){
        relationship_table.push($(this).find('#table_relationship').html())
      })
      let parent_count = 0
      for (let dependent of selected_principal.dependents){
        if (dependent.relationship == "Parent" && dependent.status != "Disapprove"){
          parent_count += 1
        }
      }
      for (let i=0;i<relationship_table.length;i++){
        if (relationship_table[i] == "Parent"){
          if (parent_count != 1){
            parent_count = parent_count + 1
          }
          else
            {
              let in_array = $.inArray(relationship_table[i], dependents_to_skip)
              if (in_array != '-1'){
                dependents_to_skip.splice(in_array, 1);
              }
            }
        }
        else{
        let in_array = $.inArray(relationship_table[i], dependents_to_skip)
        if (in_array != '-1'){
          dependents_to_skip.splice(in_array, 1);
        }
      }

      }
      swal({
        title: 'The relationship you entered is not allowed',
        html: `The relationship you entered skips the following hierarchy of dependent/s: <br> ${error_message}`,
        type: 'warning',
        confirmButtonText: '<i class="check icon"></i> Ok',
        confirmButtonClass: 'ui button',
        buttonsStyling: false,
        reverseButtons: true,
        allowOutsideClick: false
      }).catch(swal.noop)
      return false
    }
  }

  $('#submitGeneral').on('click', function(){
    let waiver = $('#principalProductID').find(':selected').attr('waiver')
    if ($('input[name="member[type]"]:checked').val() == "Dependent" && $('#principalID').val() != "" && $('#relationship').val() != "" && $('#principalProductID').val() != "") {
      let checker = validate_hierarchy_skipping(waiver)
      if (checker == true) {
      $('input[name="member[effectivity_date]"]').prop('disabled', false)
        $('#memberForm').submit()
      }
    }
    else
      {
      $('input[name="member[effectivity_date]"]').prop('disabled', false)
        $('#memberForm').submit()
      }
  })

  function check_if_skipping(principal, relationship){
    dependents_to_skip.length = 0
    let spouse_count = dependent_count(principal, "Spouse")
    let parent_count = dependent_count(principal, "Parent")
    let sibling_count = dependent_count(principal, "Sibling")
    let child_count = dependent_count(principal, "Child")
    let hello = hierarchy.indexOf(relationship) - 1
    while (hello >= 0) {
      dependents_to_skip.push(hierarchy[hello])
      hello--
    }
    if (spouse_count != 0) {
      let index = dependents_to_skip.indexOf("Spouse")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (child_count != 0) {
      let index = dependents_to_skip.indexOf("Child")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (parent_count != 0 && parent_count != 1) {
      let index = dependents_to_skip.indexOf("Parent")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (sibling_count != 0) {
      let index = dependents_to_skip.indexOf("Sibling")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }
    if (dependents_to_skip.length == 0) {
      return true
    } else {
      return false
    }

  }

  $('#addDependentSkip').click(function() {
    $('.add_skipping_hierarchy').modal('show');
    $('.skip_relationship').empty()
    let relationship_options = ``
    for (let relationship of dependents_to_skip) {
      relationship_options += `<option value="${relationship}">${relationship}</option>`
    }
    $('.skip_relationship').append(relationship_options);
    let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
    /*if ($('.skip_relationship').val() == "Spouse") {
      if (selected_principal.gender == "Male") {
        $('#skipped_gender_Female').prop('checked', true)
        $('#skipped_gender_Male').attr('disabled', true)
      } else {
        $('#skipped_gender_Male').prop('checked', true)
        $('#skipped_gender_Female').attr('disabled', true)
      }
    }
    else{
      $('#skipped_gender_Male').removeAttr('disabled')
      $('#skipped_gender_Female').removeAttr('disabled')
      $('#skipped_gender_Male').prop('checked', true)
      }
    */
    $('.skip-calendar').calendar({
      type: 'date',
      startMode: 'year',
      maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
      formatter: {
        date: function(date, settings) {
             var monthNames = [
              "Jan", "Feb", "Mar",
              "Apr", "May", "Jun", "Jul",
              "Aug", "Sep", "Oct",
              "Nov", "Dec"
             ];
             var day = date.getDate();
             var monthIndex = date.getMonth();
             var year = date.getFullYear();

             return monthNames[monthIndex] + ' ' + day + ', ' + year
        }
      }
    })
    $('.skip_dropdown').dropdown('restore defaults');

    $('#skip_reason').dropdown('restore defaults');

    //append_dependent_to_skip(skip_counter)
    //skip_counter++
  })



  const today = new Date()

  $('select[name="member[relationship]"]').change(function() {
    if ($(this).val() != null && $('#principalProductID').val() != "") {
      let relationship = $(this).val()
      let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
      let principal_birthdate = new Date(selected_principal.birthdate)
      let principal_children = []
      let principal_parents = []
      let principal_siblings = []
      let waiver = $('#principalProductID').find(':selected').attr('waiver')

      $('#member_gender_Male').attr('disabled', false)
      $('#member_gender_Female').attr('disabled', false)

      $.map(selected_principal.dependents, function(dependent, index) {
        if (dependent.relationship == "Child" && dependent.id != member_id) {
          principal_children.push(dependent)
        } else if (dependent.relationship == "Parent" && dependent.id != member_id) {
          principal_parents.push(dependent)
        } else if (dependent.relationship == "Sibling" && dependent.id != member_id) {
          principal_siblings.push(dependent)
        }
      })

      $('#skipContainer').html('')

      if (waiver == "Skip Allowed") {

        if (check_if_skipping(selected_principal, relationship)) {
          $('#addDependentSkip').addClass('disabled')
        } else {
          $('#hierarchy_table').attr('style', '')
          let relationship_table = []
          $('#hierarchy_table tbody tr').each(function(){
            relationship_table.push($(this).find('#table_relationship').html())
          })
          for (let dependent of selected_principal.dependents) {
            if (dependent.id == member_id){
              if (dependent.skipped_dependents.length > 0 && relationship_table.length == dependents_to_skip.length){
                $('#addDependentSkip').addClass('disabled')
              }
            }
          }

          setTimeout(function () {
            let relationship_table = []
            $('#hierarchy_table tbody tr').each(function(){
              relationship_table.push($(this).find('#table_relationship').html())
            })
            let parent_count = 0
            for (let dependent of selected_principal.dependents){
              if (dependent.relationship == "Parent" && dependent.status != "Disapprove"){
                parent_count += 1
              }
            }
            for (let i=0;i<relationship_table.length;i++){
              if (relationship_table[i] == "Parent"){
                if (parent_count != 1){
                  parent_count = parent_count + 1
                }
                else
                  {
                    let in_array = $.inArray(relationship_table[i], dependents_to_skip)
                    if (in_array != '-1'){
                      dependents_to_skip.splice(in_array, 1);
                    }
                  }
              }
              else{
                let in_array = $.inArray(relationship_table[i], dependents_to_skip)
                if (in_array != '-1'){
                  dependents_to_skip.splice(in_array, 1);
                }
              }
            }
            if (dependents_to_skip.length != 0){
              $('#addDependentSkip').removeClass('disabled')
            }
          }, 1)
        }

      }

      $('select[name="member[civil_status]"]').closest('.dropdown').closest('.field').removeClass('error')
      $('select[name="member[civil_status]"]').closest('.dropdown').closest('.field').find('.prompt').remove()

      if (relationship == "Child" || relationship == "Sibling") {
        $('#member_civil_status').dropdown('set selected', 'Single')
        disableCivilStatus()
        let last_minor = ""
        if (relationship == "Child") {
          last_minor = principal_children[0]
        } else if (relationship == "Sibling") {
          last_minor = principal_siblings[0]
        }
        if (last_minor == null) {
          $('#birthdate').calendar({
            type: 'date',
            startMode: 'year',
            minDate: new Date(principal_birthdate.getFullYear() + 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
            maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
            onChange: function (start_date, text, mode) {
              let birthdate = text.split("-", 1)
              let today_date = new Date()
              let total_age = today_date.getFullYear() - parseInt(birthdate[0])
              if (total_age > 60){
                $('#member_senior_true').prop('checked', true)
                $('#member_senior_false').attr('disabled', true)
                $('#member_senior_true').attr('disabled', false)
              } else if (total_age < 60) {
                $('#member_senior_false').prop('checked', true)
                $('#member_senior_true').attr('disabled', true)
                $('#member_senior_false').attr('disabled', false)
              }

              if ($('input[name="member[senior]"]:checked').val() == "true"){
                $('input[name="member[senior_id]"]').prop('disabled', false)
                $('div[id="senior_upload"]').removeClass("disabled")
              }
              else {
                $('input[name="member[senior_id]"]').prop('disabled', true)
                $('div[id="senior_upload"]').addClass("disabled")
              }
            },
            formatter: {
              date: function(date, settings) {
                 var monthNames = [
                  "Jan", "Feb", "Mar",
                  "Apr", "May", "Jun", "Jul",
                  "Aug", "Sep", "Oct",
                  "Nov", "Dec"
                 ];
                 var day = date.getDate();
                 var monthIndex = date.getMonth();
                 var year = date.getFullYear();

                 return monthNames[monthIndex] + ' ' + day + ', ' + year
              }
            }
          })
        } else{
          let last_minor_birthdate = new Date(last_minor.birthdate)
          last_minor_birthdate.setDate(last_minor_birthdate.getDate() + 1)
          $('#birthdate').calendar({
            type: 'date',
            startMode: 'year',
            minDate: new Date(last_minor_birthdate.getFullYear(), last_minor_birthdate.getMonth(), last_minor_birthdate.getDate()),
            maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
            onChange: function (start_date, text, mode) {
              let birthdate = text.split("-", 1)
              let today_date = new Date()
              let total_age = today_date.getFullYear() - parseInt(birthdate[0])
              if (total_age > 60){
                $('#member_senior_true').prop('checked', true)
                $('#member_senior_false').attr('disabled', true)
                $('#member_senior_true').attr('disabled', false)
              } else if (total_age < 60) {
                $('#member_senior_false').prop('checked', true)
                $('#member_senior_true').attr('disabled', true)
                $('#member_senior_false').attr('disabled', false)
              }

              if ($('input[name="member[senior]"]:checked').val() == "true"){
                $('input[name="member[senior_id]"]').prop('disabled', false)
                $('div[id="senior_upload"]').removeClass("disabled")
              }
              else {
                $('input[name="member[senior_id]"]').prop('disabled', true)
                $('div[id="senior_upload"]').addClass("disabled")
              }
            },
            formatter: {
              date: function(date, settings) {
                 var monthNames = [
                  "Jan", "Feb", "Mar",
                  "Apr", "May", "Jun", "Jul",
                  "Aug", "Sep", "Oct",
                  "Nov", "Dec"
                 ];
                 var day = date.getDate();
                 var monthIndex = date.getMonth();
                 var year = date.getFullYear();

                 return monthNames[monthIndex] + ' ' + day + ', ' + year
              }
            }
          })
        }
      } else if (relationship == "Parent") {
        if (principal_parents.length != 0) {
          if (principal_parents[0].gender == "Male") {
            $('#member_gender_Female').prop('checked', true)
            $('#member_gender_Male').attr('disabled', true)
          } else {
            $('#member_gender_Male').prop('checked', true)
            $('#member_gender_Female').attr('disabled', true)
          }
        }
        // $('#member_civil_status').dropdown('set selected', 'Married')
        // disableCivilStatus()
        enableCivilStatus()
        $('#birthdate').calendar({
          type: 'date',
          startMode: 'year',
          maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
          onChange: function (start_date, text, mode) {
            let birthdate = text.split("-", 1)
            let today_date = new Date()
            let total_age = today_date.getFullYear() - parseInt(birthdate[0])
            if (total_age > 60){
              $('#member_senior_true').prop('checked', true)
              $('#member_senior_false').attr('disabled', true)
              $('#member_senior_true').attr('disabled', false)
            } else if (total_age < 60) {
              $('#member_senior_false').prop('checked', true)
              $('#member_senior_true').attr('disabled', true)
              $('#member_senior_false').attr('disabled', false)
            }
            if ($('input[name="member[senior]"]:checked').val() == "true"){
              $('input[name="member[senior_id]"]').prop('disabled', false)
              $('div[id="senior_upload"]').removeClass("disabled")
            }
            else {
              $('input[name="member[senior_id]"]').prop('disabled', true)
              $('div[id="senior_upload"]').addClass("disabled")
            }
          },
          formatter: {
            date: function(date, settings) {
                 var monthNames = [
                  "Jan", "Feb", "Mar",
                  "Apr", "May", "Jun", "Jul",
                  "Aug", "Sep", "Oct",
                  "Nov", "Dec"
                 ];
                 var day = date.getDate();
                 var monthIndex = date.getMonth();
                 var year = date.getFullYear();

                 return monthNames[monthIndex] + ' ' + day + ', ' + year
            }
          }
        })
      } else if (relationship == "Spouse") {
        if (selected_principal.gender == "Male") {
          $('#member_gender_Female').prop('checked', true)
          $('#member_gender_Male').attr('disabled', true)
        } else {
          $('#member_gender_Male').prop('checked', true)
          $('#member_gender_Female').attr('disabled', true)
        }
        $('#member_civil_status').dropdown('set selected', 'Married')
        disableCivilStatus()
        $('#birthdate').calendar({
          type: 'date',
          startMode: 'year',
          maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
          onChange: function (start_date, text, mode) {
            let birthdate = text.split("-", 1)
            let today_date = new Date()
            let total_age = today_date.getFullYear() - parseInt(birthdate[0])
            if (total_age > 60){
              $('#member_senior_true').prop('checked', true)
              $('#member_senior_false').attr('disabled', true)
              $('#member_senior_true').attr('disabled', false)
            } else if (total_age < 60) {
              $('#member_senior_false').prop('checked', true)
              $('#member_senior_true').attr('disabled', true)
              $('#member_senior_false').attr('disabled', false)
            }

            if ($('input[name="member[senior]"]:checked').val() == "true"){
              $('input[name="member[senior_id]"]').prop('disabled', false)
              $('div[id="senior_upload"]').removeClass("disabled")
            }
            else {
              $('input[name="member[senior_id]"]').prop('disabled', true)
              $('div[id="senior_upload"]').addClass("disabled")
            }
          },
          formatter: {
            date: function(date, settings) {
                 var monthNames = [
                  "Jan", "Feb", "Mar",
                  "Apr", "May", "Jun", "Jul",
                  "Aug", "Sep", "Oct",
                  "Nov", "Dec"
                 ];
                 var day = date.getDate();
                 var monthIndex = date.getMonth();
                 var year = date.getFullYear();

                 return monthNames[monthIndex] + ' ' + day + ', ' + year
            }
          }
        })
      } else {
        $('#member_civil_status').dropdown('set selected', 'Single')
        disableCivilStatus()
        $('#birthdate').calendar({
          type: 'date',
          startMode: 'year',
          minDate: new Date(principal_birthdate.getFullYear() + 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
          maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
          onChange: function (start_date, text, mode) {
            let birthdate = text.split("-", 1)
            let today_date = new Date()
            let total_age = today_date.getFullYear() - parseInt(birthdate[0])
            if (total_age > 60){
              $('#member_senior_true').prop('checked', true)
              $('#member_senior_false').attr('disabled', true)
              $('#member_senior_true').attr('disabled', false)
            } else if (total_age < 60) {
              $('#member_senior_false').prop('checked', true)
              $('#member_senior_true').attr('disabled', true)
              $('#member_senior_false').attr('disabled', false)
            }

            if ($('input[name="member[senior]"]:checked').val() == "true"){
              $('input[name="member[senior_id]"]').prop('disabled', false)
              $('div[id="senior_upload"]').removeClass("disabled")
            }
            else {
              $('input[name="member[senior_id]"]').prop('disabled', true)
              $('div[id="senior_upload"]').addClass("disabled")
            }
          },
          formatter: {
            date: function(date, settings) {
                 var monthNames = [
                  "Jan", "Feb", "Mar",
                  "Apr", "May", "Jun", "Jul",
                  "Aug", "Sep", "Oct",
                  "Nov", "Dec"
                 ];
                 var day = date.getDate();
                 var monthIndex = date.getMonth();
                 var year = date.getFullYear();

                 return monthNames[monthIndex] + ' ' + day + ', ' + year
            }
          }
        })
      }
    }
  })


  $('#upload').click(function() {
    $('#uploadPhoto').click()
  })

  $('#birthdate').calendar({
    type: 'date',
    startMode: 'year',
    maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
    onChange: function (start_date, text, mode) {
      let birthdate = text.split("-", 1)
      let today_date = new Date()
      let total_age = today_date.getFullYear() - parseInt(birthdate[0])
      if (total_age > 60){
        $('#member_senior_true').prop('checked', true)
        $('#member_senior_false').attr('disabled', true)
        $('#member_senior_true').attr('disabled', false)
      } else if (total_age < 60) {
        $('#member_senior_false').prop('checked', true)
        $('#member_senior_true').attr('disabled', true)
        $('#member_senior_false').attr('disabled', false)
      }

      if ($('input[name="member[senior]"]:checked').val() == "true"){
        $('input[name="member[senior_id]"]').prop('disabled', false)
        $('div[id="senior_upload"]').removeClass("disabled")
      }
      else {
        $('input[name="member[senior_id]"]').prop('disabled', true)
        $('div[id="senior_upload"]').addClass("disabled")
      }
    },
    formatter: {
      date: function(date, settings) {
             var monthNames = [
              "Jan", "Feb", "Mar",
              "Apr", "May", "Jun", "Jul",
              "Aug", "Sep", "Oct",
              "Nov", "Dec"
             ];
             var day = date.getDate();
             var monthIndex = date.getMonth();
             var year = date.getFullYear();

             return monthNames[monthIndex] + ' ' + day + ', ' + year
      }
    }
  })

  // if ($('input[name="member[senior_id]"]').val() != ""){
  //   document.getElementById("member_senior_Yes").checked = true;
  // }

  if ($('input[name="member[senior_id]"]').val() != ""){
    document.getElementById("member_pwd_Yes").checked = true;
  }

  if ($('input[name="member[pwd]"]:checked').val() == "true"){
    $('input[name="member[pwd_id]"]').prop('disabled', false)
    $('div[id="pwd_upload"]').removeClass("disabled")
  }
  else {
    $('input[name="member[pwd_id]"]').prop('disabled', true)
    $('div[id="pwd_upload"]').addClass("disabled")
  }

  $('input[type=radio][name="member[pwd]"]').on('change', function() {
    if ($('input[name="member[pwd]"]:checked').val() == "true"){
      $('input[name="member[pwd_id]"]').prop('disabled', false)
      $('div[id="pwd_upload"]').removeClass("disabled")
    }
    else {
      $('input[name="member[pwd_id]"]').prop('disabled', true)
      $('div[id="pwd_upload"]').addClass("disabled")
    }
  });


  if ($('input[name="member[senior]"]:checked').val() == "true"){
    $('input[name="member[senior_id]"]').prop('disabled', false)
    $('div[id="senior_upload"]').removeClass("disabled")
  }
  else {
    $('input[name="member[senior_id]"]').prop('disabled', true)
    $('div[id="senior_upload"]').addClass("disabled")
  }

  $('input[type=radio][name="member[senior]"]').on('change', function() {
    if ($('input[name="member[senior]"]:checked').val() == "true"){
      $('input[name="member[senior_id]"]').prop('disabled', false)
      $('div[id="senior_upload"]').removeClass("disabled")
    }
    else {
      $('input[name="member[senior_id]"]').prop('disabled', true)
      $('div[id="senior_upload"]').addClass("disabled")
    }
  });

  $('#dateHired').calendar({
    type: 'date',
    startMode: 'year',
    formatter: {
      date: function(date, settings) {
         var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
         ];
         var day = date.getDate();
         var monthIndex = date.getMonth();
         var year = date.getFullYear();

         return monthNames[monthIndex] + ' ' + day + ', ' + year
      }
    }
  })

  $('#regularizationDate').calendar({
    type: 'date',
    startMode: 'year',
    startCalendar: $('#dateHired'),
    formatter: {
      date: function(date, settings) {
         var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
         ];
         var day = date.getDate();
         var monthIndex = date.getMonth();
         var year = date.getFullYear();

         return monthNames[monthIndex] + ' ' + day + ', ' + year
      }
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
          prompt: 'Please enter Account Code'
        }]
      },
      effectivity_date: {
        identifier: 'effectivity_date',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Effectivity Date'
        }]
      },
      expiry_date: {
        identifier: 'expiry_date',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Expiry Date'
        }]
      },
      first_name: {
        identifier: 'first_name',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter First Name'
          },
          {
            type: 'maxLength[150]',
            prompt: 'First Name cannot exceed 150 characters'
          }
        ]
      },
      last_name: {
        identifier: 'last_name',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter Last Name'
          },
          {
            type: 'maxLength[150]',
            prompt: 'Last Name cannot exceed 150 characters'
          }
        ]
      },
      middle_name: {
        identifier: 'middle_name',
        rules: [
          {
            type: 'maxLength[150]',
            prompt: 'Middle Name cannot exceed 150 characters'
          }
        ]
      },
      suffix: {
        identifier: 'suffix',
        rules: [
          {
            type: 'maxLength[10]',
            prompt: 'Suffix cannot exceed 10 characters'
          }
        ]
      },
      tin: {
        identifier: 'tin',
        rules: [
          {
            type   : 'customLength[param]',
            prompt : 'TIN must be 12 digits'
          }
        ]
      },
      birthdate: {
        identifier: 'birthdate',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Birthdate'
        }]
      },
      philhealth: {
        identifier: 'philhealth',
        optional: true,
        rules: [
          // {
          //   type: 'empty',
          //   prompt: 'Please enter PhilHealth Number'
          // },
          {
            type   : 'customLength[param]',
            prompt : 'PhilHealth Number must be 12 digits'
          }
        ]
      },
      civil_status: {
        identifier: 'civil_status',
        rules: [{
          type: 'empty',
          prompt: 'Please select Civil Status'
        }]
      },
      regularization_date: {
        identifier: 'regularization_date',
        optional: true,
        rules: [{
          type: 'empty',
          prompt: 'Please enter Regularization Date'
        }]
      },
      onSuccess: function(event, fields) {
        /*let checker = validate_hierarchy_skipping()
        if (checker == false) {
          event.preventDefault()
          }
          */
      }
    }
  })

  function validateCorporatePrincipal() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Employee No'
            },
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Employee number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        },
        regularization_date: {
          identifier: 'regularization_date',
          optional: true,
          rules: [{
            type: 'empty',
            prompt: 'Please enter Regularization Date'
          }]
        }
      }
    })
  }

  function validateCorporateDependent() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        principal_id: {
          identifier: 'principal_id',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Principal ID'
          }]
        },
        relationship: {
          identifier: 'relationship',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Relationship'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Employee number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        },
        principal_product_id: {
          identifier: 'principal_product_id',
          rules: [{
            type: 'empty',
            prompt: "Please select Principal's Plan"
          }]
        }
      },
      onSuccess: function(event, fields) {
        /*
        let checker = validate_hierarchy_skipping()
        if (checker == false) {
          event.preventDefault()
          }
          */
      }
    })
  }

  function validateCorporateGuardian() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Employee No'
            },
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Employee number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        },
        regularization_date: {
          identifier: 'regularization_date',
          optional: true,
          rules: [{
            type: 'empty',
            prompt: 'Please enter Regularization Date'
          }]
        }
      }
    })
  }

  function validateOthersPrincipal() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Principal Number'
            },
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Employee number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        },
        regularization_date: {
          identifier: 'regularization_date',
          optional: true,
          rules: [{
            type: 'empty',
            prompt: 'Please enter Regularization Date'
          }]
        },
        onSuccess: function(event, fields) {
          /*
          let checker = validate_hierarchy_skipping()
          if (checker == false) {
            event.preventDefault()
            }
            */
        }
      }
    })
  }

  function validateOthersDependent() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        principal_id: {
          identifier: 'principal_id',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Principal ID'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Principal number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        relationship: {
          identifier: 'relationship',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Relationship'
          }]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        },
        principal_product_id: {
          identifier: 'principal_product_id',
          rules: [{
            type: 'empty',
            prompt: "Please select Principal's Plan"
          }]
        }
      }
    })
  }

  function validateOthersGuardian() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Principal No'
            },
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Principal number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        },
        regularization_date: {
          identifier: 'regularization_date',
          optional: true,
          rules: [{
            type: 'empty',
            prompt: 'Please enter Regularization Date'
          }]
        }
      }
    })
  }

  function disableCivilStatus() {
    $('#member_civil_status').prop('disabled', true)
    $('#member_civil_status').closest('div.dropdown').addClass('disabled')
  }

  function enableCivilStatus() {
    $('#member_civil_status').dropdown('restore defaults')
    $('#member_civil_status').prop('disabled', false)
    $('#member_civil_status').closest('div.dropdown').removeClass('disabled')
  }

  function enableDependentFields(){
    $('#principalID').prop('disabled', false)
    $('#principalID').closest('div.dropdown').removeClass('disabled')
    $('#relationship').prop('disabled', false)
    $('#relationship').closest('div.dropdown').removeClass('disabled')
    $('#principalProductID').prop('disabled', false)
    $('#principalProductID').closest('div.dropdown').removeClass('disabled')
    $('input[name="member[effectivity_date]"]').prop('disabled', true)
 }

  function disableDependentFields(){
    $('#principalID').prop('disabled', true)
    $('#principalID').closest('div.dropdown').addClass('disabled')
    $('#relationship').prop('disabled', true)
    $('#relationship').closest('div.dropdown').addClass('disabled')
    $('#principalProductID').prop('disabled', true)
    $('#principalProductID').closest('div.dropdown').addClass('disabled')
    $('input[name="member[effectivity_date]"]').prop('disabled', false)
  }

  function disableEmployeeFields(){
    $('input[name="member[employee_no]"]').prop('disabled', true)
    $('input[name="member[date_hired]"]').prop('disabled', true)
    $('input[name="member[regularization_date]"').prop('disabled', true)
    $('input[name="member[is_regular]"]').prop('disabled', true)
  }

  function enableEmployeeFields(){
    $('input[name="member[employee_no]"]').prop('disabled', false)
    $('input[name="member[date_hired]"]').prop('disabled', false)
    $('input[name="member[regularization_date]"').prop('disabled', false)
    $('input[name="member[is_regular]"]').prop('disabled', false)
  }

  $('input[name="member[type]"]').change(function() {
    $('select[name="member[relationship]"]').dropdown('clear')
    $('select[name="member[relationship]"]').val('')
    $('select[name="member[principal_id]"]').dropdown('clear')
    $('select[name="member[principal_product_id]"]').dropdown('clear')
    $('div').removeClass('error')
    $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
    $('#member_is_regular_false').prop('checked', true)
    let val = $(this).val()
    let account_code = $('select[name="member[account_code]"]').val()
    let id = '#' + account_code
    let segment = $(id).attr('segment')
    let effectiveDate = $(id).attr('effectiveDate')
    let expiryDate = $(id).attr('expiryDate')

    enableCivilStatus()

    $('#principalProductID').html('')
    $('#principalProductID').append('<option value="">Select Principal ID</option>')
    $('#principalProductID').dropdown('clear')
    $('#principalProductID').dropdown()

    if (val == "Principal") {
      disableDependentFields()
      if (segment == "Corporate") {
        enableEmployeeFields()
        validateCorporatePrincipal()
      } else {
        disableEmployeeFields()
        validateOthersPrincipal()
        $('input[name="member[employee_no]"]').prop('disabled', false)
      }
      $('#hierarchy_table tbody tr').each(function(){
        $(this).remove()
      })
      $('#hierarchy_table').attr('style', 'display: none;')
    } else if (val == "Dependent") {
      disableEmployeeFields()
      enableDependentFields()
      if (segment == "Corporate") {
        validateCorporateDependent()
      } else {
        validateOthersDependent()
        $('input[name="member[employee_no]"]').prop('disabled', true)
      }
    } else if (val == "Guardian") {
      disableEmployeeFields()
      disableDependentFields()
      if (segment == "Corporate") {
        validateCorporateGuardian()
        $('input[name="member[employee_no]"]').prop('disabled', false)
      } else {
        validateOthersGuardian()
        $('input[name="member[employee_no]"]').prop('disabled', false)
      }
      $('#hierarchy_table tbody tr').each(function(){
        $(this).remove()
      })
      $('#hierarchy_table').attr('style', 'display: none;')
    }

    $('#birthdate').calendar({
      type: 'date',
      startMode: 'year',
      maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
      onChange: function (start_date, text, mode) {
        let birthdate = text.split("-", 1)
        let today_date = new Date()
        let total_age = today_date.getFullYear() - parseInt(birthdate[0])
        if (total_age > 60){
            $('#member_senior_true').prop('checked', true)
            $('#member_senior_false').attr('disabled', true)
            $('#member_senior_true').attr('disabled', false)
        } else if (total_age < 60) {
            $('#member_senior_false').prop('checked', true)
            $('#member_senior_true').attr('disabled', true)
            $('#member_senior_false').attr('disabled', false)
        }

        if ($('input[name="member[senior]"]:checked').val() == "true"){
          $('input[name="member[senior_id]"]').prop('disabled', false)
          $('div[id="senior_upload"]').removeClass("disabled")
        }
        else {
          $('input[name="member[senior_id]"]').prop('disabled', true)
          $('div[id="senior_upload"]').addClass("disabled")
        }
      },
      formatter: {
        date: function(date, settings) {
           var monthNames = [
            "Jan", "Feb", "Mar",
            "Apr", "May", "Jun", "Jul",
            "Aug", "Sep", "Oct",
            "Nov", "Dec"
           ];
           var day = date.getDate();
           var monthIndex = date.getMonth();
           var year = date.getFullYear();

           return monthNames[monthIndex] + ' ' + day + ', ' + year
        }
      }
    })

    if (val != "Dependent") {
      $('#effectiveDate').calendar({
        type: 'date',
        startMode: 'day',
        minDate: new Date(effectiveDate),
        maxDate: new Date(expiryDate),
        formatter: {
          date: function(date, settings) {
             var monthNames = [
              "Jan", "Feb", "Mar",
              "Apr", "May", "Jun", "Jul",
              "Aug", "Sep", "Oct",
              "Nov", "Dec"
             ];
             var day = date.getDate();
             var monthIndex = date.getMonth();
             var year = date.getFullYear();

             return monthNames[monthIndex] + ' ' + day + ', ' + year
          }
        }
      })
      $('#expiryDate').calendar({
        type: 'date',
        startMode: 'day',
        startCalendar: $('#effectiveDate'),
        maxDate: new Date(expiryDate),
        formatter: {
          date: function(date, settings) {
             var monthNames = [
              "Jan", "Feb", "Mar",
              "Apr", "May", "Jun", "Jul",
              "Aug", "Sep", "Oct",
              "Nov", "Dec"
             ];
             var day = date.getDate();
             var monthIndex = date.getMonth();
             var year = date.getFullYear();

             return monthNames[monthIndex] + ' ' + day + ', ' + year
          }
        }
      })
    }

  })

  // $('input[name="member[is_regular]"]').change(function() {
  //   let val = $(this).val()
  //   $('input[name="member[regularization_date]"]').closest('.input').closest('.calendar').closest('.field').removeClass('error')
  //   $('input[name="member[regularization_date]"]').closest('.input').closest('.calendar').closest('.field').find('.prompt').remove()
  //   if (val == "true") {
  //     $('input[name="member[regularization_date]"]').val('')
  //     $('input[name="member[regularization_date]"]').prop('disabled', true)
  //   } else {
  //     $('input[name="member[regularization_date]"]').prop('disabled', false)
  //   }
  // })

  if ($('input[name="member[type]"]:checked').val() == "Dependent") {
    $('#principalID').prop('disabled', false)
    $('#principalID').closest('div.dropdown').removeClass('disabled')
    $('#relationship').prop('disabled', false)
    $('#relationship').closest('div.dropdown').removeClass('disabled')
  } else {
    $('#principalID').prop('disabled', true)
    $('#principalID').closest('div.dropdown').removeClass('disabled')
    $('#relationship').prop('disabled', true)
    $('#relationship').closest('div.dropdown').addClass('disabled')
  }

  if ($('select[name="member[account_code]"]').val() != "") {
    $('input[name="member[type]"]').prop('disabled', false)
    let account_group_code = $('select[name="member[account_code]"]').val()

    $.ajax({
      url:`/api/v1/accounts/${account_group_code}/get_an_account_by_code`,
      type: 'GET',
      success: function(response){

        $('input[name="member[effectivity_date]"]').prop('disabled', false)
        $('input[name="member[expiry_date]"]').prop('disabled', false)

        // set dependent hierarchies of returned account
        single_dependent_hierarchy.length = 0
        single_parent_dependent_hierarchy.length = 0
        married_dependent_hierarchy.length = 0
        $.map(response.dependent_hierarchy, function(dependent_hierarchy, index) {
          if (dependent_hierarchy.hierarchy_type == "Single Employee") {
            single_dependent_hierarchy.push(dependent_hierarchy.dependent)
          }
          if (dependent_hierarchy.hierarchy_type == "Single Parent Employee") {
            single_parent_dependent_hierarchy.push(dependent_hierarchy.dependent)
          }
          if (dependent_hierarchy.hierarchy_type == "Married Employee") {
            married_dependent_hierarchy.push(dependent_hierarchy.dependent)
          }
        })

        // get employee numbers within the selected account
        employee_number_array.length = 0
        $.map(response.members, function(member, index) {
          if (member.employee_no != null && member.id != member_id){
            employee_number_array.push(member.employee_no)
          }
        })

        // get principal IDs within the selected account
        account_principals.length = 0
        $('#principalID').html('')
        $('#principalID').append('<option value="">Select Principal ID</option>')
        for (let member of response.members) {
          if ((member.type == "Principal" || member.type == "Guardian") && member.id != member_id && member.status == "Active") {
            account_principals.push(member)
            $('#principalID').append(`<option value="${member.id}">${member.id} - ${member.first_name} ${member.last_name}</option>`)
          }
        }

          let relationship = $('select#relationship option:selected').attr('id')
          for (let a=1;a<relationship;a++){
            let val = $('select#relationship').find(`#${a}`).val()
            $('select#relationship').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).addClass('disabled')
          }
        $('#principalID').dropdown('clear')
        $('#principalID').dropdown()

        setTimeout(function () {
          $('#principalID').dropdown('set selected', $('#memberPrincipalID').val())
        }, 1)

        let effectiveDate = response.account[0].start_date
        let expiryDate = response.account[0].end_date

        $('#effectiveDate').calendar({
          type: 'date',
          startMode: 'day',
          minDate: new Date(effectiveDate),
          maxDate: new Date(expiryDate),
          formatter: {
            date: function(date, settings) {
               var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
               ];
               var day = date.getDate();
               var monthIndex = date.getMonth();
               var year = date.getFullYear();

               return monthNames[monthIndex] + ' ' + day + ', ' + year
            }
          }
        })
        $('#expiryDate').calendar({
          type: 'date',
          startMode: 'day',
          startCalendar: $('#effectiveDate'),
          maxDate: new Date(expiryDate),
          formatter: {
            date: function(date, settings) {
               var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
               ];
               var day = date.getDate();
               var monthIndex = date.getMonth();
               var year = date.getFullYear();

               return monthNames[monthIndex] + ' ' + day + ', ' + year
            }
          }
        })

      }
    })
  }

  $('select[name="member[account_code]"]').change(function() {
    $('input[name="member[type]"]').prop('disabled', false)
    $('input[name="member[effectivity_date]"]').prop('disabled', false)
    $('input[name="member[expiry_date]"]').prop('disabled', false)

    let id = '#' + $(this).val()
    let effectiveDate = $(id).attr('effectiveDate')
    let expiryDate = $(id).attr('expiryDate')
    let segment = $(id).attr('segment')
    let memberType = $('input[name="member[type]"]:checked').val()

    if (segment == "Corporate") {
      $('#employeeNoLabel').html('Employee No')
    } else {
      $('#employeeNoLabel').html('Principal No')
    }

    if (memberType == "Principal") {
      disableDependentFields()
      if (segment == "Corporate") {
        enableEmployeeFields()
        validateCorporatePrincipal()
      } else {
        disableEmployeeFields()
        validateOthersPrincipal()
        $('input[name="member[employee_no]"]').prop('disabled', false)
      }
    } else if (memberType == "Dependent") {
      disableEmployeeFields()
      enableDependentFields()
      if (segment == "Corporate") {
        validateCorporateDependent()
      } else {
        validateOthersDependent()
        $('input[name="member[employee_no]"]').prop('disabled', true)
      }
    } else if (memberType == "Guardian") {
      disableEmployeeFields()
      disableDependentFields()
      if (segment == "Corporate") {
        validateCorporateGuardian()
        $('input[name="member[employee_no]"]').prop('disabled', false)
      } else {
        validateOthersGuardian()
        $('input[name="member[employee_no]"]').prop('disabled', false)
      }
    }

    $('input[name="member[effectivity_date]"]').val(effectiveDate)
    $('input[name="member[expiry_date]"]').val(expiryDate)
    $('#effectiveDate').calendar({
      type: 'date',
      startMode: 'day',
      minDate: new Date(effectiveDate),
      maxDate: new Date(expiryDate),
      formatter: {
        date: function(date, settings) {
               var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
               ];
               var day = date.getDate();
               var monthIndex = date.getMonth();
               var year = date.getFullYear();

               return monthNames[monthIndex] + ' ' + day + ', ' + year
        }
      }
    })
    $('#expiryDate').calendar({
      type: 'date',
      startMode: 'day',
      startCalendar: $('#effectiveDate'),
      maxDate: new Date(expiryDate),
      formatter: {
        date: function(date, settings) {
               var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
               ];
               var day = date.getDate();
               var monthIndex = date.getMonth();
               var year = date.getFullYear();

               return monthNames[monthIndex] + ' ' + day + ', ' + year
        }
      }
    })
  })

  if ($('select[name="member[account_code]"]').val() != "") {
    let account_code = $('select[name="member[account_code]"]').val()
    let val = $('input[name="member[type]"]:checked').val()
    let id = '#' + account_code
    let segment = $(id).attr('segment')

    if (segment == "Corporate") {
      $('#employeeNoLabel').html('Employee No')
    } else {
      $('#employeeNoLabel').html('Principal No')
    }

    if (val == "Principal") {
      disableDependentFields()
      if (segment == "Corporate") {
        enableEmployeeFields()
        validateCorporatePrincipal()
      } else {
        disableEmployeeFields()
        validateOthersPrincipal()
        $('input[name="member[employee_no]"]').prop('disabled', false)
      }
    } else if (val == "Dependent") {
      disableEmployeeFields()
      enableDependentFields()
      if (segment == "Corporate") {
        validateCorporateDependent()
      } else {
        validateOthersDependent()
        $('input[name="member[employee_no]"]').prop('disabled', true)
      }
    } else if (val == "Guardian") {
      disableEmployeeFields()
      disableDependentFields()
      if (segment == "Corporate") {
        validateCorporateGuardian()
        $('input[name="member[employee_no]"]').prop('disabled', false)
      } else {
        validateOthersGuardian()
        $('input[name="member[employee_no]"]').prop('disabled', false)
      }
    }
  }

  $('body').on('click', '.remove-skip-item', function() {
    $(this).closest('.dependents-to-skip').remove()
  });

  $('body').on('keyup', '.validate-required', function() {
    $(this).find('.prompt').remove()
    $(this).removeClass('error')
  });

  $('body').on('change', '.select-validate-required', function() {
    $(this).find('.prompt').remove()
    $(this).removeClass('error')
  });

  $('body').on('change', '.file-validate-required', function() {
    $(this).find('.prompt').remove()
    $(this).removeClass('error')
  });

  // if ($('input[name="member[is_regular]"]:checked').val() == "true") {
  //   $('input[name="member[regularization_date]"]').val('')
  //   $('input[name="member[regularization_date]"]').prop('disabled', true)
  // }

  //Additional JS for skipping hierarchy modal
  $('.add-skip-item').on('click', function(){
    let valid_text = validate_text_inputs()
    let valid_select = validate_select_inputs()
    let valid_file = validate_file_inputs()
    let relationship = ''
    let name = ''
    let first_name = ''
    let middle_name = ''
    let last_name = ''
    let suffix = ''
    let gender = ''
    let birthdate = ''
    let reason = ''
    let supporting_file = ''
    relationship = $('select.skip_relationship option:selected').val()
    name = $('input[name="member_first_name"]').val() + ' ' + $('input[name="member_middle_name"]').val() + ' ' + $('input[name="member_last_name"]').val() + ' ' + $('input[name="member_suffix"]').val()
    first_name = $('input[name="member_first_name"]').val()
    middle_name = $('input[name="member_middle_name"]').val()
    last_name = $('input[name="member_last_name"]').val()
    suffix = $('input[name="member_suffix"]').val()
    gender = $('input[name="member_gender"]:checked').val()
    birthdate = $('input[name="member_birthdate"]').val()
    reason = $('.select-validate-required').find('.skip_reason').find('select').val()
    supporting_file = $('input[name="member_supporting_document"]').prop('files')[0];
    let reader = new FileReader();
    let base64 = ''
    if (supporting_file != "") {
      reader.readAsBinaryString(supporting_file);
      reader.onload = function(readerEvt) {
        let binaryString = readerEvt.target.result;
        base64 = btoa(binaryString)
        let data = ``
        if (valid_text == true && valid_select == true && valid_file == true){
          data = `<tr>
          <td id="table_relationship" class="relationship" relationship="${relationship}" first_name="${first_name}" middle_name="${middle_name}" last_name="${last_name}" suffix="${suffix}" gender="${gender}" birthdate="${birthdate}" reason="${reason}" file_name="${supporting_file.name}" extension="${supporting_file.name.split('.').pop()}" base64="${base64}" >${relationship}</td>
          <td>${name}</td>
          <td id="table_gender">${gender}</td>
          <td>${birthdate}</td>
          <td>${reason}</td>
          <td>${supporting_file.name}</td>
          <td class="remove_skip_icon"><i class="trash icon"></i></td>
          </tr>`
          $('#hierarchy_data').append(data)
          $('.add_skipping_hierarchy').modal('hide')
          $('.remove_skip_icon').on('click', function(){
            let this_class = $(this)
            swal({
              title: 'Remove Skipping Hierarchy',
              text: "Are you sure you want to remove this Skipping Hierarchy?",
              type: 'question',
              showCancelButton: true,
              cancelButtonText: '<i class="remove icon"></i> Cancel',
              confirmButtonText: '<i class="trash icon"></i> Remove',
              cancelButtonClass: 'ui button',
              confirmButtonClass: 'ui blue button',
              buttonsStyling: false
            }).then(function () {
              let relationship = this_class.closest('td').closest('tr').find('.relationship').html()
              if (dependents_to_skip.indexOf(relationship) == -1) {
                dependents_to_skip.push(relationship)
              }
              this_class.closest('td').closest('tr').remove();

              let relationship_table = []
              setTimeout(function () {
                $('#hierarchy_table tbody tr').each(function(){
                  relationship_table.push($(this).find('#table_relationship').html())
                })
                if (relationship_table.length == 0){
                  let relationship_dropdown = $('select#relationship option:selected').attr('id')
                  for (let a=1;a<relationship_dropdown;a++){
                    let val = $('select#relationship').find(`#${a}`).val()
                    $('select#relationship').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).removeClass('disabled')
                  }
                }
                if (dependents_to_skip.length != 0){
                  $('#addDependentSkip').removeClass('disabled')
                }
              }, 1)
              /*for (let i=0;i<relationship_table.length;i++){
                let in_array = $.inArray(relationship_table[i], dependents_to_skip)
                if (in_array != '-1'){
                  dependents_to_skip.splice(in_array, 1);
                }
                }
              */
              /* if (dependents_to_skip.length != 0){
                $('#addDependentSkip').removeClass('disabled')
                }
              */
            })
          })

          /* let relationship_table = []
          setTimeout(function () {
            $('#hierarchy_table tbody tr').each(function(){
              relationship_table.push($(this).find('#table_relationship').html())
            })
          }, 1)
          for (let i=0;i<relationship_table.length;i++){
            let in_array = $.inArray(relationship_table[i], dependents_to_skip)
            if (in_array != '-1'){
              dependents_to_skip.splice(in_array, 1);
            }
          }
          if (dependents_to_skip.length == 0){
            $('#addDependentSkip').addClass('disabled')
          }
          */
        }
      }
    };
  })
  $('.add_skipping_hierarchy').modal({
    closable  : false,
    onHide : function(){
    $('select.skip_relationship').val('')
    $('input[name="member_first_name"]').val('')
    $('input[name="member_middle_name"]').val('')
    $('input[name="member_last_name"]').val('')
    $('input[name="member_suffix"]').val('')
    $('input[name="member_gender"][value="Male"]').prop('checked', true);
    $('input[name="member_birthdate"]').val('')
    $('input[name="member_reason"]').val('')
    $('input[name="member_supporting_document"]').val('');
    $('.skip_relationship').val('')
    $('#skipped_gender_Male').removeAttr('disabled')
    $('#skipped_gender_Female').removeAttr('disabled')
    $('.select-validate-required').find('.text').html('');
    let relationship = $('select#relationship option:selected').attr('id')
    let relationship_table = []
    $('#hierarchy_table tbody tr').each(function(){
      relationship_table.push($(this).find('#table_relationship').html())
    })
    let parent_count = 0
    let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
    for (let dependent of selected_principal.dependents){
      if (dependent.relationship == "Parent" && dependent.status != "Disapprove"){
        parent_count += 1
      }
    }

    for (let i=0;i<relationship_table.length;i++){
      if (relationship_table[i] == "Parent"){
        if (parent_count != 1){
          parent_count = parent_count + 1
        }
        else
          {
            let in_array = $.inArray(relationship_table[i], dependents_to_skip)
            if (in_array != '-1'){
              dependents_to_skip.splice(in_array, 1);
            }
          }
      }
      else{
        let in_array = $.inArray(relationship_table[i], dependents_to_skip)
        if (in_array != '-1'){
          dependents_to_skip.splice(in_array, 1);
        }
      }
    }
    if (dependents_to_skip.length == 0){
     $('#addDependentSkip').addClass('disabled')
    }
    if (relationship_table.length > 0){
      for (let a=1;a<relationship;a++){
        let val = $('select#relationship').find(`#${a}`).val()
        $('select#relationship').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).addClass('disabled')
      }
    }
    }

  });

  function validate_text_inputs() {
    let valid = true
    $('.validate-required').each(function(){
      $(this).removeClass('error')
      $(this).find('.prompt').remove()
      let field = $(this).find('input').val()
      if (field == "") {
        let field_name = $(this).find('label').html()
        $(this).addClass('error')
        $(this).append(`<div class="ui basic red pointing prompt label transition visible">Please enter ${field_name}</div>`)
        valid = false
      }
    })
    return valid
  }

  function validate_select_inputs() {
    let valid = true
    $('.select-validate-required').each(function(){
      $(this).removeClass('error')
      $(this).find('.prompt').remove()
      let field = $(this).find('.dropdown').find('select').val()
      if (field == "" || field == null) {
        let field_name = $(this).find('label').html()
        $(this).addClass('error')
        $(this).append(`<div class="ui basic red pointing prompt label transition visible">Please enter ${field_name}</div>`)
        valid = false
      }
    })
    return valid
  }

  function validate_file_inputs() {
    let valid = true
    $('.file-validate-required').each(function(){
      $(this).removeClass('error')
      $(this).find('.prompt').remove()
      let field = $(this).find('input').val()
      if (field == "") {
        let field_name = $(this).find('label').html()
        $(this).addClass('error')
        $(this).append(`<div class="ui basic red pointing prompt label transition visible">Please Choose a File</div>`)
        valid = false
      }else
        {
          let file_extensions = "pdf,xls,jpg,csv,doc,docx,xlsx,png"
          let this_extension = $(this).find('input[name="member_supporting_document"]').prop('files')[0].name.split('.').pop()
          if (file_extensions.indexOf(this_extension) == -1) {
            $(this).addClass('error')
            $(this).append(`<div class="ui basic red pointing prompt label transition visible">Invalid File type. Valid file type are in .xls, .xlsx, .csv, .docx, .png, .jpg, .jpeg, and .pdf  format</div>`)
          valid = false
          }
        }
    })
    return valid
  }

  $('.skip_relationship').change(function(){
    $('#skipped_gender_Male').attr('disabled', false)
    $('#skipped_gender_Female').attr('disabled', false)
    $('#skipped_gender_Male').prop('checked', true)
    let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
    if ($(this).val() == "Spouse") {
      if (selected_principal.gender == "Male") {
        $('#skipped_gender_Female').prop('checked', true)
        $('#skipped_gender_Male').attr('disabled', true)
      } else {
        $('#skipped_gender_Male').prop('checked', true)
        $('#skipped_gender_Female').attr('disabled', true)
      }
      $('.skip-calendar').calendar({
        type: 'date',
        startMode: 'year',
        maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
        formatter: {
          date: function(date, settings) {
               var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
               ];
               var day = date.getDate();
               var monthIndex = date.getMonth();
               var year = date.getFullYear();

               return monthNames[monthIndex] + ' ' + day + ', ' + year
          }
        }
      })
    }
    if ($(this).val() == "Parent") {
      let parent_gender = ''
      $('#hierarchy_table tbody tr').each(function(){
        if ($(this).find('#table_relationship').html() == 'Parent'){
          parent_gender = $(this).find('#table_gender').html()
          if (parent_gender == "Male") {
            $('#skipped_gender_Female').prop('checked', true)
            $('#skipped_gender_Male').attr('disabled', true)
          } else {
            $('#skipped_gender_Male').prop('checked', true)
            $('#skipped_gender_Female').attr('disabled', true)
          }
        }
      })
      for (let dependent of selected_principal.dependents){
        if (dependent.relationship == "Parent" && dependent.status != "Disapprove"){
          if (dependent.gender == "Male"){
            $('#skipped_gender_Female').prop('checked', true)
            $('#skipped_gender_Male').attr('disabled', true)
          }else
            {
              $('#skipped_gender_Male').prop('checked', true)
              $('#skipped_gender_Female').attr('disabled', true)
            }
        }
      }
      let principal_birthdate = new Date(selected_principal.birthdate)
      $('.skip-calendar').calendar({
        type: 'date',
        startMode: 'year',
        maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
        formatter: {
          date: function(date, settings) {
               var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
               ];
               var day = date.getDate();
               var monthIndex = date.getMonth();
               var year = date.getFullYear();

               return monthNames[monthIndex] + ' ' + day + ', ' + year
          }
        }
      })

    }
    if ($(this).val() == "Child" || $(this).val() == "Sibling") {
      let principal_birthdate = new Date(selected_principal.birthdate)
      $('.skip-calendar').calendar({
        type: 'date',
        startMode: 'year',
        minDate: new Date(principal_birthdate.getFullYear() + 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
        maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
        formatter: {
          date: function(date, settings) {
               var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
               ];
               var day = date.getDate();
               var monthIndex = date.getMonth();
               var year = date.getFullYear();

               return monthNames[monthIndex] + ' ' + day + ', ' + year
          }
        }
      })
    }

  })
  $('.cancel-skip').click(function(){
    $('.add_skipping_hierarchy').modal('hide')
  })

  function append_dependent_to_skip(count) {
    let relationship_options = ''
    for (let relationship of dependents_to_skip) {
      relationship_options += `<option value="${relationship}">${relationship}</option>`
    }
    let new_row = `\
      <div class="dependents-to-skip">\
        <div class="two fields">\
          <div class="field select-validate-required">\
            <label for="member_relationship">Relationship</label>\
            <div class="ui dropdown selection" tabindex="0">\
              <select name="member[dependent_skip][${count}][relationship]" class="skip_relationship">\
                <option value="">Select Relationship</option>\
                ${relationship_options}\
              </select>\
              <i class="dropdown icon"></i>\
              <div class="default text">Select Relationship</div>\
              <div class="menu" tabindex="-1"></div>\
            </div>\
          </div>\
          <div class="field validate-required">\
            <label for="">First Name</label>\
            <input class="person name" name="member[dependent_skip][${count}][first_name]" type="text">\
          </div>\
        </div>\
        <div class="two fields">\
          <div class="field">\
            <label>Middle Name</label>\
            <input class="person name" name="member[dependent_skip][${count}][middle_name]" type="text">\
          </div>\
          <div class="field validate-required">\
            <label>Last Name</label>\
            <input class="person name" name="member[dependent_skip][${count}][last_name]" type="text">\
          </div>\
        </div>\
        <div class="two fields">\
          <div class="field">\
            <div class="two fields">\
              <div class="field">\
                <label>Suffix</label>\
                <input name="member[dependent_skip][${count}][suffix]" type="text">\
              </div>\
              <div class="field">\
                <div class="field">\
                  <label>Gender</label>\
                </div>\
                <div class="inline fields">\
                  <div class="field">\
                    <div class="ui radio checkbox">\
                      <input checked="" name="member[dependent_skip][${count}][gender]" type="radio" value="Male" tabindex="0" class="hidden">\
                      <label>Male</label>\
                    </div>\
                  </div>\
                  <div class="field">\
                    <div class="ui radio checkbox">\
                      <input name="member[dependent_skip][${count}][gender]" type="radio" value="Female" tabindex="0" class="hidden">\
                      <label>Female</label>\
                    </div>\
                  </div>\
                </div>\
              </div>\
            </div>\
          </div>\
          <div class="field validate-required">\
            <label>Birthdate</label>\
            <div class="skip-calendar ui calendar">\
              <div class="ui input right icon">\
                <i class="calendar icon"></i>\
                <input name="member[dependent_skip][${count}][birthdate]" placeholder="YYYY-MM-DD" type="text">\
              </div>\
            </div>\
          </div>\
        </div>\
        <div class="two fields">\
          <div class="field validate-required">\
            <label>Reason</label>\
            <input class="person name" name="member[dependent_skip][${count}][reason]" type="text">\
          </div>\
          <div class="field file-validate-required">\
            <label>Supporting Document</label>\
            <input name="member[dependent_skip][${count}][supporting_document]" type="file">\
          </div>\
        </div>\
        <button type="button" class="ui button remove-skip-item">Remove</button>\
      </div>\
    `
    $('#skipContainer').append(new_row)
    $('.skip_relationship').dropdown()
    $('.ui .checkbox').checkbox()

    $('.skip-calendar').calendar({
      type: 'date',
      startMode: 'year',
      maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
      formatter: {
        date: function(date, settings) {
               var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
               ];
               var day = date.getDate();
               var monthIndex = date.getMonth();
               var year = date.getFullYear();

               return monthNames[monthIndex] + ' ' + day + ', ' + year
        }
      }
    })

  }

  //Additional for checking and setting skip_hierarchy
  /*  if ($('#member_id').val() != undefined){
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/members/${$('#member_id').val()}/get_skipping_hierarchy`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      dataType: 'json',
      success: function(response){
        for (let data of response){
          let name = ''
          if (data.suffix == null && data.middle_name != null) {
            name = data.first_name + ' ' + data.middle_name + ' ' + data.last_name
          }
          if (data.suffix != null && data.middle_name == null) {
            name = data.first_name + ' ' + data.last_name + ' ' + data.suffix
          }
          if (data.middle_name == null && data.suffix == null){
            name = data.first_name + ' ' + data.last_name
          }
          if (data.middle_name != null && data.suffix != null){
            name = data.first_name + ' ' + data.middle_name + ' ' + data.last_name + ' ' + data.suffix
          }
          let relationship_data = data.relationship
          let gender = data.gender
          let birthdate = data.birthdate
          let reason = data.reason
          let supporting_file = data.supporting_document

          let data_row = `<tr>
          <td>${relationship_data}</td>
          <td>${name}</td>
          <td>${gender}</td>
          <td>${birthdate}</td>
          <td>${reason}</td>
          <td>${supporting_file.name}</td>
          <td class="remove_skip_icon"><i class="trash icon"></i></td>
          </tr>`
          $('#hierarchy_data').append(data_row)

          let relationship = $('select#relationship option:selected').attr('id')
          for (let a=1;a<relationship;a++){
            let val = $('select#relationship').find(`#${a}`).val()
            $('select#relationship').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).addClass('disabled')
          }
        }
      }
    })
    } */

});

onmount('form[id="memberFormContact"]', function() {
  let Inputmask = require('inputmask')
  let im = new Inputmask("\\999-999-9999", {
    "clearIncomplete": false,
  })
  let countryCode = new Inputmask("+9999", {
    placeholder: "",
    prefix: '+',
    allowMinus:false,
    rightAlign: false,
  })
  let areaCode = new Inputmask("numeric", {
    allowMinus:false,
    rightAlign: false,
  })
  let localCode = new Inputmask("numeric", {
    allowMinus:false,
    rightAlign: false,
  })
  let phone = new Inputmask("999-9999", {
    "clearIncomplete": false,
    "removeMaskOnSubmit": true
  })
  const valid_mobile_prefix = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994", "976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  // mobile masks
  countryCode.mask($('.mcc'))
  im.mask($('.mobile'))
  // telephone masks
  countryCode.mask($('.tcc'))
  areaCode.mask($('.tac'))
  phone.mask($('.phone'))
  localCode.mask($('.tlc'))
  // fax masks
  countryCode.mask($('.fcc'))
  areaCode.mask($('.fac'))
  phone.mask($('.phone'))
  localCode.mask($('.flc'))
  /*
  // to clear the errors prompt in MOBILE_PHONE2[country code]
  $('#member_mcc2').on('keyup', function(){
    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });
    $('#mobile2_field').removeClass('error')
    $('#telephone_field').removeClass('error')
    $('#fax_field').removeClass('error')
  })

  // validation for blank country_code and not blank mobile_phone2
  $('#btnSubmit').on('click', function(e){

    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });
    $('#mcc_field').removeClass('error')

    let mcc2 = $('#member_mcc2').val()
    let mm2 = $('#member_mobile2').val()
    if(mm2.length > 0){
       if(mcc2.length == 0){
         $('#mcc_field').addClass('error').append(`<div class="ui basic red pointing prompt label transition visible">Please enter Country Code</div>`)
         e.preventDefault();
       }
    }
  })

  // validation for not blank country_code and blank mobile_phone2
  $('#btnSubmit').on('click', function(e){

    let mcc2 = $('#member_mcc2').val()
    let mm2 = $('#member_mobile2').val()
    if(mcc2.length > 0){
       if(mm2.length == 0){
         $('#mobile2_field').addClass('error').append(`<div class="ui basic red pointing prompt label transition visible">Please enter Mobile no.</div>`)
         e.preventDefault();
       }
    }
  })

  // to clear the errors prompt in TELEPHONE[country code]
  $('#member_tcc').on('keyup', function(){
    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });
    $('#mobile2_field').removeClass('error')
    $('#telephone_field').removeClass('error')
    $('#fax_field').removeClass('error')
  })

  // validation for blank country_code and not blank telephone
  $('#btnSubmit').on('click', function(e){

    let tcc = $('#member_tcc').val()
    let tel = $('#member_telephone').val()
    if(tel.length > 0){
       if(tcc.length == 0){
         $('#tcc_field').addClass('error').append(`<div class="ui basic red pointing prompt label transition visible">Please enter Country Code</div>`)
         e.preventDefault();
       }
    }
  })

  // validation for not blank country_code and blank telephone
  $('#btnSubmit').on('click', function(e){

    let tcc = $('#member_tcc').val()
    let tel = $('#member_telephone').val()
    if(tcc.length > 0){
       if(tel.length == 0){
         $('#telephone_field').addClass('error').append(`<div class="ui basic red pointing prompt label transition visible">Please enter Telephone no.</div>`)
         e.preventDefault();
       }
    }
  })

  // to clear the errors prompt in TELEPHONE[country code]
  $('#member_fcc').on('keyup', function(){
    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });
    $('#mobile2_field').removeClass('error')
    $('#telephone_field').removeClass('error')
    $('#fax_field').removeClass('error')
  })

  // validation for blank country_code and not blank fax
  $('#btnSubmit').on('click', function(e){

    let fcc = $('#member_fcc').val()
    let fax = $('#member_fax').val()
    if(fax.length > 0){
       if(fcc.length == 0){
         $('#fcc_field').addClass('error').append(`<div class="ui basic red pointing prompt label transition visible">Please enter Country Code</div>`)
         e.preventDefault();
       }
    }
  })

  // validation for not blank country_code and blank fax
  $('#btnSubmit').on('click', function(e){

    let fcc = $('#member_fcc').val()
    let fax = $('#member_fax').val()
    if(fcc.length > 0){
       if(fax.length == 0){
         $('#fax_field').addClass('error').append(`<div class="ui basic red pointing prompt label transition visible">Please enter Fax no.</div>`)
         e.preventDefault();
       }
    }
    })
  */

  $.fn.form.settings.rules.mobileChecker = function(param) {
    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmaked_value.length == 10) {
      return true
    } else {
      return false
    }
  }

  $.fn.form.settings.rules.mobilePrefixChecker = function(param) {
    return valid_mobile_prefix.indexOf(param.substring(0, 3)) == -1 ? false : true
  }

  $.fn.form.settings.rules.telephoneChecker = function(param) {
    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmaked_value.length == "7") {
      return true
    } else {
      return false
    }
  }

  $('#memberFormContact')
  .form({
    inline: true,
    fields: {
      email: {
        identifier: 'email',
        optional: true,
        rules: [
          {
            type: 'email',
            prompt: 'Please enter a valid email'
          }
        ]
      },
      email2: {
        identifier: 'email2',
        optional: true,
        rules: [
          {
            type: 'email',
            prompt: 'Please enter a valid email'
          }
        ]
      },
      mobile_country_code: {
        identifier: 'mobile_country_code',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter Country Code'
          }
        ]
      },
      mobile: {
        identifier: 'mobile',
        optional: true,
        rules: [
          {
            type: 'mobileChecker[param]',
            prompt: 'Mobile Phone 1 must be 10 digits'
          },
          {
            type: 'mobilePrefixChecker[param]',
            prompt: 'Invalid Mobile Phone 1 prefix'
          }
        ]
      },
      mobile2: {
        identifier: 'mobile2',
        optional: true,
        rules: [
          {
            type: 'mobileChecker[param]',
            prompt: 'Mobile Phone 2 must be 10 digits'
          },
          {
            type: 'mobilePrefixChecker[param]',
            prompt: 'Invalid Mobile Phone 2 prefix'
          }
        ]
      },
      postal: {
        identifier: 'postal',
        optional: true,
        rules: [
          {
            type: 'exactLength[4]',
            prompt: 'Postal must be 4 digits'
          }
        ]
      },
      telephone: {
        identifier: 'telephone',
        optional: true,
        rules: [
          {
            type: 'telephoneChecker[param]',
            prompt: 'Telephone Number must be 7 digits'
          }
        ]
      },
      fax: {
        identifier: 'fax',
        optional: true,
        rules: [
          {
            type: 'telephoneChecker[param]',
            prompt: 'Fax Number must be 7 digits'
          }
        ]
      }
    }
  })

  $('div[role="hide-map"]').hide();
});

onmount('div[id="memberFormSummary"]', function() {
  $('#enrollBtn').on('click', function(){
    swal({
      title: 'Enrollment Successful',
      type: 'success',
      allowOutsideClick: false,
      confirmButtonText: '<i class="check icon"></i> Ok',
      confirmButtonClass: 'ui button primary',
      buttonsStyling: false
    }).then(function () {
      window.location.href = '/members'
    }).catch(swal.noop)
  })
});

function convert_date_to_local_timezone(datetime) {
  var moment_datetime = moment(datetime);
  var local_datetime = momentTz(moment_datetime, 'Asia/Singapore');
  var transformed_date = moment(local_datetime).format('MMM DD, YYYY');

  return transformed_date;
}

onmount('div[id="memberShow"]', function() {
  let member_id = $('#member_id').val()
  let csrf = $('input[name="_csrf_token"]').val();

  $('#MemberDocumentsModal').modal('attach events', '#documents', 'show');
  let md_datatable = $('#member_docs_table').DataTable({
    "ajax": {
      "url": `/members/${member_id}/document/data`,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "processing": true,
    "serverSide": true,
    "deferRender": true,
    "pageLength": 5,
    "columnDefs": [
      {
        "targets": [ 3 ],
        data: function ( row, type, val, meta ) {
          return convert_date_to_local_timezone(`${row[3]}`);
        }
      }
    ]
  });

  $('#member_docs_table tbody').on('click', 'tr', function(){
    /**
      filename = data[8]          link = data[6]
      loa_no = data[9]          uploaded_from= data[2]
      purpose = data[1]          date_uploaded = data[3]
      let data2 = "https://d2kcgdfzhawsm9.cloudfront.net/uploads/files/7288e585-60ef-4415-ab91-68602f170078/dog.jpg?v=63703715477"
    **/

    let data = md_datatable.row(this).data();
    $('#segment_detail').removeClass('hidden')

    $("#div_filename > b").html(data[8])
    $('#div_download > a').attr("href", data[6])
    $('img.img_class').attr("src", data[6])
    $("#div_loa").html(data[9])
    $("#div_purpose").html(data[1])
    $("#div_uploaded_from").html(data[2])
    $("#div_date_uploaded").html(convert_date_to_local_timezone(data[3]))
  })

  $('#MemberLogsModal').modal('attach events', '#logs', 'show');
  $('p[class="member_log_date"]').each(function(){
    let date = $(this).html();
    $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
  })
  $('div[class="extra text"]').each(function(){
    var $this = $(this);
    var t = $this.text();
    $this.html(t.replace('&lt','<').replace('&gt', '>'));
  })

  $(".box-green").css({
    "float": "right",
    "width": "15px",
    "height": "15px",
    "margin": "5px",
    "border": "1px solid rgba(0, 0, 0, .2)",
    "background": "green"
  });

  $(".box-yellow").css({
    "float": "right",
    "width": "15px",
    "height": "15px",
    "margin": "5px",
    "border": "1px solid rgba(0, 0, 0, .2)",
    "background": "#cccc00"
  });

  $('select[name="member[product_id]"]').on('change', function(){
    $('#get-loa').submit()
  })

  $('#modalProcedure').modal({autofocus: false, observeChanges: true}).modal('attach events', '#addProducts', 'show')

  $('#sortableProducts').sortable({
    appendTo: 'body',
    helper: 'clone',
    stop: function(event, ui){
      let counter = 1
      $('#memberProductsTbl > tbody  > tr').each(function(){
        $(this).children(':first').html(`<b>${counter}</b>`)
        counter++
      })
    }
  });

  $('input[name="draggableState"]').change(function(){
    if ($(this).prop('checked') == true){
      $('#sortableProducts').sortable("enable")
    }
    else{
      $('#sortableProducts').sortable("disable")
    }
  })

  let member_product_tier = []

  $('#productTierForm').on('submit', function(){
    $('#memberProductsTbl > tbody  > tr').each(function(){
      member_product_tier.push($(this).attr('mpID'))
    })
    $('#productTier').val(member_product_tier)
  });

  var valArray = []
  $("input:checkbox").on('change', function () {
    var value = $(this).val()
    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value)
      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('input[name="member[account_product_ids_main]"]').val(valArray)
  })

  let birthdate = $('#birthdate').text()
  let age = Math.floor(moment().diff(birthdate, 'years', true))
  $('#age').html(`${age}`)

  $('.view-product').click(function() {
    let product_id = $(this).attr('productID')
    window.open(`/products/${product_id}/summary`, '_blank')
  })

  $('.delete_product').on('click', function(){
    let m_id = $(this).attr('memberID');
    let mp_id = $(this).attr('memberProductID');
    $('#product_removal_confirmation').modal('show');
    $('#confirmation_m_id').val(m_id);
    $('#confirmation_mp_id').val(mp_id);
  })

  $('#confirmation_cancel_p').click(function(){
    $('#product_removal_confirmation').modal('hide');
  });

  $('#confirmation_submit_p').click(function(){
    let csrf = $('input[name="_csrf_token"]').val();
    let m_id = $('#confirmation_m_id').val();
    let mp_id = $('#confirmation_mp_id').val();
    //$(this).addClass("disabled")
    $.ajax({
      url:`/members/${m_id}/member_product/${mp_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        if(obj.valid == true){
          window.location.href = `/members/${m_id}?tab=product&delete=success`
        } else {
          if(obj.coverage == "ACU"){
            alertify.error('<i class="close icon"></i>ACU Benefit has already been availed.')
          } else {
            alertify.error('<i class="close icon"></i>Member Plan has already been used.')
          }
        }
      },
      error: function(){
        alert('Error deleting plan!')
      }
    });
  });

  // for member comment
  $('.timefromnow').each(function() {
    let value = moment($(this).attr('timestamp')).fromNow()
    $(this).html(value)
  })

  setInterval(function(){
    $('.timefromnow').each(function() {
      let value = moment($(this).attr('timestamp')).fromNow()
      $(this).html(value)
    })
  }, 5000);

  $('a[name="comment_modal"]').on('click', function(){
    $('div[role="add-comment"]').modal('show');
  })

  $('#btnComment').on('click', function(e){
    let csrf = $('input[name="_csrf_token"]').val();
    let member_id = $('#member_id').val()
    let comment = $('#member_comment').val()
    let params = {comment: comment}


    if (comment == '') {

      $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
        $(this).remove();
      });

      $('#comment_text_area').addClass('error').append(`<div class="ui basic red pointing prompt label transition visible">Please enter comment</div>`)
    }
    else{
      $.ajax({
        url:`/members/${member_id}/add_comment`,
        headers: {"X-CSRF-TOKEN": csrf},
        data: {member_params: params},
        type: 'POST',
        success: function(response){
          let obj = JSON.parse(response)

          $('#commentContainer').prepend(`<div class="item">
                          <div class="mt-1 mb-1">${obj.comment}</div>
                          <i class="large github middle aligned icon"></i>
                          <div class="content">
                            <a class="header">${obj.created_by}</a>
                            <div class="description timefromnow" timestamp="${obj.inserted_at}">a few seconds ago</div>
                          </div>
                        </div>`)

          $('#member_comment').val('')
          $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
            $(this).remove();
          });
          $('#comment_text_area').removeClass('error')
          $('#message_count').text("0/250")

        },
        error: function(){
          alert("Erorr adding Batch comment!")
        }
      })
    }

  })

  $('#member_comment').on('keyup', function(){
    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });
    $('#comment_text_area').removeClass('error')

  let max_length = parseInt(250);

    $('#message_count').val(max_length + ' characters')
    let text_length = $(this).val().length;
    let text_remaining = max_length - text_length;
    $('#message_count').html(text_length + "/250")
  })

});

onmount('div[id="memberProducts"]', function() {
  $('#modalProcedure').modal({autofocus: false, observeChanges: true}).modal('attach events', '.add.button', 'show')

  $('#sortableProducts').sortable({
    appendTo: 'body',
    helper: 'clone',
    stop: function(event, ui){
      let counter = 1
      $('#memberProductsTbl > tbody  > tr').each(function(){
        $(this).children(':first').html(`<b>${counter}</b>`)
        counter++
      })
    }
  });

  $('input[name="draggableState"]').change(function(){
    if ($(this).prop('checked') == true){
      $('#sortableProducts').sortable("enable")
    }
    else{
      $('#sortableProducts').sortable("disable")
    }
  })

  let member_product_tier = []

  $('#productTierForm').on('submit', function(){
    $('#memberProductsTbl > tbody  > tr').each(function(){
      member_product_tier.push($(this).attr('mpID'))
    })
    $('#productTier').val(member_product_tier)
  });

  let valArray = []

  $("input:checkbox.selection").on('change', function () {
    var value = $(this).val()
    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value)
      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('input[name="member[account_product_ids_main]"]').val(valArray)
  })



  // FOR CHECK ALL
  $('#checkAllProducts').on('change', function(){
    var table = $('#productsModalTable').DataTable()
    var rows = table.rows({ 'search': 'applied' }).nodes();

    if ($(this).is(':checked')) {
      $('input[type="checkbox"]', rows).each(function() {
        var value = $(this).val()
        var eligible = $(this).attr('eligible')
        if (eligible == "true") {
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
        }
      })

    } else {
      valArray.length = 0
      $('input[type="checkbox"]').each(function() {
        $(this).prop('checked', false)
      })
    }
    $('input[name="member[account_product_ids_main]"]').val(valArray)
  })

  $('.delete_product').on('click', function(){
    let m_id = $(this).attr('memberID');
    let mp_id = $(this).attr('memberProductID');
    $('#product_removal_confirmation').modal('show');
    $('#confirmation_m_id').val(m_id);
    $('#confirmation_mp_id').val(mp_id);
  })

  $('#confirmation_submit_p').click(function(){
    let csrf = $('input[name="_csrf_token"]').val();
    let m_id = $('#confirmation_m_id').val();
    let mp_id = $('#confirmation_mp_id').val();

    $.ajax({
      url:`/members/${m_id}/member_product/${mp_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.href = `/members/${m_id}/setup?step=2&delete=success`
        //location.reload()
      },
      error: function(){
        alert('Error deleting product!')
      }
    })
  })

});

onmount('div[id="memberProductsEdit"]', function() {
  $('#modalProcedure').modal({autofocus: false, observeChanges: true}).modal('attach events', '.add.button', 'show')

  $('#sortableProducts').sortable({
    appendTo: 'body',
    helper: 'clone',
    stop: function(event, ui){
      let counter = 1
      $('#memberProductsTbl > tbody  > tr').each(function(){
        $(this).children(':first').html(`<b>${counter}</b>`)
        counter++
      })
    }
  });

  $('input[name="draggableState"]').change(function(){
    if ($(this).prop('checked') == true){
      $('#sortableProducts').sortable("enable")
    }
    else{
      $('#sortableProducts').sortable("disable")
    }
  })

  let member_product_tier = []

  $('#productTierForm').on('submit', function(){
    $('#memberProductsTbl > tbody  > tr').each(function(){
      member_product_tier.push($(this).attr('mpID'))
    })
    $('#productTier').val(member_product_tier)
  });

  let valArray = []

  $("input:checkbox.selection").on('change', function () {
    var value = $(this).val()
    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value)
      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('input[name="member[account_product_ids_main]"]').val(valArray)
  })



  // FOR CHECK ALL
  $('#checkAllProducts').on('change', function(){
    var table = $('#productsModalTable').DataTable()
    var rows = table.rows({ 'search': 'applied' }).nodes();

    if ($(this).is(':checked')) {
      $('input[type="checkbox"]', rows).each(function() {
        var value = $(this).val()
        var eligible = $(this).attr('eligible')
        if (eligible == "true") {
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
        }
      })

    } else {
      valArray.length = 0
      $('input[type="checkbox"]').each(function() {
        $(this).prop('checked', false)
      })
    }
    $('input[name="member[account_product_ids_main]"]').val(valArray)
  })

  $('.delete_product').on('click', function(){
    let m_id = $(this).attr('memberID');
    let mp_id = $(this).attr('memberProductID');
    $('#product_removal_confirmation').modal('show');
    $('#confirmation_m_id').val(m_id);
    $('#confirmation_mp_id').val(mp_id);
  })

  $('.delete_invalid').on('click', function(){
    $('.ajs-message.ajs-error.ajs-visible').remove()
    alertify.error(`<i class="close icon"></i><p>Plan was already used and this cannot be removed</p>`);
  })

  $('#confirmation_submit_p').click(function(){
    let csrf = $('input[name="_csrf_token"]').val();
    let m_id = $('#confirmation_m_id').val();
    let mp_id = $('#confirmation_mp_id').val();

    $.ajax({
      url:`/members/${m_id}/member_product/${mp_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.href = `/members/${m_id}/edit?tab=products&delete=success`
      },
      error: function(){
        alert('Error deleting product!')
      }
    })
  })

});


onmount('input[id="deleteMemberProductSuccess"]', function() {
  alertify.success(`<i class="close icon"></i><p>Plan successfully removed</p>`)
});

onmount('div[id="editGeneral"]', function() {
  const member_type = $('#memberType').val()
  const account_segment = $('#memberType').attr('account')
  let employee_number_array = []
  let csrf = $('input[name="_csrf_token"]').val()
  let pwd_arr = []
  let senior_arr = []
  let max_expiry_date = $('#maxExpiryDate').val()
  let effectivity_date = $('#effectiveDate').val()

  $('#birthdate').calendar({
    type: 'date',
    startMode: 'year',
    formatter: {
      date: function(date, settings) {
         var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
         ];
         var day = date.getDate();
         var monthIndex = date.getMonth();
         var year = date.getFullYear();

         return monthNames[monthIndex] + ' ' + day + ', ' + year
      }
    }
  })

  $('#dateHired').calendar({
    type: 'date',
    startMode: 'year',
    formatter: {
      date: function(date, settings) {
         var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
         ];
         var day = date.getDate();
         var monthIndex = date.getMonth();
         var year = date.getFullYear();

         return monthNames[monthIndex] + ' ' + day + ', ' + year
      }
    }
  })

  $('#regularizationDate').calendar({
    type: 'date',
    startMode: 'year',
    startCalendar: $('#dateHired'),
    formatter: {
      date: function(date, settings) {
         var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
         ];
         var day = date.getDate();
         var monthIndex = date.getMonth();
         var year = date.getFullYear();

         return monthNames[monthIndex] + ' ' + day + ', ' + year
      }
    }
  })

  $('#expiryDate').calendar({
    type: 'date',
    minDate: new Date(effectivity_date),
    maxDate: new Date(max_expiry_date),
    formatter: {
      date: function(date, settings) {
               var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
               ];
               var day = date.getDate();
               var monthIndex = date.getMonth();
               var year = date.getFullYear();

               return monthNames[monthIndex] + ' ' + day + ', ' + year
      }
    }
  })

  $('#member_effectivity_date').each(function(){
    let val = $(this).val()
    $(this).val(moment(val).format("MMM DD, YYYY"));
  })

  $('#birthdate').calendar({
    type: 'date',
    formatter: {
      date: function(date, settings) {
        var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
        ];
        var day = date.getDate();
        var monthIndex = date.getMonth();
        var year = date.getFullYear();

        return monthNames[monthIndex] + ' ' + day + ', ' + year;
      }
    }
  })

  $('#regularizationDate').calendar({
    type: 'date',
    formatter: {
      date: function(date, settings) {
        var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
        ];
        var day = date.getDate();
        var monthIndex = date.getMonth();
        var year = date.getFullYear();

        return monthNames[monthIndex] + ' ' + day + ', ' + year;
      }
    }
  })

  $('#dateHired').calendar({
    type: 'date',
    formatter: {
      date: function(date, settings) {
        var monthNames = [
          "Jan", "Feb", "Mar",
          "Apr", "May", "Jun", "Jul",
          "Aug", "Sep", "Oct",
          "Nov", "Dec"
        ];
        var day = date.getDate();
        var monthIndex = date.getMonth();
        var year = date.getFullYear();

        return monthNames[monthIndex] + ' ' + day + ', ' + year;
      }
    }
  })

  $('.employee_nos').each(function(){
    employee_number_array.push($(this).val())
  })

  $('input[type=radio][name="member[pwd]"]').on('change', function() {
    if ($('input[name="member[pwd]"]:checked').val() == "true"){
      $('input[name="member[pwd_id]"]').prop('disabled', false)
      $('div[id="pwd_upload"]').removeClass("disabled")
    }
    else {
      $('input[name="member[pwd_id]"]').prop('disabled', true)
      $('div[id="pwd_upload"]').addClass("disabled")
    }
  })

  $('input[type=radio][name="member[senior]"]').on('change', function() {
    if ($('input[name="member[senior]"]:checked').val() == "true"){
      $('input[name="member[senior_id]"]').prop('disabled', false)
      $('div[id="senior_upload"]').removeClass("disabled")
    }
    else {
      $('input[name="member[senior_id]"]').prop('disabled', true)
      $('div[id="senior_upload"]').addClass("disabled")
    }
  })

  $.fn.form.settings.rules.checkSeniorID = function(param) {
    // let copy = $('input[id="member_senior_id_copy"]').val();
    // let position = $.inArray(copy, senior_arr[0]);
    // if ( ~position ) senior_arr[0].splice(position, 1);

    if(senior_arr[0].includes(param)){
      return false
    } else{
      return true
    }
  }

  const checkPwdId = () => {
    $.ajax({
      url:`/members/pwd_id/all`,
        headers: {"x-csrf-token": csrf},
        type: 'get',
        datatype: 'json',
        success: function(response){
          let obj = JSON.parse(response)
          pwd_arr.push(obj)
        }
    });
  }

  checkPwdId()

  $.fn.form.settings.rules.checkEmpNumber = function(param) {
    return employee_number_array.indexOf(param) == -1 ? true : false;
  }

  $.fn.form.settings.rules.checkPWDID = function(param) {
    // let copy = $('input[id="member_pwd_id_copy"]').val();
    // let position = $.inArray(copy, pwd_arr[0]);
    // if ( ~position ) pwd_arr[0].splice(position, 1);

    if(pwd_arr[0].includes(param)){
      return false
    } else{
      return true
    }
  }

  const checkSeniorId = () => {
    $.ajax({
      url:`/members/senior_id/all`,
        headers: {"x-csrf-token": csrf},
        type: 'get',
        datatype: 'json',
        success: function(response){
          let obj = JSON.parse(response)
          senior_arr.push(obj)
        }
    });
  }
  checkSeniorId()

  $.fn.form.settings.rules.customLength = function(param) {
    if (param == '') {
      return true
    } else {
      if(param.length == 12) {
        return true
      } else{
        return false
      }
    }
  }

  $.fn.form.settings.rules.checkIfSenior = function(param) {
    let birthdate = $('input[id="member_birthdate"]').val()
    birthdate = birthdate.split("-", 1)
    let today_date = new Date()
    let total_age = today_date.getFullYear() - parseInt(birthdate[0])
    if (birthdate == ""){
      return false
    }
    else if (total_age < 60){
      return false
    }
    else{
      return true
    }
  }

  if (account_segment == "Corporate"){
    if (member_type == "Principal") {
      disableDependentFields()
      enableEmployeeFields()
      validateCorporatePrincipal()
    } else if (member_type == "Guradian") {
      disableEmployeeFields()
      disableDependentFields()
      validateCorporateGuardian()
    } else if (member_type == "Dependent") {
      disableEmployeeFields()
      enableDependentFields()
      validateCorporateDependent()
    }
  } else {
    if (member_type == "Principal") {
      disableDependentFields()
      validateOthersPrincipal()
      $('input[name="member[employee_no]"]').prop('disabled', false)
    } else if (member_type == "Guradian") {
      disableEmployeeFields()
      disableDependentFields()
      validateOthersGuardian()
    } else if (member_type == "Dependent") {
      disableEmployeeFields()
      enableDependentFields()
      validateOthersDependent()
      $('input[name="member[employee_no]"]').prop('disabled', true)
    }
  }

  $('#submitGeneral').on('click', function(){
      $('input[name="member[effectivity_date]"]').prop('disabled', false)
    $('#memberForm').submit()
  })

  $('input[name="member[philhealth_type]"]').change(function() {
    if ($(this).val() == "Not Covered") {
      $('input[name="member[philhealth]"]').closest('.field').removeClass('error')
      $('input[name="member[philhealth]"]').closest('.field').find('.prompt').remove()
      $('input[name="member[philhealth]"]').prop('disabled', true)
      $('input[name="member[philhealth]"]').val('')
    } else {
      $('input[name="member[philhealth]"]').prop('disabled', false)
    }
  })

  if ($('input[name="member[philhealth_type]"]:checked').val() == "Not Covered") {
    $('input[name="member[philhealth]"]').prop('disabled', true)
    $('input[name="member[philhealth]"]').val('')
  } else {
    $('input[name="member[philhealth]"]').prop('disabled', false)
  }

  function validateCorporatePrincipal() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Employee No'
            },
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Employee number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        }
      }
    })
  }

  function validateCorporateDependent() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        principal_id: {
          identifier: 'principal_id',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Principal ID'
          }]
        },
        relationship: {
          identifier: 'relationship',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Relationship'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Employee number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        },
        principal_product_id: {
          identifier: 'principal_product_id',
          rules: [{
            type: 'empty',
            prompt: "Please select Principal's Plan"
          }]
        }
      },
      onSuccess: function(event, fields) {
        /*
        let checker = validate_hierarchy_skipping()
        if (checker == false) {
          event.preventDefault()
          }
          */
      }
    })
  }

  function validateCorporateGuardian() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Employee No'
            },
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Employee number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        }
      }
    })
  }

  function validateOthersPrincipal() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Principal Number'
            },
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Employee number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        },
        onSuccess: function(event, fields) {
          /*
          let checker = validate_hierarchy_skipping()
          if (checker == false) {
            event.preventDefault()
            }
            */
        }
      }
    })
  }

  function validateOthersDependent() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        principal_id: {
          identifier: 'principal_id',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Principal ID'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Principal number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        relationship: {
          identifier: 'relationship',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Relationship'
          }]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        },
        principal_product_id: {
          identifier: 'principal_product_id',
          rules: [{
            type: 'empty',
            prompt: "Please select Principal's Plan"
          }]
        }
      }
    })
  }

  function validateOthersGuardian() {
    $('#memberForm')
    .form({
      inline: true,
      fields: {
        account_code: {
          identifier: 'account_code',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Account Code'
          }]
        },
        effectivity_date: {
          identifier: 'effectivity_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Effectivity Date'
          }]
        },
        expiry_date: {
          identifier: 'expiry_date',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Expiry Date'
          }]
        },
        first_name: {
          identifier: 'first_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter First Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'First Name cannot exceed 150 characters'
            }
          ]
        },
        last_name: {
          identifier: 'last_name',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Last Name'
            },
            {
              type: 'maxLength[150]',
              prompt: 'Last Name cannot exceed 150 characters'
            }
          ]
        },
        middle_name: {
          identifier: 'middle_name',
          rules: [
            {
              type: 'maxLength[150]',
              prompt: 'Middle Name cannot exceed 150 characters'
            }
          ]
        },
        suffix: {
          identifier: 'suffix',
          rules: [
            {
              type: 'maxLength[10]',
              prompt: 'Suffix cannot exceed 10 characters'
            }
          ]
        },
        tin: {
          identifier: 'tin',
          rules: [
            {
              type   : 'customLength[param]',
              prompt : 'TIN must be 12 digits'
            }
          ]
        },
        birthdate: {
          identifier: 'birthdate',
          rules: [{
            type: 'empty',
            prompt: 'Please enter Birthdate'
          }]
        },
        employee_no: {
          identifier: 'employee_no',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter Principal No'
            },
            {
              type: 'checkEmpNumber[param]',
              prompt: 'Principal number is already used within the selected account'
            }
          ]
        },
        senior_id: {
          identifier: 'member_senior_id',
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter Senior Citizen ID'
            // },
            {
              type: 'checkIfSenior[param]',
              prompt: 'Member must be 60 years old and above.'
            },
            {
              type: 'checkSeniorID[param]',
              prompt: 'Senior ID already exists'
            }
          ]
        },
        pwd_id: {
          identifier: 'pwd_id',
          rules: [
            {
              type: 'empty',
              prompt: 'Please enter PWD ID'
            },
            {
              type: 'checkPWDID[param]',
              prompt: 'PWD ID already exists'
            }
          ]
        },
        philhealth: {
          identifier: 'philhealth',
          optional: true,
          rules: [
            // {
            //   type: 'empty',
            //   prompt: 'Please enter PhilHealth Number'
            // },
            {
              type   : 'customLength[param]',
              prompt : 'PhilHealth Number must be 12 digits'
            }
          ]
        },
        civil_status: {
          identifier: 'civil_status',
          rules: [{
            type: 'empty',
            prompt: 'Please select Civil Status'
          }]
        }
      }
    })
  }

  function disableCivilStatus() {
    $('#member_civil_status').prop('disabled', true)
    $('#member_civil_status').closest('div.dropdown').addClass('disabled')
  }

  function enableCivilStatus() {
    $('#member_civil_status').dropdown('restore defaults')
    $('#member_civil_status').prop('disabled', false)
    $('#member_civil_status').closest('div.dropdown').removeClass('disabled')
  }

  function enableDependentFields(){
    $('#principalID').prop('disabled', false)
    $('#principalID').closest('div.dropdown').removeClass('disabled')
    $('#relationship').prop('disabled', false)
    $('#relationship').closest('div.dropdown').removeClass('disabled')
    $('#effectivityDate').removeClass('disabled')
    $('#principalProductID').closest('div.dropdown').removeClass('disabled')
    $('input[name="member[effectivity_date]"]').prop('disabled', false)
   }

  function disableDependentFields(){
    $('#principalID').prop('disabled', true)
    $('#principalID').closest('div.dropdown').addClass('disabled')
    $('#relationship').prop('disabled', true)
    $('#relationship').closest('div.dropdown').addClass('disabled')
    $('#effectivityDate').prop('disabled', true)
    $('#principalProductID').closest('div.dropdown').addClass('disabled')
    $('input[name="member[effectivity_date]"]').prop('disabled', true)
  }

  function disableEmployeeFields(){
    $('input[name="member[employee_no]"]').prop('disabled', true)
    $('input[name="member[date_hired]"]').prop('disabled', true)
    $('input[name="member[regularization_date]"').prop('disabled', true)
    $('input[name="member[is_regular]"]').prop('disabled', true)
  }

  function enableEmployeeFields(){
    $('input[name="member[employee_no]"]').prop('disabled', false)
    $('input[name="member[date_hired]"]').prop('disabled', false)
    $('input[name="member[regularization_date]"').prop('disabled', false)
    $('input[name="member[is_regular]"]').prop('disabled', false)
  }

});

onmount('div[id="membersIndex"]', function() {
  let table = $('table[role="datatable"]').DataTable({
    dom:
      "<'ui grid'"+
        "<'row'"+
      "<'eight wide column'l>"+
      "<'right aligned eight wide column'f>"+
      ">"+
      "<'row dt-table'"+
      "<'sixteen wide column'tr>"+
      ">"+
      "<'row'"+
      "<'seven wide column'i>"+
      "<'right aligned nine wide column'p>"+
      ">"+
      ">",
    renderer: 'semanticUI',
    pagingType: "full_numbers",
    scrollX: true,
    language: {
      emptyTable:     "No Records Found!",
      zeroRecords:    "No Records Found!",
      search:         "Search",
      paginate: {
        first: "<i class='angle single left icon'></i> First",
        previous: "<i class='angle double left icon'></i> Previous",
        next: "Next <i class='angle double right icon'></i>",
        last: "Last <i class='angle single right icon'></i>"
      }
    }
  });
  $('input[type="search"]').unbind('on').on('keyup', function(){
    const csrf2 = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/members/load/datatable`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      data: {params: { "search" : $(this).val().trim(), "offset" : 0}},
      dataType: 'json',
      success: function(response){
        table.clear()
        let dataSet = []
        for (let i=0;i<response.member.length;i++){
          table.row.add( [
            show_page(response.member[i]),
            response.member[i].name,
            response.member[i].card_no,
            response.member[i].account,
            response.member[i].status
          ] ).draw();
        }
      }
    })
  })
  $('.dataTables_length').find('.ui.dropdown').on('change', function(){
    if ($(this).find('.text').text() == 100){
      let info = table.page.info();
      if (info.pages - info.page == 1){
        let search = $('.dataTables_filter input').val();
        const csrf2 = $('input[name="_csrf_token"]').val();
        $.ajax({
          url:`/members/load/datatable`,
          headers: {"X-CSRF-TOKEN": csrf2},
          type: 'get',
          data: {params: { "search" : search.trim(), "offset" : info.recordsTotal}},
          dataType: 'json',
          success: function(response){
            let dataSet = []
            for (let i=0;i<response.member.length;i++){
              table.row.add( [
                show_page(response.member[i]),
                response.member[i].name,
                response.member[i].card_no,
                response.member[i].account,
                response.member[i].status
              ] ).draw(false);
            }
          }
        })
      }
    }
  })
  let info
  table.on('page', function () {
    info = table.page.info();
    if (info.pages - info.page == 1){
      let search = $('.dataTables_filter input').val();
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/members/load/datatable`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {params: { "search" : search.trim(), "offset" : info.recordsTotal}},
        dataType: 'json',
        success: function(response){
          let dataSet = []
          for (let i=0;i<response.member.length;i++){
            table.row.add( [
              show_page(response.member[i]),
              response.member[i].name,
              response.member[i].card_no,
              response.member[i].account,
              response.member[i].status
            ] ).draw(false);
          }
        }
      })
    }
  });
  function show_page(response){
    if(response.step == 5 || response.step == 4){
      return `<a href="/members/${response.id}">${response.id}</a>`
    }else{
      return `<a href="/members/${response.id}/setup?step=${response.step}">${response.id} Draft</a>`
    }
  }
 });


$('head').append(
  `<style type="text/css">
    @font-face {
      font-family: 'icomoon';
      src: url("../../fonts/icomoon.eot?w2rsck");
      src: url("../../fonts/icomoon.eot?w2rsck#iefix") format("embedded-opentype"), url("../../fonts/icomoon.ttf?w2rsck") format("truetype"), url("../../fonts/icomoon.woff?w2rsck") format("woff"), url("../../fonts/icomoon.svg?w2rsck#icomoon") format("svg");
      font-weight: normal;
      font-style: normal;
    }
  </style>`
)
