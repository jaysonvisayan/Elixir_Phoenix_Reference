onmount('div[id="showProduct"]', function(){
  $('#logsModal').modal('attach events', '#logs', 'show')

  $('p[class="log-date"]').each(function(){
    let date = $(this).html();
    $(this).html(moment(date).format("MMM D, YYYY"));
  })

});
