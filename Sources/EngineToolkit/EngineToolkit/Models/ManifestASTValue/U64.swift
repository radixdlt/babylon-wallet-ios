import Foundation

extension UInt64: ValueProtocol, ProxyCodable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .u64
	public func embedValue() -> ManifestASTValue {
		.u64(self)
	}

	public typealias ProxyEncodable = ProxyEncodableInt<Self>
	public typealias ProxyDecodable = ProxyDecodableInt<Self>
}
