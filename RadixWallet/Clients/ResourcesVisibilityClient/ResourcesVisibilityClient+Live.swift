extension ResourcesVisibilityClient: DependencyKey {
	public typealias Value = ResourcesVisibilityClient

	public static let liveValue: Self = .live()

	public static func live(
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
