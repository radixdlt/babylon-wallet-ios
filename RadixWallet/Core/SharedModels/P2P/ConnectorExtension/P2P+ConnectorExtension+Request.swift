// MARK: - P2P.ConnectorExtension
extension P2P {
	/// Just a namespace
	enum ConnectorExtension {}
}

// MARK: - P2P.ConnectorExtension.Request
extension P2P.ConnectorExtension {
	/// A request we send to connector extension
	enum Request: Sendable, Hashable, Encodable {
		/// Messages sent to Connector Extension for interaction with
		/// Ledger hardware wallets by LedgerHQ, e.g. Ledger Nano S
		case ledgerHardwareWallet(LedgerHardwareWallet)

		/// Accounts sent to Connector Extension
		case accountListMessage(AccountListMessage)

		func encode(to encoder: Encoder) throws {
			switch self {
			case let .ledgerHardwareWallet(request):
				try request.encode(to: encoder)
			case let .accountListMessage(request):
				try request.encode(to: encoder)
			}
		}
	}
}

// MARK: - P2P.ConnectorExtension.Request.LedgerHardwareWallet
extension P2P.ConnectorExtension.Request {
	/// Message sent to Connector Extension for interaction with
	/// Ledger hardware wallets by LedgerHQ, e.g. Ledger Nano S
	struct LedgerHardwareWallet: Sendable, Hashable, Encodable {
		let interactionID: P2P.LedgerHardwareWallet.InteractionId
		let request: Request

		init(interactionID: P2P.LedgerHardwareWallet.InteractionId, request: Request) {
			self.interactionID = interactionID
			self.request = request
		}

		enum Request: Sendable, Hashable, Encodable {
			case getDeviceInfo
			case derivePublicKeys(DerivePublicKeys)
			case signTransaction(SignTransaction)
			case signPreAuthorization(SignPreAuthorization)
			case signChallenge(SignAuthChallenge)
			case deriveAndDisplayAddress(DeriveAndDisplayAddress)

			var discriminator: P2P.LedgerHardwareWallet.Discriminator {
				switch self {
				case .derivePublicKeys: .derivePublicKeys
				case .getDeviceInfo: .getDeviceInfo
				case .signTransaction: .signTransaction
				case .signPreAuthorization: .signPreAuthorization
				case .signChallenge: .signChallenge
				case .deriveAndDisplayAddress: .deriveAndDisplayAddress
				}
			}

			struct DerivePublicKeys: Sendable, Hashable, Encodable {
				let keysParameters: [P2P.LedgerHardwareWallet.KeyParameters]
				let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice

				init(
					keysParameters: [P2P.LedgerHardwareWallet.KeyParameters],
					ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				) {
					self.keysParameters = keysParameters
					self.ledgerDevice = ledgerDevice
				}
			}

			struct SignTransaction: Sendable, Hashable, Encodable {
				let signers: [P2P.LedgerHardwareWallet.KeyParameters]
				let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				let compiledTransactionIntent: HexCodable
				let displayHash: Bool
				let mode: String

				init(
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

			struct SignPreAuthorization: Sendable, Hashable, Encodable {
				let signers: [P2P.LedgerHardwareWallet.KeyParameters]
				let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				let compiledSubintent: HexCodable
				let displayHash: Bool
				let mode: String

				init(
					signers: [P2P.LedgerHardwareWallet.KeyParameters],
					ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice,
					compiledSubintent: HexCodable,
					displayHash: Bool
				) {
					self.signers = signers
					self.ledgerDevice = ledgerDevice
					self.compiledSubintent = compiledSubintent
					self.mode = "summary"
					self.displayHash = displayHash
				}
			}

			struct SignAuthChallenge: Sendable, Hashable, Encodable {
				let signers: [P2P.LedgerHardwareWallet.KeyParameters]
				let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				let challenge: DappToWalletInteractionAuthChallengeNonce
				let origin: DappOrigin
				let dAppDefinitionAddress: AccountAddress

				init(
					signers: [P2P.LedgerHardwareWallet.KeyParameters],
					ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice,
					challenge: DappToWalletInteractionAuthChallengeNonce,
					origin: DappOrigin,
					dAppDefinitionAddress: AccountAddress
				) {
					self.signers = signers
					self.ledgerDevice = ledgerDevice
					self.challenge = challenge
					self.origin = origin
					self.dAppDefinitionAddress = dAppDefinitionAddress
				}
			}

			struct DeriveAndDisplayAddress: Sendable, Hashable, Encodable {
				let keyParameters: P2P.LedgerHardwareWallet.KeyParameters
				let ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				init(
					keyParameters: P2P.LedgerHardwareWallet.KeyParameters,
					ledgerDevice: P2P.LedgerHardwareWallet.LedgerDevice
				) {
					self.keyParameters = keyParameters
					self.ledgerDevice = ledgerDevice
				}
			}
		}

		private typealias CodingKeys = P2P.LedgerHardwareWallet.CodingKeys
		func encode(to encoder: Encoder) throws {
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
			case let .signPreAuthorization(request):
				try request.encode(to: encoder)
			case let .signChallenge(request):
				try request.encode(to: encoder)
			case let .deriveAndDisplayAddress(request):
				try request.encode(to: encoder)
			}
		}
	}

	struct LinkClientInteractionResponse: Sendable, Hashable, Encodable {
		enum Discriminator: String, Sendable, Hashable, Encodable {
			case linkClient
		}

		let discriminator: Discriminator
		let publicKey: Ed25519PublicKey
		let signature: Ed25519Signature
	}

	struct AccountListMessage: Sendable, Hashable, Encodable {
		enum Discriminator: String, Sendable, Hashable, Encodable {
			case accountList
		}

		let discriminator: Discriminator
		let accounts: [WalletInteractionWalletAccount]
	}
}
