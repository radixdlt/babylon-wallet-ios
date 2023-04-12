import Prelude

// MARK: - P2P.ToConnectorExtension
extension P2P {
	public enum ToConnectorExtension: Sendable, Hashable, Encodable {
		/// Messages sent to Connector Extension for interaction with
		/// Ledger hardware wallets by LedgerHQ, e.g. Ledger Nano S
		case ledgerHardwareWallet(LedgerHardwareWallet)
	}
}

// MARK: - P2P.ToConnectorExtension.LedgerHardwareWallet
extension P2P.ToConnectorExtension {
	/// Message sent to Connector Extension for interaction with
	/// Ledger hardware wallets by LedgerHQ, e.g. Ledger Nano S
	public struct LedgerHardwareWallet: Sendable, Hashable, Encodable {
		public let interactionID: P2P.LedgerHardwareWallet.InteractionId
		public let request: Request

		public enum Request: Sendable, Hashable, Encodable {
			case getDeviceInfo
			case derivePublicKey(DerivePublicKey)
			case signTransaction(SignTransaction)

			public struct DerivePublicKey: Sendable, Hashable, Encodable {
				public let keyParameters: P2P.LedgerHardwareWallet.KeyParameters
				public let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
			}

			public struct SignTransaction: Sendable, Hashable, Encodable {
				public let keyParameters: P2P.LedgerHardwareWallet.KeyParameters
				public let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				public let compiledTransactionIntent: HexCodable
				public let mode: Mode
				public enum Mode: String, Sendable, Hashable, Encodable {
					case verbose
					case summary
				}
			}
		}

		private typealias CodingKeys = P2P.LedgerHardwareWallet.CodingKeys
		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(interactionID, forKey: .interactionID)
			switch request {
			case .getDeviceInfo:
				try container.encode(
					P2P.LedgerHardwareWallet.Discriminator.getDeviceInfo,
					forKey: .discriminator
				)
			case let .derivePublicKey(derivePublicKey):
				try container.encode(
					P2P.LedgerHardwareWallet.Discriminator.derivePublicKey,
					forKey: .discriminator
				)
				try derivePublicKey.encode(to: encoder)
			case let .signTransaction(signTransaction):
				try container.encode(
					P2P.LedgerHardwareWallet.Discriminator.signTransaction,
					forKey: .discriminator
				)
				try signTransaction.encode(to: encoder)
			}
		}
	}
}

// MARK: - P2P.FromConnectorExtension
extension P2P {
	public enum FromConnectorExtension: Sendable, Hashable, Decodable {
		/// Messages sent from Connector Extension being a response
		/// from an interaction with a Ledger hardware wallet by LedgerHQ,
		/// e.g. Ledger Nano S
		case ledgerHardwareWallet(LedgerHardwareWallet)
	}
}

// MARK: - P2P.FromConnectorExtension.LedgerHardwareWallet
extension P2P.FromConnectorExtension {
	/// Message sent from Connector Extension being a response
	/// from an interaction with a Ledger hardware wallet by LedgerHQ,
	/// e.g. Ledger Nano S
	public struct LedgerHardwareWallet: Sendable, Hashable, Decodable {
		public let interactionID: P2P.LedgerHardwareWallet.InteractionId
		public let discriminator: P2P.LedgerHardwareWallet.Discriminator
		public let response: Result<Success, Failure>
	}
}

extension P2P.FromConnectorExtension.LedgerHardwareWallet {
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
			public let model: Int // P2P.LedgerHardwareWallet.Model
		}

		public struct DerivePublicKey: Sendable, Hashable, Decodable {
			public let publicKey: HexCodable
		}

		public struct SignTransaction: Sendable, Hashable, Decodable {
			public let signature: HexCodable
			public let publicKey: HexCodable
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

import Profile
import Tagged

// MARK: - P2P.LedgerHardwareWallet
extension P2P {
	/// Just a namespace for types shared between `P2P.FromConnectorExtension.LedgerHardwareWallet`
	/// and `P2P.ToConnectorExtension.LedgerHardwareWallet`
	public enum LedgerHardwareWallet {
		enum CodingKeys: String, CodingKey {
			case interactionID = "interactionId"
			case discriminator
			case success
			case failure
		}

		public typealias InteractionId = Tagged<(Self, id: ()), String>

		public enum Discriminator: String, Sendable, Hashable, Codable {
			case getDeviceInfo
			case derivePublicKey
			case signTransaction
		}

		// N.B. these *might* have the exact same JSON representation as
		// `FactorSource.LedgerHardwareWallet.Model` but in case we ever
		// change the JSON values for CAP21 or for Profile, we want them
		// to be **decoupled**.
		public enum Model: String, Sendable, Hashable, Codable {
			case nanoS
			case nanoSPlus
			case nanoX
		}

		// N.B. these *might* have the exact same JSON representation as
		// `FactorSource.LedgerHardwareWallet.Device` but in case we ever
		// change the JSON values for CAP21 or for Profile, we want them
		// to be **decoupled**.
		public struct LedgerDevice: Sendable, Hashable, Codable {
			public let name: NonEmptyString?
			public let id: String
			public let model: Int // Model
		}

		public struct KeyParameters: Sendable, Hashable, Codable {
			public let curve: Curve
			public let derivationPath: String
			public enum Curve: String, Sendable, Hashable, Codable {
				case curve25519
				case secp256k1
			}
		}
	}
}
