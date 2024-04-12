

public typealias SecurityStructureConfigurationReference = AbstractSecurityStructureConfiguration<FactorSourceID>

extension SecurityStructureConfigurationReference {
	public var isSimple: Bool {
		configuration.isSimple
	}
}

extension SecurityStructureConfigurationReference.Configuration {
	public var isSimple: Bool {
		primaryRole.hasSingleFactorSourceOf(kind: .device) &&
			recoveryRole.hasSingleFactorSourceOf(kind: .trustedContact) &&
			confirmationRole.hasSingleFactorSourceOf(kind: .securityQuestions)
	}
}

extension SecurityStructureConfigurationReference.Configuration.Recovery {
	public static let defaultNumberOfDaysUntilAutoConfirmation: RecoveryAutoConfirmDelayInDays = .init(14)
}
