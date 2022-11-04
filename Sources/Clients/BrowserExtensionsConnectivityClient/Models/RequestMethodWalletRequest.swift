import EngineToolkit
import Foundation
import Profile

// MARK: - RequestMethodWalletRequest
public struct RequestMethodWalletRequest: Sendable, Hashable, Decodable {
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
	enum Payload: Sendable, Hashable, Decodable {
		case accountAddresses(AccountAddressesRequestMethodWalletRequest)
		case signTXRequest(SignTXRequestFromDapp)
	}
}

// MARK: Payload+Decodable
public extension RequestMethodWalletRequest.Payload {
	enum CodingKeys: String, CodingKey {
		case requestType
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(RequestType.self, forKey: .requestType)
		switch discriminator {
		case .accountAddresses:
			self = try .accountAddresses(.init(from: decoder))
		case .sendTransaction:
			self = try .signTXRequest(.init(from: decoder))
		}
	}
}

public extension RequestMethodWalletRequest.Payload {
	var requestType: RequestType {
		switch self {
		case let .signTXRequest(request): return request.requestType
		case let .accountAddresses(request): return request.requestType
		}
	}
}

// MARK: - RequestMethodWalletRequest.AccountAddressesRequestMethodWalletRequest
public extension RequestMethodWalletRequest {
	struct AccountAddressesRequestMethodWalletRequest: Sendable, Hashable, Decodable {
		public let requestType: RequestType
		public let numberOfAddresses: Int?
		public init(requestType: RequestType, numberOfAddresses: Int?) {
			precondition(requestType == .accountAddresses)
			self.requestType = requestType
			self.numberOfAddresses = numberOfAddresses
		}
	}
}

// MARK: - RequestMethodWalletRequest.SignTXRequestFromDapp
public extension RequestMethodWalletRequest {
	struct SignTXRequestFromDapp: Sendable, Hashable, Decodable {
		public var accountAddress: AccountAddress {
			try! .init(address: __accountAddress)
		}

		// FIXME: Clean up JSON decoding post E2E
		public let __accountAddress: String
		public let version: Version
		public let __transactionManifest: String
		public let __blobsHex: [String]?
		public var blobs: [[UInt8]] {
			guard let blobsHex = __blobsHex else { return [] }
			return blobsHex.map {
				try! [UInt8](Data(hexString: $0))
			}
		}

		public var transactionManifest: TransactionManifest {
			TransactionManifest(instructions: .string(__transactionManifest), blobs: blobs)
		}

		public let requestType: RequestType

		enum CodingKeys: String, CodingKey {
			// FIXME: Clean up JSON decoding post E2E
			case __accountAddress = "accountAddress"
			case __transactionManifest = "transactionManifest"
			case __blobsHex = "blobs"
			case version, requestType
		}

		public init(
			accountAddress: AccountAddress,
			version: Version,
			transactionManifest: String,
			blobsHex: [String] = [],
			requestType: RequestType
		) {
			precondition(requestType == .sendTransaction)
			// FIXME: Clean up JSON decoding post E2E
			__accountAddress = accountAddress.address
			self.version = version
			__transactionManifest = transactionManifest
			__blobsHex = blobsHex
			self.requestType = requestType
		}
	}
}

// MARK: - RequestMethodWalletRequest.Metadata
public extension RequestMethodWalletRequest {
	struct Metadata: Sendable, Hashable, Decodable {
		public let networkId: Int
		public let dAppId: String?
		public init(networkId: Int, dAppId: String?) {
			self.networkId = networkId
			self.dAppId = dAppId
		}
	}
}
