import ClientPrelude
import Cryptography
import EngineToolkit

extension EngineToolkitClient: TestDependencyKey {
	public static let previewValue = Self(
		getTransactionVersion: { TXVersion.default },
		generateTXNonce: { .init(rawValue: 1) },
		convertManifestInstructionsToJSONIfItWasString: { _ in
			.init(
				instructions: [],
				convertedManifestThatContainsThem: .init(instructions: .parsed([]))
			)
		},
		compileTransactionIntent: { _ in .init(compiledIntent: [0xDE, 0xAD]) },
		compileSignedTransactionIntent: { _ in .init(bytes: [0xDE, 0xAD]) },
		compileNotarizedTransactionIntent: { _ in .init(compiledIntent: [0xDE, 0xAD]) },
		generateTXID: { _ in "deadbeef" },
		accountAddressesNeedingToSignTransaction: { _ in [] },
		accountAddressesSuitableToPayTransactionFee: { _ in [] },
		knownEntityAddresses: { _ in throw NoopError() },
		generateTransactionReview: unimplemented("\(Self.self).generateTransactionReview"),
		decodeAddress: unimplemented("\(Self.self).decodeAddress")
	)

	public static let testValue = Self(
		getTransactionVersion: unimplemented("\(Self.self).getTransactionVersion"),
		generateTXNonce: unimplemented("\(Self.self).generateTXNonce"),
		convertManifestInstructionsToJSONIfItWasString: unimplemented("\(Self.self).convertManifestInstructionsToJSONIfItWasString"),
		compileTransactionIntent: unimplemented("\(Self.self).compileTransactionIntent"),
		compileSignedTransactionIntent: unimplemented("\(Self.self).compileSignedTransactionIntent"),
		compileNotarizedTransactionIntent: unimplemented("\(Self.self).compileNotarizedTransactionIntent"),
		generateTXID: unimplemented("\(Self.self).generateTXID"),
		accountAddressesNeedingToSignTransaction: unimplemented("\(Self.self).accountAddressesNeedingToSignTransaction"),
		accountAddressesSuitableToPayTransactionFee: unimplemented("\(Self.self).accountAddressesSuitableToPayTransactionFee"),
		knownEntityAddresses: unimplemented("\(Self.self).knownEntityAddresses"),
		generateTransactionReview: unimplemented("\(Self.self).generateTransactionReview"),
		decodeAddress: unimplemented("\(Self.self).decodeAddress")
	)
}
