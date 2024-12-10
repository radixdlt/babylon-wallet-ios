// MARK: - FactorSourceDetail.View
extension FactorSourceDetail {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<FactorSourceDetail>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .zero) {
						ForEachStatic(rows(viewStore)) { kind in
							SettingsRow(kind: kind, store: store)
						}
					}
				}
				.background(Color.app.gray5)
				.radixToolbar(title: viewStore.name)
				.foregroundStyle(.app.gray1)
			}
		}

		private func rows(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> [SettingsRow<FactorSourceDetail>.Kind] {
			switch viewStore.factorSource.kind {
			case .device:
				[
					.header("Factor Settings"),
					renameRow(viewStore),
					.header("Test"),
					spotCheckRow(viewStore),
					.header("Advanced"),
					viewSeedPhraseRow(viewStore),
				]
			case .ledgerHqHardwareWallet, .offDeviceMnemonic, .password:
				[
					.header("Factor Settings"),
					renameRow(viewStore),
					.header("Test"),
					spotCheckRow(viewStore),
				]
			case .arculusCard:
				[
					.header("Factor Settings"),
					renameRow(viewStore),
					togglePinRow(viewStore),
					changePinRow(viewStore),
					.header("Test"),
					spotCheckRow(viewStore),
				]
			case .trustedContact, .securityQuestions:
				fatalError("Not implemented")
			}
		}

		private func renameRow(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> SettingsRow<FactorSourceDetail>.Kind {
			.model(
				title: viewStore.name,
				subtitle: "Rename this factor",
				icon: .asset(.create),
				action: .renameTapped
			)
		}

		private func spotCheckRow(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> SettingsRow<FactorSourceDetail>.Kind {
			.model(
				title: "Spot Check",
				subtitle: "Test that you can use this factor",
				markdown: viewStore.lastUsed,
				icon: .systemImage("checkmark.circle"),
				action: .renameTapped
			)
		}

		private func viewSeedPhraseRow(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> SettingsRow<FactorSourceDetail>.Kind {
			.model(
				title: "View Seed Phrase",
				subtitle: "Write down the seed phrase for advanced recovery",
				icon: .systemImage("eye.fill"),
				action: .viewSeedPhraseTapped
			)
		}

		private func togglePinRow(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> SettingsRow<FactorSourceDetail>.Kind {
			.toggleModel(
				icon: .create,
				title: "Turn PIN on/off",
				minHeight: .zero,
				isOn: .constant(true)
			)
		}

		private func changePinRow(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> SettingsRow<FactorSourceDetail>.Kind {
			.model(
				title: "Change PIN",
				icon: .asset(.create),
				action: .changePinTapped
			)
		}
	}
}

private extension FactorSourceDetail.State {
	var name: String {
		factorSource.asGeneral.name
	}

	var lastUsed: String {
		let value = RadixDateFormatter.string(from: factorSource.asGeneral.common.lastUsedOn, dateStyle: .abbreviated)
		return "**Last used:** \(value)"
	}
}
