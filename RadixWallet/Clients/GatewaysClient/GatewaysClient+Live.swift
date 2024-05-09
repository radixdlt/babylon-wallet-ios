
extension GatewaysClient: DependencyKey {
	public typealias Value = GatewaysClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			currentGatewayValues: { await profileStore.currentGatewayValues() },
			gatewaysValues: { await profileStore.gatewaysValues() },
			getAllGateways: { await appPreferencesClient.getPreferences().gateways.all.asIdentified() },
			getCurrentGateway: { await appPreferencesClient.getPreferences().gateways.current },
			addGateway: { gateway in
				try await profileStore.updating { profile in
					try profile.addNewGateway(gateway)
				}
			},
			removeGateway: { gateway in
				try await profileStore.updating { profile in
					try profile.removeGateway(gateway)
				}
			},
			changeGateway: { gateway in
				try await profileStore.updating { profile in
					try profile.changeGateway(to: gateway)
				}
			}
		)
	}

	public static let liveValue: Self = .live()
}
