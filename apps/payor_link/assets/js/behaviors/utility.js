onmount('.logs-format-datetime', function() {

  $('p[class="format-inserted-at"]').each(function() {
    let date = $(this).html()
    $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'))
  })

});