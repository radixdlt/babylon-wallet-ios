import FeaturePrelude

// MARK: - Permission.State
extension Permission {
	struct State: Sendable, Hashable {
		let permissionKind: DappInteraction.PermissionKind
		let dappMetadata: DappMetadata

		init(
			permissionKind: DappInteraction.PermissionKind,
			dappMetadata: DappMetadata
		) {
			self.permissionKind = permissionKind
			self.dappMetadata = dappMetadata
		}
	}
}

#if DEBUG
extension Permission.State {
	static let previewValue: Self = .init(
		permissionKind: .accounts(.ongoing),
		dappMetadata: .previewValue
	)
}
#endif
