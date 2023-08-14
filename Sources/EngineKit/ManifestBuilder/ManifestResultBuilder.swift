import EngineToolkit
import Prelude

// MARK: - Result Builder
extension ManifestBuilder {
	/// Every Manifest builder function signature of form `(ManifestBuilder) -> (args...) throws -> ManifestBuilder`
	///
	/// To be able to use manifest builder, it is required to transform all functions to have the same signature.
	/// So this ResultBuilder defines an instruction as `(ManifestBuilder) throws -> ManifestBuilder`.
	/// To achive this we flip the arguments order of the manifest builder functions to a form of:
	/// `(args...) -> (ManifestBuilder) -> throws -> ManifestBuilder`
	/// This allows to create partial instruction which are then build once put together.
	///
	public static let faucetLockFee = flip(faucetLockFee)
	public static let faucetFreeXrd = flip(faucetFreeXrd)
	public static let accountTryDepositBatchOrAbort = flip(accountTryDepositBatchOrAbort)
	public static let withdrawAmount = flip(withdrawFromAccount)
	public static let withdrawTokens = flip(withdrawNonFungiblesFromAccount)
	public static let takeFromWorktop = flip(takeFromWorktop)
	public static let accountTryDepositOrAbort = flip(accountTryDepositOrAbort)
	public static let takeNonFungiblesFromWorktop = flip(takeNonFungiblesFromWorktop)
	public static let setOwnerKeys = flip(setOwnerKeys)

	@resultBuilder
	public enum InstructionsChain {
		public typealias Instructions = [Instruction]
		public typealias Instruction = (ManifestBuilder) throws -> ManifestBuilder

		public static func buildBlock(_ components: Instructions...) -> Instructions {
			Array(components.joined())
		}

		public static func buildArray(_ components: [Instructions]) -> Instructions {
			Array(components.joined())
		}

		public static func buildExpression(_ expression: @escaping Instruction) -> Instructions {
			[expression]
		}

		public static func buildOptional(_ component: Instructions?) -> Instructions {
			component ?? []
		}
	}

	/// A result builder extension on ManifestBuilder to allow easier building of the manifests when there is additional logic required to compute the manifest.
	/// Examples:
	/// - Building a manifest with dynamic number of instructions, requiring a `for-loop`
	/// - Building a manifest that has conditional logic to add certain instructions, requiring to use `if-else` statements.
	///
	/// If the manifest you are trying to build does not require additional logic, simply use the `ManifestBuilder()`.
	public static func make(@InstructionsChain _ content: () throws -> InstructionsChain.Instructions) throws -> ManifestBuilder {
		var builder = ManifestBuilder()
		// Collect all partial instructions to be built
		try content().forEach {
			// Build each instruction by updating the builder
			builder = try $0(builder)
		}
		return builder
	}
}
