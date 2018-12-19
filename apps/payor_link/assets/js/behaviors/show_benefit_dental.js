import Vue from 'vue/dist/vue.js'

import axios from 'axios';

import { ReusableDataTable }  from './re-usable-datatable.js'

onmount('div[id="show_benefit_dental"]', function(){
  let url = '/api/v1/sap/benefits/get_dental'
  let token = $(this).attr("token")
  let code = $(this).attr("code")
  let cdt_data  = {benefit: code, with_cdt: true}

  new Vue({
    el: '#view_benefit_dental',
    data: {
      results: []
    },
    mounted(){
      this.getPreExisting()
    },
    methods:{
      getPreExisting: function() {
        axios({
          method: 'post',
          url: url,
          headers: { 'Authorization': `Bearer ${token}` },
          data: cdt_data
        })
        .then(response => {
        this.results = response.data
        })
        .catch(function (error) {
          window.document.location = `/web`
          alertify.error(`<i class="close icon"></i>${error.response.data.error.message}`)
        })
        .then(function(response) {
          $('.ui.dropdown').dropdown()
        })
      }
    },
    updated: function () {
      this.$nextTick(function () {
        $('div[role="array"]').each(function(){
          let val = $(this).attr("id")
          $(this).html(val)
        })
        ReusableDataTable('cdt_tbl', 'cdt', token, cdt_data, url)
      })
    }
  })
});

