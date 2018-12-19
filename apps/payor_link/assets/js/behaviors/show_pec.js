import Vue from 'vue/dist/vue.js'

import axios from 'axios';

import { PreexistingCondition, PreexistingDiagnosis }  from './web_pre_existing_datatable.js'

onmount('div[id="show_pec"]', function(){
  let url = '/api/v1/sap/get_pre_existings'
  let token = $(this).attr("token")
  let code = $(this).attr("code")
  let condition_data_prin = {pre_existing: code, with_diagnosis: false, member_type: "Principal"}
  let condition_data_dep = {pre_existing: code, with_diagnosis: false, member_type: "Dependent"}
  let diagnosis_data = {pre_existing: code, with_diagnosis: true}

  new Vue({
    el: '#view_pec',
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
          data: diagnosis_data
        })
        .then(response => {
          this.results = response.data
        })
        .catch(function (error) {
          window.document.location = `/web`
          alertify.error(`<i class="close icon"></i>${error.response.data.error.message}`)
        })
        .then(function(response) {
          $('.ui.floating.dropdown').dropdown()
        })
      }
    },
    updated: function () {
      this.$nextTick(function () {
        PreexistingCondition('condition_prin_tbl', 'principal', token, condition_data_prin, url)
        PreexistingCondition('condition_dep_tbl', 'dependent', token, condition_data_dep, url)
        PreexistingDiagnosis('diagnosis_tbl', 'diagnosis', token, diagnosis_data, url)

      })
    }
  })

});

