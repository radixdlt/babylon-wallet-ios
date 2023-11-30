import ComposableArchitecture
import SwiftUI

extension DerivePublicKeys.State {
	var viewState: DerivePublicKeys.ViewState {
		.init(
			ledger: ledgerBeingUsed,
			entityKind: (/SecureStorageClient.LoadMnemonicPurpose.createEntity).extract(from: purpose)
		)
	}
}

// MARK: - DerivePublicKeys.View
extension DerivePublicKeys {
	public struct ViewState: Equatable {
		public let ledger: LedgerHardwareWalletFactorSource?
		let entityKind: EntityKind?
	}

	@MainActor
	public struct View: SwiftUI.View {
		@SwiftUI.State private var id = UUID()
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
				.onFirstAppear {
					viewStore.send(.onFirstAppear)
				}
			}
		}
	}
}
