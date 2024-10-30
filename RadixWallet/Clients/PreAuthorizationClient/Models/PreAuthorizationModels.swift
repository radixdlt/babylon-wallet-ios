import Foundation

struct PreAuthorizationPreview: Sendable, Hashable {
	let kind: PreAuthToReview
	let networkID: NetworkID

	var manifest: SubintentManifest {
		switch kind {
		case let .open(open):
			open.manifest
		case let .enclosed(enclosed):
			enclosed.manifest
		}
	}
}
