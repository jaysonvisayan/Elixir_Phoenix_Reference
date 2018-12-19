import "phoenix_html"
import Vue from "vue"
import Notifications from "./components/notifications.vue"

Vue.component('notifications', Notifications)

window.onmount = require('onmount')
window._ = require('lodash')
window.moment = require('moment')
window.momentTz = require('moment-timezone')
window.Inputmask = require('inputmask');

glob('./behaviors/*', (e, files) => { files.forEach(require) })

/*
 * For datatable's pipelining of data
 */

let timeout
$.fn.dataTable.dt_timeout = (ajax_url, csrf) => {
  return function ( request, drawCallback, settings ) {
    clearTimeout(timeout)

    timeout = setTimeout(() => {
      $.ajax({
        url: ajax_url,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        dataType: 'json',
        data: request,
        success: response => {
          return drawCallback(response)
        }
      })
    }, 800);
  }
}

$(function () { onmount() })

onmount('div[id="notifications"]', function(){
  let notifications = new Vue({
    el: '#notifications',
    render(createElement){
      return createElement(Notifications, {})
    }
  })

});


onmount('div[id="open_pb_modal"]', function(){
  $('.ui.dropdown').dropdown({
    fullTextSearch: "exact",
    allowAdditions: true
  });
});

onmount('div[id="form_procedures"]', function(){
  $('.ui.std_procedures.dropdown').dropdown({
    fullTextSearch: 'exact'
  });
});

onmount('div[id="product_risk_shares"]', function () {
  $('.ui.dropdown').dropdown({
    fullTextSearch: "exact",
    allowAdditions: true
  });
});

onmount('div[id="practitioner_facility"]', function () {
  $('.ui.dropdown').dropdown({
    fullTextSearch: "exact",
    allowAdditions: true
  });
});

onmount('div[name="formConsultation"]', function(){
  $('.search-dropdown').dropdown({
    fullTextSearch: "exact",
    match: "text",
    forceSelection: false
  })
});

onmount('div[id="member_account_reports"]', function () {
  $('.ui .dropdown').dropdown({
    fullTextSearch: "exact",
    match: "text",
    forceSelection: false
  })
});

onmount('div[id="acu_schedule_form"]', function () {
  $('.ui .dropdown').dropdown({
    fullTextSearch: "exact",
    match: "text",
    forceSelection: false
  })
});

onmount('div[id="acu_schedule_edit_form"]', function () {
  $('.ui .dropdown').dropdown({
    fullTextSearch: "exact",
    match: "text",
    forceSelection: false
  })
});

alertify.defaults = {
  // notifier defaults
  notifier:{
    // auto-dismiss wait time (in seconds)
    delay:5,
    // default position
    position:'top-right',
    // adds a close button to notifier messages
    closeButton: false
  }
}
// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
