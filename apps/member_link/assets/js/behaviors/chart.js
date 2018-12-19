onmount('.pie-chart', function(){
  let ctx = $("#loaChart");

  const approved = $('input[status="approved"]').val()
  const pending = $('input[status="pending"]').val()
  const approval = $('input[status="for-approval"]').val()

  let data = {
    datasets: [{
      data: [approved, pending, approval],
      backgroundColor: [
        "#4ACAB4",
        "#FFEA88",
        "#FF8153",
      ],
      borderColor: [
        "#4ACAB4",
        "#FFEA88",
        "#FF8153",
      ],
      borderWidth: [1, 1, 1, 1, 1]
    }],

    // These labels appear in the legend and in the tooltips when hovering different arcs
    labels: [
        'Approved',
        'Pending',
        'For Approval'
    ]
  };

  let options = {
    segmentShowStroke : false,
	  animateScale : true,
    title: {
      display: true,
      text: 'Member\'s LOA'
    },
    legend: {
      display: true,
      position: "bottom",
    }
  }

  let myPieChart = new Chart(ctx,{
    animationEnabled: true,
    type: 'pie',
    data: data,
    options: options
  });
})
