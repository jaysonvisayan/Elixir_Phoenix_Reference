onmount('div[id="benefit_miscellaneous"]', function () {

  $('#modalAddMiscellaneous').modal({autofocus: false}).modal('attach events', '.add_miscellaneous', 'show');

  var valArray = []

  $("input:checkbox.selection").on('change', function () {
    var value = $(this).val();

    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }

    $('input[name="benefit[miscellaneous_ids_main]"]').val(valArray)

  })

  // FOR CHECK ALL
  $('#checkAllMiscellaneous').on('change', function(){
    var table = $('#miscellaneous_table_modal').DataTable()
    var rows = table.rows({ 'search': 'applied' }).nodes();

    if ($(this).is(':checked')) {
      $('input[type="checkbox"]', rows).each(function() {
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
      })

    } else {
      valArray.length = 0
      $('input[type="checkbox"]', rows).each(function() {
        $(this).prop('checked', false)
      })
    }
    $('input[name="benefit[miscellaneous_ids_main]"]').val(valArray)
  })

})
