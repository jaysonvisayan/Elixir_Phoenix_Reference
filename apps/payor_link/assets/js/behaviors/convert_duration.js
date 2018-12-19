onmount('div[role="convert-duration"]', function(){

  let convertToMoment = (date) => {
    return moment(date, "YYYY-MM-DD")
  }

  let parseDuration = (diff) => {
    let duration = moment.duration(diff)
    let result = ""

    if(duration.years() > 0){
      result = `${duration.years()} years ${duration.months()} months ${duration.days()} days`
    }else if(duration.months() > 0){
      result = `${duration.months()} months ${duration.days()} days`
    }else{
      result = `${duration.days()} days`
    }
    return result
  }

  let convertDuration = (container) => {
    let from = convertToMoment($(container).find('span[role="from"]').text())
    let to = convertToMoment($(container).find('span[role="to"]').text())
    let diff = to.diff(from)
    let result = parseDuration(diff)
    $(container).find('span[role="duration"]').text(result)
  }

  let containers = $('div[role="convert-duration"]')
  _.each(containers, (c) => {
    convertDuration(c)
  })


})
