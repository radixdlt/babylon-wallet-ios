import Common
import CryptoKit
import EngineToolkit
import Foundation
import Prelude
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey
import XCTestDynamicOverlay

extension EngineToolkitClient: TestDependencyKey {
	public static let previewValue = Self(
		getTransactionVersion: { Version.default },
		generateTXNonce: { .init(rawValue: 1) },
		convertManifestInstructionsToJSONIfItWasString: { _ in
			.init(
				instructions: [],
				convertedManifestThatContainsThem: .init(instructions: .json([]))
			)
		},
		compileTransactionIntent: { _ in .init(compiledIntent: [0xDE, 0xAD]) },
		compileSignedTransactionIntent: { _ in .init(bytes: [0xDE, 0xAD]) },
		compileNotarizedTransactionIntent: { _ in .init(compiledNotarizedIntent: [0xDE, 0xAD]) },
		generateTXID: { _ in "deadbeef" },
		accountAddressesNeedingToSignTransaction: { _ in [] }
	)

	public static let testValue = Self(
		getTransactionVersion: unimplemented("\(Self.self).getTransactionVersion"),
		generateTXNonce: unimplemented("\(Self.self).generateTXNonce"),
		convertManifestInstructionsToJSONIfItWasString: unimplemented("\(Self.self).convertManifestInstructionsToJSONIfItWasString"),
		compileTransactionIntent: unimplemented("\(Self.self).compileTransactionIntent"),
		compileSignedTransactionIntent: unimplemented("\(Self.self).compileSignedTransactionIntent"),
		compileNotarizedTransactionIntent: unimplemented("\(Self.self).compileNotarizedTransactionIntent"),
		generateTXID: unimplemented("\(Self.self).generateTXID"),
		accountAddressesNeedingToSignTransaction: unimplemented("\(Self.self).accountAddressesNeedingToSignTransaction")
	)
}
