

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
	///

	public static func faucetLockFee() -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func faucetFreeXrd() -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func accountTryDepositEntireWorktopOrAbort(
		_ accountAddress: RETAddress,
		_ authorizedDepositorBadge: ResourceOrNonFungible?
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public func accountTryDepositEntireWorktopOrAbort(
		accountAddress: RETAddress,
		authorizedDepositorBadge: ResourceOrNonFungible?
	) -> ManifestBuilder {
		panic()
	}

	public static func withdrawAmount(
		_ from: RETAddress,
		_ resourceAddress: RETAddress,
		_ amount: RETDecimal
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func withdrawTokens(
		_ from: RETAddress,
		_ resourceAddress: RETAddress,
		ids: [NonFungibleLocalId]
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func takeFromWorktop(
		_ address: RETAddress,
		_ amount: RETDecimal,
		_ bucket: ManifestBuilderBucket
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	///	= flip(takeAllFromWorktop)
	public static func takeAllFromWorktop(
		_ resourceAddress: RETAddress,
		_ bucket: ManifestBuilderBucket
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	///	= flip(accountTryDepositOrAbort)
	public static func accountTryDepositOrAbort(
		_ address: RETAddress,
		_ bucket: ManifestBuilderBucket,
		_ authorizedDepositorBadge: ResourceOrNonFungible?
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func accountDeposit(
		_ recipientAddress: RETAddress,
		_ bucket: ManifestBuilderBucket
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	///	= flip(takeNonFungiblesFromWorktop)
	public static func takeNonFungiblesFromWorktop(
		_ resourceAddress: RETAddress,
		_ localIds: [NonFungibleLocalId],
		_ bucket: ManifestBuilderBucket
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func accountWithdrawNonFungibles(
		_ account: RETAddress,
		_ resourceAddress: RETAddress,
		_ ids: [NonFungibleLocalId]
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public func createFungibleResourceManager(
		ownerRole: OwnerRole,
		trackTotalSupply: Bool,
		divisibility: UInt8,
		initialSupply: RETDecimal,
		resourceRoles: FungibleResourceRoles,
		metadata: MetadataModuleConfig,
		addressReservation: ManifestBuilderAddressReservation?
	) -> ManifestBuilder {
		panic()
	}

	public static func createFungibleResourceManager(
		_ ownerRole: OwnerRole,
		_ trackTotalSupply: Bool,
		_ divisibility: UInt8,
		_ initialSupply: RETDecimal,
		_ resourceRoles: FungibleResourceRoles,
		_ metadata: MetadataModuleConfig,
		_ addressReservation: ManifestBuilderAddressReservation?
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func validatorClaimXrd(
		_ validatorAddress: RETAddress,
		_ bucket: ManifestBuilderBucket
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

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

		public static func buildEither(first component: Instructions) -> Instructions {
			component
		}

		public static func buildEither(second component: Instructions) -> Instructions {
			component
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
		for item in try content() {
			// Build each instruction by updating the builder
			builder = try item(builder)
		}
		return builder
	}

	public static func make(@InstructionsChain _ content: () async throws -> InstructionsChain.Instructions) async throws -> ManifestBuilder {
		var builder = ManifestBuilder()
		// Collect all partial instructions to be built
		for item in try await content() {
			// Build each instruction by updating the builder
			builder = try item(builder)
		}
		return builder
	}
}

/// Flips the argument order of a five-argument curried function.
///
/// - Parameter function: A five-argument, curried function.
/// - Returns: A curried function with its first two arguments flipped.
public func flip<A, B, C, D, E, F, G, H, I>(_ function: @escaping (A) -> (B, C, D, E, F, G, H) throws -> I)
	-> (B, C, D, E, F, G, H) -> (A) throws -> I
{
	{ (b: B, c: C, d: D, e: E, f: F, g: G, h: H) -> (A) throws -> I in
		{ (a: A) throws -> I in
			try function(a)(b, c, d, e, f, g, h)
		}
	}
}
