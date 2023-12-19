import ComposableArchitecture
import SwiftUI

extension DerivePublicKeys.State {
	var viewState: DerivePublicKeys.ViewState {
		.init(
			ledger: ledgerBeingUsed,
			purpose: purpose
		)
	}
}

// MARK: - DerivePublicKeys.View
extension DerivePublicKeys {
	public struct ViewState: Equatable {
		public let ledger: LedgerHardwareWalletFactorSource?
		let purpose: DerivePublicKeys.State.Purpose

		var title: String {
			switch purpose {
			case .createNewEntity(.account):
				L10n.DerivePublicKeys.titleCreateAccount

			case .createNewEntity(.identity):
				L10n.DerivePublicKeys.titleCreatePersona

			case .accountRecoveryScan:
				L10n.DerivePublicKeys.titleAccountRecoveryScan

			case .importLegacyAccounts:
				L10n.DerivePublicKeys.titleImportLegacyAccount

			case .createAuthSigningKey(.account):
				L10n.DerivePublicKeys.titleCreateAuthSignKeyForAccount

			case .createAuthSigningKey(.identity):
				L10n.DerivePublicKeys.titleCreateAuthSignKeyForPersona
			}
		}

		var subtitle: String {
			if ledger != nil {
				L10n.DerivePublicKeys.subtitleLedger
			} else {
				L10n.DerivePublicKeys.subtitleDevice
			}
		}
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

					Text(viewStore.title)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
						.padding(.bottom, .medium1)

					Text(LocalizedStringKey(viewStore.subtitle))
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
