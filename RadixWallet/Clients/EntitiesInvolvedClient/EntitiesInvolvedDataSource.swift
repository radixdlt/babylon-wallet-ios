import Foundation

// MARK: - EntitiesInvolvedDataSource
protocol EntitiesInvolvedDataSource: Sendable {
	var addressesOfPersonasRequiringAuth: [IdentityAddress] { get }
	var addressesOfAccountsRequiringAuth: [AccountAddress] { get }
	var addressesOfAccountsWithdrawnFrom: [AccountAddress] { get }
	var addressesOfAccountsDepositedInto: [AccountAddress] { get }
}

// MARK: - ManifestSummary + EntitiesInvolvedDataSource
extension ManifestSummary: EntitiesInvolvedDataSource {}

// MARK: - PreAuthToReview + EntitiesInvolvedDataSource
extension PreAuthToReview: EntitiesInvolvedDataSource {
	var addressesOfPersonasRequiringAuth: [IdentityAddress] {
		switch self {
		case let .open(value):
			value.summary.addressesOfPersonasRequiringAuth
		case let .enclosed(value):
			value.summary.addressesOfIdentitiesRequiringAuth
		}
	}

	var addressesOfAccountsRequiringAuth: [AccountAddress] {
		switch self {
		case let .open(value):
			value.summary.addressesOfAccountsRequiringAuth
		case let .enclosed(value):
			value.summary.addressesOfAccountsRequiringAuth
		}
	}

	var addressesOfAccountsWithdrawnFrom: [AccountAddress] {
		switch self {
		case let .open(value):
			value.summary.addressesOfAccountsWithdrawnFrom
		case let .enclosed(value):
			// TODO: Add support
			[]
		}
	}

	var addressesOfAccountsDepositedInto: [AccountAddress] {
		switch self {
		case let .open(value):
			value.summary.addressesOfAccountsDepositedInto
		case let .enclosed(value):
			// TODO: Add support
			[]
		}
	}
}
