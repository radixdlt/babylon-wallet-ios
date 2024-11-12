extension ResourcesVisibilityClient: DependencyKey {
	typealias Value = ResourcesVisibilityClient

	static let liveValue: Self = .live()

	static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		.init(
			hide: { resource, hide in
				try await profileStore.updatingOnCurrentNetwork { network in
					hide ? network.resourcePreferences.hideResource(resource: resource) : network.resourcePreferences.unhideResource(resource: resource)
				}
			},
			getHidden: {
				try await profileStore.network().getHiddenResources()
			},
			hiddenValues: {
				await profileStore.hiddenResourcesValues()
			}
		)
	}
}
