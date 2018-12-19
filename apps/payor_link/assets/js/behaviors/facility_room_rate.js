onmount('div[id="room_rate_index"]', function(){
  $('.ui.deny.button').on('click',function(){

$('#room_rate').modal('hide');
    $('#room_rate_edit').modal('hide');
  })
  $('#add_room').on('click', function(){
    $('.field').removeClass('error')
    $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()

$('#code_type_code').val(null).trigger('change');
    $('#hierarchy').val('')
    $('#ruv_rate').val('')
    $('#facility_room_rate_facility_room_type').val('')
    $('#facility_room_number').val('')
    $('#facility_room_rate').val('')
    $('#room_rate').modal('show', function(){

let selected_code_type = $('#code_type_code').find( 'option:selected' ).text();
      let arr = selected_code_type.split('/');
      let code = arr[0]
      const facility_id = $('#code_type_code').attr('facilityid');
      if (facility_id != "" && code != ""){

const csrf = $('input[name="_csrf_token"]').val();
        $.ajax({

url:`/facilities/room_rate/${facility_id}/${code}`,
          headers: {"X-CSRF-TOKEN": csrf},
          type: 'get',
          success: function(response){

const data =  JSON.parse(response)
            $('#hierarchy').removeAttr("disabled");
            $('#hierarchy').val(data[0].hierarchy)
            $('#room_id').val(data[0].id)
            $('#ruv_rate').val(data[0].ruv_rate)
            $('#hierarchy').attr("disabled", "disabled");


          },
        })
      }
  //get all room number in facility room rate table
  let room_number = []
  $('.table.facility_room').find('.room_rate').each(function(){
    room_number.push($(this).attr('facility_room_number'))
  })
//identify if the record save in the table is already exist
  $.fn.form.settings.rules.checkRoomNumber = function(param) {
    return room_number.indexOf(param) == -1 ? true : false;
  }



$.fn.form.settings.rules.checkRNFormat = function(param) {
    // return regExp[/[a-zA-Z0-9_()-.]*$/]


}

$('#addroom')

.form({

on: blur,
        inline: true,
        fields: {
          'facility_room_rate[room_id]': {
            identifier: 'facility_room_rate[room_id]',
            rules: [
              {
                type: 'empty',

prompt: 'Code/Type is required'

}

]
          },

          'facility_room_rate[hierarchy]': {
            identifier: 'facility_room_rate[hierarchy]',
            rules: [
              {
                type: 'empty',

prompt: 'Hierarchy is required'

}

]

},

         'facility_room_rate[facility_ruv_rate]': {
            identifier: 'facility_room_rate[facility_ruv_rate]',
            rules: [
              {
                type: 'empty',

prompt: 'RUV Rate is required'

}

]
          },


          'facility_room_rate[facility_room_type]': {
            identifier: 'facility_room_rate[facility_room_type]',
            rules: [
              {
                type: 'empty',

prompt: 'Facility Room Type is required'

}

]

},


        'facility_room_rate[facility_room_number]': {

identifier: 'facility_room_rate[facility_room_number]',
            rules: [

{
                type: 'empty',

prompt: 'Room Number is required'
              },
              {

type: 'checkRoomNumber[param]',
                prompt: 'Room Number is already exists'
              },
              {

type: 'regExp[/^[a-zA-Z0-9_().]+(-[a-zA-Z0-9_().]+)*$/]',
                prompt: 'Room Number is invalid'
              }


            ]

          },


          'facility_room_rate[facility_room_rate]': {
            identifier: 'facility_room_rate[facility_room_rate]',
            rules: [
              {
                type: 'empty',

prompt: 'Facility Room Rate is required'

}

]

}


        },

      onSuccess: function(event, fields) {
        $('#room_rate').modal('hide')
      }

      });
    });
  });

  let room_rate_id
  let code_type
  let added_code_type

  $('.room_rate').on('click', function(){


room_rate_id = $(this).attr('roomrateid');
    let facility_id = $(this).attr('facilityid');
    let room_id = $(this).attr('room_id');
    let code = $(this).attr('codeid');
    let type = $(this).attr('room_type');
    let hierarchy = $(this).attr('room_hierarchy');
    let room_rate = $(this).attr('facility_room_rate');
    let room_type = $(this).attr('facility_room_type');
    let room_number = $(this).attr('facility_room_number');
    let ruv_rate = $(this).attr('facility_ruv_rate');

    $("#edit_code_type option[value="+added_code_type +"]").remove();
    $('#room_rate_edit').modal({autofocus: false}).modal('show', function(){

      code_type = code + '/' + type
      $('#edit_hierarchy').val(hierarchy)
      $('#edit_hierarchy').attr("disabled", "disabled")
      $('#edit_facility_room_rate').val(room_rate)
      $('#edit_facility_room_type').val(room_type)
      $('#edit_facility_room_number').val(room_number)
      $('#edit_ruv_rate').val(ruv_rate)
      $('#room_rate_id').val(room_rate_id)
      $('#facility_id').val(facility_id)
          let found = 0
      $('select#edit_code_type').find('option').each(function() {
        if ($(this).text() == code_type){
          found = 1

}
      });
      if(found == 0)
        {

added_code_type = room_id
          $('#edit_code_type').append($('<option value="'+room_id+'">'+code_type+'</option>'));
          $('#edit_code_type').dropdown('set text', code_type)
          $('#edit_code_type').dropdown('set value', room_id)

}

    })

  let list_room_number = []
  $('.table.facility_room').find('.room_rate').each(function(){
    list_room_number.push($(this).attr('facility_room_number'))
  })
  let index = list_room_number.indexOf(room_number);
  if (index !== -1) list_room_number.splice(index, 1);

  $.fn.form.settings.rules.checkRoomNumber = function(param) {
    return list_room_number.indexOf(param) == -1 ? true : false;
  }

  // $.fn.form.settings.rules.checkRNFormat = function(param) {
  // alert(111)
  // alert(regExp[/[a-zA-Z0-9_()-.]*$/])
  //   // return regExp[/[a-zA-Z0-9_()-.]*$/]

  // }

 $('#room_rate_edit')
      .form({
        on: blur,
        inline: true,
        fields: {
          'facility_room_rate[hierarchy]': {
            identifier: 'facility_room_rate[hierarchy]',
            rules: [
              {
                type: 'empty',
                prompt: 'Hierarchy is required'
              }
            ]
          },

        'facility_room_rate[facility_ruv_rate]': {
            identifier: 'facility_room_rate[facility_ruv_rate]',
            rules: [
              {
                type: 'empty',
                prompt: 'RUV Rate is required'
              }
            ]
          },


          'facility_room_rate[facility_room_type]': {
            identifier: 'facility_room_rate[facility_room_type]',
            rules: [
              {
                type: 'empty',
                prompt: 'Facility Room Type is required'
              }
            ]
          },

       'facility_room_rate[facility_room_number]': {
            identifier: 'facility_room_rate[facility_room_number]',
            rules: [
              {
                type: 'empty',
                prompt: 'Room Number is required'
              },
              {
                type: 'checkRoomNumber[param]',
                prompt: 'Room Number is already exists'
              },
              {
                type: 'regExp[/^[a-zA-Z0-9_().]+(-[a-zA-Z0-9_().]+)*$/]',
                prompt: 'Room Number is invalid'
              }
             ]
          },

          'facility_room_rate[facility_room_rate]': {
            identifier: 'facility_room_rate[facility_room_rate]',
            rules: [
              {
                type: 'empty',
                prompt: 'Facility Room Rate is required'
              }
            ]
          }


        }

      });




  });

    $('#edit_code_type').on('change', function() {
      let selected_code_type = $('#edit_code_type').find( 'option:selected' ).text();
      let arr = selected_code_type.split('/');
      let code = arr[0]
      if (code != '')
        {
      const facility_id = $('#edit_code_type').attr('facilityid');
      const csrf = $('input[name="_csrf_token"]').val();
      $.ajax({
      url:`/facilities/room_rate/${facility_id}/${code}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        const data =  JSON.parse(response)
          $('#edit_hierarchy').removeAttr("disabled")
          $('#edit_hierarchy').val(data[0].hierarchy)
          $('#edit_code_type').removeAttr("disabled")
          $('#edit_code_type').val(data[0].id)
          $('#edit_hierarchy').attr("disabled", "disabled")
          $('#edit_code_type').attr("disabled", "disabled")
          $('#edit_ruv_rate').val(data[0].ruv_rate)
          $('#edit_room_number').val(data[0].facility_room_number);

      }
      })
        }

    });

    $('#code_type_code').on('change',function() {
      let selected_code_type = $('#code_type_code').find( 'option:selected' ).text();
      let arr = selected_code_type.split('/');
      let code = arr[0]
      if (code != '')
        {
      const facility_id = $('#code_type_code').attr('facilityid');
      const csrf = $('input[name="_csrf_token"]').val();
      $.ajax({
      url:`/facilities/room_rate/${facility_id}/${code}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        const data =  JSON.parse(response)
          $('#hierarchy').removeAttr("disabled");
          $('#hierarchy').val(data[0].hierarchy)
          $('#ruv_rate').val(data[0].ruv_rate);
          $('#room_id').val(data[0].id)
          $('#hierarchy').attr("disabled", "disabled");

      },
      })
       }
    });

});



onmount('div[id="room_rate"]', function(){

var im = new Inputmask("decimal", {

    min: 0,
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () {
      if($('#facility_room_rate').val() != ''){
        self.value('');

}

}

});

im.mask($('.amount_fld'));


$('#room_rate').submit(() => {
          var input = document.getElementById('ruv_rate');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()

$('#ruv_rate').val(unmasked)
   var input = document.getElementById('facility_room_rate');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()

$('#facility_room_rate').val(unmasked)
})

var im = new Inputmask("integer", {

    min: 0,
    allowMinus:false,
     autoGroup: true,
    rightAlign: false,

oncleared: function () { self.Value(''); }
  });

im.mask($('.amount_fld_numeric'));

});
onmount('div[id="room_rate_edit"]', function(){

$('#room_rate').submit(() => {
          var input = document.getElementById('ruv_rate');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()

$('#ruv_rate').val(unmasked)
   var input = document.getElementById('facility_room_rate');
          var unmasked = input.inputmask.unmaskedvalue()
          input.inputmask.remove()
          $('#facility_room_rate').val(unmasked)

})


var im = new Inputmask("integer", {

    min: 0,
    allowMinus:false,
     autoGroup: true,
    rightAlign: false,

oncleared: function () { self.Value(''); }
  });

im.mask($('.amount_fld_numeric'));

 $('#btnRemove').on('click', function(){

swal({

title: 'Remove Room Rates Details',
      text: "Are you sure you want to remove this Room Rate?",
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="send icon"></i> Remove',
      cancelButtonText: '<i class="remove icon"></i> Cancel',
      confirmButtonClass: 'ui blue button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false
    }).then(function () {
    let confirm_room_rate_id = $('#room_rate_id').val();
    let confirm_facility_id = $('#facility_id').val();
      window.location.replace(`/facilities/${confirm_facility_id}/facility_room_rate/${confirm_room_rate_id}/delete`);
    })
 })

 $('#submit_room_rate').click(function(){
 })

})

