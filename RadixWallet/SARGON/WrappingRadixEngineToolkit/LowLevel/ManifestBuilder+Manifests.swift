

extension ManifestBuilder {
	public static func withdrawTokens(
		fungible: ResourceAddress,
		nonFungibleIDs: [NonFungibleLocalId],
		fromOwner: AccountAddress
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func takeFromWorktop(
		resource: ResourceAddress,
		amount: RETDecimal,
		bucket: ManifestBuilderBucket
	) throws -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func accountTryDepositOrAbort(
		recipientAddress: AccountAddress,
		bucket: ManifestBuilderBucket,
		authorizedDepositorBadge: ResourceOrNonFungible?
	) -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func accountDeposit(
		recipientAddress: AccountAddress,
		bucket: ManifestBuilderBucket
	) throws -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func takeNonFungiblesFromWorktop(
		resource: ResourceAddress,
		localIds: [NonFungibleLocalId],
		bucket: ManifestBuilderBucket
	) throws -> ManifestBuilder.InstructionsChain.Instruction {
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

extension ManifestBuilderBucket {
	public static var unique: ManifestBuilderBucket {
		panic()
	}
}
