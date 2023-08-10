import EngineToolkit
import Prelude

// MARK: - Result Builder
extension ManifestBuilder {
	public static let faucetLockFee = flipVoid(faucetLockFee)
	public static let faucetFreeXrd = flipVoid(faucetFreeXrd)
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

	public static func make(@InstructionsChain _ content: () throws -> InstructionsChain.Instructions) throws -> ManifestBuilder {
		var builder = ManifestBuilder()
		try content().forEach {
			builder = try $0(builder)
		}
		return builder
	}
}

func flipVoid<A, T>(_ f: @escaping (A) -> () throws -> T) -> (A) throws -> T {
	{ a in
		try f(a)()
	}
}
