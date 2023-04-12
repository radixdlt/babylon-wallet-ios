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
	public struct LedgerHardwareWallet: Sendable, Hashable, Encodable {}
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

extension P2P.FromConnectorExtension {
	/// Message sent from Connector Extension being a response
	/// from an interaction with a Ledger hardware wallet by LedgerHQ,
	/// e.g. Ledger Nano S
	public typealias LedgerHardwareWallet = Result<Success, Failure>

	public struct Failure: Swift.Error, Sendable, Hashable, Decodable {
		public let interactionID: P2P.LedgerHardwareWallet.InteractionId
		public let discriminator: P2P.LedgerHardwareWallet.Discriminator
		public let error: Error
		public struct Error: Swift.Error, Sendable, Hashable, Decodable {
			public let code: Int // enum?
			public let message: String
		}
	}

	public enum Success: Sendable, Hashable, Decodable {
		case getDeviceInfo(GetDeviceInfo)
		case derivePublicKey(DerivePublicKey)
		case signTransaction(SignTransaction)

		public struct GetDeviceInfo: Sendable, Hashable, Decodable {
			public let interactionID: P2P.LedgerHardwareWallet.InteractionId
			public let id: FactorSource.LedgerHardwareWallet.DeviceID
			public let model: Int // P2P.LedgerHardwareWallet.Model
		}

		public struct DerivePublicKey: Sendable, Hashable, Decodable {
			public let interactionID: P2P.LedgerHardwareWallet.InteractionId
			public let publicKey: HexCodable
		}

		public struct SignTransaction: Sendable, Hashable, Decodable {
			public let interactionID: P2P.LedgerHardwareWallet.InteractionId
			public let signedTransaction: HexCodable
			// public let publicKey: HexCodable
		}

		private enum CodingKeys: String, CodingKey {
			case interactionID = "interactionId"
			case discriminator
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let discriminator = try container.decode(
				P2P.LedgerHardwareWallet.Discriminator.self,
				forKey: .discriminator
			)
			let interactionID = try container.decode(P2P.LedgerHardwareWallet.InteractionId.self, forKey: .interactionID)
			switch discriminator {
			case .derivePublicKey:
				self = try .derivePublicKey(.init(from: decoder))
			case .getDeviceInfo:
				self = try .getDeviceInfo(.init(from: decoder))
			case .signTransaction:
				self = try .signTransaction(.init(from: decoder))
			}
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

		public struct LedgerDevice: Sendable, Hashable, Codable {
			public let name: NonEmptyString?
			public let id: String
			public let model: Int // Model
		}
	}
}
