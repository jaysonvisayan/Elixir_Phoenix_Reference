onmount('input[role="mask"]', function () {
console.log("yea")
  var Inputmask = require('inputmask');
  var im = new Inputmask("0\\999-999-99-99");
  var dm = new Inputmask("9999-99-99", { "clearIncomplete": true});
  var dm2 = new Inputmask("99/99/9999", { "clearIncomplete": true});
  var phone = new Inputmask("999-99-99")
  var time = new Inputmask("99:99", { "clearIncomplete": true})
  var ph = new Inputmask("99-999999999-9")
  var tin = new Inputmask("999-999-999-999")
  var postal = new Inputmask("9999")
  var currency = new Inputmask("numeric", {
    allowMinus:false,
    min: 1,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false
  });

  im.mask($('.mobile'));
  dm.mask($('.date'));
  dm2.mask($('.date2'));
  phone.mask($('.phone'));
  time.mask($('.time'));
  ph.mask($('.philhealth'));
  tin.mask($('.tin'));
  postal.mask($('.postal'));
  currency.mask($('.currency'))
});
