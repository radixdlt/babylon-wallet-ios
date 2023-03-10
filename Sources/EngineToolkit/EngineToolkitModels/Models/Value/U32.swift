import Foundation

extension UInt32: ValueProtocol, ProxyCodable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .u32
	public func embedValue() -> ManifestASTValue {
		.u32(self)
	}

	public typealias ProxyEncodable = ProxyEncodableInt<Self>
	public typealias ProxyDecodable = ProxyDecodableInt<Self>
}
