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
	public var executionCost: Decimal192 { sargon() }
	public var finalizationCost: Decimal192 { sargon() }
	public var storageExpansionCost: Decimal192 { sargon() }
	public var royaltyCost: Decimal192 { sargon() }
}

// MARK: - FeeLocks
public enum FeeLocks: DummySargon {
	public var lock: Decimal192 { sargon() }
	public var contingentLock: Decimal192 { sargon() }
}

// MARK: - ReservedInstruction
public enum ReservedInstruction: DummySargon {}
