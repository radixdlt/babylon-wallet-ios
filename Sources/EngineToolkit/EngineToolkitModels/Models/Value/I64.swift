import Foundation

extension Int64: ValueProtocol, ProxyCodable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .i64
	public func embedValue() -> ManifestASTValue {
		.i64(self)
	}

	public typealias ProxyEncodable = ProxyEncodableInt<Self>
	public typealias ProxyDecodable = ProxyDecodableInt<Self>
}
