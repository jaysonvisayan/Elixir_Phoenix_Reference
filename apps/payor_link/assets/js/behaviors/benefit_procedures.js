onmount('div[id="benefit_procedures"]', function () {
  $('#modalAddProcedure').modal({autofocus: false, observeChanges: true}).modal('attach events', '.add.button', 'show')

  var valArray = []

  $('body').on('change', '.selection', function () {
    var value = $(this).val()

    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }

    $('input[name="benefit[procedure_ids_main]"]').val(valArray)

  })

  // FOR CHECK ALL
  $('body').on('change', '#checkAllProcedures', function(){
    var table = $('#procedure_table_modal').DataTable()
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
      $('input[name="benefit[procedure_ids][]"]').each(function() {
        $(this).prop('checked', false)
      })
    }
    console.log('input[type="checkbox"]', rows)
    $('input[name="benefit[procedure_ids_main]"]').val(valArray)
  })

})

onmount('div[id="benefit_ruv"]', function () {
  $('#modalAddRUV').modal({autofocus: false, observeChanges: true}).modal('attach events', '.add.button', 'show')

  var valArray = []

  $("input:checkbox.selection").on('change', function () {
    var value = $(this).val()

    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }

    $('input[name="benefit[ruv_ids_main]"]').val(valArray)

  })

  // FOR CHECK ALL
  $('#checkAllRuvs').on('change', function(){
    var table = $('#ruv_table_modal').DataTable()
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
      $('input[name="benefit[ruv_ids][]"]').each(function() {
        $(this).prop('checked', false)
      })
    }
    console.log('input[type="checkbox"]', rows)
    $('input[name="benefit[ruv_ids_main]"]').val(valArray)
  })

})

onmount('div[id="benefit_package"]', function () {
  $('#modalAddPackage').modal({autofocus: false, observeChanges: true}).modal('attach events', '.add.button', 'show')
  $('#modalAddACUProcedure').modal({autofocus: false, observeChanges: true}).modal('attach events', '#acu', 'show')
  var valArray = []

  $("input:checkbox.selection").on('change', function () {
    var value = $(this).val()

    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }

    $('input[name="benefit[package_ids_main]"]').val(valArray)

  })

  // FOR CHECK ALL
  $('#checkAllPackages').on('change', function(){
    var table = $('#package_table_modal').DataTable()
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
      $('input[name="benefit[package_ids][]"]').each(function() {
        $(this).prop('checked', false)
      })
    }
    console.log('input[type="checkbox"]', rows)
    $('input[name="benefit[package_ids_main]"]').val(valArray)
  })

})


onmount('div[id="benefit_diagnosis"]', function () {
  $('#modalAddDisease').modal({autofocus: false, observeChanges: true}).modal('attach events', '.add.button', 'show')

  var valArray = [];

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

    $('input[name="benefit[diagnosis_ids_main]"]').val(valArray)

  })

  // FOR CHECK ALL
  $('#checkAll').on('change', function(){
    var table = $('#disease_table_modal').DataTable()
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
    $('input[name="benefit[diagnosis_ids_main]"]').val(valArray)
  })

});


onmount('div[id="modalAddProcedure"]', function () {
  const csrf = $('input[name="_csrf_token"]').val();
  let id = $('#benefit_id').val()
  $('#procedure_table_modal').DataTable({
    "ajax": {
      "url": `/benefits/modal_procedure/data?id=${id}`,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true,
       "columnDefs": [ {
       "targets": [ 0 ],
        data: function ( row, type, val, meta ) {
        return `<input type="checkbox" style="width:20px; height:20px" name="benefit[procedure_ids][]" value="${row[0]}" class="selection" />`;
      }
  } ]
  });
})