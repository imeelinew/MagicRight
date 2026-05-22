import AppKit
import SwiftUI

@MainActor
final class MagicRightWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?

    func show() {
        if let window {
            NSApp.setActivationPolicy(.regular)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: MagicRightView())
        let win = NSWindow(contentViewController: hosting)
        win.title = "MagicRight"
        win.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        win.isReleasedWhenClosed = false
        win.setContentSize(NSSize(width: 680, height: 520))
        win.minSize = NSSize(width: 620, height: 460)
        win.center()
        win.delegate = self
        window = win

        NSApp.setActivationPolicy(.regular)
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
