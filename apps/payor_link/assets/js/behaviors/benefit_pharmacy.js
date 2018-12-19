onmount('div[id="benefit_pharmacies"]', function () {

  $('#modalAddPharmacy').modal({autofocus: false}).modal('attach events', '.add_pharmacy', 'show');

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

    $('input[name="benefit[pharmacy_ids_main]"]').val(valArray)

  })

  // FOR CHECK ALL
  $('#checkAllPharmacy').on('change', function(){
    var table = $('#pharmacy_table_modal').DataTable()
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
    $('input[name="benefit[pharmacy_ids_main]"]').val(valArray)
  })

})
