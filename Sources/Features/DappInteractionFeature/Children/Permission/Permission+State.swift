import FeaturePrelude

// MARK: - Permission.State
extension Permission {
	struct State: Sendable, Hashable {
		let permissionKind: Kind
		let dappMetadata: DappMetadata

		init(
			permissionKind: Kind,
			dappMetadata: DappMetadata
		) {
			self.permissionKind = permissionKind
			self.dappMetadata = dappMetadata
		}
	}
}

// MARK: - Permission.Kind
extension Permission {
	enum Kind: Sendable, Equatable {
		case account
		case personalData
	}
}

#if DEBUG
extension Permission.State {
	static let previewValue: Self = .init(
		permissionKind: .account,
		dappMetadata: .previewValue
	)
}
#endif
