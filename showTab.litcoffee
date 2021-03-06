This event triggers before the context menu opens. It sends the selected text to
the global script. The latter checks whether the selection (`event.userInfo`) is
empty.

    document.addEventListener "contextmenu", (event) ->
        safari.self.tab.setContextMenuEventUserInfo event, window.getSelection().toString().trim()


Script is injected once per window/iframe. Need to ignore iframes.

    if window.top is window

Initially, request the template string.

        template = ""
        links = []
        currentPageIndex = 0
        prevButton = null
        nextButton = null
        popoutButton = null
        closeButton = null
        safari.self.addEventListener "message", (event) ->
            switch event.name
                when "templateSentBack"
                    template = event.message
                    tab = document.createElement "div"
                    tab.setAttribute "id", "side-search-tab"
                    tab.innerHTML = template
                    document.getElementsByTagName("body")[0].appendChild tab

Prevent scrolling outside area inside the tab

                    tab.addEventListener "mouseover", ->
                        document.body.style.overflow = "hidden"
                    tab.addEventListener "mouseout", ->
                        document.body.style.overflow = "auto"

                    prevButton = document.getElementById "side-search-button-prev"
                    nextButton = document.getElementById "side-search-button-next"
                    popoutButton = document.getElementById "side-search-button-popout"
                    closeButton = document.getElementById "side-search-button-close"

                    activateNavigationButtons()

                when "showSearchTab"
                    sideSearchTab = document.getElementById("side-search-tab")
                    sideSearchTab.style.visibility = "visible"
                    sideSearchTab.style.webkitTransform = "translate3d(-600px, 0, 0)"

Using ajax to get another domain's content is only allowed by the global script.
It loads the search result page, parses it and returns an array of links. Here,
we then specify which link page we want to fetch.

                when "searchResultReturned"
                    links = event.message
                    if links.length is 0 or links.length is 1
                        disable prevButton
                        disable nextButton
                    if links.length is 0
                        disable popoutButton
                        displayNoSearchResult()
                    safari.self.tab.dispatchMessage "requestPage", links[0]

                when "pageReturned"
                    iframeContent = document.getElementById("side-search-tab-content").contentWindow.document
                    iframeContent.open()
                    iframeContent.close()
                    iframeContent.open()
                    iframeContent.write event.message
                    iframeContent.close()

        activateNavigationButtons = ->
            prevButton.addEventListener "click", (e) ->
                enable nextButton
                if currentPageIndex > 0
                    currentPageIndex--
                    safari.self.tab.dispatchMessage "requestPage", links[currentPageIndex]
                else
                    disable e.target

            nextButton.addEventListener "click", (e) ->
                enable prevButton
                if currentPageIndex < links.length - 1
                    currentPageIndex++
                    safari.self.tab.dispatchMessage "requestPage", links[currentPageIndex]
                else
                    disable e.target

            popoutButton.addEventListener "click", (e) ->
                safari.self.tab.dispatchMessage "popoutPage", links[currentPageIndex]

            closeButton.addEventListener "click", (e) ->
                sideSearchTab = document.getElementById("side-search-tab")
                sideSearchTab.style.webkitTransform = "translate3d(0, 0, 0)"

            return

Order of addition/removal might be important here to avoid flickering.

        disable = (button) ->
            button.classList.remove "disabled"
            button.classList.add "disabled"
            button.classList.remove "enabled"
        enable = (button) ->
            button.classList.remove "enabled"
            button.classList.add "enabled"
            button.classList.remove "disabled"

        displayNoSearchResult = ->
            noResultText = document.getElementById "side-search-tab-noResult"
            # noResultText.setAttribute "visibility", "visible"


        safari.self.tab.dispatchMessage "requestTemplate"









