/**
 * Created with IntelliJ IDEA.
 * User: user
 * Date: 10/12/13
 * Time: 9:49 AM
 * To change this template use File | Settings | File Templates.
 */

;
/*
jQuery(document).ready(function($){

   $('.newsfeed ul').hover(function(){

        var imgUrl = $(this).find("li:first-child").css("background-image");

        var hoverUrl = imgUrl.replace("-b","");

        $(this).find("li:first-child").css("background-image",hoverUrl);

    },function(){

        var hoverUrl = $(this).find("li:first-child").css("background-image");

        var imgUrl = hoverUrl.replace(".png","-b.png");

        $(this).find("li:first-child").css("background-image",imgUrl);

    });

    $(window).on('resize',function(){
        $.sidr('close', 'sidr-mobile-menu');
    });

    $('section').find('img').addClass('img-responsive');

    var appVersion = navigator.appVersion;

    var browserVersion = navigator.userAgent;

    var os,browser;

    if(appVersion.indexOf("Macintosh") != -1){

        os = "mac";

    } else if(appVersion.indexOf("Windows") != -1) {

        os = "win";

    }



    if(browserVersion.indexOf("Chrome") != -1){

        browser = "chrome";

    } else if(browserVersion.indexOf("Safari") != -1) {

        browser = "safari";

    } else if(browserVersion.indexOf("Trident") != -1) {

        browser = "ie";

    } else if(browserVersion.indexOf("Firefox") != -1) {

        browser = "firefox";

    }

    $('html').addClass(os);

    $('html').addClass(browser);

    if((window.location.href.indexOf("http://www.rebonline.com.au/rankings/7298-top-50-sales-offices-2014") != -1) || (window.location.href.indexOf("http://www.rebonline.com.au/top-50-sales-offices-2014") != -1)){
        var options1 = {
            additionalFilterTriggers: [$('#onlyyes'), $('#onlyno'), $('#quickfind')],
            clearFiltersControls: [$('#cleanfilters')],
            matchingRow: function(state, tr, textTokens) {
                if (!state || !state.id) {
                    return true;
                }
                var child = tr.children('td:eq(2)');
                if (!child) return true;
                var val = child.text();
                switch (state.id) {
                    case 'onlyyes':
                        return state.value !== true || val === 'yes';
                    case 'onlyno':
                        return state.value !== true || val === 'no';
                    default:
                        return true;
                }
            }
        };
        // Initialise Plugin
        $('#demotable1').tableFilter(options1);

    }
});
*/

/*
jQuery.fn.liScroll = function(settings) {
    settings = jQuery.extend({
        travelocity: 0.07
    }, settings);
    return this.each(function(){
        var $strip = jQuery(this);
        $strip.addClass("newsticker")
        var stripWidth = 1;
        $strip.find("li").each(function(i){
            stripWidth += jQuery(this, i).outerWidth(true); // thanks to Michael Haszprunar and Fabien Volpi
        });
        var $mask = $strip.wrap("<div class='mask'></div>");
        var $tickercontainer = $strip.parent().wrap("<div class='tickercontainer'></div>");
        var containerWidth = $strip.parent().parent().width();	//a.k.a. 'mask' width
        $strip.width(stripWidth);
        var totalTravel = stripWidth+containerWidth;
        var defTiming = totalTravel/settings.travelocity;	// thanks to Scott Waye
        function scrollnews(spazio, tempo){
            $strip.animate({left: '-='+ spazio}, tempo, "linear", function(){$strip.css("left", containerWidth); scrollnews(totalTravel, defTiming);});
        }
        scrollnews(totalTravel, defTiming);
        $strip.hover(function(){
                jQuery(this).stop();
            },
            function(){
                var offset = jQuery(this).offset();
                var residualSpace = offset.left + stripWidth;
                var residualTime = residualSpace/settings.travelocity;
                scrollnews(residualSpace, residualTime);
            });
    });
};


*/
