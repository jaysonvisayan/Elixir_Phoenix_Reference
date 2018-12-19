onmount('div[id="miscellaneous_step1"]', function(){

  const csrf = $('input[name="_csrf_token"]').val();
  const misc_code = $('input[name="miscellaneous[code]"]').val()

  $.ajax({
    url: `/get_all_miscellaneous_code`,
    headers: {
      "X-CSRF-TOKEN": csrf
    },
    type: 'get',
    success: function(response) {
      const data = JSON.parse(response)
      const array = $.map(data, function(value, index) {
        return [value.code]
      });
      console.log(array)
      if (misc_code != undefined) {
        array.splice($.inArray(misc_code, array), 0)
      }

      $.fn.form.settings.rules.checkMiscellaneousCode = function(param) {
        return array.indexOf(param) == -1 ? true : false
      }

      $('input[name="miscellaneous[code]"]').on('keypress', function(evt){
        let theEvent = evt || window.event;
        let key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode( key );
        let regex = /[``~<>^'{}[\]\\;,.'"/?!@#$%&*_+=]/;

        if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
          return false;
        }else{
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      })


      $('input[name="miscellaneous[description]"]').on('keypress', function(evt){
        let theEvent = evt || window.event;
        let key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode( key );
      let regex = /[``~<>^'{}[\]\\;.'"/?!@#$%&*_+=]/;

        if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
          return false;
        }else{
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      })

  var im = new Inputmask("decimal", {
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('.amount_fld'));

      $('#step1_form')
      .form({
        on: 'blur',
        inline : true,
        fields: {
          'miscellaneous[code]': {
            identifier: 'miscellaneous[code]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter code'
              },
              {
                type: 'regExp',
                value: '^[-:a-zA-Z0-9() ]+$',
                prompt: 'Please enter alphanumeric character'
              },
              {
                type: 'checkMiscellaneousCode[param]',
                prompt: 'Item code is already taken!'
              }
            ]
          },
          'miscellaneous[description]': {
            identifier: 'miscellaneous[description]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter description'
              },
              {
                type: 'regExp',
                value: '^[-,:a-zA-Z0-9() ]+$',
                prompt: 'Please enter alphanumeric character'
              }
            ]
          },
          'miscellaneous[price]': {
            identifier: 'miscellaneous[price]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter price'
              },
             ]
          }
        }
      })

    }
  })

})

onmount('div[id="miscellaneous_index"]', function() {
 var im = new Inputmask("decimal", {
         allowMinus:false,
         radixPoint: ".",
         groupSeparator: ",",
         digits: 2,
         autoGroup: true,
         rightAlign: false,
         oncleared: function () { self.Value(''); }
        });
         im.mask($('.amount_fld'));

})

onmount('div[id="edit_miscellaneous_modal"]', function() {
   $(this).modal({
            closable: false,

        })
        .modal('attach events', '.edit_miscellaneous', 'show')

     $(".edit_miscellaneous").click(function() {
        let miscellaneous_id = $(this).attr('mid')
        let miscellaneous_code =$(this).attr('mcode')
        let miscellaneous_description =  $(this).attr('mdescription')
        let miscellaneous_price = $(this).attr('mprice')
        let priced = $(this).closest('td').closest('tr').find('.price').find('.amount_fld').html()
console.log(priced)
        $('#misc_id').val(miscellaneous_id)
        $('#code').text(miscellaneous_code)
        $('#description').text(miscellaneous_description)
        $('#price').text(priced)
        $('#edit_button').attr('href', 'miscellaneous/'+ miscellaneous_id +'/edit/')
  })
})

onmount('div[id="miscellaneous_step1_edit"]', function() {

  var im = new Inputmask("decimal", {
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('.amount_fld'));
})

onmount('a[id="delete_miscellaneous"]', function ()
{
  $('#delete_miscellaneous').on('click', function() {

    let miscId = $('#misc_id').val()
    let code = $('#code').text()
    let description = $('#description').text()
    let price = $('#price').text()

     swal({
      title: 'Remove Item?',
     html: "<br><div class='content'><div class='ui two column centered grid'>" +
                    "<div class='three column centered row'>" +
                    "<div class='column'>" +
                    "<b>Item Code</b></div>" +
                    "<div class='column'>" + code + "</div>" + "</div>" +
                    "<div class='three column centered row'>" +
                    "<div class='column'>" +
                    "<b>Description</b></div>" +
                    "<div class='column'>" + description + "</div>" + "</div>" +
                    "<div class='three column centered row'>" +
                    "<div class='column'>" +
                    "<b>Maximum Price</b></div>" +
                    "<div class='column'>Php. " + price + "</div>" + "</div></div></div><br><br>",
        type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Remove Item',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Item',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      showCloseButton: true,
      allowOutsideClick: false
    }).then(function() {


    let csrf = $('input[name="_csrf_token"]').val();
    $.ajax({
      url:`/miscellaneous/${miscId}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'DELETE',
      success: function(response){
      alertify.success('<i class="close icon"></i>Succesfully deleted!')
        window.location.href = '/miscellaneous'
      },
      error: function(){
        alert("Error deleting miscellaneous!")
      }
    })

    }).catch(swal.noop)
  })

})

onmount('div[id="edit_miscellaneous_step1"]', function(){

      $('input[name="miscellaneous[code]"]').on('keypress', function(evt){
        let theEvent = evt || window.event;
        let key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode( key );
        let regex = /[``~<>^'{}[\]\\;,.'"/?!@#$%&*_+=]/;

        if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
          return false;
        }else{
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      })

      $('input[name="miscellaneous[description]"]').on('keypress', function(evt){
        let theEvent = evt || window.event;
        let key = theEvent.keyCode || theEvent.which;
        key = String.fromCharCode( key );
      let regex = /[``~<>^'{}[\]\\;.'"/?!@#$%&*_+=]/;

        if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key)){
          return false;
        }else{
          $(this).on('focusout', function(evt){
            $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
          })
        }
      })

  var im = new Inputmask("decimal", {
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('.amount_fld'));

      $('#step1_form')
      .form({
        on: 'blur',
        inline : true,
        fields: {
          'miscellaneous[code]': {
            identifier: 'miscellaneous[code]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter code'
              },
              {
                type: 'regExp',
                value: '^[-:a-zA-Z0-9() ]+$',
                prompt: 'Please enter alphanumeric character'
              },
                      ]
          },
          'miscellaneous[description]': {
            identifier: 'miscellaneous[description]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter description'
              },
              {
                type: 'regExp',
                value: '^[-,:a-zA-Z0-9() ]+$',
                prompt: 'Please enter alphanumeric character'
              }
            ]
          },
          'miscellaneous[price]': {
            identifier: 'miscellaneous[price]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter price'
              },
             ]
          }
        }
      })
})

