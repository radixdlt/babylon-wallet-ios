import FactorSourcesClient
import FeaturePrelude

extension SignWithFactorSourcesOfKindLedger.State {
	var viewState: SignWithFactorSourcesOfKindLedger.ViewState {
		.init(
			currentSigningFactor: currentSigningFactor,
			purpose: signingPurposeWithPayload.purpose == .signAuth ? .signAuth : .signTX
		)
	}
}

// MARK: - SignWithFactorSourcesOfKindLedger.View
extension SignWithFactorSourcesOfKindLedger {
	public struct ViewState: Equatable {
		let currentSigningFactor: SigningFactor?
		let purpose: UseLedgerView.Purpose

		var ledger: LedgerHardwareWalletFactorSource? {
			currentSigningFactor.flatMap {
				currentSigningFactor.factorSource.extract(LedgerHardwareWalletFactorSource.self)
			}
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SignWithFactorSourcesOfKindLedger>

		public init(store: StoreOf<SignWithFactorSourcesOfKindLedger>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Image(asset: AssetResource.signingKey)
						.padding(.bottom, .large3)
						.foregroundColor(.app.gray3)

					Text(L10n.Signing.SignatureRequest.title)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
						.padding(.bottom, .large2)

					Text(LocalizedStringKey(L10n.Signing.SignatureRequest.body))
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)
						.padding(.bottom, .medium1)

					Text(L10n.Signing.SignatureRequest.instructions)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)

					Spacer(minLength: .small2)

					if let ledger = viewStore.ledger {
						HStack(spacing: 0) {
							Image(asset: AssetResource.signingKey)
								.resizable()
								.aspectRatio(contentMode: .fit)
								.foregroundColor(.app.gray3)
								.frame(.smallest)
								.padding(.trailing, .small1)

							Text(ledger.name)
								.textStyle(.secondaryHeader)
						}
						.padding(.horizontal, .medium2)
						.padding(.vertical, .medium3)
						.background(.app.gray5, in: Capsule(style: .continuous))
						.padding(.bottom, .medium2)

						Button {
							viewStore.send(.retryButtonTapped)
						} label: {
							Text(L10n.Common.retry)
								.textStyle(.body1Header)
								.foregroundColor(.app.gray1)
						}
						.padding(.bottom, .medium2)
					} else {
						// FIXME: Error state
					}
				}
				.multilineTextAlignment(.center)
				.padding(.horizontal, .large2)
				.onFirstTask { @MainActor in
					await viewStore.send(.onFirstTask).finish()
				}
			}
		}
	}
}
