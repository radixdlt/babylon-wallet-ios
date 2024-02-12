import Foundation

// MARK: - ExecutionSummary
public struct ExecutionSummary: DummySargon {
	public struct NewEntities: DummySargon {
		public var metadata: [String: [String: MetadataValue?]] {
			sargon()
		}
	}

	public var newEntities: NewEntities {
		sargon()
	}

	public var accountWithdraws: [String: [ResourceIndicator]] {
		sargon()
	}

	public var accountDeposits: [String: [ResourceIndicator]] {
		sargon()
	}

	public var reservedInstructions: [ReservedInstruction] {
		sargon()
	}

	public var newlyCreatedNonFungibles: [NonFungibleGlobalId] {
		sargon()
	}

	public var presentedProofs: [ResourceAddress] {
		sargon()
	}

	public var encounteredEntities: [Address] {
		sargon()
	}

	public var feeLocks: FeeLocks { sargon() }

	public var feeSummary: FeeSummary { sargon() }

	public var detailedManifestClass: DetailedManifestClass? {
		sargon()
	}

	public var metadataOfNewlyCreatedEntities: [String: [String: MetadataValue?]] {
		newEntities.metadata
	}

	public var addressesOfNewlyCreatedEntities: [Address] {
		sargon()
	}
}

// MARK: - FeeSummary
public enum FeeSummary: DummySargon {
	public var executionCost: RETDecimal { sargon() }
	public var finalizationCost: RETDecimal { sargon() }
	public var storageExpansionCost: RETDecimal { sargon() }
	public var royaltyCost: RETDecimal { sargon() }
}

// MARK: - FeeLocks
public enum FeeLocks: DummySargon {
	public var lock: RETDecimal { sargon() }
	public var contingentLock: RETDecimal { sargon() }
}

// MARK: - ReservedInstruction
public enum ReservedInstruction: DummySargon {}
