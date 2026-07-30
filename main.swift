// StorageBar — the storage section on its own, as its own menu bar app.
//
// The section itself is in StorageSection.swift, and it is the same file MacBar
// compiles in when it puts several sections behind one menu bar item. This entry
// point exists so the section can be built and tried out by itself.

import AppKit

Host.run(sections: [StorageSection()])
