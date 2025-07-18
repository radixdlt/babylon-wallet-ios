// MARK: - FactorSourceDetail.View
extension FactorSourceDetail {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<FactorSourceDetail>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .zero) {
						ForEachStatic(rows()) { kind in
							SettingsRow(kind: kind, store: store)
						}
					}
				}
				.background(Color.secondaryBackground)
				.radixToolbar(title: store.name)
				.foregroundStyle(Color.primaryText)
				.destination(store: store)
			}
		}

		private func rows() -> [SettingsRow<FactorSourceDetail>.Kind] {
			switch store.integrity {
			case let .device(device):
				[
					.header(L10n.FactorSources.Detail.manage),
					renameRow(),
					deviceSeedPhraseRow(device),
					// .header(L10n.FactorSources.Detail.test),
					// spotCheckRow(viewStore),
				]
			case .ledger:
				[
					.header(L10n.FactorSources.Detail.manage),
					renameRow(),
//					.header(L10n.FactorSources.Detail.test),
//					spotCheckRow(viewStore),
				]
			default:
				[
					.header(L10n.FactorSources.Detail.manage),
				]
			}
		}

		private func renameRow() -> SettingsRow<FactorSourceDetail>.Kind {
			.model(
				title: store.name,
				subtitle: L10n.FactorSources.Detail.rename,
				icon: .asset(.create),
				action: .renameTapped
			)
		}

//		private func spotCheckRow(_ viewStore: ViewStore<FactorSourceDetail.State, FactorSourceDetail.ViewAction>) -> SettingsRow<FactorSourceDetail>.Kind {
//			.model(
//				title: L10n.FactorSources.Detail.spotCheck,
//				subtitle: L10n.FactorSources.Detail.testCanUse,
//				markdown: viewStore.lastUsedMessage,
//				icon: .systemImage("checkmark.circle"),
//				action: .spotCheckTapped
//			)
//		}

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
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<FactorSourceDetail>) -> some View {
		let destinationStore = store.destination
		return rename(with: destinationStore)
			.displayMnemonic(with: destinationStore)
			.importMnemonics(with: destinationStore)
		// .spotCheckAlert(with: destinationStore)
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
		sheet(store: destinationStore.scope(state: \.importMnemonic, action: \.importMnemonic)) { store in
			NavigationStack {
				ImportMnemonicForFactorSource.View(store: store)
			}
		}
	}

//	private func spotCheckAlert(with destinationStore: PresentationStoreOf<FactorSourceDetail.Destination>) -> some View {
//		alert(store: destinationStore.scope(state: \.spotCheckAlert, action: \.spotCheckAlert))
//	}
}
