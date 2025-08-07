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
				.tint(Color.primaryText)
				.foregroundColor(Color.primaryText)
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
			.background(Color.secondaryBackground)
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
			model(kind: .ledgerHqHardwareWallet),
			model(kind: .arculusCard),
//			.header(L10n.SecurityFactors.information),
//			model(kind: .password),
//			model(kind: .offDeviceMnemonic),
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
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SecurityFactors>) -> some View {
		let destinationStore = store.destination
		return deviceFactorSources(with: destinationStore)
	}

	private func deviceFactorSources(with destinationStore: PresentationStoreOf<SecurityFactors.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.factorSourcesList, action: \.factorSourcesList)) {
			FactorSourcesList.View(store: $0)
		}
	}
}
