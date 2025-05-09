// MARK: - FactoryReset.View
extension FactoryReset {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<FactoryReset>

		init(store: StoreOf<FactoryReset>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			content
				.radixToolbar(title: L10n.FactoryReset.title)
				.tint(.primaryText)
				.foregroundColor(.primaryText)
				.presentsLoadingViewOverlay()
				.destinations(with: store)
		}
	}
}

@MainActor
extension FactoryReset.View {
	private var content: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: .large3) {
				Text(L10n.FactoryReset.message)
					.textStyle(.body1Link)
					.foregroundColor(.secondaryText)
					.padding(.horizontal, .small3)

				securityCenter()

				Spacer()
			}
			.padding(.horizontal, .medium2)
			.padding(.vertical, .medium3)
		}
		.background(.secondaryBackground)
		.footer { resetWallet }
		.onFirstTask { @MainActor in
			await store.send(.view(.onFirstTask)).finish()
		}
	}

	private func securityCenter() -> some View {
		VStack(spacing: .zero) {
			VStack(spacing: .medium2) {
				Text(L10n.FactoryReset.status)
					.textStyle(.body1Header)
					.foregroundColor(.primaryText)

				status()
			}
			.padding(.horizontal, .medium3)
			.padding(.vertical, .large3)
			.background(.primaryBackground)

			disclosure
		}
		.cornerRadius(.small1)
		.shadow(color: .secondaryText.opacity(0.26), radius: .medium3, x: 0, y: 6)
	}

	private func status() -> some View {
		WithViewStore(store, observe: \.isRecoverable) { viewStore in
			let isRecoverable = viewStore.state
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
				.background(isRecoverable ? .app.green2 : .alert)
				.cornerRadius(.small1)

				if !isRecoverable {
					Text(L10n.FactoryReset.Unrecoverable.message)
						.textStyle(.body1Link)
						.foregroundColor(.alert)
				}
			}
		}
	}

	private var disclosure: some View {
		HStack(spacing: .medium3) {
			Image(.error)
			Text(L10n.FactoryReset.disclosure)
				.textStyle(.body1Regular)
		}
		.foregroundColor(.primaryText)
		.padding(.medium2)
		.frame(maxWidth: .infinity)
		.background(.secondaryBackground)
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
		alert(store: destinationStore.scope(state: \.confirmReset, action: \.confirmReset))
	}
}
