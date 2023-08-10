import EngineToolkit
import Prelude

// MARK: - Result Builder
extension ManifestBuilder {
	public static let faucetLockFee = flipVoid(faucetLockFee)
	public static let faucetFreeXrd = flipVoid(faucetFreeXrd)
	public static let accountTryDepositBatchOrAbort = flip(accountTryDepositBatchOrAbort)
	public static let withdrawAmount = flip(withdrawAmount)
	public static let withdrawTokens = flip(withdrawTokens)
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

//
// func flip<A, B, T>(_ f: @escaping (A) -> (B) throws -> T) -> (B) -> (A) throws -> T {
//	{ b in
//		{ a in
//			try f(a)(b)
//		}
//	}
// }
//
// func flip<A, B, C, T>(_ f: @escaping (A) -> (B, C) throws -> T) -> (B, C) -> (A) throws -> T {
//	{ b, c in
//		{ a in
//			try f(a)(b, c)
//		}
//	}
// }
//
// func flip<A, B, C, D, T>(_ f: @escaping (A) -> (B, C, D) throws -> T) -> (B, C, D) -> (A) throws -> T {
//	{ b, c, d in
//		{ a in
//			try f(a)(b, c, d)
//		}
//	}
// }

extension ManifestBuilderBucket {
	public static var unique: ManifestBuilderBucket {
		.init(name: UUID().uuidString)
	}
}

extension PublicKeyHash {
	/// https://rdxworks.slack.com/archives/C031A0V1A1W/p1683275008777499?thread_ts=1683221252.228129&cid=C031A0V1A1W
	var discriminator: String {
		switch self {
		case .secp256k1: return "0u8"
		case .ed25519: return "1u8"
		}
	}

	func bytes() throws -> [UInt8] {
		switch self {
		case let .secp256k1(value), let .ed25519(value):
			return value
		}
	}
}
