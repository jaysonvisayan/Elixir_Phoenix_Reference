onmount('div[id="aaf_form"]', function(){
  var array1 = []
  var selected_facilities1 = $('.aaf_facility_ids')
  var selected_tab1 = $('.tab1').val();


  for (var i=0; i < selected_facilities1.length; i++){
    array1.push(selected_facilities1[i].value)
  }

  var test1 = $('#aaftab1').dropdown('set selected',array1);

  // if (array1.length != 0) {
  //  alert(array1)
  //}

  //if(selected_tab == true ){
  //  $('.ui.sf.fluid.dropdown').dropdown('restore defaults');
  // }

});

