onmount('div[name="AccountSearch"]', function () {
  const csrf = $('input[name="_csrf_token"]').val();
  $('#accounts_index').DataTable({
    "ajax": {
      "url": `/accounts/index/data`,
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
            return `<a href="/accounts/${row[0].split('|')[1]}/versions">${row[0].split('|')[0]}</a>`;
          }
        },
        {
          "targets": [ 4 ],
          data: function ( row, type, val, meta ) {
            return `<p class="${row[4].split('|')[1]}"><i class="circle icon"></i>${row[4].split('|')[0]}</p>`;
          }
        }
      ]
  });
})