This event triggers before the context menu opens. It sends the selected text to
the global script. The latter checks whether the selection (`event.userInfo`) is
empty.

    onContextmenu = (event) ->
        safari.self.tab.setContextMenuEventUserInfo event, window.getSelection().toString().trim()

    document.addEventListener "contextmenu", onContextmenu

Script is injected once per window/iframe. Need to ignore iframes.

    if window.top is window

Initially, request the template string.

        template = ""
        safari.self.addEventListener "message", (event) ->
            switch event.name
                when "templateSentBack"
                    template = event.message
                    tab = document.createElement "div"
                    tab.setAttribute "id", "side-search-tab"
                    tab.innerHTML = template
                    document.getElementsByTagName("body")[0].appendChild tab
                when "showSearchTab"
                    sideSearchTab = document.getElementById("side-search-tab")
                    sideSearchTab.style.visibility = "visible"
                    sideSearchTab.style.webkitTransform = "translate3d(-500px, 0, 0)"
                when "searchResultReturned"
                    document.getElementById("side-search-tab-content").innerHTML = event.message

        safari.self.tab.dispatchMessage "requestTemplate"
