#if DEBUG
import ClientPrelude

extension TransactionClient: TestDependencyKey {
	public static let testValue: TransactionClient = .init(
		convertManifestInstructionsToJSONIfItWasString: unimplemented("\(Self.self).convertManifestInstructionsToJSONIfItWasString"),
		addLockFeeInstructionToManifest: unimplemented("\(Self.self).addLockFeeInstructionToManifest"),
		addGuaranteesToManifest: unimplemented("\(Self.self).addLockFeeInstructionToManifest"),
		signAndSubmitTransaction: unimplemented("\(Self.self).signAndSubmitTransaction"),
		getTransactionReview: unimplemented("\(Self.self).getTransactionReview")
	)
}
#endif // DEBUG
