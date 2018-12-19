onmount('div[id="auth_index"]', function () {
  const csrf = $('input[name="_csrf_token"]').val();

  $('.auth_convert_date').each(function(index, value){
    let date = $(value).text();
    $(value).text(convertToMoment(date))
  })

  function convertToMoment(dateTime){
    return moment(dateTime).format('MM/DD/YYYY h:mm A')
  }

  $('#auth_table').DataTable({
    "ajax": {
      "url": `/authorizations/index/data`,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true,
      "columnDefs": [
        {
          "targets": [ 8 ],
          data: function ( row, type, val, meta ) {
            return convertToMoment(row[8]);
          }
        },
        {
          "targets": [ 12 ],
          "orderable": false
        }
      ],
  });
})
