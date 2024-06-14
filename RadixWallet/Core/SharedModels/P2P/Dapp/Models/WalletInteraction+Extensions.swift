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

// MARK: - DappInteractionNumberOfAccounts
public typealias DappInteractionNumberOfAccounts = RequestedQuantity

// MARK: - TxVersion
extension TxVersion {
	public static let `default`: Self = 1
}

// MARK: - DappToWalletInteractionSendTransactionItem
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
