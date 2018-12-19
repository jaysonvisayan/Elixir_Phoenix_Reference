
// Authorization Emergency
// onmount('div[id="emergency"]', function() {
//     $('select#authorization_practitioner_id').select2({
//       placeholder: "Select practitioner",
//       theme: "bootstrap",
//       minimumInputLength: 3
//     })

//     $('select#diagnosis').select2({
//       placeholder: "Select Diagnosis",
//       theme: "bootstrap",
//       minimumInputLength: 3
//     })

//     $('select#procedures').select2({
//       placeholder: "Select Payor Procedure",
//       theme: "bootstrap",
//       minimumInputLength: 3
//     })

//     $('select#authorization_ruv_id').select2({
//       placeholder: "Select RUV",
//       theme: "bootstrap",
//       minimumInputLength: 3
//     })
// })

// Authorization OP Consult
onmount('div[name="formValidateStep4Consult"]', function(){

    // $('select#authorization_practitioner_id').select2({
    //   placeholder: "Select practitioner",
    //   theme: "bootstrap",
    //   minimumInputLength: 3
    // })

    $('select#authorization_diagnosis_id').select2({
      placeholder: "Select Diagnosis",
      theme: "bootstrap",
      minimumInputLength: 3
    })

    $('select#authorization_practitioner_id').val("juan").trigger("change")
})

// Authorization OP Laboratory
// onmount('div[name="formValidateStep4Laboratory"]', function() {
//     $('select#authorization_practitioner_id').select2({
//       placeholder: "Select practitioner",
//       theme: "bootstrap",
//       minimumInputLength: 3
//     })

//     $('select#diagnosis').select2({
//       placeholder: "Select Diagnosis",
//       theme: "bootstrap",
//       minimumInputLength: 3
//     })

//     $('select#procedures').select2({
//       placeholder: "Select Payor Procedure",
//       theme: "bootstrap",
//       minimumInputLength: 3
//     })

//     $('select#authorization_ruv_id').select2({
//       placeholder: "Select RUV",
//       theme: "bootstrap",
//       minimumInputLength: 3
//     })
// })

// Payor Procedure
onmount('div[id="form_procedures"]', function() {
  $('select#payor_procedure_procedure_id').select2({
    placeholder: "Select Procedure",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

// Case Rate
onmount('div[id="form_case_rate"]', function() {
  $('select#case_rate_diagnosis_id').select2({
    placeholder: "Select ICD",
    theme: "bootstrap",
    minimumInputLength: 3
  })
  $('select#case_rate_ruv_id').select2({
    placeholder: "Select RUV",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

// Facility Room
onmount('form[id="addroom"]', function() {
  $('select#code_type_code').select2({
    placeholder: "Select Room",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

// Facility Payor Procedure
onmount('form[id="addProcedure"]', function() {
  $('select#code_type').select2({
    placeholder: "Select Payor CPT",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

// Facility RUV
onmount('form[id="addruv"]', function() {
  $('select#code_description').select2({
    placeholder: "Select RUV",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

// Package Facility
onmount('div[id="add_package_facility_form"]', function() {
  $('select#package_facility_id').select2({
    placeholder: "Select Facility",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

// Facility Practitioner
onmount('div[name="pf-formValidate"]', function() {
  $('select#practitioner_facility_facility_id').select2({
    placeholder: "Select Facility",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

// Member
onmount('form[id="memberForm"]', function() {
  $('select#member_account_code').select2({
    placeholder: "Select Account Code",
    theme: "bootstrap",
    minimumInputLength: 3
  })

  $('select#principalID').select2({
    placeholder: "Select Principal ID - Name",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

// Practitioner Financial
onmount('div[name="formValidatePractitionerFinancial"]', function() {
  $('select#bank').select2({
    placeholder: "Select Bank",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})


//ACU Schedule

onmount('div[id="acu_schedule_form"]', function(){
  $('select#acu_schedule_account_code').select2({
    placeholder: "Select Account Code/Name",
    theme: "bootstrap",
    minimumInputLength: 3
  })

  $('select#acu_schedule_cluster_id').select2({
    placeholder: "Select Cluster Code/Name",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

onmount('div[id="acu_schedule_edit_form"]', function(){
  $('select#acu_schedule_account_code').select2({
    placeholder: "Select Account Code/Name",
    theme: "bootstrap",
    minimumInputLength: 3
  })

  $('select#acu_schedule_cluster_id').select2({
    placeholder: "Select Cluster Code/Name",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

onmount('div[id="member_account_reports"]', function(){
  $('select#account_group_code_name').select2({
    placeholder: "Select Account Code/Name",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

onmount('div[id="new_acu_schedule_form"]', function(){
  $('select#acu_schedule_account_code').select2({
    placeholder: "Select Account Code/Name",
    theme: "bootstrap",
    minimumInputLength: 3
  })

  $('select#acu_schedule_cluster_id').select2({
    placeholder: "Select Cluster Code/Name",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})

onmount('div[id="new_acu_schedule_edit_form"]', function(){
  $('select#acu_schedule_account_code').select2({
    placeholder: "Select Account Code/Name",
    theme: "bootstrap",
    minimumInputLength: 3
  })

  $('select#acu_schedule_cluster_id').select2({
    placeholder: "Select Cluster Code/Name",
    theme: "bootstrap",
    minimumInputLength: 3
  })
})
