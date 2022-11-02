import Foundation

// MARK: - RequestMethodWalletRequest
public struct RequestMethodWalletRequest: Decodable {
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
	enum Payload: Decodable {
		case accountAddresses(AccountAddressesRequestMethodWalletRequest)
	}
}

// MARK: RequestMethodWalletRequest.AccountAddressesRequestMethodWalletRequest
public extension RequestMethodWalletRequest {
	struct AccountAddressesRequestMethodWalletRequest: Decodable {
		let requestType: RequestType
		let numberOfAddresses: Int?
	}
}

// MARK: RequestMethodWalletRequest.Metadata
public extension RequestMethodWalletRequest {
	struct Metadata: Decodable {
		let networkId: Int
	}
}
