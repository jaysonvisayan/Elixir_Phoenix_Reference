onmount('#main_exclusions', function() {

 $('#mainExclusionsVersions').on('click', function() {
    $('.versions-sidebar').sidebar('toggle')
  })

 $('body').on('click', '#show_diagnosis_modal', function() {
    $('#show_details').modal('show');

    let code = $(this).attr('code');
    let description = $(this).attr('description');
    let group_code = $(this).attr('group_code');
    let group_description = $(this).attr('group_description');
    let group_name = $(this).attr('group_name');
    let chapter = $(this).attr('chapter');
    let type = $(this).attr('type');
    let congenital = $(this).attr('congenital');
    let coverages = $(this).attr('coverages');
    let exclusion_type = $(this).attr('exclusion');

    let coverages_split = coverages.split(",")
    let coverages_join = coverages_split.join(", ")

    $('label[id="code"]').text(code);
    $('label[id="description"]').text(description);
    $('label[id="group_code"]').text(group_code);
    $('label[id="group_description"]').text(group_description);
    $('label[id="group_name"]').text(group_name);
    $('label[id="chapter"]').text(chapter);
    $('label[id="type"]').text(type);
    $('label[id="congenital"]').text(congenital);
    $('label[id="coverages"]').text(coverages_join);
    $('label[id="exclusion_type"]').text(exclusion_type);
  });

});


