// MARK: - SecurityFactors.View
extension SecurityFactors {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SecurityFactors>

		init(store: StoreOf<SecurityFactors>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			content
				.radixToolbar(title: L10n.SecurityFactors.title)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
				.presentsLoadingViewOverlay()
				.destinations(with: store)
		}
	}
}

@MainActor
private extension SecurityFactors.View {
	var content: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .zero) {
					ForEachStatic(rows(viewStore: viewStore)) { kind in
						SettingsRow(kind: kind, store: store)
					}
				}
			}
			.background(Color.app.gray5)
			.task {
				store.send(.view(.task))
			}
		}
	}

	func rows(viewStore: ViewStore<SecurityFactors.State, SecurityFactors.ViewAction>) -> [SettingsRow<SecurityFactors>.Kind] {
		[
			.header("Manage the security factors you’ll use in your Security Shield."),
			model(kind: .device, hints: viewStore.deviceHints),
			.header("Hardware"),
			model(kind: .ledgerHqHardwareWallet),
		]
	}

	func model(kind: FactorSourceKind, hints: [Hint.ViewState] = []) -> SettingsRow<SecurityFactors>.Kind {
		.model(
			title: kind.title,
			subtitle: kind.details,
			hints: hints,
			icon: .asset(kind.icon),
			action: .rowTapped(kind)
		)
	}
}

// MARK: - Extensions

private extension SecurityFactors.State {
	var deviceHints: [Hint.ViewState] {
		securityProblems
			.compactMap(\.securityFactors)
			.map { .init(kind: .warning, text: $0) }
	}
}

private extension StoreOf<SecurityFactors> {
	var destination: PresentationStoreOf<SecurityFactors.Destination> {
		func scopeState(state: State) -> PresentationState<SecurityFactors.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SecurityFactors>) -> some View {
		let destinationStore = store.destination
		return seedPhrases(with: destinationStore)
			.ledgerHardwareWallets(with: destinationStore)
	}

	private func seedPhrases(with destinationStore: PresentationStoreOf<SecurityFactors.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.seedPhrases, action: \.seedPhrases)) {
			DisplayMnemonics.View(store: $0)
		}
	}

	private func ledgerHardwareWallets(with destinationStore: PresentationStoreOf<SecurityFactors.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.ledgerWallets, action: \.ledgerWallets)) {
			LedgerHardwareDevices.View(store: $0)
				.background(.app.gray5)
				.radixToolbar(title: L10n.AccountSecuritySettings.LedgerHardwareWallets.title)
		}
	}
}
