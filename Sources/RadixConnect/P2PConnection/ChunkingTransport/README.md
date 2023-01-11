# ChunkingTransport
WebrTC has a limitation on how large messages can be sent over P2P. For [information about this limit see this article][limit].

We have interpreted the article as if the limit is 16 KB. That is for a whole message, but we decorate each message with metadata, thus we define the limit to be `15441` bytes.

When embedded into a `ChunkedMessageChunkPackage`

```swift
let chunkLimit = 10
let chunks = 2
let longMessage = Data(repeating: 0xab, count: chunkLimit * chunks) // abababababababababababababababababababab
let splitter = MessageSplitter.live(messageSizeChunkLimit: chunkLimit)
let assember = ChunkedMessagePackageAssembler.live()
let packages = try splitter.split(longMessage, "<Unique Msg ID goes here>")
let reassembled = try assember.assemble(packages: packages)
XCTAssertEqual(reassembled, longMessage)
```

And if we print `packages` above, we get:
```swift
{
	"messageId" : "<Unique Msg ID goes here>",
	"hashOfMessage" : "4844a34d8cec095f6eff24651f335fa163e5049a1722dfb6aa7159aab461eaf6",
	"chunkCount" : 2,
	"messageByteCount" : 20,
	"packageType" : "metaData"
}
{
	"messageId" : "<Unique Msg ID goes here>",
	"chunkIndex" : 0,
	"packageType" : "chunk",
	"chunkData" : "q6urq6urq6urqw=="
}
{
	"messageId" : "<Unique Msg ID goes here>",
	"chunkIndex" : 1,
	"packageType" : "chunk",
	"chunkData" : "q6urq6urq6urqw=="
}
```

In this example it is the JSON encoded size of a package of type `chunk` which is not allowed to exceed 16 kb, thus it is the size of the `chunkData` which is not allowed to exceed `15441` bytes.

[limit]: https://lgrahl.de/articles/demystifying-webrtc-dc-size-limit.html