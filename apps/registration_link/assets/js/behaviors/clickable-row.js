onmount('.clickable-row', function () {
  const el = $(this)
  el.on('click', function(e) {
    window.document.location = $(this).attr("href");
  })
});
