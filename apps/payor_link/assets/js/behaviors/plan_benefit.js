onmount('div[id="plan_benefit"]', function(){
  $('.ui.mdl.button').click(function() {
    $('.ui.modal').modal('show');
  });

  $('#benefitdropdown > div.menu').on('click', function(e){
    $('#benefitdropdown').dropdown('set selected',);
    //console.log(this)
  });
});
