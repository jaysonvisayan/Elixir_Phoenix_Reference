onmount('div[id="exclusionIndex"]', function () {
  let url = window.location.href
  if(url.includes("?") == true){
    let get_active = url.split("?")
    let active_value = get_active[1]
    let value = active_value.split('=')

    if (value[1] == "general-disease"){
      $("#exclusionIndex > div.ui.pointing.secondary.menu > a:nth-child(2)").addClass("active")
      $("#exclusionIndex > div.ui.pointing.secondary.menu > a:nth-child(1)").removeClass("active")
      $("#exclusionIndex > div:nth-child(4)").addClass("active")
      $("#exclusionIndex > div:nth-child(3)").removeClass("active")
    }
    else if (value[1] == "general-payor_procedure"){
      $("#exclusionIndex > div.ui.pointing.secondary.menu > a:nth-child(1)").removeClass("active")
      $("#exclusionIndex > div.ui.pointing.secondary.menu > a:nth-child(2)").addClass("active")
      $("#exclusionIndex > div:nth-child(3)").removeClass("active")
      $("#exclusionIndex > div:nth-child(4)").addClass("active")

      $("#general_disease_tab").removeClass("active")
      $("#general_payor_procedure_tab").addClass("active")
      $("#render_disease").removeClass("active")
      $("#render_payor_procedure").addClass("active")
    }

  }
})

