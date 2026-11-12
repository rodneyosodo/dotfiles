// Hokum runs notify(n) for every notification before it shows.
// Return n (changed or not) to show it, or false to drop it.
//
// n.app, n.summary, n.body, n.context: text
// n.urgency: 0 low, 1 normal, 2 critical
// n.value: 0.0 to 1.0 for a progress bar, or () for none
// n.timeout: seconds to stay, 0 to stay until dismissed, () for the default
// n.template: a template from your theme to draw it with, or () for the theme's choice
// n.actions: [#{ key: "reply", label: "Reply" }, ...]

fn notify(n) {
    // Examples:
    // if n.app == "Spotify" { return false; }
    // if n.body.contains("failed") { n.urgency = 2; }
    // if n.app == "Slack" && n.context == "#random" { n.timeout = 3; }
    n
}
