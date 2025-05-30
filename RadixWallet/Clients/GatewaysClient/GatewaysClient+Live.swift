
extension GatewaysClient: DependencyKey {
	typealias Value = GatewaysClient

	static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		@Dependency(\.appPreferencesClient) var appPreferencesClient

		return Self(
			currentGatewayValues: { await profileStore.currentGatewayValues() },
			gatewaysValues: { await profileStore.gatewaysValues() },
			getAllGateways: { await appPreferencesClient.getPreferences().gateways.all.asIdentified() },
			getCurrentGateway: { await profileStore.tryGetProfile()?.appPreferences.gateways.current ?? .mainnet },
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
			},
			hasGateway: { url in
				await appPreferencesClient.getPreferences().hasGateway(with: url)
			}
		)
	}

	static let liveValue: Self = .live()
}
