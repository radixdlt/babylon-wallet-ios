import Foundation

// MARK: - RequestMethodWalletResponse
public struct RequestMethodWalletResponse: Encodable {
	public let method: RequestMethod
	public let requestId: String
	public let payload: [Payload]

	public init(
		method: RequestMethod,
		requestId: String,
		payload: [Payload]
	) {
		self.method = method
		self.requestId = requestId
		self.payload = payload
	}
}

// MARK: RequestMethodWalletResponse.Payload
public extension RequestMethodWalletResponse {
	enum Payload: Encodable {
		case accountAddresses(AccountAddressesRequestMethodWalletResponse)
	}
}

// MARK: RequestMethodWalletResponse.AccountAddressesRequestMethodWalletResponse
public extension RequestMethodWalletResponse {
	struct AccountAddressesRequestMethodWalletResponse: Encodable {
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
	struct AccountAddress: Encodable {
		public let address: String
		public let label: String
		public init(address: String, label: String) {
			self.address = address
			self.label = label
		}
	}
}
