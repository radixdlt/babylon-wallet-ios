extension Preferences.State {
	var viewState: Preferences.ViewState {
		.init()
	}
}

// MARK: - Preferences.View

public extension Preferences {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Preferences>

		public init(store: StoreOf<Preferences>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			content
				.navigationTitle("Preferences")
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
				.toolbarBackground(.app.background, for: .navigationBar)
				.toolbarBackground(.visible, for: .navigationBar)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
				.presentsLoadingViewOverlay()
				.destinations(with: store)
		}
	}
}

extension Preferences.View {
	@MainActor
	private var content: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .zero) {
					ForEach(rows) { kind in
						kind.build(viewStore: viewStore)
					}
				}
			}
			.background(Color.app.gray4)
			.onAppear {
				viewStore.send(.appeared)
			}
		}
	}

	@MainActor
	private var rows: [SettingsRowKind<Preferences>] {
		[
			.separator,
			.model(.init(
				title: "Default Deposit Guarantees",
				subtitle: "Set your guaranteed minimum for estimated deposits",
				icon: .asset(AssetResource.depositGuarantees),
				action: .depositGuaranteesButtonTapped
			)),
		]
	}
}

private extension StoreOf<Preferences> {
	var destination: PresentationStoreOf<Preferences.Destination> {
		func scopeState(state: State) -> PresentationState<Preferences.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<Preferences>) -> some View {
		let destinationStore = store.destination
		return depositGuarantees(with: destinationStore)
	}

	private func depositGuarantees(with destinationStore: PresentationStoreOf<Preferences.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /Preferences.Destination.State.depositGuarantees,
			action: Preferences.Destination.Action.depositGuarantees,
			destination: { DefaultDepositGuarantees.View(store: $0) }
		)
	}
}
