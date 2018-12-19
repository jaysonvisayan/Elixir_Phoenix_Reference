onmount('div', function (){
  $('td[class="date_transform"]').each(function(){
    let date = $(this).html();
    let val = moment(date).format("D MMMM YYYY");

    if(val != "Invalid date"){
      $(this).html(val)
    }
  });
});

onmount('.valid_timezone', function (){
  $('.valid_timezone').each(function(){
    let val = $(this).text()
    if (val == "") {
      ""
    } else {
      $(this).text(moment(val).format("MMM DD, YYYY hh:mm A"));
    }
  })
  $('.valid_timezone.date-only').each(function(){
    let val = $(this).text()
    if (val == "") {
      ""
    } else {
      $(this).text(moment(val).format("MMM DD, YYYY"));
    }
  })
})


onmount('div[name="scheduleForm"]', function (){
  $('a[class="time_transform"]').each(function(){
    let time = $(this).text()
    let date = moment(`2012-12-12 ${time}`);
    $(this).html(date.format("HH:mm"));
  });
});
