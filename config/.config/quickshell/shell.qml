// Quickshell desktop shell. Replaces waybar.
// Run with `qs`, or `qs -p ~/.config/quickshell` to target this config explicitly.

import Quickshell

ShellRoot {
    // One bar per connected monitor.
    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
