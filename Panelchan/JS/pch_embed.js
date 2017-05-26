var observeDOM = (function(){
    var MutationObserver = window.MutationObserver || window.WebKitMutationObserver,
    eventListenerSupported = window.addEventListener;

    return function(obj, callback){
        var obs = new MutationObserver(function(mutations, observer){
            callback();
        });
        obs.observe( obj, { childList:true, subtree:true, attributes: true, characterData: true });
    };
})();

var __pch = {
    _prepare_result: function (res) {
        return JSON.stringify(res)
    },

    is_injected: function () {
        return 1
    },

    count_sel: function (sel) {
        return this._prepare_result([Zepto(sel).length])
    },

    click_selector: function (sel) {
        if (Zepto(sel).length > 0) {
            Zepto(sel).click()

            return this._prepare_result([])
        } else {
            return this._prepare_result(null)
        }
    },

    images_bigger_than: function (px) {
        var result = []
        let images = Zepto("img")

        for (key in images) {
            let image = images[key]

            if (image.clientWidth > px || image.clientHeight > px) {
                result.push(image.src)
            }
        }

        return this._prepare_result(result)
    },

    element_at: function (x, y) {
        var element = document.elementFromPoint(x, y)

        return this._prepare_result({
            "tag": element.tagName,
            "class": element.className,
            "id": element.id,
        })
    },
}

/*
Zepto(document).on('ready', function () {
    setTimeout(function () {
        window.open("pch://ready")
    }, 1000)

    observeDOM(document.getElementsByTagName("body")[0], function () {
        setTimeout(function () {
            window.open("pch://mutated")
        }, 1000)
    })
})
*/
