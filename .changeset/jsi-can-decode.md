---
'expo-modules-jsi': patch
'expo-modules-core': patch
---

[iOS] Add `canDecode(_:)` to `JavaScriptDecodable`: a check of the JavaScript value's type that tells whether `decode` can accept it, without throwing. Primitives, optionals, arrays, dictionaries, `Data`, `Date`, `ArrayBuffer`, typed arrays, records and shared objects implement it; other types accept every value.
