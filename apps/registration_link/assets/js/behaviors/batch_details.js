onmount('div[id="batchDetails"]', function () {

  const csrf = $('input[name="_csrf_token"]').val()

  $('#addEditedSOAamount').on('click', function(){
    $('#addEditedSOAamountModal').modal('show')
  })

  $('.timefromnow').each(function() {
    let value = moment($(this).attr('timestamp')).fromNow()
    $(this).html(value)
  })

  setInterval(function(){
    $('.timefromnow').each(function() {
      let value = moment($(this).attr('timestamp')).fromNow()
      $(this).html(value)
    })
  }, 5000);

  $('.convert-date').each(function() {
    let value = $(this).html()
    let converted_date = moment(value).format('MMM DD, YYYY')
    $(this).html(converted_date)
  })

  $('#deleteBatch').on('click', function(){
    $('#deleteBatchModal').modal('show')
  })

  $('#confirmDeleteBatch').on('click', function(){
    let batch_id = $('#batchID').val()
    $.ajax({
      url:`/batch_processing/${batch_id}/delete_batch`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'DELETE',
      success: function(response){
        window.location.href = '/batch_processing'
      },
      error: function(){
        alert("Erorr deleting Batch!")
      }
    })
  })

  $('#addComment').on('click', function(){
    let batch_id = $('#batchID').val()
    let comment = $('#commentBox').val()
    if (comment == '') {
      $('#commentField').addClass('error').append(`<div class="ui basic red pointing prompt label transition visible">Please enter comment</div>`)
    } else {
      let params = {comment: comment}
      $.ajax({
        url:`/batch_processing/${batch_id}/add_comment`,
        headers: {"X-CSRF-TOKEN": csrf},
        data: {batch_params: params},
        type: 'POST',
        success: function(response){
          let response_obj = JSON.parse(response)
          $('#commentContainer').prepend(`<div class="item">
                          <div class="mt-1 mb-1 blacken">${response_obj.comment}</div>
                          <i class="large github middle aligned icon"></i>
                          <div class="content">
                            <a class="header blacken">${response_obj.created_by}</a>
                            <div class="description timefromnow blacken" timestamp="${response_obj.inserted_at}">a few seconds ago</div>
                          </div>
                        </div>`)
          $('#commentBox').val('')
        },
        error: function(){
          alert("Erorr adding Batch comment!")
        }
      })
    }
  })

  $('#commentBox').on('keyup', function(){
    $('#commentField').removeClass('error').find('.prompt').remove()
  })

})
