import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewDepositSetting.View
extension TransactionReviewDepositSetting {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReviewDepositSetting>

		public init(store: StoreOf<TransactionReviewDepositSetting>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				Card {
					VStack(spacing: .small1) {
						ForEach(viewStore.changes) { change in
							InnerCard {
								SmallAccountCard(account: change.account)

								HStack(spacing: .medium3) {
									Image(asset: change.ruleChange.image)
										.frame(.smallest)

									Text(LocalizedStringKey(change.ruleChange.string))
										.foregroundColor(.app.gray1)
										.textStyle(.body1Regular)
								}
								.padding(.medium3)
							}
						}
					}
				}
			}
		}
	}
}

// MARK: - TransactionReviewDepositExceptions.View
extension TransactionReviewDepositExceptions {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReviewDepositExceptions>

		public init(store: StoreOf<TransactionReviewDepositExceptions>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			EmptyView()
		}
	}
}

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

		init(account: Profile.Network.Account, resourcePreferenceChanges: IdentifiedArrayOf<ResourceChangeView.ViewState>, allowedDepositorChanges: IdentifiedArrayOf<ResourceChangeView.ViewState>, depositRuleChange: AccountDefaultDepositRule?) {
			self.account = account
			self.resourcePreferenceChanges = resourcePreferenceChanges
			self.allowedDepositorChanges = allowedDepositorChanges
			self.depositRuleChange = depositRuleChange
		}
	}

	let viewState: ViewState

	public var body: some SwiftUI.View {
		Card {
			InnerCard {
				SmallAccountCard(account: viewState.account)
					.border(.red)

				VStack(spacing: .medium2) {
					if let depositRuleChange = viewState.depositRuleChange {
						Text(LocalizedStringKey(depositRuleChange.string))
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.border(.purple)
						if viewState.hasChanges {
							Separator()
						}
					}
					ForEach(viewState.resourcePreferenceChanges) { viewState in
						ResourceChangeView(viewState: viewState)
							.border(.yellow)
					}
					ForEach(viewState.allowedDepositorChanges) { viewState in
						ResourceChangeView(viewState: viewState)
							.border(.green)
					}
				}
				.border(.pink)
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

	var image: ImageAsset {
		switch self {
		case .accept:
			AssetResource.iconAcceptAirdrop
		case .reject:
			AssetResource.iconDeclineAirdrop
		case .allowExisting:
			AssetResource.iconAcceptKnownAirdrop
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
