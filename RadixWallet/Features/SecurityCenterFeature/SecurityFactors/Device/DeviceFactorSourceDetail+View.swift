// MARK: - DeviceFactorSourceDetail.View
extension DeviceFactorSourceDetail {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DeviceFactorSourceDetail>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .zero) {
						ForEachStatic(rows(viewStore: viewStore)) { kind in
							SettingsRow(kind: kind, store: store)
						}
					}
				}
				.background(Color.app.gray5)
				.radixToolbar(title: viewStore.name)
				.foregroundStyle(.app.gray1)
			}
		}

		private func rows(viewStore: ViewStore<DeviceFactorSourceDetail.State, DeviceFactorSourceDetail.ViewAction>) -> [SettingsRow<DeviceFactorSourceDetail>.Kind] {
			[
				.header("Factor Settings"),
				.model(
					title: viewStore.name,
					subtitle: "Rename this factor",
					icon: .asset(.create),
					action: .renameTapped
				),
				.header("Test"),
				.model(
					title: "Spot Check",
					subtitle: "Test that you can use this factor",
					markdown: viewStore.lastUsed,
					icon: .systemImage("checkmark.circle"),
					action: .renameTapped
				),
				.header("Advanced"),
				.model(
					title: "View Seed Phrase",
					subtitle: "Write down the seed phrase for advanced recovery",
					icon: .systemImage("eye.fill"),
					action: .viewSeedPhraseTapped
				),
			]
		}
	}
}

private extension DeviceFactorSourceDetail.State {
	var name: String {
		factorSource.asGeneral.name
	}

	var lastUsed: String {
		let value = RadixDateFormatter.string(from: factorSource.asGeneral.common.lastUsedOn, dateStyle: .abbreviated)
		return "**Last used:** \(value)"
	}
}
