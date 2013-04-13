For DRY purposes, the template is stored in the global html page, right before
this script. This template string will be sent when a tab requests it upon
loading. The injected script will listen for the templateSent message.

    template = document.getElementById("side-search-tab").innerHTML
    safari.application.addEventListener "message", (event) ->
        if event.name is "requestTemplate"
            event.target.page.dispatchMessage "templateSentBack", template

        if event.name is "requestPage"
            pageRequest = new XMLHttpRequest()
            pageRequest.open "GET", event.message
            pageRequest.send()
            pageRequest.onreadystatechange = ->
                if pageRequest.readyState is 4 and pageRequest.status is 200
                    parsedResponseText = parsePage pageRequest.responseText, event.message
                    safari.application.activeBrowserWindow.activeTab.page.dispatchMessage "pageReturned", parsedResponseText

        if event.name is "popoutPage"
            safari.application.activeBrowserWindow.openTab().url = event.message

Prevent the context menu item from appearing if no text is selected. The
selection can only be sent by the injected script, since this global script has
no notion of tabs.

    safari.application.addEventListener "validate", (event) ->
        if not event.userInfo? or event.userInfo is ""
            event.target.disabled = yes

On search triggering, fetch the google result page, parse the html and get all the links, return the links to

    safari.application.addEventListener "command", (event) ->
        if event.command is "searchKeyword"
            safari.application.activeBrowserWindow.activeTab.page.dispatchMessage "showSearchTab"
            searchResultsRequest = new XMLHttpRequest()
            searchResultsRequest.open "GET", "http://www.google.com/search?q=" + event.userInfo
            searchResultsRequest.send()
            searchResultsRequest.onreadystatechange = ->
                if searchResultsRequest.readyState is 4 and searchResultsRequest.status is 200
                    links = parseSearchPage searchResultsRequest.responseText
                    safari.application.activeBrowserWindow.activeTab.page.dispatchMessage "searchResultReturned", links

Now we parse the returned Google page. We're parsing with `text/sml` because
Safari doesn't support text/html`. We then select the links, whose class is `l`.
It's not sure whether this is ideal, since it might be more future-proof to
extract the `cite` tags and parse them instead (`l` seems really volatile). For
the sake of easiness, we'll settle for the former option for now.

Safari's `parseFromString` doesn't allow text/html. Parsing using text/xml
causes error on Google's page. We'll have to use some dirty hacks here.

    parseSearchPage = (responseText) ->
        documentContent = document.implementation.createHTMLDocument ""
        documentContent.body.innerHTML = responseText
        anchors = documentContent.getElementsByClassName "l"
        links = []
        for anchor in anchors
            links.push anchor.getAttribute "href"
        return links

Some sites use relative URLs, which don't work within an iframe. Add a base URL.
The base URL is formatted like this:

* en.wikipedia.org/ (ends with a /)
* en.wikipedia.org/wiki/test (doesn't end with /)

We grab whatever's after the last slash and discard it.

    parsePage = (responseText, link) ->
        documentContent = document.implementation.createHTMLDocument ""
        documentContent.documentElement.innerHTML = responseText
        baseTag = documentContent.getElementsByTagName("base")[0]
        if not baseTag?
            baseTag = document.createElement "base"
            lastSlashPosition = link.lastIndexOf "/"
            baseURL = link
            if lastSlashPosition isnt -1
                baseURL = link[0..lastSlashPosition]
            baseTag.setAttribute "href", baseURL

            head = documentContent.getElementsByTagName("head")[0]
            head.insertBefore baseTag, head.firstChild
        return documentContent.documentElement.innerHTML






