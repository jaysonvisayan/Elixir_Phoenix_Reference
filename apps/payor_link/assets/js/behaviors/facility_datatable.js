onmount('div[role="facility_index"]', function () {
  const csrf = $('input[name="_csrf_token"]').val();
  $('#facility_index').DataTable({
    "ajax": {
      "url": `/facilities/index/data`,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true,
      "columnDefs": [
        {
          "targets": [ 0 ],
          data: function ( row, type, val, meta ) {
            let split = row[0].split('|')
            if (split[2] >= 7) {
              return `<a href="/facilities/${split[1]}?active=profile">${split[0]}</a>`;
            } else {
              return `<a href="/facilities/${split[1]}/setup?step=${split[2]}">${split[0]} (Draft)</a>`;
            }
          }
        }
      ]
  });
})
