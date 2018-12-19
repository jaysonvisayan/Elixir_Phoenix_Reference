let pgurl = window.location.href;

$(".sidebar a.item").each(function() {
  if (pgurl.indexOf($(this).attr("id")) > -1) {
    $(this).addClass("active");
  }
});

$('#account_sub a.item').each(function() {
  if ($(this).hasClass('active')){
    $('#account').addClass('active');
  }
});

$('#approval_sub a.item').each(function() {
  if ($(this).hasClass('active')){
    $('#approval').addClass('active');
  }
});
