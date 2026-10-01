// Copyright 2026-present 650 Industries. All rights reserved.

import ExpoModulesJSI
import Testing

@testable import ExpoModulesCore

/// `canDecode` of the core types that decode only from a JavaScript object. A rejection must be
/// definitive, because a union skips the case without trying to decode it.
@Suite("JavaScriptDecodable.canDecode in core")
@JavaScriptActor
struct JavaScriptCodableCanDecodeTests {
  let appContext = AppContext.create()

  static let samples = ["42", "'text'", "true", "null", "undefined", "10n", "({})", "new Uint8Array(1)"]
  static let objects: Set<String> = ["({})", "new Uint8Array(1)"]

  private func expectAcceptsOnlyObjects<T: JavaScriptDecodable>(
    _ type: T.Type,
    sourceLocation: SourceLocation = #_sourceLocation
  ) throws {
    let runtime = try appContext.runtime
    for source in Self.samples {
      let value = try runtime.eval(source)
      let expected = Self.objects.contains(source)
      #expect(T.canDecode(value) == expected, "owning \(source)", sourceLocation: sourceLocation)

      let buffer = JavaScriptValuesBuffer.copying(in: runtime, values: [value])
      let unownedResult = T.canDecode(buffer.unownedValue(at: 0))
      #expect(unownedResult == expected, "unowned \(source)", sourceLocation: sourceLocation)

      if !expected {
        #expect(throws: (any Error).self, "decode \(source)", sourceLocation: sourceLocation) {
          _ = try T.decode(value, in: runtime)
        }
      }
    }
  }

  @Test
  func `ArrayBuffer accepts only objects`() throws {
    try expectAcceptsOnlyObjects(ArrayBuffer.self)
  }

  @Test
  func `typed arrays accept only objects`() throws {
    try expectAcceptsOnlyObjects(Uint8Array.self)
  }

  @Test
  func `records accept only objects`() throws {
    try expectAcceptsOnlyObjects(CodablePoint.self)
  }

  @Test
  func `shared objects accept only objects`() throws {
    try expectAcceptsOnlyObjects(CanDecodeSharedObject.self)
  }
}

private final class CanDecodeSharedObject: SharedObject {}
