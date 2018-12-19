onmount('div', function (){
  $('td[class="date_transform"]').each(function(){
    let date = $(this).html();
    $(this).html(moment(date).format("MMM D, YYYY"));
  });
});

onmount('div[name="scheduleForm"]', function (){
  $('a[class="time_transform"]').each(function(){
    let time = $(this).text()
    let date = moment(`2012-12-12 ${time}`);
    $(this).html(date.format("HH:mm"));
  });
});
