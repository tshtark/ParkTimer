# Swift Conventions for ParkTimer

Tal has zero Swift experience. Claude writes all code. These rules ensure consistency.

## Code Style

1. **SwiftUI views are structs** — never classes. Views are lightweight value types.
2. **`@Observable` for shared state** — ParkingEngine, SessionStore, StoreManager. Not `ObservableObject` (that's the old pattern).
3. **Prefer `struct` over `class`** — unless you need reference semantics (shared mutable state).
4. **Use `let` by default** — only `var` when mutation is needed.
5. **No force unwraps (`!`)** — use `guard let`, `if let`, or nil coalescing (`??`).
6. **No `Any` or `AnyObject`** — use generics or protocols.

## File Organization

7. **One major type per file** — small related types (e.g., an enum used only by one struct) can share a file.
8. **File name matches primary type** — `ParkingEngine.swift` contains `class ParkingEngine`.
9. **Extensions go in the same file** unless they're for protocol conformance that adds significant code.

## SwiftUI Patterns

10. **Extract subviews when a body exceeds ~40 lines** — use computed properties or separate structs.
11. **`#Preview` macro at bottom of every view file** — for Xcode previews.
12. **Navigation via `NavigationStack`** — not the deprecated `NavigationView`.
13. **Environment and state injection via `@Environment` and `@State`** — minimize prop drilling.

## Error Handling

14. **`try` with proper `do/catch`** — never `try!` or `try?` unless the failure is genuinely impossible or ignorable.
15. **`return await` inside try/catch** — same rule as Nexus. `return promise` without `await` bypasses catch.

## Build System

16. **After creating/moving/deleting Swift files** — always run `xcodegen generate` before building.
17. **Verify builds after changes** — run the build command from CLAUDE.md.
