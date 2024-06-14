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

public typealias NumberOfAccounts = RequestedQuantity

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

// MARK: - DappToWalletInteraction.RequestValidation
extension DappToWalletInteraction {
	public struct RequestValidation: Sendable, Hashable {
		public var missingEntries: [PersonaData.Entry.Kind: MissingEntry] = [:]
		public var existingRequestedEntries: [PersonaData.Entry.Kind: [PersonaData.Entry]] = [:]

		public var response: WalletToDappInteractionPersonaDataRequestResponseItem? {
			guard missingEntries.isEmpty else { return nil }
			return try? .init(
				name: existingRequestedEntries.extract(.fullName),
				emailAddresses: existingRequestedEntries.extract(.emailAddress)?.elements,
				phoneNumbers: existingRequestedEntries.extract(.phoneNumber)?.elements
			)
		}
	}
}

private extension [PersonaData.Entry.Kind: [PersonaData.Entry]] {
	func extract<F>(_ kind: PersonaData.Entry.Kind, as: F.Type = F.self) throws -> F? where F: PersonaDataEntryProtocol {
		try self[kind]?.first.map { try $0.extract(as: F.self) }
	}

	func extract<F>(_ kind: PersonaData.Entry.Kind, as: F.Type = F.self) throws -> OrderedSet<F>? where F: PersonaDataEntryProtocol {
		try self[kind].map { try $0.extract() }
	}
}

private extension [PersonaData.Entry] {
	func extract<F>(as _: F.Type = F.self) throws -> OrderedSet<F> where F: PersonaDataEntryProtocol {
		try .init(validating: map { try $0.extract() })
	}
}
