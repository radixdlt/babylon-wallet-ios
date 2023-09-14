@testable import Profile

extension EntityProtocol {
	func publicKey() -> SLIP10.PublicKey? {
		switch securityState {
		case let .unsecured(control):
			return control.transactionSigning.publicKey
		}
	}

	func authPublicKey() -> SLIP10.PublicKey? {
		switch securityState {
		case let .unsecured(control):
			return control.authenticationSigning?.publicKey
		}
	}
}

extension DeviceFactorSource {
	public static func babylon(
		mnemonic: Mnemonic,
		model: Hint.Model,
		name: String,
		addedOn: Date
	) throws -> Self {
		try babylon(mnemonicWithPassphrase: .init(mnemonic: mnemonic), model: model, name: name, addedOn: addedOn, lastUsedOn: addedOn)
	}

	public static func olympia(
		mnemonic: Mnemonic,
		model: Hint.Model,
		name: String,
		addedOn: Date
	) throws -> Self {
		try olympia(mnemonicWithPassphrase: .init(mnemonic: mnemonic), model: model, name: name, addedOn: addedOn, lastUsedOn: addedOn)
	}
}

// MARK: - EmailAddress + ExpressibleByStringLiteral
extension EmailAddress: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		let nonEmpty = NonEmptyString(rawValue: value)!
		try! self.init(validating: nonEmpty)
	}
}

// MARK: - SpecificAddress + ExpressibleByStringLiteral
extension SpecificAddress: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		try! self.init(validatingAddress: value)
	}
}

extension Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData {
	init(personaData: PersonaData) throws {
		try self.init(
			name: personaData.name?.id,
			dateOfBirth: personaData.dateOfBirth?.id,
			companyName: personaData.companyName?.id,
			emailAddresses: .init(ids: .init(validating: personaData.emailAddresses.map(\.id)), forRequest: .atLeast(1)),
			phoneNumbers: .init(ids: .init(validating: personaData.phoneNumbers.map(\.id)), forRequest: .atLeast(1)),
			urls: .init(ids: .init(validating: personaData.urls.map(\.id)), forRequest: .atLeast(1)),
			postalAddresses: .init(ids: .init(validating: personaData.postalAddresses.map(\.id)), forRequest: .atLeast(1)),
			creditCards: .init(ids: .init(validating: personaData.creditCards.map(\.id)), forRequest: .atLeast(1))
		)
	}
}

extension MnemonicWithPassphrase {
	func deviceFactorSourceID() throws -> FactorSource.ID.FromHash {
		try FactorSource.ID.FromHash(
			kind: .device,
			mnemonicWithPassphrase: self
		)
	}
}
