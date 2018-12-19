    //sidebar trigger
    $("#toc").sidebar({
        dimPage: true,
        transition: "overlay",
        mobileTransition: "uncover"
    });
    //sidebar trigger

    // $("body").niceScroll({
    //     cursorcolor: "#818387",
    //     cursorwidth: 7,
    //     cursorborderradius: 5,
    //     cursorborder: 2,
    //     scrollspeed: 50,
    //     autohidemode: true,
    //     zindex: 9999999
    // });

    $('.hamburger').on('click', function() {
        if ("show" == $(this).data("name")) {
            $(".toc").animate({
                width: "130px"
            }, 350);
            $(".logo").animate({
                width: "130px"
            }, 350);
            $(".logo img").transition("tada").attr("src", "/images/thumblogo.png");
            $(".toc").html('<div class="ui visible left vertical labeled icon uncover sidebar menu very thin sidemenu thinside">\
                                <a class="item no-border borderless" href="/authorizations" id="authorizations">\
                                    <i class="check square icon"></i>\
                                    Authorizations\
                                </a>\
                                <a class="item no-border borderless" href="/accounts" id="accounts">\
                                    <i class="building outline icon"></i>\
                                    Accounts\
                                </a>\
                                <a class="item no-border borderless" href="/products" id="products">\
                                    <i class="cubes icon"></i>\
                                    Plans\
                                </a>\
                                <a class="item no-border borderless" href="/coverages" id="coverages">\
                                    <i class="h icon"></i>\
                                    Coverages\
                                </a>\
                                <a class="item no-border borderless" href="/benefits" id="benefits">\
                                  <i class="credit card alternative icon"></i>\
                                  Benefits\
                                </a>\
                                <a class="item no-border borderless" href="/procedures" id="procedures">\
                                  <i class="cut icon"></i>\
                                  Procedures\
                                </a>\
                                 <a class="item no-border borderless" href="/diseases"  id="diseases">\
                                  <i class="eyedropper icon"></i>\
                                  Diseases\
                                  </a>\
                                 <a class="item no-border borderless" href="/pharmacies"  id="pharmacies">\
                                  <i class="medkit icon"></i>\
                                  Pharmacies\
                                </a>\
                                <a class="item no-border borderless" href="/clusters" id="clusters">\
                                  <i class="sitemap icon"></i>\
                                  Clusters\
                                </a>\
                                <a class="item no-border borderless" href="/exclusions" id="exclusions">\
                                  <i class="ban icon"></i>\
                                  Exclusions\
                                </a>\
                                <a class="item no-border borderless" href="/packages" id="packages">\
                                  <i class="cube icon"></i>\
                                  Packages\
                                </a>\
                                <a class="item no-border borderless" href="/ruvs" id="ruvs">\
                                  <i class="heartbeat icon"></i>\
                                  RUVs\
                                </a>\
                                <a class="item no-border borderless" href="/case_rates" id="case_rates">\
                                  <i class="percent icon"></i>\
                                  Case Rates\
                                </a>\
                                <a class="item no-border borderless" href="/acu_schedules" id="acu_schedules">\
                                  <i class="calendar alternate icon"></i>\
                                  ACU Schedules\
                                </a>\
                                <a class="item no-border borderless" href="/facilities" id="facilities">\
                                  <i class="hospital icon"></i>\
                                  Facilities\
                                </a>\
                                <a class="item no-border borderless" href="/rooms" id="rooms">\
                                  <i class="hotel icon"></i>\
                                  Rooms\
                                </a>\
                                <a class="item no-border borderless" href="/practitioners" id="practitioners">\
                                  <i class="doctor icon"></i>\
                                  Practitioners\
                                </a>\
                                <a class="item no-border borderless" href="/users" id="user">\
                                  <i class="users icon"></i>\
                                  Users\
                                </a>\
                                <a class="item no-border borderless" href="/members" id="members">\
                                  <i class="user circle icon"></i>\
                                  Members\
                                </a> \
                                <a class="item no-border borderless" href="/roles" id="roles">\
                                  <i class="travel icon"></i>\
                                  Roles\
                                </a> \
                                <a class="item no-border borderless" href="/companies" id="companies">\
                                  <i class="building icon"></i>\
                                  Companies\
                                </a>', function() {
                $(".ui .dropdown").dropdown({
                    transition: "fade up",
                    on: "hover"
                });
                $(".logoImg").transition('jiggle')
            });
            $(this).data("name", "hide");
            $('#footer').css('margin-left', '130px');
        } else {
            $(".toc").animate({
                width: "300px"
            }, 350);
            $(".logo").animate({
                width: "300px"
            }, 350);
            $(".logo img").attr("src", "/images/logo.png");
            $(".toc").html('<div class="ui visible left vertical sidebar menu sidemenu">\
                                <div class="item borderless">\
                                    <b>Transaction</b>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/authorizations" id="authorizations">\
                                      Authorizations\
                                      <i class="check square icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                <a class="item" href="/accounts" id="accounts">\
                                    Accounts\
                                    <i class="building outline icon"></i>\
                                </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/products" id="products">\
                                        Plans\
                                        <i class="cubes icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/coverages" id="coverages">\
                                        Coverages\
                                        <i class="h icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/benefits" id="benefits">\
                                        Benefits\
                                        <i class="credit card alternative icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/procedures" id="procedures">\
                                        Procedures\
                                        <i class="cut icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/diseases" id="diseases">\
                                        Diseases\
                                        <i class="eyedropper icon"></i>\
                                    </a>\
                                    </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/pharmacies" id="pharmacies">\
                                        Pharmacies\
                                        <i class="medkit icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/clusters" id="clusters">\
                                        Clusters\
                                        <i class="sitemap icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/exclusions" id="exclusions">\
                                        Exclusions\
                                        <i class="ban icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/packages" id="packages">\
                                        Packages\
                                        <i class="cube icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/ruvs">\
                                        RUVs\
                                        <i class="heartbeat icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                  <a class="item" href="/case_rates" id="case_rates>">\
                                        Case Rates\
                                        <i class="percent icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                  <a class="item no-border borderless" href="/acu_schedules" id="acu_schedules">\
                                    <i class="calendar alternate icon"></i>\
                                    ACU Schedules\
                                  </a>\
                                </div>\
                                <div class="item borderless">\
                                    <b>Information</b>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/facilities" id="facilities">\
                                        Facilities\
                                        <i class="hospital icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/rooms" id="rooms">\
                                        Rooms\
                                        <i class="hotel icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/practitioners" id="practitioners">\
                                        Practitioners\
                                        <i class="doctor icon"></i>\
                                    </a>\
                                </div>\
                                <div class="item borderless">\
                                    <b>Administration</b>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/users" id="users">\
                                        Users\
                                        <i class="users icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/members" id="members">\
                                        Members\
                                        <i class="user circle icon"></i>\
                                    </a>\
                                </div>\
                                <div class="content pad1L">\
                                    <a class="item" href="/roles" id="roles">\
                                        Roles\
                                        <i class="travel icon"></i>\
                                    </a>\
                                </div>', function() {
                $(".ui.accordion").accordion();
                $(".logoImg").transition("tada");
            });
            $(this).data("name", "show");
            $('#footer').css('margin-left', '300px');
        }
    });

    setTimeout(function(){ 
        let icomoon_checker = document.fonts.check('1em icomoon')
        if(!icomoon_checker) {
            $('head').append(
                `<style type="text/css">
                  @font-face {
                    font-family: 'icomoon';
                    src: url("../../fonts/icomoon.eot?w2rsck");
                    src: url("../../fonts/icomoon.eot?w2rsck#iefix") format("embedded-opentype"), url("../../fonts/icomoon.ttf?w2rsck") format("truetype"), url("../../fonts/icomoon.woff?w2rsck") format("woff"), url("../../fonts/icomoon.svg?w2rsck#icomoon") format("svg");
                    font-weight: normal;
                    font-style: normal;
                  }
                </style>`
            )
        }

        let lato_checker = document.fonts.check('1em Lato')
        if(!lato_checker) {
            $("head").append(
                `<style type="text/css">
                    @font-face {
                        font-family: "Lato";
                        src: local('Lato Regular'), local('Lato-Regular'), url(https://fonts.gstatic.com/s/lato/v14/S6uyw4BMUTPHjxAwXjeu.woff2) format('woff2')
                        unicode-range: U+0100-024F, U+0259, U+1E00-1EFF, U+2020, U+20A0-20AB, U+20AD-20CF, U+2113, U+2C60-2C7F, U+A720-A7FF;
                    }
                    body {
                        font-family: 'Lato', sans-serif !important;
                    }
                </style>`
            );
        }
    }, 1000);

    onmount('#toc', function() {
        $(".ui.accordion").accordion();
    });

    onmount('.mobilenavbar', function() {
        $(".ui.dropdown").dropdown({
            allowCategorySelection: true
        });
        $("#toc").sidebar("attach events", ".launch.button, .view-ui, .launch.item");
    });

    let pgurl = window.location.href;

    $(".sidemenu a.item").each(function() {
        if (pgurl.indexOf($(this).attr("id")) > -1) {
            $(this).addClass("active");
        }
    });
