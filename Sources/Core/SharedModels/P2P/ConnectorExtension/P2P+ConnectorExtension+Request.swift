import Prelude

// MARK: - P2P.ConnectorExtension
extension P2P {
	/// Just a namespace
	public enum ConnectorExtension {}
}

// MARK: - P2P.ConnectorExtension.Request
extension P2P.ConnectorExtension {
	/// A request we send to connector extension
	public enum Request: Sendable, Hashable, Encodable {
		/// Messages sent to Connector Extension for interaction with
		/// Ledger hardware wallets by LedgerHQ, e.g. Ledger Nano S
		case ledgerHardwareWallet(LedgerHardwareWallet)
	}
}

// MARK: - P2P.ConnectorExtension.Request.LedgerHardwareWallet
extension P2P.ConnectorExtension.Request {
	/// Message sent to Connector Extension for interaction with
	/// Ledger hardware wallets by LedgerHQ, e.g. Ledger Nano S
	public struct LedgerHardwareWallet: Sendable, Hashable, Encodable {
		public let interactionID: P2P.LedgerHardwareWallet.InteractionId
		public let request: Request

		public init(interactionID: P2P.LedgerHardwareWallet.InteractionId, request: Request) {
			self.interactionID = interactionID
			self.request = request
		}

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
