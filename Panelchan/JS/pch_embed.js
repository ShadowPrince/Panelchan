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

    location: function () {
        return this._prepare_result([window.location.href])
    },

    count_sel: function (sel) {
        return this._prepare_result([Zepto(sel).length])
    },

    click_selector: function (sel, innerText) {
        var collection = Zepto(sel).filter(function () { 
            return innerText == "" ? true : this.innerText == innerText
        })

        if (collection.length > 0) {
            Zepto(collection).first().click()

            return this._prepare_result([])
        } else {
            return this._prepare_result(null)
        }
    },

    images_bigger_than: function (px) {
        var result = []
        let images = Zepto("img").filter(function () {
            var elem = Zepto(this)
            return !!(this.width || this.height) && elem.css("display") !== "none" && elem.position().top >= 0 && elem.position().left >= 0
        })

        for (key in images) {
            let image = images[key]

            if (image.width > px && image.height > px) {
                result.push(image.src)
            }
        }

        unique_result = result.filter(function(item, pos) {
            return result.indexOf(item) == pos;
        })

        return this._prepare_result(unique_result)
    },

    element_at: function (x, y) {
        var element = document.elementFromPoint(x, y)

        return this._prepare_result({
            "tag": element.tagName,
            "class": element.className,
            "id": element.id,
            "text": element.text,
            "title": element.title
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
