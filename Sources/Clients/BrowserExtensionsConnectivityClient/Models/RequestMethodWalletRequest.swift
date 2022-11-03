import Foundation

// MARK: - RequestMethodWalletRequest
public struct RequestMethodWalletRequest: Sendable, Equatable, Decodable {
	public typealias RequestID = String
	public let method: RequestMethod
	public let requestId: RequestID
	public let payload: [Payload]
	public let metadata: Metadata

	public init(
		method: RequestMethod,
		requestId: RequestID,
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
		public init(networkId: Int) {
			self.networkId = networkId
		}
	}
}
