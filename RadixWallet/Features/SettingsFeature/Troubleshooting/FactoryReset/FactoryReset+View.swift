extension FactoryReset.State {
	var viewState: FactoryReset.ViewState {
		.init(isRecoverable: isRecoverable)
	}
}

// MARK: - FactoryReset.View

public extension FactoryReset {
	struct ViewState: Equatable {
		let isRecoverable: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<FactoryReset>

		public init(store: StoreOf<FactoryReset>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			content
				.radixToolbar(title: L10n.FactoryReset.title)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
				.presentsLoadingViewOverlay()
				.destinations(with: store)
		}
	}
}

@MainActor
extension FactoryReset.View {
	private var content: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(alignment: .leading, spacing: .large3) {
					Text(L10n.FactoryReset.message)
						.textStyle(.body1Link)
						.foregroundColor(.app.gray2)
						.padding(.horizontal, .small3)

					securityCenter(isRecoverable: viewStore.isRecoverable)

					Spacer()
				}
				.padding(.horizontal, .medium2)
				.padding(.vertical, .medium3)
			}
			.background(Color.app.gray5)
			.footer { resetWallet }
			.onFirstTask { @MainActor in
				await viewStore.send(.onFirstTask).finish()
			}
		}
	}

	private func securityCenter(isRecoverable: Bool) -> some View {
		VStack(spacing: .zero) {
			VStack(spacing: .medium2) {
				Text(L10n.FactoryReset.status)
					.textStyle(.body1Header)
					.foregroundColor(.app.gray1)

				status(isRecoverable: isRecoverable)
			}
			.padding(.horizontal, .medium3)
			.padding(.vertical, .large3)
			.background(Color.app.white)

			disclosure
		}
		.cornerRadius(.small1)
		.shadow(color: .app.gray2.opacity(0.26), radius: .medium3, x: 0, y: 6)
	}

	private func status(isRecoverable: Bool) -> some View {
		VStack(alignment: .leading) {
			HStack(spacing: .small1) {
				Image(isRecoverable ? .security : .error)
				Text(isRecoverable ? L10n.FactoryReset.recoverable : L10n.FactoryReset.Unrecoverable.title)
					.textStyle(.body1Header)
					.multilineTextAlignment(.leading)
					.minimumScaleFactor(0.8)
					.lineLimit(1)
				Spacer()
			}
			.foregroundColor(.app.white)
			.padding(.horizontal, .medium2)
			.padding(.vertical, .small2)
			.frame(maxWidth: .infinity)
			.background(isRecoverable ? .app.green2 : .app.alert)
			.cornerRadius(.small1)

			if !isRecoverable {
				Text(L10n.FactoryReset.Unrecoverable.message)
					.textStyle(.body1Link)
					.foregroundColor(.app.alert)
			}
		}
	}

	private var disclosure: some View {
		HStack(spacing: .medium3) {
			Image(.error)
			Text(L10n.FactoryReset.disclosure)
				.textStyle(.body1Regular)
		}
		.foregroundColor(.app.gray1)
		.padding(.medium2)
		.frame(maxWidth: .infinity)
		.background(Color.app.gray5)
	}

	private var resetWallet: some View {
		Button(L10n.FactoryReset.resetWallet) {
			store.send(.view(.resetWalletButtonTapped))
		}
		.buttonStyle(.primaryRectangular(isDestructive: true))
	}
}

private extension StoreOf<FactoryReset> {
	var destination: PresentationStoreOf<FactoryReset.Destination> {
		func scopeState(state: State) -> PresentationState<FactoryReset.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<FactoryReset>) -> some View {
		let destination = store.destination
		return confirmReset(with: destination)
	}

	private func confirmReset(with destinationStore: PresentationStoreOf<FactoryReset.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /FactoryReset.Destination.State.confirmReset,
			action: FactoryReset.Destination.Action.confirmReset
		)
	}
}
