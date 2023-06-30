import Prelude

// MARK: - AbstractSecurityStructureConfiguration
public struct AbstractSecurityStructureConfiguration<AbstractFactor>:
	Sendable, Hashable, Codable, Identifiable
	where AbstractFactor: FactorOfTierProtocol & Sendable & Hashable & Codable
{
	public typealias Configuration = AbstractSecurityStructure<AbstractFactor>
	// Mutable so that we can update factor structure
	public var configuration: Configuration

	// Mutable so we can rename and update date
	public var metadata: SecurityStructureMetadata

	public init(
		metadata: SecurityStructureMetadata,
		configuration: Configuration
	) {
		self.metadata = metadata
		self.configuration = configuration
	}
}

extension AbstractSecurityStructureConfiguration {
	public typealias ID = UUID
	public var id: ID {
		metadata.id
	}
}
