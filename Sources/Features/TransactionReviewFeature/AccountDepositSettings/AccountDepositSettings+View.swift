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
		.init(
			account: account,
			resourcePreferenceChanges: .init(uncheckedUniqueElements: resourceChanges.map {
				ResourceChangeView.ViewState(resource: $0.resource, changeDescription: $0.change.description)
			}),
			allowedDepositorChanges: .init(uncheckedUniqueElements: allowedDepositorChanges.map {
				ResourceChangeView.ViewState(resource: $0.resource, changeDescription: $0.change.description)
			}),
			depositRuleChange: depositRuleChange
		)
	}
}

// MARK: - TransactionReviewAccount.View
extension AccountDepositSettingsChange {
	public struct ViewState: Equatable {
		let account: Profile.Network.Account
		let resourcePreferenceChanges: IdentifiedArrayOf<ResourceChangeView.ViewState>
		let allowedDepositorChanges: IdentifiedArrayOf<ResourceChangeView.ViewState>
		let depositRuleChange: AccountDefaultDepositRule?

		var hasChanges: Bool {
			!resourcePreferenceChanges.isEmpty || !allowedDepositorChanges.isEmpty
		}
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
							if viewStore.hasChanges {
								Separator()
							}
						}
						ForEach(viewStore.resourcePreferenceChanges) { viewState in
							ResourceChangeView(viewState: viewState) {
								viewStore.send(.assetTapped($0))
							}
						}
						ForEach(viewStore.allowedDepositorChanges) { viewState in
							ResourceChangeView(viewState: viewState) {
								viewStore.send(.assetTapped($0))
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
	let onTapped: (OnLedgerEntity.Resource) -> Void

	var body: some View {
		Button(action: { onTapped(viewState.resource) }) {
			HStack {
				ResourceIconNameView(resource: viewState.resource)
				Spacer(minLength: .zero)
				Text(viewState.changeDescription)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
			}
		}
	}
}

extension ResourcePreferenceAction {
	var description: String {
		// FIXME: Strings
		switch self {
		case .remove:
			return "Clear Exception"
		case .set(.allowed):
			return "Allow"
		case .set(.disallowed):
			return "Disallow"
		}
	}
}

extension AccountDepositSettingsChange.State.AllowedDepositorChange.Change {
	var description: String {
		switch self {
		case .added:
			return "Add Depositor"
		case .removed:
			return "Clear Depositor"
		}
	}
}

extension AccountDefaultDepositRule {
	var string: String {
		// FIXME: Strings
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
