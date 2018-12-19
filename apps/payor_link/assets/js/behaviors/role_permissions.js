onmount('div[id="role_permissions"]', function () {
  var valArray = [];

    $('tr').find('input[name="role[permission_id][]"]').each(function () {
      var value = $(this).val();

      if(this.checked) {
        valArray.push(value);
        valArray = valArray.filter(onlyUnique)
      } else {
        var index = valArray.indexOf(value);

        if (index >= 0) {
          valArray.splice( index, 1)
        }
        valArray = valArray.filter(onlyUnique)
      }
      console.log(valArray);
      $('input[name="role[permissions]"]').val(valArray);
  });

  function onlyUnique(value, index, self) {
    return self.indexOf(value) === index;
  }

  $('tbody').on('mouseenter', function () {
    $("input:checkbox").on('change', function () {
      var value = $(this).val();

      if(this.checked) {
        valArray.push(value);
        valArray = valArray.filter(onlyUnique)
      } else {
        var index = valArray.indexOf(value);

        if (index >= 0) {
          valArray.splice( index, 1)
        }
        valArray = valArray.filter(onlyUnique)
      }
      console.log(valArray);
      $('input[name="role[permissions]"]').val(valArray);
    });
  });

  function onlyUnique(value, index, self) {
    return self.indexOf(value) === index;
  }

  $('tr').find('input[type="radio"]').each(function(){
    $(this).on('change', function(){
      if($(this).is(':checked')){
        let value = $(this).attr("id")
        if(value == "Manage Authorizations") {
          $('#modal_approval_limit').modal('show')
        }
        else{
          $('#modal_show_approval_limit').attr("hidden", true)
          $('#modal_approval_limit').attr('amount', "")
          $('#approval_limit').val("")
          $('#approval_limit_val').val("")
        }
      }
    })
  })

  $('#modal_show_approval_limit').on('click', function(){
    $('#modal_approval_limit').modal('show')
  })

  if($('#modal_approval_limit').attr('amount') == ""){
    $('#modal_show_approval_limit').attr("hidden", true)
  }
  else{
    $('#modal_show_approval_limit').attr("hidden", false)
  }

  var im = new Inputmask("numeric", {
    allowMinus:false,
    min: 0,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false
  });
  im.mask($('#approval_limit'))

  $('#modal_approval_limit').modal({
    closable : false,
    onShow : function(){
    let approvalLimitAmount = $('#modal_approval_limit').attr('amount')
      $('div[class="ui basic red pointing prompt label transition visible"]').remove()
      im.mask($('#approval_limit'))
      $('#approval_limit').val(approvalLimitAmount)
    },
    onApprove : function(){
      let unmasked_value = $('#approval_limit').val().replace(/,/g, '')
      if($('#approval_limit').val() == "" || unmasked_value <= 0){
        $('p[role="append"]').remove()
        $('div[role="approval_limit_validate"]').removeClass('error')
        $('div[role="approval_limit_validate"]').addClass('error')
        $('div[role="approval_limit_validate"]').append(`<p role="append"></p>`)
        $('p[role="append"]').append(`<div class="ui basic red pointing prompt label transition visible">Please enter approval limit</div>`)
        return false;
      }
      else if(unmasked_value > 2000000){
        $('p[role="append"]').remove()
        $('div[role="approval_limit_validate"]').removeClass('error')
        $('div[role="approval_limit_validate"]').addClass('error')
        $('div[role="approval_limit_validate"]').append(`<p role="append"></p>`)
        $('p[role="append"]').append(`<div class="ui basic red pointing prompt label transition visible">Approval Limit Amount is up to Php 2,000,000.00 only</div>`)
        return false;
      }
      else{
        $('#modal_show_approval_limit').attr("hidden", false)
        var input = document.getElementById('approval_limit');
        var unmasked = input.inputmask.unmaskedvalue()
        input.inputmask.remove()
        $('#approval_limit').val(unmasked)
        $('#approval_limit_val').val(unmasked)
        $('#modal_approval_limit').attr('amount', unmasked)
        alertify.success('<i class="close icon"></i>Approval limit successfully saved.')
      }
    },
    onDeny : function(){
      if($('#approval_limit').val() == ""){
        $('#authorizations_permissions').prop('checked', 'checked')
      }
    }
  })
})
