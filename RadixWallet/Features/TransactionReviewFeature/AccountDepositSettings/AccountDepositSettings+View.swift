import ComposableArchitecture
import SwiftUI

// MARK: - AccountDepositSettings.View
extension AccountDepositSettings {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountDepositSettings>

		public init(store: StoreOf<AccountDepositSettings>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: .small1) {
					ForEach(viewStore.accounts) {
						AccountDepositSettingsChangeView(viewState: .init(from: $0))
					}
				}
			}
		}
	}
}

extension AccountDepositSettingsChangeView.ViewState {
	init(from settingsChange: AccountDepositSettingsChange) {
		self.init(
			account: settingsChange.account,
			resourcePreferenceChanges: .init(uncheckedUniqueElements: settingsChange.resourceChanges.map {
				ResourceChangeView.ViewState(resource: $0.resource, changeDescription: $0.change.description)
			}),
			allowedDepositorChanges: .init(uncheckedUniqueElements: settingsChange.allowedDepositorChanges.map {
				ResourceChangeView.ViewState(resource: $0.resource, changeDescription: $0.change.description)
			}),
			depositRuleChange: settingsChange.depositRuleChange
		)
	}
}

// MARK: - AccountDepositSettingsChangeView
struct AccountDepositSettingsChangeView: View {
	public struct ViewState: Equatable {
		let account: Profile.Network.Account
		let resourcePreferenceChanges: IdentifiedArrayOf<ResourceChangeView.ViewState>
		let allowedDepositorChanges: IdentifiedArrayOf<ResourceChangeView.ViewState>
		let depositRuleChange: AccountDefaultDepositRule?

		var hasChanges: Bool {
			!resourcePreferenceChanges.isEmpty || !allowedDepositorChanges.isEmpty
		}
	}

	let viewState: ViewState

	public var body: some SwiftUI.View {
		Card {
			InnerCard {
				SmallAccountCard(account: viewState.account)
				VStack(spacing: .medium2) {
					if let depositRuleChange = viewState.depositRuleChange {
						Text(LocalizedStringKey(depositRuleChange.string))
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
						if viewState.hasChanges {
							Separator()
						}
					}
					ForEach(viewState.resourcePreferenceChanges) { viewState in
						ResourceChangeView(viewState: viewState)
					}
					ForEach(viewState.allowedDepositorChanges) { viewState in
						ResourceChangeView(viewState: viewState)
					}
				}
				.padding(.medium3)
				.frame(maxWidth: .infinity)
				.background(.app.gray5)
			}
			.padding(.small1)
		}
	}
}

// MARK: - ResourceChangeView
struct ResourceChangeView: View {
	struct ViewState: Equatable, Identifiable {
		var id: OnLedgerEntity.Resource {
			resource
		}

		let resource: OnLedgerEntity.Resource
		let changeDescription: String
	}

	let viewState: ViewState

	var body: some View {
		HStack {
			ResourceIconNameView(resource: viewState.resource)
			Spacer(minLength: .zero)
			Text(viewState.changeDescription)
				.textStyle(.secondaryHeader)
				.foregroundColor(.app.gray1)
		}
	}
}

extension ResourcePreferenceUpdate {
	var description: String {
		switch self {
		case .remove:
			L10n.TransactionReview.AccountDepositSettings.assetChangeClear
		case .set(.allowed):
			L10n.TransactionReview.AccountDepositSettings.assetChangeAllow
		case .set(.disallowed):
			L10n.TransactionReview.AccountDepositSettings.assetChangeDisallow
		}
	}
}

extension AccountDepositSettingsChange.AllowedDepositorChange.Change {
	var description: String {
		switch self {
		case .added:
			L10n.TransactionReview.AccountDepositSettings.depositorChangeAdd
		case .removed:
			L10n.TransactionReview.AccountDepositSettings.depositorChangeRemove
		}
	}
}

extension AccountDefaultDepositRule {
	var string: String {
		switch self {
		case .accept:
			L10n.TransactionReview.AccountDepositSettings.acceptAllRule
		case .reject:
			L10n.TransactionReview.AccountDepositSettings.denyAllRule
		case .allowExisting:
			L10n.TransactionReview.AccountDepositSettings.acceptKnownRule
		}
	}
}

// MARK: - ResourceIconNameView
struct ResourceIconNameView: View {
	let resource: OnLedgerEntity.Resource

	var body: some View {
		HStack(alignment: .center) {
			if case .globalNonFungibleResourceManager = resource.resourceAddress.decodedKind {
				NFTThumbnail(resource.metadata.iconURL)
			} else {
				TokenThumbnail(.known(resource.metadata.iconURL))
			}
			Text(resource.metadata.name ?? "")
				.foregroundColor(.app.gray1)
				.textStyle(.body2HighImportance)
		}
	}
}
