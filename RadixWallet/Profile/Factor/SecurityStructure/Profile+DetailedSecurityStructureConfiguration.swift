

extension Profile {
	public func detailedSecurityStructureConfiguration(
		reference: SecurityStructureConfigurationReference
	) throws -> SecurityStructureConfigurationDetailed {
		try .init(
			metadata: reference.metadata,
			configuration: detailedSecurityStructureConfiguration(referenceConfiguration: reference.configuration)
		)
	}

	func detailedSecurityStructureConfiguration(
		referenceConfiguration reference: SecurityStructureConfigurationReference.Configuration
	) throws -> SecurityStructureConfigurationDetailed.Configuration {
		try .init(
			numberOfDaysUntilAutoConfirmation: reference.numberOfDaysUntilAutoConfirmation,
			primaryRole: detailedSecurityStructureRole(referenceRole: reference.primaryRole),
			recoveryRole: detailedSecurityStructureRole(referenceRole: reference.recoveryRole),
			confirmationRole: detailedSecurityStructureRole(referenceRole: reference.confirmationRole)
		)
	}

	func detailedSecurityStructureRole<R: RoleProtocol>(
		referenceRole reference: RoleOfTier<R, FactorSourceID>
	) throws -> RoleOfTier<R, FactorSource> {
		func lookup(id: FactorSourceID) throws -> FactorSource {
			guard let factorSource = factorSources.first(where: { $0.id == id }) else {
				throw FactorSourceWithIDNotFound()
			}
			return factorSource
		}

		return try .init(
			uncheckedThresholdFactors: .init(validating: reference.thresholdFactors.map(lookup(id:))),
			superAdminFactors: .init(validating: reference.superAdminFactors.map(lookup(id:))),
			threshold: reference.threshold
		)
	}
}
