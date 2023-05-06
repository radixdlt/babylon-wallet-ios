#if DEBUG
import ClientPrelude

extension TransactionClient: TestDependencyKey {
	public static let testValue: TransactionClient = .init(
		convertManifestInstructionsToJSONIfItWasString: unimplemented("\(Self.self).convertManifestInstructionsToJSONIfItWasString"),
		lockFeeBySearchingForSuitablePayer: unimplemented("\(Self.self).lockFeeBySearchingForSuitablePayer"),
		lockFeeWithSelectedPayer: unimplemented("\(Self.self).lockFeeWithSelectedPayer"),
		addInstructionToManifest: unimplemented("\(Self.self).addInstructionToManifest"),
		addGuaranteesToManifest: unimplemented("\(Self.self).addGuaranteesToManifest"),
		getTransactionReview: unimplemented("\(Self.self).getTransactionReview"),
		buildTransactionIntent: unimplemented("\(Self.self).buildTransactionIntent"),
		notarizeTransaction: unimplemented("\(Self.self).notarizeTransaction")
	)
}
#endif // DEBUG
