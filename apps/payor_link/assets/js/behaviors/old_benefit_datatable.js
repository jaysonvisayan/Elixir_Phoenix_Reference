onmount('div[id="benefits_index_v2"]', function () {
  const csrf = $('input[name="_csrf_token"]').val();
  $('#benefits_datatable_v2').DataTable({
    "ajax": {
      "url": `/benefits/index/data_v2`,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true
  });
})
