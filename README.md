# Swexy
Swift, but Sexy.

## Motivation
Swift Foundation leaves a lot to be desired. You often have to write tons and tons of boilerplate, and don't get me started on the Codable system.

Swexy includes common extension patterns I find myself writing across projects, and I hope others can find value in them.

## Current Extensions
- KeyPath-based reducing into dictionaries, with support for compactMap-style omission of optional keys/values (`[(abc: 123, def: "ghi")].dictionary(keyedBy: \.def, valuedBy: \.abc)`)
- Sorting an array by a KeyPath (`[Person].sorted(usingKey: .age, by: >)`, `[Person].sorted(usingKey: .age, withDefaultValue: 0, by: >`)
- Flatten a collection of collections into an array of its elements (`Collection.flatten()`)
- [Anonymous Coding](#anonymous-coding)

## Anonymous Coding
Sometimes – no, not sometimes, many times – you run into data structures that either cannot be made codable because they reside in another module, or require significant boilerplate to write codable conformance for.

Swexy adds two new methods:

```swift
public extension JSONEncoder {
    func encode(_ cb: @escaping (Encoder) throws -> ()) throws -> Data
}
```

```swift
public extension JSONDecoder {
    func decode<P>(data: Data, _ cb: @escaping (Decoder) throws -> P) throws -> P
}
```

These allow you to quickly encode and decode datatypes without hacking in extensions. For instance, you cannot conform an external structure to a protocol, so making it codable requires some wrappers that get a bit hairy.

Here's an example:

> Somewhere in another module
```swift
struct MyArbitraryUncodableStruct {
    let aBool: Bool
    let aInt: Int
}
```

> Your code
```swift
let instance = MyArbitraryUncodableStruct(aBool: true, aInt: 54)

enum UncodableCodingKeys: CodingKey {
    case aBool, aInt
}
    
let data = try JSONEncoder().encode { encoder in
    var container = encoder.container(keyedBy: UncodableCodingKeys.self)
    
    try container.encode(instance.aBool, forKey: .aBool)
    try container.encode(instance.aInt, forKey: .aInt)
}

let parsed = try JSONDecoder().decode(data: data) { decoder -> MyArbitraryUncodableStruct in
    let container = try decoder.container(keyedBy: UncodableCodingKeys.self)
    
    return MyArbitraryUncodableStruct(
        aBool: try container.decode(Bool.self, forKey: .aBool),
        aInt: try container.decode(Int.self, forKey: .aInt)
    )
}

print(data)
print(String(decoding: data, as: UTF8.self))
print(parsed.aBool)
print(parsed.aInt)
```

It should be noted that this should be avoided wherever possible, but I personally prefer it over writing messy coding systems for things like associated-value enums.
