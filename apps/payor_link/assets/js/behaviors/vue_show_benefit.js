import Vue from 'vue/dist/vue.js'

import axios from 'axios';

import {BenefitLimitDatatable} from './benefit_limit_dt.js'
import {BenefitPackageDatatable} from './benefit_packages_dt.js'
import {BenefitDiagnosesDatatable} from './benefit_diagnoses_dt.js'
import {BenefitProceduresDatatable} from './benefit_procedures_dt.js'

onmount('div[id="show_benefit_all_coverage"]', function(){
  let url = '/api/v1/sap/get_benefits'
  let token = $(this).attr('token')
  const csrf = $('input[name="_csrf_token"]').val();
  let code = $(this).attr('code')
  let benefit = {benefits: code}

$('.show-diagnosis-details').click(function() {
    $('div[role="show-details"]').modal('show');
  });

  const getCover = (coverages) => {
     let cover = []
     let cover2 = []
     let count = 0;
     let peme = false
     let acu = false

     for(let coverage in coverages) {
       if(coverages[coverage].name == "PEME"){
        cover += "PEME"
        cover2.push("PEME")
        peme = true
       }else if(coverages[coverage].name == "ACU") {
        cover += "ACU"
        acu = true
        cover2.push("ACU")
       }else{
        if(coverage < coverages.length - 1) {
        cover += coverages[coverage].name +  ", "
        cover2.push(coverages[coverage].name)
        }else{
        cover += coverages[coverage].name
        cover2.push(coverages[coverage].name)
        }
       }
     }
     count = cover2.length
    return {coverage: cover, peme: peme, acu: acu, count: count}
  }

  const getCategory = (loa_facilitated, reimbursement) => {
    if(loa_facilitated && reimbursement){
      return  "LOA Facilitated, Reimbursement"
    }else if(loa_facilitated){
      return "LOA Facilitated"
    }else if(reimbursement){
      return "Reimbursement"
    }else{
      return "N/A"
    }
  }

  const getProvider = (provider_access) => {
     if (provider_access == "Hospital/Clinic") {
      return "Hospital and Clinic"
     }else if(provider_access == "Hospital/Clinic and Mobile"){
      return "Hospital, Clinic and Mobile"
    }else if(provider_access == "Hospital and Clinic and Mobile"){
      return "Hospital, Clinic and Mobile"
    }else{
      return provider_access
    }
  }

  const getMemberPay = (member_pays) => {
    if (!Array.isArray(member_pays) || !member_pays.length) {
     return ""
    }else{
      let mp = member_pays.join(", ")
      return mp
    }
   }

  const getLimit = (limits) => {
    let limit_values = ''
    let limit_count = limits.length
    if(limits.length > 0){
    for (let limit in limits) {
       switch (limits[limit].limit_type) {
        case 'Sessions':
         limit_values += limits[limit].limit_session
         break;

        case 'Peso':
         limit_values += 'Php ' + limits[limit].limit_amount
         break;

        case 'Plan Limit Percentage':
         limit_values += limits[limit].limit_percentage + '%'
         break;

        default:
         limit_values += 'N/A'
      }
    }
    }else{
      limit_values = 'N/A'
    }
    return {limit_values: limit_values, limit_count: limit_count}
  }

  new Vue({
    el: '#view_benefit_all_coverage',
    data: {
      results: [],
      coverages: [],
      category: [],
      benefit_id: [],
      limits: [],
      provider_access: [],
      member_pays: []
    },
    mounted(){
      this.getBenefit()
    },
    methods: {
      getBenefit: function() {
        axios({
          method: 'post',
          url: url,
          headers: { 'Authorization': `Bearer ${token}` },
          data: benefit
        })
        .then(response => {
          this.results = response.data
          this.benefit_id = response.data.id
          this.category = getCategory(response.data.loa_facilitated, response.data.reimbursement)
          this.coverages = getCover(response.data.coverages)
          this.limits = getLimit(response.data.limits)
          this.provider_access = getProvider(response.data.provider_access)
          this.member_pays = getMemberPay(response.data.member_pays_handling)
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
        BenefitLimitDatatable($('#benefit_limit_coverages_dt2'), this.benefit_id, csrf)
        BenefitDiagnosesDatatable($('#benefit_diagnoses_dt2'), this.benefit_id, csrf)
        BenefitProceduresDatatable($('#benefit_procedures_dt2'), this.benefit_id, csrf)
        BenefitPackageDatatable($('#benefit_packages_dt2'), this.benefit_id, csrf)
      })
    }
  })

})


