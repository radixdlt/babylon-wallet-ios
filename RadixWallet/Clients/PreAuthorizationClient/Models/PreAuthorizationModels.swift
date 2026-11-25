import Foundation

// MARK: - PreAuthorizationPreview
struct PreAuthorizationPreview: Hashable {
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
	/// Whether the wallet has something to sign: entities that must authorize
	/// it, or access controllers it calls, e.g. a recovery proposal for a
	/// shared account, whose roles may name this wallet's keys.
	var requiresSignatures: Bool {
		switch self {
		case let .open(value):
			!value.summary.addressesOfAccountsRequiringAuth.isEmpty
				|| !value.summary.addressesOfPersonasRequiringAuth.isEmpty
				|| !value.summary.accessControllersCalled.isEmpty
		case let .enclosed(value):
			!value.summary.addressesOfAccountsRequiringAuth.isEmpty
				|| !value.summary.addressesOfIdentitiesRequiringAuth.isEmpty
				|| value.summary.callsAccessControllers
		}
	}
}

private extension ExecutionSummary {
	/// Whether it changes, confirms, stops or locks access controllers, the
	/// operations a pre-authorization may make: signed with the wallet's keys
	/// their roles name.
	var callsAccessControllers: Bool {
		detailedClassification?.isAccessControllerOperation ?? false
	}
}
