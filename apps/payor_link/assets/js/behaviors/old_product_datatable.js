onmount('div[id="product_index"]', function () {
  const csrf = $('input[name="_csrf_token"]').val();
  $('#product_datatable').DataTable({
    "ajax": {
      "url": `/products/index/data_v2`,
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
      "processing": true,
      "serverSide": true,
      "deferRender": true
  });
})
