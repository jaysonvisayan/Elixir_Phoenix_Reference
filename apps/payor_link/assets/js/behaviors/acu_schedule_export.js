onmount('#export_btn', function(){
  const csrf = $('input[name="_csrf_token"]').val();
  let user_ids = []
  let files = []


  $('.valid_timezone').each(function(){
    let val = $(this).text()
    $(this).text(moment(val).format("MMMM DD, YYYY hh:mm A"));
  })

Array.prototype.delayedForEach = function(callback, timeout, thisArg, done){
    var i = 0,
        l = this.length,
        self = this;

    var caller = function() {
        callback.call(thisArg || self, self[i], i, self);
        if(++i < l) {
            setTimeout(caller, timeout);
        } else if(done) {
            setTimeout(done, timeout);
        }
    };

    caller();
};


  $('#acu_schedule_table').find('tbody').find('tr').find('input[type="checkbox"]').on('change', function(){
      let value = $(this).val()
      let check = $(this).attr("checked")
      let created_date = $(this).closest('td').closest('tr').find('.valid_timezone').text()
      value = `{"id": "${value}", "datetime": "${created_date}"}`
      if($(this).is(":checked")){
        user_ids.push(value)
      } else {
        let index = user_ids.indexOf(value);
        if (index >= 0) {
           user_ids.splice( index, 1)
        }
      }
    })



  $('#export_btn').on('click', function(){
    if (user_ids.length){
            user_ids.delayedForEach(function(value){
              window.location.assign(`/acu_schedules/export/${value}`)
            }, 2000, null, function() {
              // delete_xlsx()
            })
          }
    else{
         swal({
      title: 'Please select batch first',
      type: 'error',
      allowOutsideClick: false,
      confirmButtonText: '<i class="check icon"></i> Ok',
      confirmButtonClass: 'ui button primary',
      buttonsStyling: false
    }).then(function () {
    }).catch(swal.noop)
    }
  })

 // FOR CHECK ALL
  $('#checkAllacu').on('change', function(){
    var table = $('#acu_schedule_table').DataTable()
    var rows = table.rows({ 'search': 'applied' }).nodes();

    if ($(this).is(':checked')) {
      user_ids = []
      $('input[type="checkbox"]', rows).each(function() {
      let created_date = $(this).closest('td').closest('tr').find('.valid_timezone').text()
      var value = $(this).val()
      value = `{"id": "${value}", "datetime": "${created_date}"}`
        if (this.checked) {
          user_ids.push(value)
        } else {
          var index = user_ids.indexOf(value);

          if (index >= 0) {
            user_ids.splice(index, 1)
          }
          user_ids.push(value)
        }
        $(this).prop('checked', true)
      })

    }
 else {
      user_ids.length = 0
      $('input[id="acu_sched_ids"]').each(function() {
        $(this).prop('checked', false)
      })
    }
  })

})
