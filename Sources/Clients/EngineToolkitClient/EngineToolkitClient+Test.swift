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
		decompileTransactionIntent: { _ in throw NoopError() },
		decompileNotarizedTransactionIntent: { _ in throw NoopError() },
		deriveOlympiaAdressFromPublicKey: { _ in throw NoopError() },
		generateTXID: { _ in "deadbeef" },
		knownEntityAddresses: { _ in throw NoopError() },
		analyzeManifest: { _ in throw NoopError() },
		analyzeManifestWithPreviewContext: { _ in throw NoopError() },
		decodeAddress: { _ in throw NoopError() }
	)

	public static let testValue = Self(
		getTransactionVersion: unimplemented("\(Self.self).getTransactionVersion"),
		generateTXNonce: unimplemented("\(Self.self).generateTXNonce"),
		convertManifestInstructionsToJSONIfItWasString: unimplemented("\(Self.self).convertManifestInstructionsToJSONIfItWasString"),
		compileTransactionIntent: unimplemented("\(Self.self).compileTransactionIntent"),
		compileSignedTransactionIntent: unimplemented("\(Self.self).compileSignedTransactionIntent"),
		compileNotarizedTransactionIntent: unimplemented("\(Self.self).compileNotarizedTransactionIntent"),
		decompileTransactionIntent: unimplemented("\(Self.self).decompileTransactionIntent"),
		decompileNotarizedTransactionIntent: unimplemented("\(Self.self).decompileNotarizedTransactionIntent"),
		deriveOlympiaAdressFromPublicKey: unimplemented("\(Self.self).deriveOlympiaAdressFromPublicKey"),
		generateTXID: unimplemented("\(Self.self).generateTXID"),
		knownEntityAddresses: unimplemented("\(Self.self).knownEntityAddresses"),
		analyzeManifest: unimplemented("\(Self.self).analyzeManifest"),
		analyzeManifestWithPreviewContext: unimplemented("\(Self.self).analyzeManifestWithPreviewContext"),
		decodeAddress: unimplemented("\(Self.self).decodeAddress")
	)
}
