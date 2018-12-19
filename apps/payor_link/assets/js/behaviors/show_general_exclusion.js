import Vue from 'vue/dist/vue.js'

import axios from 'axios';

import {PreexistingDiagnosis, ExclusionProcedure}  from './web_general_exclusion_datatable.js'

onmount('div[id="show_general_exclusion"]', function(){
  let url = '/api/v1/sap/get_exclusions'
  let token = $(this).attr("token")
  let code = $(this).attr("code")
  let params = {code: code, with_diagnosis: true}
  let diagnosis_data = {pre_existing: code, with_diagnosis: true}
  let diagnosis_datatable_url = '/api/v1/sap/get_pre_existings'
  let procedure_datatable_url = '/api/v1/exclusion_procedure_datatable'

  new Vue({
    el: '#view_general_exclusion',
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
          data: params
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
        ExclusionProcedure('procedure_tbl', 'diagnosis', token, {exclusion: code}, procedure_datatable_url)
        PreexistingDiagnosis('diagnosis_datatable', 'diagnosis', token, diagnosis_data, diagnosis_datatable_url)
      })
    }
  })

});

