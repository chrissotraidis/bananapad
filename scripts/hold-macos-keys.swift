#!/usr/bin/env swift

import CoreGraphics
import Foundation

let keyCodes: [String: CGKeyCode] = [
    "a": 0, "s": 1, "d": 2, "z": 6, "x": 7, "q": 12, "w": 13,
    "e": 14, "j": 38, "k": 40, "l": 37, "i": 34, "return": 36,
    "shift": 56, "left": 123, "right": 124, "down": 125, "up": 126,
]

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("hold-macos-keys: \(message)\n".utf8))
    exit(2)
}

guard CommandLine.arguments.count >= 3 else {
    fail("usage: hold-macos-keys MILLISECONDS KEY [KEY ...]")
}
guard let milliseconds = UInt32(CommandLine.arguments[1]), milliseconds > 0 else {
    fail("duration must be a positive number of milliseconds")
}

let names = Array(CommandLine.arguments.dropFirst(2))
let codes = names.map { name -> CGKeyCode in
    guard let code = keyCodes[name.lowercased()] else {
        fail("unknown key '\(name)'")
    }
    return code
}

guard let source = CGEventSource(stateID: .hidSystemState) else {
    fail("could not create HID event source")
}

for code in codes {
    guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true) else {
        fail("could not create key-down event")
    }
    event.post(tap: .cghidEventTap)
}

usleep(milliseconds * 1_000)

for code in codes.reversed() {
    guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false) else {
        fail("could not create key-up event")
    }
    event.post(tap: .cghidEventTap)
}
