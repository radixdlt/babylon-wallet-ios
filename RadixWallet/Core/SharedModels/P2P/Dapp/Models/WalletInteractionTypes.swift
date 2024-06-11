import Sargon

// MARK: - DappToWalletInteractionMetadata.Origin
extension DappToWalletInteractionMetadata {
	public typealias Origin = URL
}

extension DappToWalletInteractionMetadata.Origin {
	public static let wallet: Self = {
		let walletAppScheme = "com.radixpublishing.radixwallet.ios"
		return .init(string: walletAppScheme)!
	}()
}

extension TxVersion {
	public static let `default`: Self = 1
}

extension WalletToDappInteractionResponse {
	public var interactionId: WalletInteractionId {
		switch self {
		case let .success(response):
			response.interactionId
		case let .failure(response):
			response.interactionId
		}
	}

	public enum Accounts: Sendable, Hashable {
		case withoutProofOfOwnership(IdentifiedArrayOf<Account>)
		case withProofOfOwnership(challenge: DappToWalletInteractionAuthChallengeNonce, IdentifiedArrayOf<WithProof>)

		public struct WithProof: Sendable, Hashable, Identifiable {
			public typealias ID = WalletInteractionWalletAccount
			public var id: ID { account }
			public let account: WalletInteractionWalletAccount

			public let proof: WalletToDappInteractionAuthProof

			public init(
				account: WalletInteractionWalletAccount,
				proof: WalletToDappInteractionAuthProof
			) {
				self.account = account
				self.proof = proof
			}
		}
	}
}

extension WalletToDappInteractionAccountsRequestResponseItem {
	public init(
		accounts: WalletToDappInteractionResponse.Accounts
	) {
		switch accounts {
		case let .withProofOfOwnership(challenge, accountsWithProof):
			self.init(
				accounts: accountsWithProof.map(\.account),
				challenge: challenge,
				proofs: accountsWithProof.map { .init(accountAddress: $0.account.address, proof: $0.proof) }
			)
		case let .withoutProofOfOwnership(account):
			self.init(
				accounts: account.map(WalletInteractionWalletAccount.init(account:)),
				challenge: nil,
				proofs: nil
			)
		}
	}
}

extension DappToWalletInteractionSendTransactionItem {
	public init(
		version: TxVersion = .default,
		transactionManifest: TransactionManifest,
		message: String? = nil
	) {
		self.init(
			unvalidatedManifest: .init(manifest: transactionManifest),
			version: version,
			message: message
		)
	}
}

extension WalletInteractionWalletAccount {
	public init(account: Account) {
		self.init(
			address: account.address,
			label: account.displayName,
			appearanceId: account.appearanceID
		)
	}
}

extension WalletToDappInteractionAuthProof {
	public init(entitySignature: SignatureOfEntity) {
		let sigPub = entitySignature.signatureWithPublicKey
		let signature = sigPub.signature
		self.init(
			publicKey: sigPub.publicKey,
			curve: sigPub.publicKey.curve,
			signature: signature
		)
	}
}

extension DappWalletInteractionPersona {
	public init(persona: Persona) {
		self.init(identityAddress: persona.address, label: persona.displayName.rawValue)
	}
}

extension WalletInteractionId {
	public static func walletInteractionID(for interaction: DappInteractionClient.WalletInteraction) -> Self {
		"\(interaction.rawValue)_\(UUID().uuidString)"
	}

	public var isWalletAccountDepositSettingsInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.accountDepositSettings.rawValue)
	}

	public var isWalletAccountTransferInteraction: Bool {
		hasPrefix(DappInteractionClient.WalletInteraction.accountTransfer.rawValue)
	}

	public var isWalletInteraction: Bool {
		isWalletAccountTransferInteraction || isWalletAccountDepositSettingsInteraction
	}
}

extension DappToWalletInteraction {
	public enum MissingEntry: Sendable, Hashable {
		case missingEntry
		case missing(Int)
	}

	public enum KindRequest: Sendable, Hashable {
		case entry
		case number(RequestedQuantity)
	}
}

extension DappToWalletInteractionPersonaDataRequestItem {
	public var kindRequests: [PersonaData.Entry.Kind: DappToWalletInteraction.KindRequest] {
		var result: [PersonaData.Entry.Kind: DappToWalletInteraction.KindRequest] = [:]
		if isRequestingName == true {
			result[.fullName] = .entry
		}
		if let numberOfRequestedPhoneNumbers, numberOfRequestedPhoneNumbers.isValid {
			result[.phoneNumber] = .number(numberOfRequestedPhoneNumbers)
		}
		if let numberOfRequestedEmailAddresses, numberOfRequestedEmailAddresses.isValid {
			result[.emailAddress] = .number(numberOfRequestedEmailAddresses)
		}
		return result
	}
}
