onmount('div[id="account_group_cluster"]', function () {
  
  $('.btnAccountGroup').on('click', function(){
    let account_group_cluster_id = $(this).attr('account_group_cluster_id')

    swal({
          title: 'Delete Account?',
          type: 'question',
          showCancelButton: true,
          cancelButtonText: '<i class="remove icon"></i> No, Keep Account',
          confirmButtonText: '<i class="check icon"></i> Yes, Delete Account',
          cancelButtonClass: 'ui negative button',
          confirmButtonClass: 'ui positive button',
          reverseButtons: true,
          buttonsStyling: false
          }).then(function () {
              window.location.replace(`/clusters/${account_group_cluster_id}/delete_account_group_clusters`);
          })
    })

  $('.btnEditAccountGroup').on('click', function(){
    let account_group_cluster_id = $(this).attr('account_group_cluster_id')

    swal({
          title: 'Delete Account?',
          type: 'question',
          showCancelButton: true,
          cancelButtonText: '<i class="remove icon"></i> No, Keep Account',
          confirmButtonText: '<i class="check icon"></i> Yes, Delete Account',
          cancelButtonClass: 'ui negative button',
          confirmButtonClass: 'ui positive button',
          reverseButtons: true,
          buttonsStyling: false
          }).then(function () {
              window.location.replace(`/clusters/${account_group_cluster_id}/delete_edit_account_group_clusters`);
          })
  })


  $('.modal').modal('attach events', '.add.button', 'show');

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
    $('input[name="cluster[account_group_cluster_ids_main]"]').val(valArray)
  })
    
  

    // FOR CHECK ALL
  $('#checkAllAccounts').on('change', function(){
    if ($(this).is(':checked')){
      $('input[name="cluster[account_group_cluster_ids][]"]').each(function(){
        var value = $(this).val()

        if(this.checked) {
          valArray.push(value)
        } else {
          var index = valArray.indexOf(value);

          if (index >= 0) {
            valArray.splice( index, 1)
          }
          valArray.push(value)
        }
        $(this).prop('checked', true)
      })
      
    } else {
      valArray.length = 0
      $('input[name="cluster[account_group_cluster_ids][]"]').each(function(){
        $(this).prop('checked', false)
      })
    }
    $('input[name="cluster[account_group_cluster_ids_main]"]').val(valArray)
  })

});

