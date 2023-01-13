import Foundation

// MARK: - EncodableProxy
public protocol EncodableProxy: Encodable {
	associatedtype ToEncode: Encodable
	var toEncode: ToEncode { get }
	init(toEncode: ToEncode)
}

// MARK: - DecodableProxy
public protocol DecodableProxy: Decodable {
	associatedtype Decoded: Decodable
	var decoded: Decoded { get }
}

// MARK: - ProxyCodable
public protocol ProxyCodable: Codable where ProxyEncodable.ToEncode == Self, ProxyDecodable.Decoded == Self {
	associatedtype ProxyEncodable: EncodableProxy
	associatedtype ProxyDecodable: DecodableProxy
	var proxyEncodable: ProxyEncodable { get }
	init(decodedProxy: ProxyDecodable)
}

public extension ProxyCodable {
	var proxyEncodable: ProxyEncodable { .init(toEncode: self) }

	init(decodedProxy: ProxyDecodable) {
		self = decodedProxy.decoded
	}
}
