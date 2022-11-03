import Foundation

// MARK: - RequestMethodWalletResponse
public struct RequestMethodWalletResponse: Sendable, Hashable, Encodable {
	public typealias RequestID = RequestMethodWalletRequest.RequestID
	public let method: RequestMethod
	public let requestId: RequestID
	public let payload: [Payload]

	public init(
		method: RequestMethod,
		requestId: RequestID,
		payload: [Payload]
	) {
		self.method = method
		self.requestId = requestId
		self.payload = payload
	}
}

// MARK: RequestMethodWalletResponse.Payload
public extension RequestMethodWalletResponse {
	enum Payload: Sendable, Hashable, Encodable {
		case accountAddresses(AccountAddressesRequestMethodWalletResponse)
	}
}

// MARK: RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse
public extension RequestMethodWalletResponse {
	struct AccountAddressesRequestMethodWalletResponse: Sendable, Hashable, Encodable {
		public let requestType: RequestType
		public let accountAddresses: [AccountAddress]
		public init(requestType: RequestType, accountAddresses: [AccountAddress]) {
			self.requestType = requestType
			self.accountAddresses = accountAddresses
		}
	}
}

// MARK: - RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse.AccountAddress
public extension RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse {
	struct AccountAddress: Sendable, Hashable, Encodable {
		public let address: String
		public let label: String
		public init(address: String, label: String) {
			self.address = address
			self.label = label
		}
	}
}
