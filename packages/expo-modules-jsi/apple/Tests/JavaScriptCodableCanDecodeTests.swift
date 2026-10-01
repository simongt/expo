// Copyright 2026-present 650 Industries. All rights reserved.

import ExpoModulesJSI
import Foundation
import Testing

@Suite("JavaScriptDecodable.canDecode")
@JavaScriptActor
struct JavaScriptCodableCanDecodeTests {
  let runtime = JavaScriptRuntime()

  /// One sample value of each JS type, keyed by the source that evaluates to it.
  static let samples = [
    "42", "1.5", "'text'", "true", "null", "undefined", "10n", "({})", "[1]", "new Uint8Array(1)",
  ]

  /// Checks that `canDecode` accepts exactly the `accepted` samples, for both the owning and the
  /// unowned value, and that `decode` throws for every rejected one. A rejection must be definitive,
  /// because a union skips the case without trying to decode it.
  private func expectCanDecode<T: JavaScriptDecodable>(
    _ type: T.Type,
    accepts accepted: Set<String>,
    sourceLocation: SourceLocation = #_sourceLocation
  ) throws {
    for source in Self.samples {
      let value = try runtime.eval(source)
      let expected = accepted.contains(source)
      #expect(T.canDecode(value) == expected, "owning \(source)", sourceLocation: sourceLocation)

      let buffer = JavaScriptValuesBuffer.allocate(in: runtime, with: value)
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
  func `Bool accepts only booleans`() throws {
    try expectCanDecode(Bool.self, accepts: ["true"])
  }

  @Test
  func `String accepts only strings`() throws {
    try expectCanDecode(String.self, accepts: ["'text'"])
  }

  @Test
  func `floating-point types accept only numbers`() throws {
    try expectCanDecode(Double.self, accepts: ["42", "1.5"])
    try expectCanDecode(Float.self, accepts: ["42", "1.5"])
    try expectCanDecode(CGFloat.self, accepts: ["42", "1.5"])
  }

  @Test
  func `narrow integer types accept only numbers`() throws {
    try expectCanDecode(Int8.self, accepts: ["42", "1.5"])
    try expectCanDecode(Int16.self, accepts: ["42", "1.5"])
    try expectCanDecode(Int32.self, accepts: ["42", "1.5"])
    try expectCanDecode(UInt8.self, accepts: ["42", "1.5"])
    try expectCanDecode(UInt16.self, accepts: ["42", "1.5"])
    try expectCanDecode(UInt32.self, accepts: ["42", "1.5"])
  }

  @Test
  func `64-bit integer types accept numbers and bigints`() throws {
    try expectCanDecode(Int.self, accepts: ["42", "1.5", "10n"])
    try expectCanDecode(Int64.self, accepts: ["42", "1.5", "10n"])
    try expectCanDecode(UInt.self, accepts: ["42", "1.5", "10n"])
    try expectCanDecode(UInt64.self, accepts: ["42", "1.5", "10n"])
  }

  @Test
  func `Optional accepts null, undefined and what the wrapped type accepts`() throws {
    try expectCanDecode(String?.self, accepts: ["'text'", "null", "undefined"])
  }

  @Test
  func `Array accepts objects and what the element type accepts`() throws {
    // A non-array value is decoded as a single-element array.
    try expectCanDecode([String].self, accepts: ["'text'", "({})", "[1]", "new Uint8Array(1)"])
  }

  @Test
  func `Dictionary accepts only objects`() throws {
    try expectCanDecode([String: Int].self, accepts: ["({})", "[1]", "new Uint8Array(1)"])
  }

  @Test
  func `Data accepts only objects`() throws {
    try expectCanDecode(Data.self, accepts: ["({})", "[1]", "new Uint8Array(1)"])
  }

  @Test
  func `Date accepts numbers, strings and objects`() throws {
    try expectCanDecode(Date.self, accepts: ["42", "1.5", "'text'", "({})", "[1]", "new Uint8Array(1)"])
  }

  @Test
  func `JavaScriptValue accepts every value`() throws {
    try expectCanDecode(JavaScriptValue.self, accepts: Set(Self.samples))
  }
}
