onmount('input[role="mask"]', function () {
  var Inputmask = require('inputmask');
  var im = new Inputmask("0\\999-999-99-99", { "clearIncomplete": true});
  var dm = new Inputmask("99-99-9999", { "clearIncomplete": true});
  var dm2 = new Inputmask("99/99/9999", { "clearIncomplete": true});
  var phone = new Inputmask("999-99-99", { "clearIncomplete": true})
  var time = new Inputmask("99:99", { "clearIncomplete": true})
  var ph = new Inputmask("99-999999999-9", {"clearIncomplete": true})
  var tin = new Inputmask("999-999-999-999", {"clearIncomplete": false})
  var id_no = new Inputmask("999-999-999", {"clearIncomplete": false})
  var year = new Inputmask("9999", {"clearIncomplete": true});
  var day = new Inputmask("99", {"clearIncomplete": true});
  var zip = new Inputmask("9999", {"clearIncomplete": true});
  var tin2 = new Inputmask("999-999-999-999", {"clearIncomplete": true})
  var sss_no = new Inputmask("999-999-999", {"clearIncomplete": true})
  var unified_no = new Inputmask("999-999-999", {"clearIncomplete": true})

  im.mask($('.mob')); //update class name. have same class name in semantic- JMUDC
  dm.mask($('.date'));
  dm2.mask($('.date2'));
  phone.mask($('.phone'));
  time.mask($('.time'));
  ph.mask($('.philhealth'));
  tin.mask($('.tin'))
  tin2.mask($('.tin2'))
  id_no.mask($('.id_no'))
  sss_no.mask($('.sss_no'))
  unified_no.mask($('.unified_no'))
  year.mask($('.year'));
  day.mask($('.day'));
  zip.mask($('.zip'));
});
