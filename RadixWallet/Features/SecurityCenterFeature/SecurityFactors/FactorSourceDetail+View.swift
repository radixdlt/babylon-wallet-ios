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
			switch viewStore.factorSource.kind {
			case .device:
				[
					.header(L10n.FactorSources.Detail.settings),
					renameRow(viewStore),
					.header(L10n.FactorSources.Detail.test),
					spotCheckRow(viewStore),
					.header(L10n.FactorSources.Detail.advanced),
					viewSeedPhraseRow(viewStore),
				]
			case .ledgerHqHardwareWallet, .offDeviceMnemonic, .password:
				[
					.header(L10n.FactorSources.Detail.settings),
					renameRow(viewStore),
					.header(L10n.FactorSources.Detail.test),
					spotCheckRow(viewStore),
				]
			case .arculusCard:
				[
					.header(L10n.FactorSources.Detail.settings),
					renameRow(viewStore),
					changePinRow(viewStore),
					.header(L10n.FactorSources.Detail.test),
					spotCheckRow(viewStore),
				]
			case .trustedContact, .securityQuestions:
				fatalError("Not implemented")
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
				markdown: viewStore.lastUsed,
				icon: .systemImage("checkmark.circle"),
				action: .renameTapped
			)
		}

		private func viewSeedPhraseRow(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> SettingsRow<FactorSourceDetail>.Kind {
			.model(
				title: L10n.FactorSources.Detail.viewSeedPhrase,
				subtitle: L10n.FactorSources.Detail.writeSeedPhrase,
				icon: .systemImage("eye.fill"),
				action: .viewSeedPhraseTapped
			)
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
	var lastUsed: String {
		let value = RadixDateFormatter.string(from: factorSource.asGeneral.common.lastUsedOn, dateStyle: .abbreviated)
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
}
