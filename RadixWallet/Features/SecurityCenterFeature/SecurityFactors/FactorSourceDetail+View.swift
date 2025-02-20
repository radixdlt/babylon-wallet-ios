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
				.destination(store: store)
			}
		}

		private func rows(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> [SettingsRow<FactorSourceDetail>.Kind] {
			switch viewStore.integrity {
			case let .device(device):
				[
					.header(L10n.FactorSources.Detail.manage),
					renameRow(viewStore),
					deviceSeedPhraseRow(device),
					.header(L10n.FactorSources.Detail.test),
					spotCheckRow(viewStore),
				]
			case .ledger, .offDeviceMnemonic, .password:
				[
					.header(L10n.FactorSources.Detail.manage),
					renameRow(viewStore),
					.header(L10n.FactorSources.Detail.test),
					spotCheckRow(viewStore),
				]
			case .arculusCard:
				[
					.header(L10n.FactorSources.Detail.manage),
					renameRow(viewStore),
					changePinRow(viewStore),
					.header(L10n.FactorSources.Detail.test),
					spotCheckRow(viewStore),
				]
			}
		}

		private func renameRow(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> SettingsRow<FactorSourceDetail>.Kind {
			.model(
				title: viewStore.name,
				subtitle: L10n.FactorSources.Detail.rename,
				icon: .asset(.create),
				action: .renameTapped
			)
		}

		private func spotCheckRow(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> SettingsRow<FactorSourceDetail>.Kind {
			.model(
				title: L10n.FactorSources.Detail.spotCheck,
				subtitle: L10n.FactorSources.Detail.testCanUse,
				markdown: viewStore.lastUsedMessage,
				icon: .systemImage("checkmark.circle"),
				action: .spotCheckTapped
			)
		}

		private func deviceSeedPhraseRow(_ integrity: DeviceFactorSourceIntegrity) -> SettingsRow<FactorSourceDetail>.Kind {
			if integrity.isMnemonicPresentInSecureStorage {
				.model(
					title: L10n.FactorSources.Detail.viewSeedPhrase,
					subtitle: L10n.FactorSources.Detail.writeSeedPhrase,
					icon: .systemImage("eye.fill"),
					action: .viewSeedPhraseTapped
				)
			} else {
				.model(
					isError: true,
					title: L10n.FactorSources.Detail.seedPhraseLost,
					subtitle: L10n.FactorSources.Detail.enterSeedPhrase,
					icon: .systemImage("eye.fill"),
					action: .enterSeedPhraseTapped
				)
			}
		}

		private func changePinRow(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> SettingsRow<FactorSourceDetail>.Kind {
			.model(
				title: L10n.FactorSources.Detail.changePin,
				icon: .asset(.create),
				action: .changePinTapped
			)
		}
	}
}

private extension FactorSourceDetail.State {
	var lastUsedMessage: String {
		let value = RadixDateFormatter.string(from: lastUsed, dateStyle: .abbreviated)
		return L10n.FactorSources.Detail.lastUsed(value)
	}
}

private extension StoreOf<FactorSourceDetail> {
	var destination: PresentationStoreOf<FactorSourceDetail.Destination> {
		func scopeState(state: State) -> PresentationState<FactorSourceDetail.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<FactorSourceDetail>) -> some View {
		let destinationStore = store.destination
		return rename(with: destinationStore)
			.displayMnemonic(with: destinationStore)
			.importMnemonics(with: destinationStore)
			.spotCheckAlert(with: destinationStore)
	}

	private func rename(with destinationStore: PresentationStoreOf<FactorSourceDetail.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.rename, action: \.rename)) {
			RenameLabel.View(store: $0)
		}
	}

	private func displayMnemonic(with destinationStore: PresentationStoreOf<FactorSourceDetail.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.displayMnemonic, action: \.displayMnemonic)) {
			DisplayMnemonic.View(store: $0)
		}
	}

	private func importMnemonics(with destinationStore: PresentationStoreOf<FactorSourceDetail.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.importMnemonics, action: \.importMnemonics)) {
			ImportMnemonicsFlowCoordinator.View(store: $0)
		}
	}

	private func spotCheckAlert(with destinationStore: PresentationStoreOf<FactorSourceDetail.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.spotCheckAlert, action: \.spotCheckAlert))
	}
}
