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
			case .createNewEntity(kind: .account):
				L10n.CreateAccount.DerivePublicKeys.title

			case .createNewEntity(kind: .identity):
				L10n.CreatePersona.DerivePublicKeys.title

			case .importLegacyAccounts:
				"Deriving Accounts" // FIXME: String

			case .accountRecoveryScan:
				"Deriving Accounts" // FIXME: Strings

			case .createAuthSigningKey(forEntityKind: .account):
				"Creating Key" // FIXME: Strings

			case .createAuthSigningKey(forEntityKind: .identity):
				"Creating Key" // FIXME: Strings
			}
		}

		var subtitle: String {
			switch purpose {
			case .createNewEntity(.account):
				"Authenticate to your phone to complete using your phone’s signing key." // FIXME: Strings delete `createAccount_derivePublicKeys_subtitle` add new key `L10n.DerivePublicKeys.CreateNewAccount.subtitle`

			case .createNewEntity(.identity):
				"Authenticate to your phone to complete using your phone’s signing key." // FIXME: Strings is this correct?  add new key `L10n.DerivePublicKeys.CreateNewPersona.subtitle`

			case .accountRecoveryScan:
				"Authenticate to your phone to complete using your phone's signing key" // FIXME: Strings is this correct?  add new key `L10n.DerivePublicKeys.AccountRecoveryScan.subtitle`

			case .importLegacyAccounts:
				"Authenticate to your phone to complete using your phone's signing key" // FIXME: Strings is this correct?  add new key `L10n.DerivePublicKeys.ImportLegacyAccount.subtitle`

			case .createAuthSigningKey(.account):
				"Authenticate to your phone to complete using your phone's signing key" // FIXME: Strings is this correct?  add new key `L10n.DerivePublicKeys.CreateAuthSignKeyForAccount.subtitle`

			case .createAuthSigningKey(.identity):
				"Authenticate to your phone to complete using your phone's signing key" // FIXME: Strings is this correct?  add new key `L10n.DerivePublicKeys.CreateAuthSignKeyForIdentity.subtitle`
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

					Text(
						viewStore.title
					)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
					.padding(.bottom, .medium1)

					Text(viewStore.subtitle)
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
