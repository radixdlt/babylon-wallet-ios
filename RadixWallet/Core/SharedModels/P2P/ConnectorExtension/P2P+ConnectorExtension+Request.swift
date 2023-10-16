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

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .ledgerHardwareWallet(request):
				try request.encode(to: encoder)
			}
		}
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
			case derivePublicKeys(DerivePublicKeys)
			case signTransaction(SignTransaction)
			case signChallenge(SignAuthChallenge)
			case deriveAndDisplayAddress(DeriveAndDisplayAddress)

			public var discriminator: P2P.LedgerHardwareWallet.Discriminator {
				switch self {
				case .derivePublicKeys: .derivePublicKeys
				case .getDeviceInfo: .getDeviceInfo
				case .signTransaction: .signTransaction
				case .signChallenge: .signChallenge
				case .deriveAndDisplayAddress: .deriveAndDisplayAddress
				}
			}

			public struct DerivePublicKeys: Sendable, Hashable, Encodable {
				public let keysParameters: [P2P.LedgerHardwareWallet.KeyParameters]
				public let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice

				public init(
					keysParameters: [P2P.LedgerHardwareWallet.KeyParameters],
					ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				) {
					self.keysParameters = keysParameters
					self.ledgerDevice = ledgerDevice
				}
			}

			public struct SignTransaction: Sendable, Hashable, Encodable {
				public let signers: [P2P.LedgerHardwareWallet.KeyParameters]
				public let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				public let compiledTransactionIntent: HexCodable
				public let displayHash: Bool
				public let mode: String

				public init(
					signers: [P2P.LedgerHardwareWallet.KeyParameters],
					ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice,
					compiledTransactionIntent: HexCodable,
					displayHash: Bool
				) {
					self.signers = signers
					self.ledgerDevice = ledgerDevice
					self.compiledTransactionIntent = compiledTransactionIntent
					self.mode = "summary"
					self.displayHash = displayHash
				}
			}

			public struct SignAuthChallenge: Sendable, Hashable, Encodable {
				public let signers: [P2P.LedgerHardwareWallet.KeyParameters]
				public let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				public let challenge: P2P.Dapp.Request.AuthChallengeNonce
				public let origin: P2P.Dapp.Request.Metadata.Origin
				public let dAppDefinitionAddress: AccountAddress

				public init(
					signers: [P2P.LedgerHardwareWallet.KeyParameters],
					ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice,
					challenge: P2P.Dapp.Request.AuthChallengeNonce,
					origin: P2P.Dapp.Request.Metadata.Origin,
					dAppDefinitionAddress: AccountAddress
				) {
					self.signers = signers
					self.ledgerDevice = ledgerDevice
					self.challenge = challenge
					self.origin = origin
					self.dAppDefinitionAddress = dAppDefinitionAddress
				}
			}

			public struct DeriveAndDisplayAddress: Sendable, Hashable, Encodable {
				public let keyParameters: P2P.LedgerHardwareWallet.KeyParameters
				public let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				public init(
					keyParameters: P2P.LedgerHardwareWallet.KeyParameters,
					ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				) {
					self.keyParameters = keyParameters
					self.ledgerDevice = ledgerDevice
				}
			}
		}

		private typealias CodingKeys = P2P.LedgerHardwareWallet.CodingKeys
		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(interactionID, forKey: .interactionID)
			try container.encode(
				request.discriminator,
				forKey: .discriminator
			)
			switch request {
			case .getDeviceInfo: break
			case let .derivePublicKeys(request):
				try request.encode(to: encoder)
			case let .signTransaction(request):
				try request.encode(to: encoder)
			case let .signChallenge(request):
				try request.encode(to: encoder)
			case let .deriveAndDisplayAddress(request):
				try request.encode(to: encoder)
			}
		}
	}
}
