import Prelude
import Profile
import Tagged

// MARK: - P2P.ConnectorExtension.Response
extension P2P.ConnectorExtension {
	/// A response received from connector extension for some request we have sent.
	public enum Response: Sendable, Hashable, Decodable {
		/// Messages sent from Connector Extension being a response
		/// from an interaction with a Ledger hardware wallet by LedgerHQ,
		/// e.g. Ledger Nano S
		case ledgerHardwareWallet(LedgerHardwareWallet)
	}
}

// MARK: - P2P.ConnectorExtension.Response.LedgerHardwareWallet
extension P2P.ConnectorExtension.Response {
	/// Message sent from Connector Extension being a response
	/// from an interaction with a Ledger hardware wallet by LedgerHQ,
	/// e.g. Ledger Nano S
	public struct LedgerHardwareWallet: Sendable, Hashable, Decodable {
		public let interactionID: P2P.LedgerHardwareWallet.InteractionId
		public let discriminator: P2P.LedgerHardwareWallet.Discriminator
		public let response: Result<Success, Failure>
	}
}

extension P2P.ConnectorExtension.Response.LedgerHardwareWallet {
	public struct Failure: Swift.Error, Sendable, Hashable, Decodable {
		public let code: Int // enum?
		public let message: String
	}

	public enum Success: Sendable, Hashable, Decodable {
		case getDeviceInfo(GetDeviceInfo)
		case derivePublicKey(DerivePublicKey)
		case signTransaction(SignTransaction)

		public struct GetDeviceInfo: Sendable, Hashable, Decodable {
			public let id: FactorSource.LedgerHardwareWallet.DeviceID
			public let model: P2P.LedgerHardwareWallet.Model
		}

		public struct DerivePublicKey: Sendable, Hashable, Decodable {
			public let publicKey: HexCodable
		}

		public struct SignTransaction: Sendable, Hashable, Decodable {
			public let signature: HexCodable
			public let publicKey: HexCodable
		}

		public struct ImportOlympiaDevice: Sendable, Hashable, Decodable {
			public let id: FactorSource.LedgerHardwareWallet.DeviceID
			public let model: P2P.LedgerHardwareWallet.Model
			public let derivedPublicKeys: [DerivedPublicKey]
			public struct DerivedPublicKey: Sendable, Hashable, Decodable {
				public let publicKey: HexCodable
				public let path: String
			}
		}
	}

	private typealias CodingKeys = P2P.LedgerHardwareWallet.CodingKeys

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let discriminator = try container.decode(
			P2P.LedgerHardwareWallet.Discriminator.self,
			forKey: .discriminator
		)
		self.discriminator = discriminator
		self.interactionID = try container.decode(P2P.LedgerHardwareWallet.InteractionId.self, forKey: .interactionID)

		if let successPayload = try container.decodeIfPresent(Success.self, forKey: .success) {
			self.response = .success(successPayload)
		} else if let failurePayload = try container.decodeIfPresent(Failure.self, forKey: .failure) {
			self.response = .failure(failurePayload)
		} else {
			struct NeitherSuccessNorFailureJSONKeysFound: Swift.Error {}
			throw NeitherSuccessNorFailureJSONKeysFound()
		}
	}
}
