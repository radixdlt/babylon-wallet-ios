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
			.header(L10n.SecurityFactors.subtitle),
			model(kind: .device, hints: viewStore.deviceHints),
			.header(L10n.SecurityFactors.hardware),
			model(kind: .arculusCard),
			model(kind: .ledgerHqHardwareWallet),
			.header(L10n.SecurityFactors.information),
			model(kind: .password),
			model(kind: .offDeviceMnemonic),
		]
	}

	func model(kind: FactorSourceKind, hints: [Hint.ViewState] = []) -> SettingsRow<SecurityFactors>.Kind {
		.model(
			title: kind.title,
			subtitle: kind.details,
			hints: hints,
			icon: .asset(kind.icon),
			action: .factorSourceRowTapped(kind)
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
		return device(with: destinationStore)
			.ledgerHardwareWallets(with: destinationStore)
			.todo(with: destinationStore)
	}

	private func device(with destinationStore: PresentationStoreOf<SecurityFactors.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.device, action: \.device)) {
			DeviceFactorSourcesList.View(store: $0)
		}
	}

	private func ledgerHardwareWallets(with destinationStore: PresentationStoreOf<SecurityFactors.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.ledgerWallets, action: \.ledgerWallets)) {
			LedgerHardwareDevices.View(store: $0)
				.background(.app.gray5)
				.radixToolbar(title: L10n.AccountSecuritySettings.LedgerHardwareWallets.title)
		}
	}

	private func todo(with destinationStore: PresentationStoreOf<SecurityFactors.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.todo, action: \.todo)) { _ in
			TodoView(feature: "Add factor")
		}
	}
}
