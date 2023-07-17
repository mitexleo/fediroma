(function () {
    function registerHandler() {
        try {
            navigator.registerProtocolHandler(
                "web+ap",
                `${window.origin}/.well-known/protocol-handler?target=%s`,
                "Akkoma web+ap handler",
            )
        } catch (e) {
            console.error("Could not register", e)
            window.alert("Sorry, your browser does not support web-based protocol handler registration.")
        }
    }

    document.getElementById("register").addEventListener("click", registerHandler);
}());