onmount('div[id="coverage-facility"]', function () {
  const csrf = $('input[name="_csrf_token"]').val();

  // $('.location-group').on('change', function() {
  //   let location_group_id = $('.location-group').dropdown('get value')
  //   console.log(location_group_id)

  //   $('.modal-open-facilities').on('click', function(){
  //     $('#exclusion_facility_table').DataTable({
  //       "ajax": {
  //         "url": `/products/dental/exclusion_facilities?location_group_id=${location_group_id}`,
  //         "headers": { "X-CSRF-TOKEN": csrf },
  //         "type": "get"
  //       },
  //         "processing": true,
  //         "serverSide": true,
  //         "deferRender": true
  //     });
  //   })
  // })

})
