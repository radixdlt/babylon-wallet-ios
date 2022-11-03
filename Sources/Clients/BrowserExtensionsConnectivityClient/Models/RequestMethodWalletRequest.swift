import Foundation

// MARK: - RequestMethodWalletRequest
public struct RequestMethodWalletRequest: Sendable, Equatable, Decodable {
	public typealias RequestID = String
	public let method: RequestMethod
	public let requestId: RequestID
	public let payloads: [Payload]
	public let metadata: Metadata

	enum CodingKeys: String, CodingKey {
		case method, requestId, metadata
		case payloads = "payload"
	}

	public init(
		method: RequestMethod,
		requestId: RequestID,
		payloads: [Payload],
		metadata: Metadata
	) {
		self.method = method
		self.requestId = requestId
		self.payloads = payloads
		self.metadata = metadata
	}
}

// MARK: RequestMethodWalletRequest.Payload
public extension RequestMethodWalletRequest {
	enum Payload: Sendable, Equatable, Decodable {
		case accountAddresses(AccountAddressesRequestMethodWalletRequest)

		enum CodingKeys: String, CodingKey {
			case requestType
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let discriminator = try container.decode(RequestType.self, forKey: .requestType)
			switch discriminator {
			case .accountAddresses:
				self = try .accountAddresses(.init(from: decoder))
			}
		}
	}
}

// MARK: RequestMethodWalletRequest.AccountAddressesRequestMethodWalletRequest
public extension RequestMethodWalletRequest {
	struct AccountAddressesRequestMethodWalletRequest: Sendable, Equatable, Decodable {
		public let requestType: RequestType
		public let numberOfAddresses: Int?
		public init(requestType: RequestType, numberOfAddresses: Int?) {
			self.requestType = requestType
			self.numberOfAddresses = numberOfAddresses
		}
	}
}

// MARK: RequestMethodWalletRequest.Metadata
public extension RequestMethodWalletRequest {
	struct Metadata: Sendable, Equatable, Decodable {
		public let networkId: Int
		public let dAppId: String?
		public init(networkId: Int, dAppId: String?) {
			self.networkId = networkId
			self.dAppId = dAppId
		}
	}
}
