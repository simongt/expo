// Copyright 2025-present 650 Industries. All rights reserved.

/// A protocol for types that can be created from a JavaScript value without type erasure.
///
/// `decode` returns the concrete `Self` directly, so the macro-synthesized bindings that call it
/// never box the value as `Any` or cast it back with `as!`. It is the JS → native half of
/// `JavaScriptCodable`.
///
/// The conversion runs on the JavaScript thread; conformers are called under `@JavaScriptActor`.
/// The `value` and `runtime` are `borrowing` because the conversions only read them; borrowing the
/// reference-typed `JavaScriptValue` also avoids a retain/release on every decode. A conversion that
/// needs to store or escape the runtime makes an owned copy with `copy runtime`.
public protocol JavaScriptDecodable {
  /// Decodes an owning `JavaScriptValue` into `Self`.
  ///
  /// This overload is the protocol requirement: every conformer provides it. It is also the
  /// correct entry point for any value that must outlive the call (stored, captured, handed to a
  /// `Promise`).
  @JavaScriptActor
  static func decode(_ value: borrowing JavaScriptValue, in runtime: borrowing JavaScriptRuntime) throws -> Self

  /// Decodes a non-owning `JavaScriptUnownedValue` into `Self` without copying the underlying
  /// `jsi::Value`.
  ///
  /// This is the argument-decode fast path: the value borrows the argument the
  /// `JavaScriptValuesBuffer` already owns for the duration of the call. It is defaulted (see the
  /// extension below), so conformers get it for free by materializing an owning value; types that
  /// can read straight from the borrowed value override it to stay zero-copy.
  @JavaScriptActor
  static func decode(_ value: borrowing JavaScriptUnownedValue, in runtime: borrowing JavaScriptRuntime) throws -> Self

  /// Returns whether the JavaScript type of `value` is one `decode` can accept, from type checks alone.
  ///
  /// A `false` is definitive: `decode` would throw for this value. A `true` only means the type
  /// matches, so `decode` may still throw, for example for an out-of-range number or a missing record
  /// field. Code that picks between several types, like a union, calls it to skip the ones that can't
  /// match without paying for a thrown error. Defaults to `true`.
  @JavaScriptActor
  static func canDecode(_ value: borrowing JavaScriptValue) -> Bool

  /// The `JavaScriptUnownedValue` overload of `canDecode(_:)`.
  @JavaScriptActor
  static func canDecode(_ value: borrowing JavaScriptUnownedValue) -> Bool
}

extension JavaScriptDecodable {
  /// Default fast-path implementation: materialize an owning value and forward to the requirement.
  /// This is the "explicitly copy" behavior for types that cannot (or need not) read directly from
  /// the borrowed value.
  ///
  /// `@inlinable` so the default specializes into the user module across the resilient
  /// (library-evolution) boundary instead of dispatching through the prebuilt binary.
  @JavaScriptActor
  @inlinable
  public static func decode(_ value: borrowing JavaScriptUnownedValue, in runtime: borrowing JavaScriptRuntime) throws
    -> Self
  {
    return try decode(value.copied(in: runtime), in: runtime)
  }

  /// Default: accepts every value, so a conformer that doesn't override it is always tried.
  @JavaScriptActor
  @inlinable
  public static func canDecode(_ value: borrowing JavaScriptValue) -> Bool {
    return true
  }

  @JavaScriptActor
  @inlinable
  public static func canDecode(_ value: borrowing JavaScriptUnownedValue) -> Bool {
    return true
  }
}
