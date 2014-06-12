jQuery(document).ready(function($){
    var mode;
    if(getURLParam('mode') == 'test') {
        $('.test').addClass('no-test');
        $('.no-test').removeClass('test');
        mode = 'test';
    }


    shortcut.add("Ctrl+Alt+T",function() {
        var url = window.location.href;

        if(mode == 'test') {
            mode = false;
        }else {
            mode = 'test'
        }
        var gotoURL = window.location.href.split('?');
        window.location.href = gotoURL[0]+"?"+putParam('mode',mode);
    });

    function getURLParam(variable) {
        var query = window.location.search.substring(1);
        var vars = query.split('&');
        for (var i = 0; i < vars.length; i++) {
            var pair = vars[i].split('=');
            if (decodeURIComponent(pair[0]) == variable) {
                return decodeURIComponent(pair[1]);
            }
        }
        return false;
    }
    function putParam(variable,value) {
        var query = window.location.search.substring(1);
        var vars = query.split('&');
        var paramFound = false;
        var pairDeleted = false;
        var pair = [];
        for (var i = 0; i < vars.length; i++) {
            pair[i] = vars[i].split('=');
            if (decodeURIComponent(pair[i][0]) == variable) {
                if(value !== false){
                    pair[i][1] = encodeURIComponent(value);
                } else {
                    delete pair[i];
                    pairDeleted = true;
                }
                paramFound = true;
            }
            if(!pairDeleted){
                pair[i] = pair[i].join('=');
            }
        }
        if(paramFound){
            console.log(pair);
           return pair.join('&');
        }else {
           return query+'&'+variable+"="+value;
        }
    }
});