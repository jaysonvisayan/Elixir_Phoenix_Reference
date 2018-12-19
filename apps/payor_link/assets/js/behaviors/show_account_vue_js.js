import Vue from 'vue/dist/vue.js';
import axios from 'axios';

onmount('div[id="view_account"]', function() {
  let url = '/api/v1/sap/accounts/get_account'
  let token = $(this).attr("token")
  let code = $("#account_code_id").val()
  let params = {code: code, name: ""}

  new Vue({
    el: '#view_account',
    data: {
      results: [],
      contact_arrays: [],
      addresses: [],
      financial: []
      // plan: [],
      // approver: []
    },
    mounted(){
      this.getAccount()
    },
    methods:{
      getAccount: function() {
        axios({
          method: 'post',
          url: url,
          headers: { 'Authorization': `Bearer ${token}` },
          data: params
        })
        .then(response => {
          this.results = response.data
          this.contact_arrays = response.data.contacts
          this.addresses = response.data.account_group_address
          this.financial = response.data.financial
          // this.plan = response.data.plan
          // this.approver = response.data.approver
        })
        .catch(function (error) {
          window.document.location = `/web`
          alertify.error(`<i class="close icon"></i>${error.response.data.error.message}`)
        })
        // .then(function(response) {
        //   $('.ui.floating.dropdown').dropdown()
        // })
      }
    },
    updated: function () {
      this.$nextTick(function () {
          // let effective_date = $('#effective_date').val()
          // let expiry_date = $('#expiry_date').val()
          // let original_effective_date = $('#original_effective_date').val()

          // let eds = effective_date.split("-")
          // let exds = expiry_date.split("-")
          // let ods = original_effective_date.split("-")

          // let month1 = eds[1]
          // let month2 = exds[1]
          // let month3 = ods[1]

          // let m1 = parseInt(month1) - 1
          // let m2 = parseInt(month2) - 1
          // let m3 = parseInt(month3) - 1

          // let month_names = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC']

          // let m1_eff = month_names[m1]
          // let m2_exp = month_names[m2]
          // let m3_orig = month_names[m3]

          // let eff_new = m1_eff + '-' + eds[2] + '-' + eds[0]
          // let exp_new = m2_exp + '-' + exds[2] + '-' + exds[0]
          // let orig_new = m3_orig + '-' + ods[2] + '-' + ods[0]

          // $('#effective_date_display').text(eff_new)
          // $('#expiry_date_display').text(exp_new)
          // $('#original_effective_date_display').text(orig_new)
      })
    }
  })

  $('.ui.dropdown').dropdown();

  $(document).ready(function(){
    $('.demo.menu .item').tab({history:false});
  });

})


