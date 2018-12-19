onmount('form[class="ui form"]', function(){
  let mode_of_payment = $('select[name="account[mode_of_payment]"]').val()
  disable_payment()
  disable_bank(mode_of_payment)

  $('.hide').hide()

  /*$('input[name="account[funding_arrangement]"]').on('change', function(){
    disable_payment()
  }); */

  $('select[name="account[mode_of_payment]"]').on('change', function(){
    disable_bank($(this).val())
  });

  $('#account_group_address_country').prop("disabled", true)
  $('#account_group_address_country_2').prop("disabled", true)

})

onmount('div[role="financial"]', function(){
  let val = $('select[name="account[mode_of_payment]"]').val()
  let step = $('select[name="account[mode_of_payment]"]').attr("step")

  on_edit_check_payee()
  //on_edit_hide()
  on_edit_disable(val, step)

  on_key_up_check()
  on_edit_check_payee()
  on_edit_check_bank_name()
  on_edit_check_bank_no()

  populate_approval_fields()

  if(val == "Check"){
    is_check_approval_check()
  }else{
    is_check_approval_debit()
  }

  //if ($('#account_payee_name').val() == $('#account_approval_payee_name').val()){
  //$('#approval_check_box').prop("checked", true)
  //}

  //$('div[role="funding_arrangement"]').css("cursor", "pointer")

  /*$('div[role="funding_arrangement"]').on('click', function(){
    $(this).find('input[type="radio"]').prop("checked", true)
    on_edit_hide()
  }); */

  // Mode of payment interchanging value
  $('div[mode="1"]').on('mouseenter', function(){
    $('select[mode="1"]').on('change', function(){
      let val = $(this).val()
      on_edit_disable($(this).val(), $(this).attr("step"))
      on_key_up_check()
      on_edit_check_payee()
      on_edit_check_bank_name()
      on_edit_check_bank_no()
      populate_approval_fields()

      $('div[mode="2"]').find('.ui.dropdown').dropdown();
      $('div[mode="1"]').find('.ui.dropdown').dropdown();
      $('select[mode="2"]').val(val).change()
    });
      $('div[mode="1"]').find('.ui.dropdown').dropdown();
      $('div[mode="2"]').find('.ui.dropdown').dropdown();
  });

  // Mode of payment interchanging value
  $('div[mode="2"]').on('mouseenter', function(){
    $('select[mode="2"]').on('change', function(){
      let val = $(this).val()
      on_edit_disable($(this).val(), $(this).attr("step"))
      on_key_up_check()
      on_edit_check_payee()
      on_edit_check_bank_name()
      on_edit_check_bank_no()
      populate_approval_fields()

      $('div[mode="1"]').find('.ui.dropdown').dropdown();
      $('div[mode="2"]').find('.ui.dropdown').dropdown();
      $('select[mode="1"]').val(val).change()
    })
      $('div[mode="1"]').find('.ui.dropdown').dropdown();
      $('div[mode="2"]').find('.ui.dropdown').dropdown();
  })

  $('.accordion > .title').on('click', function(){
    let val = $('select[name="account[mode_of_payment]"]').val()
    let step = $('select[name="account[mode_of_payment]"]').attr("step")
    on_edit_disable(val, step)
    on_edit_hide()
    on_key_up_check()
    on_edit_check_payee()
    on_edit_check_bank_name()
    on_edit_check_bank_no()
  })
})


// On Edit of Account
const populate_approval_fields = () => {

  // If checked, Populate the payee field in special approval
  $('input[role="check"]').on('change', function(){
    is_check_approval_check()
  })

  // If checked, Populate the Bank name, number and branch fields in approval
  $('input[role="debit"]').on('change', function(){
    is_check_approval_debit()
  })

}

const is_check_approval_check = () => {
  if($('input[role="check"]').is(':checked')){
    const payee = $('input[name="account[payee_name]"]').val()
    $('input[name="account[approval_payee_name]"]').val(payee)
    $('input[type="text"][name="account[approval_payee_name]"]').prop("disabled", true)
    $('div[mode="2"]').find('div[tabindex="0"]').addClass("disabled")
  }else{
    //$('input[name="account[approval_payee_name]"]').val("")
    $('input[name="account[approval_payee_name]"]').prop("disabled", false)
    $('input[type="hidden"][name="account[approval_payee_name]"]').prop("disabled", true)
    $('div[mode="2"]').find('div[tabindex="0"]').removeClass("disabled")
  }
}

const is_check_approval_debit = () => {
  if($('input[role="debit"]').is(':checked')){
    const acc_name = $('input[name="account[account_name]"]').val()
    const acc_no = $('input[name="account[account_no]"]').val()
    const branch = $('input[name="account[branch]"]').val()

    $('input[name="account[approval_account_name]"]').val(acc_name)
    $('input[name="account[approval_account_no]"]').val(acc_no)
    $('input[name="account[approval_branch]"]').val(branch)
    $('input[type="text"][name="account[approval_account_name]"]').prop("disabled", true)
    $('input[type="number"][name="account[approval_account_no]"]').prop("disabled", true)
    $('input[type="text"][name="account[approval_branch]"]').prop("disabled", true)
    $('input[type="hidden"][name="account[approval_account_name]"]').prop("disabled", false)
    $('input[type="hidden"][name="account[approval_account_no]"]').prop("disabled", false)
    $('input[type="hidden"][name="account[approval_branch]"]').prop("disabled", false)
    $('input[id="approval_payee_name"]').prop("disabled", true)
    $('div[mode="2"]').find('div[tabindex="0"]').addClass("disabled")
  }else{
    //$('input[name="account[approval_account_name]"]').val("")
    //$('input[name="account[approval_account_no]"]').val("")
    //$('input[name="account[approval_branch]"]').val("")
    $('input[name="account[approval_account_name]"]').prop("disabled", false)
    $('input[name="account[approval_account_no]"]').prop("disabled", false)
    $('input[name="account[approval_branch]"]').prop("disabled", false)
    $('input[type="hidden"][name="account[approval_account_name]"]').prop("disabled", true)
    $('input[type="hidden"][name="account[approval_account_no]"]').prop("disabled", true)
    $('input[type="hidden"][name="account[approval_branch]"]').prop("disabled", true)
    $('div[mode="2"]').find('div[tabindex="0"]').removeClass("disabled")
  }
}

const on_key_up_check = () => {
  $('#account_payee_name').on('keyup', function(){
    on_edit_check_payee()
  });

  $('#account_account_name').on('keyup', function(){
    on_edit_check_bank_name()
  });

  $('#account_account_no').on('keyup', function(){
    on_edit_check_bank_no()
  });
}

//check if payee is empty, as a result special approval checkbox will be disabled
const on_edit_check_payee = () => {
  if($('input[name="account[payee_name]"]').val() == ""){
    $('input[role="check"').prop("disabled", true)
    $('input[role="check"').prop("checked", false)
  }else{
    $('input[role="check"').prop("disabled", false)
  }
}

//check if bank name is empty, as a result special approval checkbox will be disabled
const on_edit_check_bank_name = () => {
  if($('input[name="account[account_no]"]').val() == "" || $('input[name="account[account_name]"]') == ""){
    $('input[role="debit"').prop("disabled", true)
    $('input[role="debit"').prop("checked", false)
  }else{
    $('input[role="debit"').prop("disabled", false)
  }
}

//check if bank no is empty, as a result special approval checkbox will be disabled
const on_edit_check_bank_no = () => {
  if($('input[name="account[account_no]"]').val() == "" || $('input[name="account[account_name]"]') == ""){
    $('input[role="debit"').prop("disabled", true)
    $('input[role="debit"').prop("checked", false)
  }else{
    $('input[role="debit"').prop("disabled", false)
  }
}

const on_edit_disable = (value, step) => {
  $('div[for="Check"]').hide();
  $('div[for="Check"]').find('input').prop("disabled", true);

  if( value == "Electronic Debit"){
    $('div[for="Check"]').hide();
    $('div[for="Check"]').find('input').prop("disabled", true);

    $('div[for="Electronic_debit"]').show();
    $('div[for="Electronic_debit"]').find('input').prop("disabled", false);
    $('div[for="Electronic_debit"]').find('#approval_payment').find('div').removeClass("disabled");

    //$('input[name="account[approval_account_name]"]').val("")
    //$('input[name="account[approval_account_no]"]').val("")

    //$('input[name="account[approval_is_check]"]').prop("disabled", true)
    //$('input[name="account[approval_is_check]"]').prop("checked", false)
    $('input[name="account[approval_is_check]"]').removeAttr("role")
    $('input[name="account[approval_is_check]"]').attr("role", "debit")
    $('div[mode="2"]').find('div[tabindex="0"]').removeClass("disabled")

  }else if( value == "Check"){
    $('div[for="Check"]').show();
    $('div[for="Check"]').find('input').prop("disabled", false);

    $('div[for="Electronic_debit"]').hide();
    $('div[for="Electronic_debit"]').find('select').prop("disabled", true);
    $('div[for="Electronic_debit"]').find('input').prop("disabled", true);

    // $('input[name="account[approval_payee_name]"]').val("")

    //$('input[name="account[approval_is_check]"]').prop("disabled", true)
    //$('input[name="account[approval_is_check]"]').prop("checked", false)
    $('input[name="account[approval_is_check]"]').removeAttr("role")
    $('input[name="account[approval_is_check]"]').attr("role", "check")
    $('div[mode="2"]').find('div[tabindex="0"]').removeClass("disabled")
  }
}

const on_edit_hide = () => {
  if($('input[value="Full Risk"]').is(':checked')){
    $('div[for="ASO"]').hide();
    $('div[for="ASO"]').find('input').prop("disabled", true);
  }else{
    $('div[for="ASO"]').show();
    $('div[for="ASO"]').find('input').prop("disabled", false);
  }
}

// In Creation of Account
const disable_payment = () => {
  if($('input[value="Full Risk"]').is(':checked')){
    $('input[name="account[threshold]"]').prop("disabled", true);
    $('input[name="account[revolving_fund]"]').prop("disabled", true);
  }else{
    $('input[name="account[threshold]"]').prop("disabled", false);
    $('input[name="account[revolving_fund]"]').prop("disabled", false);
  }
}

const disable_bank = (value) => {
  if(value == "Electronic Debit"){
    $('input[name="account[account_name]"]').prop("disabled", false);
    $('input[name="account[branch]"]').prop("disabled", false);
    $('input[name="account[account_no]"]').prop("disabled", false);
    $('input[name="account[authority_debit]"]').prop("disabled", false);
    $('input[name="account[file]"]').prop("disabled", false);
    $('input[name="account[approval_payee_name]"]').prop("disabled", true);
    $('input[id="approval_payee_name"]').attr("disabled", true);
  }else{
    $('input[name="account[approval_payee_name]"]').prop("disabled", false);
    $('input[id="approval_payee_name"]').removeAttr("disabled");
    $('input[name="account[account_name]"]').prop("disabled", true);
    $('input[name="account[branch]"]').prop("disabled", true);
    $('input[name="account[account_no]"]').prop("disabled", true);
    $('input[name="account[authority_debit]"]').prop("disabled", true);
    $('input[name="account[file]"]').prop("disabled", true);
  }
}
