import FeaturePrelude

// MARK: - Permission.State
public extension Permission {
	struct State: Sendable, Hashable {
		public let permissionKind: Kind
		public let dappMetadata: DappMetadata

		public init(
			permissionKind: Kind,
			dappMetadata: DappMetadata
		) {
			self.permissionKind = permissionKind
			self.dappMetadata = dappMetadata
		}
	}
}

// MARK: - Permission.Kind
public extension Permission {
	enum Kind: Sendable, Equatable {
		case account
		case personalData
	}
}

#if DEBUG
public extension Permission.State {
	static let previewValue: Self = .init(
		permissionKind: .account,
		dappMetadata: .previewValue
	)
}
#endif
