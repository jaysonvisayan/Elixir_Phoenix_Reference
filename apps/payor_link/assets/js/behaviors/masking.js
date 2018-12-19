onmount('input[role="mask"]', function () {
  // var la = new Inputmask("0\\999-999-99-99", { "clearIncomplete": true});
  var Inputmask = require('inputmask');
  var im = new Inputmask("\\999-999-9999", { "clearIncomplete": true});
  var dm = new Inputmask("99-99-9999", { "clearIncomplete": true});
  var dm2 = new Inputmask("99/99/9999", { "clearIncomplete": true});
  var phone = new Inputmask("999-9999", { "clearIncomplete": true})
  let area_local = new Inputmask("numeric", {
    allowMinus:false,
    rightAlign: false
  });
  area_local.mask($('.area_and_local'));
  var time = new Inputmask("99:99", { "clearIncomplete": true})
  var tin = new Inputmask("999-999-999-999", { "clearIncomplete": true})
  im.mask($('.mobile'));
  dm.mask($('.date'));
  dm2.mask($('.date2'));
  phone.mask($('.phone'));
  time.mask($('.time'));
  tin.mask($('.tin'));
  // la.mask($('.limit'));
})
