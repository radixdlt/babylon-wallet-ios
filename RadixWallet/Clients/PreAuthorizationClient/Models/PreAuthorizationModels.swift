import Foundation

// MARK: - PreAuthorizationPreview
struct PreAuthorizationPreview: Sendable, Hashable {
	let kind: PreAuthToReview
	let networkId: NetworkID

	var manifest: SubintentManifest {
		switch kind {
		case let .open(open):
			open.manifest
		case let .enclosed(enclosed):
			enclosed.manifest
		}
	}

	var requiresSignatures: Bool {
		kind.requiresSignatures
	}
}

private extension PreAuthToReview {
	var requiresSignatures: Bool {
		switch self {
		case let .open(value):
			!value.summary.addressesOfAccountsRequiringAuth.isEmpty || !value.summary.addressesOfPersonasRequiringAuth.isEmpty
		case let .enclosed(value):
			!value.summary.addressesOfAccountsRequiringAuth.isEmpty || !value.summary.addressesOfIdentitiesRequiringAuth.isEmpty
		}
	}
}
