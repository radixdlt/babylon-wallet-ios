import Sargon

// MARK: - DappOrigin
// extension DappToWalletInteractionMetadata {
//	typealias Origin = URL
// }

extension DappOrigin {
	static let wallet = "com.radixpublishing.radixwallet.ios"

	struct InvalidOriginURL: Error {}

	func url() throws -> URL {
		guard let url = URL(string: self) else {
			throw InvalidOriginURL()
		}
		return url
	}
}

// MARK: - DappInteractionNumberOfAccounts
typealias DappInteractionNumberOfAccounts = RequestedQuantity

// MARK: - TxVersion
extension TxVersion {
	static let `default`: Self = 1
}

// MARK: - DappToWalletInteractionSendTransactionItem
extension DappToWalletInteractionSendTransactionItem {
	init(
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
	struct RequestValidation: Hashable {
		var missingEntries: [PersonaData.Entry.Kind: MissingEntry] = [:]
		var existingRequestedEntries: [PersonaData.Entry.Kind: [PersonaData.Entry]] = [:]

		var response: WalletToDappInteractionPersonaDataRequestResponseItem? {
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
	func extract<F: PersonaDataEntryProtocol>(_ kind: PersonaData.Entry.Kind, as: F.Type = F.self) throws -> F? {
		try self[kind]?.first.map { try $0.extract(as: F.self) }
	}

	func extract<F: PersonaDataEntryProtocol>(_ kind: PersonaData.Entry.Kind, as: F.Type = F.self) throws -> OrderedSet<F>? {
		try self[kind].map { try $0.extract() }
	}
}

private extension [PersonaData.Entry] {
	func extract<F: PersonaDataEntryProtocol>(as _: F.Type = F.self) throws -> OrderedSet<F> {
		try .init(validating: map { try $0.extract() })
	}
}
