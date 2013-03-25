For DRY purposes, the template is stored in the global html page, right before
this script. This template string will be sent when a tab requests it upon
loading. The injected script will listen for the templateSent message.

    template = document.getElementById("side-search-tab").innerHTML
    safari.application.addEventListener "message", (event) ->
        if event.name is "requestTemplate"
            event.target.page.dispatchMessage "templateSentBack", template

Prevent the context menu item from appear if no text is selected. The selection
can only be sent by the injected script, since this global script has no notion
of tabs.

    safari.application.addEventListener "validate", (event) ->
        if event.userInfo is ""
            event.target.disabled = yes

    safari.application.addEventListener "command", (event) ->
        if event.command is "searchKeyword"
            safari.application.activeBrowserWindow.activeTab.page.dispatchMessage "showSearchTab"
            xmlhttp = new XMLHttpRequest()
            xmlhttp.onreadystatechange = ->
                if xmlhttp.readyState is 4 and xmlhttp.status is 200
                    safari.application.activeBrowserWindow.activeTab.page.dispatchMessage "searchResultReturned", xmlhttp.responseText
            xmlhttp.open "GET", "http://www.google.com/search?q=test"
            xmlhttp.send()
