// MARK: - FactorSourceAccess.View

public extension FactorSourceAccess {
	struct ViewState: Equatable {
		let title: String
		let message: String
		let externalDevice: String?
		let retryEnabled: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<FactorSourceAccess>

		public init(store: StoreOf<FactorSourceAccess>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium3) {
					Image(asset: AssetResource.signingKey)
						.foregroundColor(.app.gray3)

					Text(viewStore.title)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)

					Text(viewStore.message)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)

					externalDevice(viewStore.externalDevice)

					if viewStore.retryEnabled {
						Button {
							viewStore.send(.retryButtonTapped)
						} label: {
							Text(L10n.Common.retry)
								.textStyle(.body1Header)
								.foregroundColor(.app.blue2)
								.frame(height: .standardButtonHeight)
								.frame(maxWidth: .infinity)
						}
					}
				}
				.padding(.horizontal, .large2)
			}
			.withNavigationBar {
				store.send(.view(.closeButtonTapped))
			}
			.presentationDetents([.fraction(0.66)])
			.presentationDragIndicator(.visible)
			.interactiveDismissDisabled()
			.onFirstTask { @MainActor in
				await store.send(.view(.onFirstTask)).finish()
			}
		}

		@ViewBuilder
		private func externalDevice(_ value: String?) -> some SwiftUI.View {
			if let value {
				HStack(spacing: .medium3) {
					Image(asset: AssetResource.signingKey)
						.resizable()
						.frame(.smallest)
						.foregroundColor(.app.gray3)

					Text(value)
						.textStyle(.secondaryHeader)
						.foregroundColor(.app.gray1)
						.padding(.trailing, .small2)
				}
				.padding(.medium2)
				.background(Color.app.gray5)
				.cornerRadius(.large1)
			}
		}
	}
}

// MARK: - ViewState
extension FactorSourceAccess.State {
	var viewState: FactorSourceAccess.ViewState {
		.init(
			title: title,
			message: message,
			externalDevice: externalDevice,
			retryEnabled: retryEnabled
		)
	}

	private var title: String {
		typealias S = L10n.FactorSourceAccess.Title
		switch purpose {
		case .signature:
			return S.signature
		case .createAccount:
			return S.createAccount
		case .deriveAccounts:
			return S.deriveAccounts
		case .proveOwnership:
			return S.proveOwnership
		case .encryptMessage:
			return S.encryptMessage
		case .createKey:
			return S.createKey
		}
	}

	private var message: String {
		typealias S = L10n.FactorSourceAccess.Message
		switch kind {
		case .device:
			switch purpose {
			case .signature:
				return S.Device.signature
			case .createAccount, .deriveAccounts, .proveOwnership, .encryptMessage, .createKey:
				return S.Device.general
			}
		case .ledger:
			switch purpose {
			case .signature:
				return S.Ledger.signature
			case .deriveAccounts:
				return S.Ledger.deriveAccounts
			case .createAccount, .proveOwnership, .encryptMessage, .createKey:
				return S.Ledger.general
			}
		}
	}

	private var externalDevice: String? {
		switch kind {
		case .device:
			nil
		case let .ledger(value):
			value?.hint.name
		}
	}

	private var retryEnabled: Bool {
		false
	}
}
