import ClientPrelude

// MARK: - ImageServiceClient
public struct ImageServiceClient: Sendable {
	public var fixedSize: FixedSize

	public init(
		fixedSize: @escaping FixedSize
	) {
		self.fixedSize = fixedSize
	}
}

// MARK: ImageServiceClient.FixedSize
extension ImageServiceClient {
	public typealias FixedSize = @Sendable (URL, CGSize) -> URL
}
