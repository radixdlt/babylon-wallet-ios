#if DEBUG
import Prelude

extension TransactionClient: TestDependencyKey {
	public static let testValue: TransactionClient = .init(
		convertManifestInstructionsToJSONIfItWasString: unimplemented("\(Self.self).convertManifestInstructionsToJSONIfItWasString"),
		addLockFeeInstructionToManifest: unimplemented("\(Self.self).addLockFeeInstructionToManifest"),
		signAndSubmitTransaction: unimplemented("\(Self.self).signAndSubmitTransaction")
	)
}
#endif // DEBUG
