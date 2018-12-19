onmount('div[id="product_coverages"]', function () {

  $('.coverage_item_edit').click(function(e){
    let link = $(this).attr('link')
    let product_id = $(this).attr('productID')
    checkCoverages(link, product_id)
  })

  function checkCoverages(link_tab, p_id) {
    let counter = 0
    $('.coverages_validate').each(function(){
      counter++
    })
    if(counter == 0){
       $('#coverageOptionValidation').removeClass('hidden')
    } else {
        let link = "/products/" + p_id + "/edit?tab=" + link_tab
        window.location.replace(link)
    }

    // let counter = 0;
    // let pc_counter = 0;
    // $('.coverages').each(function(){
    //   if($(this).is(':checked') == true ){
    //     let cbCoverage = $(this).val()
    //     let product_coverage = '#'+cbCoverage
    //     counter++;
    //     var pc_length = $(product_coverage).length
    //     console.log(pc_length)
    //     for(var i =0; i < pc_length; i++){
    //        pc_counter++
    //     }
    //        alert(pc_counter)
    //   }
    // })

    // // checker for onclick
    // if(counter == 0){
    //   // if no coverage checked
    //   $('#coverageOptionValidation').removeClass('hidden')
    // }
    // else if(pc_counter == 0){
    //   // if they checked a coverage but not yet submitted
    //   $('#coverageSaveValidation').removeClass('hidden')
    // }
  }


});
