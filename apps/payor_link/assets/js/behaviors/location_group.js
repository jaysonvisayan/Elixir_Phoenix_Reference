onmount('div[id="location_group_step1"]', function(){

  console.log("test_LG");

  $.fn.form.settings.rules.checkAphanumeric = function(param) {

  }

  const csrf = $('input[name="_csrf_token"]').val();
  const lg_name = $('input[name="location_group[name]"]').val()

  $.ajax({
    url: `/get_all_location_group_name`,
    headers: {
      "X-CSRF-TOKEN": csrf
    },
    type: 'get',
    success: function(response) {
      const data = JSON.parse(response)
      const array = $.map(data, function(value, index) {
        return [value.name]
      });
console.log(array)
      if (lg_name != undefined) {
        array.splice($.inArray(lg_name, array), 1)
      }

      $.fn.form.settings.rules.checkLocationGroupName = function(param) {
        return array.indexOf(param) == -1 ? true : false
      }


  $('input[name="location_group[name]"]').on('keypress', function(evt){
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

    $('input[name="location_group[description]"]').on('keypress', function(evt){
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

      $('#step1_form')
      .form({
        on: 'blur',
        inline : true,
        fields: {
          'location_group[name]': {
            identifier: 'location_group[name]',
            rules: [
              {
                type: 'empty',
                prompt: 'Please enter name'
              },
              {
                type: 'regExp',
                value: '^[-:a-zA-Z0-9() ]+$',
                prompt: 'Please enter alphanumeric character'
              },
              {
                type: 'checkLocationGroupName[param]',
                prompt: 'Location Group Name is already taken!'
              }
            ]
          },
          'location_group[description]': {
            identifier: 'location_group[description]',
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
          }
        }
      })
    }
  })
})

onmount('div[id="location_group_step2"]', function(){
 $('.islands').change(function(){
    let val = $(this).val()
    if($(this).prop('checked') == true){
      $(`.${val}`).addClass('checked')
      $(`.${val}`).find('input').prop('checked', true)
    } else {
      $(`.${val}`).removeClass('checked')
      $(`.${val}`).find('input').prop('checked', false)
    }
  })
})

onmount('button[id="deleteLG"]', function () {

  const csrf = $('input[name="_csrf_token"]').val()

  $('#deleteLG').on('click', function() {
    let lg_ID = $(this).attr('lg_ID')
    swal({
      title: 'Delete Location Group?',
      text: "Deleting this Location Group will permanently remove it from the system.",
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes',
      cancelButtonText: '<i class="remove icon"></i> No',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false
    }).then(function() {

      $.ajax({
        url:`/location_groups/${lg_ID}`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'DELETE',
        success: function(response){
          window.location.href = '/location_groups'
        },
        error: function(){
          alert("Erorr deleting location group!")
        }
      })

    }).catch(swal.noop)
  })

})
