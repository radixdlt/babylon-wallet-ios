import Foundation

// MARK: - ManifestSummary
public struct ManifestSummary: DummySargon {
	public var accountsDepositedInto: [AccountAddress] {
		panic()
	}

	public var accountsWithdrawnFrom: [AccountAddress] {
		panic()
	}

	public var accountsRequiringAuth: [AccountAddress] {
		panic()
	}

	public var identitiesRequiringAuth: [IdentityAddress] {
		panic()
	}
}
