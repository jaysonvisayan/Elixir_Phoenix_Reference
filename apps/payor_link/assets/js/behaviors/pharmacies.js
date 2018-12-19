onmount('#pharmacies_new', function(){

 const csrf = $('input[name="_csrf_token"]').val();
 const drug_code = $('input[name="pharmacy[drug_code]"]').val()

 $.ajax({
        url: '/get_all_pharmacy_code',
        headers:{
                "X-CSRF-TOKEN": csrf
        },
        type: 'get',
        success: function(response){

        let drug_codes = response.drug_codes;
        $.fn.form.settings.rules.checkPharmacyCode = function(param) {
         return drug_codes.indexOf(param) == -1 ? true : false
        }

       $('input[id="drug_code"]').on('keyup', function(evt){
       $(this).val(function (_, val) {
             return val.toUpperCase();
        });
       });

       $('input[id="drug_code"]').on('keypress', function(evt){
        let theEvent = evt || window.event;
        let key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode( key );
        let regex = /[``~<>^'{}[\]\\;.,'"/?!@#$%&*_+=]/;

        if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
          return false;
        }else{
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      })

      $('input[name="pharmacy[generic_name]"]').on('keypress', function(evt){
        let theEvent = evt || window.event;
        let key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode( key );
        let regex = /[``~<>^'{}[\]\\;.,'"/?!@#$%&*_+=]/;

        if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
          return false;
        }else{
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      })

       $('input[name="pharmacy[brand]"]').on('keypress', function(evt){
        let theEvent = evt || window.event;
        let key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode( key );
        let regex = /[``~<>^'{}[\]\\;.,'"/?!@#$%&*_+=]/;

        if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
          return false;
        }else{
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      })



 var im = new Inputmask("decimal", {

    min: 0,
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('.amount_fld'));

 $('#pharmacy').form({
          on: 'blur',
          inline: true,
          fields: {
            'pharmacy[drug_code]': {
              identifier: 'pharmacy[drug_code]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Code is required'
                },
                {
                  type: 'checkPharmacyCode[param]',
                  prompt: 'Drug code is already exist'
                }
              ]
            },
            'pharmacy[generic_name]': {
              identifier: 'pharmacy[generic_name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Generic Name is required'
                }
              ]
            },
            'pharmacy[brand]': {
              identifier: 'pharmacy[brand]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Brand is required'
                }
              ]
            },
            'pharmacy[strength]': {
              identifier: 'pharmacy[strength]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Strength is required'
                }
              ]
            },
            'pharmacy[maximum_price]': {
              identifier: 'pharmacy[maximum_price]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Maximum Price is required'
                }
              ]
            },
            'pharmacy[form]': {
              identifier: 'pharmacy[form]',
              rules: [
                {
                  type: 'empty',
                  prompt: ' Form is required'
                }
              ]
            }
          }
  });


        }
 })



});

onmount('#pharmacy-index', function(){
  $('.show-pharmacy-details').on('click', function(){
    $('div[role="show-details"]').modal("show")
    let row = $(this).closest(".pharmacy_row")
    let code = $(this).text()
    let p_id = $(this).attr('pharmacyId')
    let name = row.find('td[role="name"]').text()
    let brand = row.find('td[role="brand"]').text()
    let strength = row.find('td[role="strength"]').text()
    let form = row.find('td[role="form"]').text()
    let price = row.find('td[role="price"]').text()

    $('#drug_code').text(code)
    $('#generic_name').text(name)
    $('#brand').text(brand)
    $('#strength').text(strength)
    $('#form').text(form)
    $('#maximum_price').text(price)
    $('#edit_link').attr("href", `/pharmacies/${p_id}/edit`)
    $('#ph_id').val(p_id)
  })
 var im = new Inputmask("decimal", {
    min: 0,
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
  });
  im.mask($('.amount_fld'));

});

onmount('#pharmacies_update', function(){

 $('input[id="drug_code"]').on('keyup', function(evt){
    $(this).val(function (_, val) {
      return val.toUpperCase();
    });
  });

   $('input[id="drug_code"]').on('keypress', function(evt){
        let theEvent = evt || window.event;
        let key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode( key );
        let regex = /[``~<>^'{}[\]\\;.,'"/?!@#$%&*_+=]/;

        if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
          return false;
        }else{
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      })

      $('input[name="pharmacy[generic_name]"]').on('keypress', function(evt){
        let theEvent = evt || window.event;
        let key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode( key );
        let regex = /[``~<>^'{}[\]\\;.,'"/?!@#$%&*_+=]/;

        if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
          return false;
        }else{
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      })

       $('input[name="pharmacy[brand]"]').on('keypress', function(evt){
        let theEvent = evt || window.event;
        let key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode( key );
        let regex = /[``~<>^'{}[\]\\;.,'"/?!@#$%&*_+=]/;

        if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
          return false;
        }else{
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      })

 var im = new Inputmask("decimal", {

    min: 0,
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('.amount_fld'));

  $('#pharmacy_edit').form({
          on: 'blur',
          inline: true,
          fields: {
            'pharmacy[drug_code]': {
              identifier: 'pharmacy[drug_code]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Code is required'
                }
              ]
            },
            'pharmacy[generic_name]': {
              identifier: 'pharmacy[generic_name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Generic Name is required'
                }
              ]
            },
            'pharmacy[brand]': {
              identifier: 'pharmacy[brand]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Brand is required'
                }
              ]
            },
            'pharmacy[strength]': {
              identifier: 'pharmacy[strength]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Strength is required'
                }
              ]
            },
            'pharmacy[maximum_price]': {
              identifier: 'pharmacy[maximum_price]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Maximum Price is required'
                }
              ]
            },
            'pharmacy[form]': {
              identifier: 'pharmacy[form]',
              rules: [
                {
                  type: 'empty',
                  prompt: ' Form is required'
                }
              ]
            }
          }
  });
});

onmount('a[id="delete_pharmacy"]', function ()
{
  $('#delete_pharmacy').on('click', function() {

    let pharmacyId = $('#ph_id').val()
    let drugCode = $('#drug_code').text()
    let genName = $('#generic_name').text()
    let brand = $('#brand').text()
    let strength = $('#strength').text()
    let form = $('#form').text()
    let maximum = $('#maximum_price').text()

    swal({
      title: 'Remove Medicine?',
     html: "<br><div class='content'><div class='ui two column centered grid'>" +
                    "<div class='three column centered row'>" +
                    "<div class='column'>" +
                    "<b>Drug Code</b></div>" +
                    "<div class='column'>" + drugCode + "</div>" + "</div>" +
                    "<div class='three column centered row'>" +
                    "<div class='column'>" +
                    "<b>Generic Name</b></div>" +
                    "<div class='column'>" + genName + "</div>" + "</div>" +
                    "<div class='three column centered row'>" +
                    "<div class='column'>" +
                     "<b>Brand</b></div>" +
                    "<div class='column'>" + brand + "</div>" + "</div>" +
                    "<div class='three column centered row'>" +
                    "<div class='column'>" +
                    "<b>Strength</b></div>" +
                    "<div class='column'>" + strength + "</div>" + "</div>" +
                    "<div class='three column centered row'>" +
                    "<div class='column'>" +
                    "<b>Form</b></div>" +
                    "<div class='column'>" + form + "</div>" + "</div>" +
                    "<div class='three column centered row'>" +
                    "<div class='column'>" +
                    "<b>Maximum Price</b></div>" +
                    "<div class='column'>" + maximum + "</div>" + "</div></div></div><br><br>",
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Remove Medicine',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Medicine',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      showCloseButton: true,
      allowOutsideClick: false
    }).then(function() {

    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/pharmacies/${pharmacyId}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'DELETE',
      success: function(response){
      alertify.success('<i class="close icon"></i>Succesfully deleted!')
        window.location.href = '/pharmacies'
      },
      error: function(){
        alert("Error deleting medicine!")
      }
    })

    }).catch(swal.noop)
  })

})


