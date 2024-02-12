import Foundation

// MARK: - ManifestSummary
public struct ManifestSummary: DummySargon {
	public var accountsDepositedInto: [AccountAddress] {
		sargon()
	}

	public var accountsWithdrawnFrom: [AccountAddress] {
		sargon()
	}

	public var accountsRequiringAuth: [AccountAddress] {
		sargon()
	}

	public var identitiesRequiringAuth: [IdentityAddress] {
		sargon()
	}
}
