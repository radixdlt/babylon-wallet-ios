
extension GatewaysClient: DependencyKey {
	public typealias Value = GatewaysClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			currentGatewayValues: { await getProfileStore().currentGatewayValues() },
			gatewaysValues: { await getProfileStore().gatewaysValues() },
			getAllGateways: { await appPreferencesClient.getPreferences().gateways.all },
			getCurrentGateway: { await appPreferencesClient.getPreferences().gateways.current },
			addGateway: { gateway in
				try await getProfileStore().updating { profile in
					try profile.addNewGateway(gateway)
				}
			},
			removeGateway: { gateway in
				try await getProfileStore().updating { profile in
					try profile.removeGateway(gateway)
				}
			},
			changeGateway: { gateway in
				try await getProfileStore().updating { profile in
					try profile.changeGateway(to: gateway)
				}
			}
		)
	}

	public static let liveValue: Self = .live()
}
