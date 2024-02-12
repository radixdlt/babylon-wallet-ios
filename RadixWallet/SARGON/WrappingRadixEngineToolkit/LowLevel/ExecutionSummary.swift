import Foundation

// MARK: - ExecutionSummary
public struct ExecutionSummary: DummySargon {
	public struct NewEntities: DummySargon {
		public var metadata: [String: [String: MetadataValue?]] {
			panic()
		}

		public var componentAddresses: [ComponentAddress] {
			panic()
		}

		public var resourceAddresses: [ResourceAddress] {
			panic()
		}

		public var packageAddresses: [PackageAddress] {
			panic()
		}
	}

	public var detailedClassification: [DetailedManifestClass] {
		panic()
	}

	public var newEntities: NewEntities {
		panic()
	}

	public var accountWithdraws: [String: [ResourceIndicator]] {
		panic()
	}

	public var accountDeposits: [String: [ResourceIndicator]] {
		panic()
	}

	public var reservedInstructions: [ReservedInstruction] {
		panic()
	}

	public var newlyCreatedNonFungibles: [NonFungibleGlobalId] {
		panic()
	}

	public var presentedProofs: [ResourceAddress] {
		panic()
	}

	public var encounteredEntities: [Address] {
		panic()
	}

	public var feeLocks: FeeLocks { panic() }

	public var feeSummary: FeeSummary { panic() }

	/// Use the first supported manifest class. Returns `nil` for non-conforming transactions
	public var detailedManifestClass: DetailedManifestClass? {
		detailedClassification.first(where: \.isSupported)
	}

	public var metadataOfNewlyCreatedEntities: [String: [String: MetadataValue?]] {
		newEntities.metadata
	}

	public var dataOfNewlyMintedNonFungibles: [String: [NonFungibleLocalId: Data]] {
		[:] // TODO: Is this never populated for .general?
	}

	public var addressesOfNewlyCreatedEntities: [Address] {
		newEntities.componentAddresses.map(\.asGeneral) + newEntities.packageAddresses.map(\.asGeneral) + newEntities.resourceAddresses.map(\.asGeneral)
	}
}

// MARK: - FeeSummary
public enum FeeSummary: DummySargon {
	public var executionCost: RETDecimal { panic() }
	public var finalizationCost: RETDecimal { panic() }
	public var storageExpansionCost: RETDecimal { panic() }
	public var royaltyCost: RETDecimal { panic() }
}

// MARK: - FeeLocks
public enum FeeLocks: DummySargon {
	public var lock: RETDecimal { panic() }
	public var contingentLock: RETDecimal { panic() }
}

// MARK: - ReservedInstruction
public enum ReservedInstruction: DummySargon {}
