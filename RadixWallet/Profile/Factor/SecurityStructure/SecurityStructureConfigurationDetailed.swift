

public typealias SecurityStructureConfigurationDetailed = AbstractSecurityStructureConfiguration<FactorSource>

extension SecurityStructureConfigurationDetailed {
	public func asReference() -> SecurityStructureConfigurationReference {
		.init(
			metadata: metadata,
			configuration: configuration.asReference()
		)
	}

	public var isSimple: Bool {
		asReference().isSimple
	}
}

extension SecurityStructureConfigurationDetailed.Configuration {
	public func asReference() -> SecurityStructureConfigurationReference.Configuration {
		.init(
			numberOfDaysUntilAutoConfirmation: numberOfDaysUntilAutoConfirmation,
			primaryRole: primaryRole.asReference(),
			recoveryRole: recoveryRole.asReference(),
			confirmationRole: confirmationRole.asReference()
		)
	}

	public var isSimple: Bool {
		asReference().isSimple
	}
}
