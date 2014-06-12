/**
 * Created by user on 18/12/13.
 */

jQuery(document).ready(function($){
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').width("100%");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').height("auto");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("ins").width("100%");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("ins").css("display","block");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("ins").height("auto");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("iframe").width("100%");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("iframe").css("display","block");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("iframe").css("position","static");
    //$('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("iframe").height("auto");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("iframe").contents().find("div").width("100%");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("iframe").contents().find("div").height("auto");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("iframe").contents().find("img").attr("width","100%");
    $('div.custom-top-ad').find('div[id*="div-gpt-ad"]').find("iframe").contents().find("img").attr("height","");

});