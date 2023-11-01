import ComposableArchitecture
import SwiftUI
extension DerivePublicKeys.State {
	var viewState: DerivePublicKeys.ViewState {
		.init(
			ledger: ledgerBeingUsed,
			entityKind: (/DerivePublicKeys.State.Purpose.createEntity).extract(from: purpose)
		)
	}
}

// MARK: - DerivePublicKeys.View
extension DerivePublicKeys {
	public struct ViewState: Equatable {
		public let ledger: LedgerHardwareWalletFactorSource?
		let entityKind: EntityKind?
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<DerivePublicKeys>

		public init(store: StoreOf<DerivePublicKeys>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					Image(asset: AssetResource.iconHardwareLedger)
						.frame(.medium)
						.padding(.vertical, .medium2)

					Text(
						viewStore.entityKind == .identity
							? L10n.CreatePersona.DerivePublicKeys.title
							: L10n.CreateAccount.DerivePublicKeys.title
					)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
					.padding(.bottom, .medium1)

					Text(L10n.CreateAccount.DerivePublicKeys.subtitle)
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
						.padding(.horizontal, .medium1)
						.padding(.bottom, .medium1)

					if let ledger = viewStore.ledger {
						LedgerRowView(viewState: .init(factorSource: ledger))
					}

					ProgressView()
						.padding(.top, .large3)

					Spacer(minLength: 0)
				}
				.padding(.horizontal, .medium1)
				.onFirstTask { @MainActor in
					/// For more information about that `sleep` please  check [this discussion in Slack](https://rdxworks.slack.com/archives/C03QFAWBRNX/p1687967412207119?thread_ts=1687964494.772899&cid=C03QFAWBRNX)
					@Dependency(\.continuousClock) var clock
					try? await clock.sleep(for: .milliseconds(700))

					await viewStore.send(.onFirstTask).finish()
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI
import ComposableArchitecture //
//// MARK: - DerivePublicKey_Preview
// struct DerivePublicKey_Preview: PreviewProvider {
//	static var previews: some View {
//		DerivePublicKeys.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: DerivePublicKeys.init
//			)
//		)
//	}
// }
//
// extension DerivePublicKeys.State {
//	public static let previewValue = Self()
// }
// #endif
