onmount('div[id="sf_form"]', function(){
  var array2 = []
  var selected_facilities2 = $('.sf_facility_ids')
  var selected_tab2 = $('.tab2').val();

  for (var i=0; i < selected_facilities2.length; i++){
    array2.push(selected_facilities2[i].value)
  }

  var test2 = $('#sftab2').dropdown('set selected',array2);

  //if (array2.length != 0) {
  //  alert(array2)
  //}

  //if(selected_tab == false ){
  //  $('.ui.aaf.fluid.dropdown').dropdown('restore defaults');
  //}

});
