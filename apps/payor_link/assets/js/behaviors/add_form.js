onmount('div[role="address-form"]', function(){

  $('div[role="hide-map"]').hide();
  let form_selector = 'div[role="hidden-form"]';

  if($('input[name="account[is_check]"]').is(':checked')){
    $(form_selector).hide();
    $(form_selector).find('input').prop("disabled", true);
  }else{
    $('div[id="map"]').css("height", "1200px");
  }

  $('input[name="account[is_check]"]').on('change', function(){
    if($(this).is(':checked')){
      $(form_selector).hide();
      $(form_selector).find('input').prop("disabled", true);
      $('div[id="map"]').css("height", "500px");
    }else{
      $(form_selector).show();
      $(form_selector).find('input').prop("disabled", false);
      $(form_selector).find('input[name="account[country_2]"]').prop("disabled", true);
      $('div[id="map"]').css("height", "1200px");
    }
  });

});

onmount('div[role="add"]', function(){

  const Inputmask = require('inputmask');
  let tel = 'input[name="account[telephone][]"]'

  $('a[add="telephone"]').on('click', function(){
    let telHtml = $('div[role="form-telephone"]').html();
    let tel = `<div class="fields" role="form-telephone" id="append-tel">${telHtml}</div>`
    $('p[role="append-telephone"]').append(tel);

    $('div[id="append-tel"]').find('a').removeAttr("add");
    $('div[id="append-tel"]').find('a').removeAttr("class");
    $('div[id="append-tel"]').find('a').attr("remove", "tel");
    $('div[id="append-tel"]').find('a').attr("class", "ui icon red button");
    $('div[id="append-tel"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-tel"]').find('label').remove();
    $('div[id="append-tel"]').find('select').find('option[value="32"]').attr('selected', true);
    $('.ui.dropdown').dropdown();

    $('div[role="form-telephone"]').on('click', 'a[remove="tel"]', function(e) {
      $(this).closest('div[role="form-telephone"]').remove();
    });

    let phone = new Inputmask("999-9999", { "clearIncomplete": true})

    let area_local = new Inputmask("numeric", {
      allowMinus:false,
      rightAlign: false
    });
    area_local.mask($('.area_and_local'));
    phone.mask($('.phone'));
    tel = 'input[name="account[telephone][]"]'

    $('div[role="form-telephone"]').hover(function(){
      $(this).find(tel).prop("disabled", false)
    }, function(){
      if ($(this).find(tel).val() == "") {
        $(this).find(tel).prop("disabled", true)
      } else{
        $(this).find(tel).prop("disabled", false)
      }
    })
  })

  $('a[add="fax"]').on('click', function(){
    let faxHtml = $('div[role="form-fax"]').html();
    let fax = `<div class="fields" role="form-fax" id="append-fax">${faxHtml}</div>`

    $('p[role="append-fax"]').append(fax);
    $('div[id="append-fax"]').find('a').removeAttr("add");
    $('div[id="append-fax"]').find('a').removeAttr("class");
    $('div[id="append-fax"]').find('a').attr("remove", "fax");
    $('div[id="append-fax"]').find('a').attr("class", "ui icon red button");
    $('div[id="append-fax"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-fax"]').find('label').remove();
    $('div[id="append-fax"]').find('select').find('option[value="32"]').attr('selected', true);
    $('.ui.dropdown').dropdown();

    $('div[role="form-fax"]').on('click', 'a[remove="fax"]', function(e) {
      $(this).closest('div[role="form-fax"]').remove();
    });

    let phone = new Inputmask("999-9999", { "clearIncomplete": true})
    let area_local = new Inputmask("numeric", {
      allowMinus:false,
      rightAlign: false
    });
    area_local.mask($('.area_and_local'));
    phone.mask($('.phone'));
  })

  $('a[add="mobile"]').on('click', function(){
    let mobc = parseInt($('p[role="append-mobile"]').attr('mobc')) + 1
    let append_mob = "append_mob" + mobc

    let mobHtml = $('div[role="form-mobile"]').html();
    let mob = `<div class="fields" role="form-mobile" id="${append_mob}">${mobHtml}</div>`

    $('p[role="append-mobile"]').append(mob);
    $('p[role="append-mobile"]').attr("mobc", mobc)
    $(`div[id="${append_mob}"]`).find('a').removeAttr("add");
    $(`div[id="${append_mob}"]`).find('a').removeAttr("class");
    $(`div[id="${append_mob}"]`).find('a').attr("remove", "mobile");
    $(`div[id="${append_mob}"]`).find('a').attr("class", "ui icon red button");
    $(`div[id="${append_mob}"]`).find('a').html(`<i class="icon trash"></i>`);
    $(`div[id="${append_mob}"]`).find('label').remove();
    $(`div[id="${append_mob}"]`).find('select').find('option[value="0905"]').attr('selected', true);
    $('.ui.dropdown').dropdown();

    $('div[role="form-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
      $(this).closest('div[role="form-mobile"]').remove();
    });

    let im = new Inputmask("\\999-999-9999", { "clearIncomplete": true});
    im.mask($(`div[id="${append_mob}"]`).find('.mobile'));
  })

  function validate_length(){

    $('input[id="contact"]').on('focusout', function(){
      $(this).each(function(){
        if ($(this).prop('disabled') == false) {
          if ($(this).val().length >= $(this).attr("minlength")) {
            $(this).next('p[role="validate"]').hide();
          }
        }
      })
    });
  }

});

onmount('div[role="add-contact"]', function(){
  $(".number").keydown(function (e) {
      // Allow: backspace, delete, tab, escape, enter and .
      if ($.inArray(e.keyCode, [46, 8, 9, 27, 13, 110, 190]) !== -1 ||
           // Allow: Ctrl+A, Command+A
          (e.keyCode === 65 && (e.ctrlKey === true || e.metaKey === true)) ||
           // Allow: home, end, left, right, down, up
          (e.keyCode >= 35 && e.keyCode <= 40)) {
               // let it happen, don't do anything
               return;
      }
      // Ensure that it is a number and stop the keypress
      if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) && (e.keyCode < 96 || e.keyCode > 105)) {
          e.preventDefault();
      }
  });
  $('p[role="append-telephone"]').on('click', 'a[remove="tel"]', function(e) {
    $(this).closest('div[role="form-telephone"]').remove();
  });

  $('div[role="form-telephone"]').on('click', 'a[remove="tel"]', function(e) {
    $(this).closest('div[role="form-telephone"]').remove();
  });

  $('p[role="append-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
    $(this).closest('div[role="form-mobile"]').remove();
  });

  $('div[role="form-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
    $(this).closest('div[role="form-mobile"]').remove();
  });

  $('p[role="append-fax"]').on('click', 'a[remove="fax"]', function(e) {
    $(this).closest('div[role="form-fax"]').remove();
  });

  $('div[role="form-fax"]').on('click', 'a[remove="fax"]', function(e) {
    $(this).closest('div[role="form-fax"]').remove();
  });

  $('p[role="append-email"]').on('click', 'a[remove="email"]', function(e) {
    $(this).closest('div[role="form-email"]').remove();
  });

  $('div[role="form-email"]').on('click', 'a[remove="email"]', function(e) {
    $(this).closest('div[role="form-email"]').remove();
  });

  $('a[add="telephone"]').on('click', function(){
    let telHtml = $('div[role="form-telephone"]').html();
    let tel = `<div class="fields" role="form-telephone" id="append-tel">${telHtml}</div>`

    $('p[role="append-telephone"]').append(tel);
    $('div[id="append-tel"]').find('a').removeAttr("add");
    $('div[id="append-tel"]').find('a').attr("remove", "tel");
    $('div[id="append-tel"]').find('a').attr("class", "ui icon red button");
    $('div[id="append-tel"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-tel"]').find('label').remove();

    var Inputmask = require('inputmask');
    var phone = new Inputmask("999-9999", { "clearIncomplete": true})
    let area_local = new Inputmask("numeric", {
      allowMinus:false,
      rightAlign: false
    });
    area_local.mask($('.area_and_local'));
    phone.mask($('.phone'));
  })

  $('a[add="fax"]').on('click', function(){
    let faxHtml = $('div[role="form-fax"]').html();
    let fax = `<div class="fields" role="form-fax" id="append-fax">${faxHtml}</div>`

    $('p[role="append-fax"]').append(fax);
    $('div[id="append-fax"]').find('a').removeAttr("add");
    $('div[id="append-fax"]').find('a').attr("remove", "fax");
    $('div[id="append-fax"]').find('a').attr("class", "ui icon red button");
    $('div[id="append-fax"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-fax"]').find('label').remove();

    var Inputmask = require('inputmask');
    var phone = new Inputmask("999-9999", { "clearIncomplete": true})
    let area_local = new Inputmask("numeric", {
      allowMinus:false,
      rightAlign: false
    });
    area_local.mask($('.area_and_local'));
    phone.mask($('.phone'));
  })

  $('a[add="mobile"]').on('click', function(){
    let mobc = parseInt($('p[role="append-fmobile"]').attr('mobc')) + 1
    let append_mob = "append_mob" + mobc

    let mobHtml = $('div[role="form-mobile"]').html();
    let mob = `<div class="fields" role="form-mobile" id="${append_mob}">${mobHtml}</div>`

    $('p[role="append-fmobile"]').append(mob);
    $('p[role="append-fmobile"]').attr("mobc", mobc)
    $(`div[id="${append_mob}"]`).find('a').removeAttr("add");
    $(`div[id="${append_mob}"]`).find('a').attr("remove", "mobile");
    $(`div[id="${append_mob}"]`).find('a').attr("class", "ui icon red button");
    $(`div[id="${append_mob}"]`).find('a').html(`<i class="icon trash"></i>`);
    $(`div[id="${append_mob}"]`).find('label').remove();

    var Inputmask = require('inputmask');
    var im = new Inputmask("\\999-999-9999", { "clearIncomplete": true});
    im.mask($(`div[id="${append_mob}"]`).find('.mobile'));
  })

  $('a[add="email"]').on('click', function(){
    let emailHtml = $('div[role="form-email"]').html();
    let email = `<div class="two fields" role="form-email" id="append-email">${emailHtml}</div>`

    $('p[role="append-email"]').append(email);
    $('div[id="append-email"]').find('a').removeAttr("add");
    $('div[id="append-email"]').find('a').attr("remove", "email");
    $('div[id="append-email"]').find('a').attr("class", "ui icon red button");
    $('div[id="append-email"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-email"]').find('label').remove();

    $('div[role="form-email"]').on('click', 'a[remove="email"]', function(e) {
      $(this).closest('div[role="form-email"]').remove();
    });
  })

  function validate_length(){
    $('input[id="contact"]').on('focusout', function(){
      $(this).each(function(){f
        if ($(this).val().length >= $(this).attr("minlength")) {
          $(this).next('p[role="validate"]').hide();
        }
      })
    });
  }

});

onmount('div[role="add-practitioner-contact"]', function(){
  $(".number").keydown(function (e) {
    // Allow: backspace, delete, tab, escape, enter and .
    if ($.inArray(e.keyCode, [46, 8, 9, 27, 13, 110, 190]) !== -1 ||
         // Allow: Ctrl+A, Command+A
        (e.keyCode === 65 && (e.ctrlKey === true || e.metaKey === true)) ||
         // Allow: home, end, left, right, down, up
        (e.keyCode >= 35 && e.keyCode <= 40)) {
             // let it happen, don't do anything
             return;
    }
    // Ensure that it is a number and stop the keypress
    if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) && (e.keyCode < 96 || e.keyCode > 105)) {
        e.preventDefault();
    }
  });

    $('p[role="append-telephone"]').on('click', 'a[remove="tel"]', function(e) {
      $(this).closest('div[role="form-telephone"]').remove();
    });

    $('div[role="form-telephone"]').on('click', 'a[remove="tel"]', function(e) {
      $(this).closest('div[role="form-telephone"]').remove();
    });

    $('p[role="append-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
      $(this).closest('div[role="form-mobile"]').remove();
    });

    $('div[role="form-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
      $(this).closest('div[role="form-mobile"]').remove();
    });

    $('p[role="append-fax"]').on('click', 'a[remove="fax"]', function(e) {
      $(this).closest('div[role="form-fax"]').remove();
    });

    $('div[role="form-fax"]').on('click', 'a[remove="fax"]', function(e) {
      $(this).closest('div[role="form-fax"]').remove();
    });

    $('p[role="append-email"]').on('click', 'a[remove="email"]', function(e) {
      $(this).closest('div[role="form-email"]').remove();
    });

    $('div[role="form-email"]').on('click', 'a[remove="email"]', function(e) {
      $(this).closest('div[role="form-email"]').remove();
    });

  $('a[add="telephone"]').on('click', function(){
    let telHtml = $('div[role="append-form-telephone"]').html();
    let tel = `<div class="fields" role="form-telephone" id="append-tel">${telHtml}</div>`

    $('p[role="append-telephone"]').append(tel);
    $('div[id="append-tel"]').find('input').val("");
    $('div[id="append-tel"]').find('input[name="practitioner[tel_country_code][]"]').val("+63");
    $('div[id="append-tel"]').find('input[name="practitioner_facility[tel_country_code][]"]').val("+63");
    $('div[id="append-tel"]').find('a').removeAttr("add");
    $('div[id="append-tel"]').find('a').attr("remove", "tel");
    $('div[id="append-tel"]').find('a').attr("class", "ui icon red button");
    $('div[id="append-tel"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-tel"]').find('label').remove();

    var Inputmask = require('inputmask');
    var phone = new Inputmask("999-9999", { "clearIncomplete": true})
    let area_local = new Inputmask("numeric", {
      allowMinus:false,
      rightAlign: false
    });
    area_local.mask($('.area_and_local'));
    phone.mask($('.phone'));
  })

  $('a[add="fax"]').on('click', function(){
    let faxHtml = $('div[role="append-form-fax"]').html();
    let fax = `<div class="fields" role="form-fax" id="append-fax">${faxHtml}</div>`

    $('p[role="append-fax"]').append(fax);
    $('div[id="append-fax"]').find('a').removeAttr("add");
    $('div[id="append-fax"]').find('a').attr("remove", "fax");
    $('div[id="append-fax"]').find('a').attr("class", "ui icon red button");
    $('div[id="append-fax"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-fax"]').find('label').remove();

    var Inputmask = require('inputmask');
    var phone = new Inputmask("999-9999", { "clearIncomplete": true})

    let area_local = new Inputmask("numeric", {
      allowMinus:false,
      rightAlign: false
    });
    area_local.mask($('.area_and_local'));
    phone.mask($('.phone'));
  })

  $('a[add="mobile"]').on('click', function(){
    let mobHtml = $('div[role="append-form-mobile"]').html();
    let mob = `<div class="fields" role="form-mobile" id="append-mob">${mobHtml}</div>`

    $('p[role="append-mobile"]').append(mob);
    $('div[id="append-mob"]').find('a').removeAttr("add");
    $('div[id="append-mob"]').find('a').attr("remove", "mobile");
    $('div[id="append-mob"]').find('a').attr("class", "ui icon red button");
    $('div[id="append-mob"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-mob"]').find('label').remove();

    var Inputmask = require('inputmask');
    var im = new Inputmask("\\999-999-9999", { "clearIncomplete": true});
    im.mask($('.mobile'));
  })

  $('a[add="email"]').on('click', function(){
    let emailHtml = $('div[role="append-form-email"]').html();
    let email = `<div class="fields" role="form-email" id="append-email">${emailHtml}</div>`

    $('p[role="append-email"]').append(email);
    $('div[id="append-email"]').find('a').removeAttr("add");
    $('div[id="append-email"]').find('a').attr("remove", "email");
    $('div[id="append-email"]').find('a').attr("class", "ui icon red button");
    $('div[id="append-email"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="append-email"]').find('label').remove();

  })

});
