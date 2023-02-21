import CryptoKit
import Foundation
import Prelude

// MARK: - HexCodable32Bytes
public struct HexCodable32Bytes: Sendable, Codable, Equatable {
	struct IncorretByteCountError: Swift.Error {
		let got: Int
		let expected: Int
	}

	static let byteCount = 32

	public let data: HexCodable
	public init(_ data: HexCodable) throws {
		guard data.count == Self.byteCount else {
			throw IncorretByteCountError(got: data.count, expected: Self.byteCount)
		}
		self.data = data
	}

	public init(data: Data) throws {
		try self.init(.init(data: data))
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(data.hex())
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let data = try Data(hex: container.decode(String.self))
		try self.init(data: data)
	}
}

public extension EncryptionKey {
	private var symmetric: SymmetricKey {
		.init(data: self.data.data)
	}

	func decrypt(data: Data) throws -> Data {
		try AES.GCM.open(
			AES.GCM.SealedBox(combined: data),
			using: symmetric
		)
	}

	func encrypt(data: Data) throws -> Data {
		try AES.GCM
			.seal(data, using: symmetric)
			.combined!
	}
}

extension ClientMessage {
	func extractRTCPrimitive(_ encryptionKey: EncryptionKey,
	                         decoder: JSONDecoder = JSONDecoder()) throws -> RTCPrimitive
	{
		let data = try encryptionKey.decrypt(data: encryptedPayload.rawValue.data)

		switch method {
		case .offer:
			return .offer(.init(content: try decoder.decode(RTCPrimitive.Offer.self, from: data), id: sourceClientId))
		case .answer:
			return .answer(.init(content: try decoder.decode(RTCPrimitive.Answer.self, from: data), id: sourceClientId))
		case .iceCandidate:
			return .iceCandidate(.init(content: try decoder.decode(RTCPrimitive.ICECandidate.self, from: data), id: sourceClientId))
		case .iceCandidates:
			fatalError()
		}
	}
}
