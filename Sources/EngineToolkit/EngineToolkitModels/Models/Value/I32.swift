import Foundation

extension Int32: ValueProtocol, ProxyCodable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .i32
	public func embedValue() -> ManifestASTValue {
		.i32(self)
	}

	public typealias ProxyEncodable = ProxyEncodableInt<Self>
	public typealias ProxyDecodable = ProxyDecodableInt<Self>
}
