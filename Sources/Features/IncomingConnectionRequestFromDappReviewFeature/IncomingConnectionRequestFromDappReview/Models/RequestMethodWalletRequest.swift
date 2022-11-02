import Foundation

// MARK: - RequestMethodWalletRequest
public struct RequestMethodWalletRequest: Sendable, Equatable, Decodable {
	public let method: RequestMethod
	public let requestId: String
	public let payload: [Payload]
	public let metadata: Metadata

	public init(
		method: RequestMethod,
		requestId: String,
		payload: [Payload],
		metadata: Metadata
	) {
		self.method = method
		self.requestId = requestId
		self.payload = payload
		self.metadata = metadata
	}
}

// MARK: RequestMethodWalletRequest.Payload
public extension RequestMethodWalletRequest {
	enum Payload: Sendable, Equatable, Decodable {
		case accountAddresses(AccountAddressesRequestMethodWalletRequest)
	}
}

// MARK: RequestMethodWalletRequest.AccountAddressesRequestMethodWalletRequest
public extension RequestMethodWalletRequest {
	struct AccountAddressesRequestMethodWalletRequest: Sendable, Equatable, Decodable {
		let requestType: RequestType
		let numberOfAddresses: Int?
	}
}

// MARK: RequestMethodWalletRequest.Metadata
public extension RequestMethodWalletRequest {
	struct Metadata: Sendable, Equatable, Decodable {
		let networkId: Int
	}
}
