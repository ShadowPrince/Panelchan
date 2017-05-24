
var __pch = {
    _prepare_result: function (res) {
        return JSON.stringify(res)
    },

    is_injected: function () {
        return 1
    },

    click_selector: function (sel) {
        Zepto(sel).click()
    },

    images_bigger_than: function (px) {
        var result = []
        let images = Zepto("img")

        for (key in images) {
            let image = images[key]

            if (image.clientWidth > px || image.clientHeight > px) {
                result.push(image)
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
