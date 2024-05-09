extension FactoryReset.State {
	var viewState: FactoryReset.ViewState {
		.init(isRecoverable: false)
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
				.setUpNavigationBar(title: "Factory Reset")
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
				.presentsLoadingViewOverlay()
//				.destinations(with: store)
		}
	}
}

@MainActor
extension FactoryReset.View {
	private var content: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			VStack(alignment: .leading, spacing: .large3) {
				Text("A factory reset will restore your Radix wallet to its original settings. All of your data and preferences will be erased.")
					.textStyle(.body1Link)
					.foregroundColor(.app.gray2)
					.padding(.horizontal, .small3)

				securityCenter(isRecoverable: viewStore.isRecoverable)

				Spacer()
			}
			.padding(.horizontal, .medium2)
			.padding(.vertical, .medium3)
			.background(Color.app.gray5)
			.footer { resetWallet }
		}
	}

	private func securityCenter(isRecoverable: Bool) -> some View {
		VStack(spacing: .zero) {
			VStack(spacing: .medium2) {
				Text("Security Center status")
					.textStyle(.body1Header)
					.foregroundColor(.app.gray1)

				status(isRecoverable: isRecoverable)
			}
			.padding(.horizontal, .medium3)
			.padding(.vertical, .large3)
			// .frame(maxWidth: .infinity)
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
				Text(isRecoverable ? "Your wallet is recoverable" : "Your wallet is not recoverable")
					.textStyle(.body1Header)
				Spacer()
			}
			.foregroundColor(.app.white)
			.padding(.horizontal, .medium2)
			.frame(height: .large1)
			.frame(maxWidth: .infinity)
			.background(isRecoverable ? .app.green2 : .app.alert)
			.cornerRadius(.small1)

			if !isRecoverable {
				Text("Your wallet is currently unrecoverable. If you do a factory reset now, you will never be able to access your Accounts and Personas again.")
					.textStyle(.body1Link)
					.foregroundColor(.app.alert)
			}
		}
	}

	private var disclosure: some View {
		HStack(spacing: .medium3) {
			Image(.error)
			Text("Once you’ve completed a factory reset, you will not be able to access your Accounts and Personas unless you do a full recovery.")
				.textStyle(.body1Regular)
		}
		.foregroundColor(.app.gray1)
		.padding(.medium2)
		.frame(maxWidth: .infinity)
		.background(Color.app.gray5)
	}

	private var resetWallet: some View {
		Button("Reset Wallet") {
			store.send(.view(.resetWalletButtonTapped))
		}
		.buttonStyle(.primaryRectangular(isDestructive: true))
	}
}
