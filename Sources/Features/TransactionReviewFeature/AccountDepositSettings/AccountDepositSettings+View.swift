import EngineKit
import FeaturePrelude

// MARK: - AccountDepositSettings.View
extension AccountDepositSettings {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountDepositSettings>

		public init(store: StoreOf<AccountDepositSettings>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
				Card {
					VStack(spacing: .small1) {
						ForEachStore(
							store.scope(
								state: \.accounts,
								action: { .child(.account(id: $0, action: $1)) }
							),
							content: { AccountDepositSettingsChange.View(store: $0) }
						)
					}
					.padding(.small1)
				}
			}
		}
	}
}

extension AccountDepositSettingsChange.State {
	var viewState: AccountDepositSettingsChange.ViewState {
		.init(account: account, resourceChanges: resourceChanges, depositRuleChange: depositRuleChange)
	}
}

// MARK: - TransactionReviewAccount.View
extension AccountDepositSettingsChange {
	public struct ViewState: Equatable {
		let account: Profile.Network.Account
		let resourceChanges: IdentifiedArrayOf<AccountDepositSettingsChange.State.ResourceChange>
		let depositRuleChange: AccountDefaultDepositRule?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountDepositSettingsChange>

		public init(store: StoreOf<AccountDepositSettingsChange>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				InnerCard {
					SmallAccountCard(account: viewStore.account)
					VStack(spacing: .medium3) {
						if let depositRuleChange = viewStore.depositRuleChange {
							Text(depositRuleChange.string)
								.foregroundColor(.app.gray1)
								.textStyle(.body1Regular)
							Separator()
						}
						ForEach(viewStore.resourceChanges) { resourceChange in
							Button(action: { viewStore.send(.assetTapped(resourceChange.resource)) }) {
								HStack {
									ResourceIconNameView(resource: resourceChange.resource)
									Spacer(minLength: .zero)
									Text(resourceChange.change.string)
										.textStyle(.secondaryHeader)
										.foregroundColor(.app.gray1)
								}
							}
						}
					}
					.padding(.medium3)
					.frame(maxWidth: .infinity)
					.background(.app.gray5)
				}
			}
		}
	}
}

extension AccountDepositSettingsChange.State.ResourceChange.Change {
	var string: String {
		switch self {
		case .resourcePreference(.remove):
			return "Clear Exception"
		case .resourcePreference(.set(.allowed)):
			return "Allow"
		case .resourcePreference(.set(.disallowed)):
			return "Disallow"
		case .authorizedDepositorAdded:
			return "Allow Depositor"
		case .authorizedDepositorRemoved:
			return "Clear Depositor"
		}
	}
}

extension AccountDefaultDepositRule {
	var string: String {
		switch self {
		case .accept:
			return "Allow third parties to deposit any asset to this account."
		case .reject:
			return "Disallow all deposits from third parties without your consent."
		case .allowExisting:
			return "Allow third parties to deposit only assets this account has already held."
		}
	}
}

// MARK: - ResourceIconNameView
struct ResourceIconNameView: View {
	let resource: OnLedgerEntity.Resource

	var body: some View {
		HStack(alignment: .center) {
			if case .globalNonFungibleResourceManager = resource.resourceAddress.decodedKind {
				NFTThumbnail(resource.iconURL)
			} else {
				TokenThumbnail(.known(resource.iconURL))
			}
			Text(resource.name ?? "")
				.foregroundColor(.app.gray1)
				.textStyle(.body2HighImportance)
		}
	}
}
