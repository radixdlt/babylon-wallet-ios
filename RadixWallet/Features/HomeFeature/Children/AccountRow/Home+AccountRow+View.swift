import ComposableArchitecture
import SwiftUI

extension Home.AccountRow {
	public struct ViewState: Equatable {
		let name: String
		let address: AccountAddress
		let appearanceID: Profile.Network.Account.AppearanceID
		let isLoadingResources: Bool

		public enum AccountTag: Int, Hashable, Identifiable, Sendable {
			case ledgerBabylon
			case ledgerLegacy
			case legacySoftware
			case dAppDefinition

			init?(state: Home.AccountRow.State) {
				switch (state.isDappDefinitionAccount, state.isLegacyAccount, state.isLedgerAccount) {
				case (false, false, false): return nil
				case (true, _, _): self = .dAppDefinition
				case (false, true, true): self = .ledgerLegacy
				case (false, true, false): self = .legacySoftware
				case (false, false, true): self = .ledgerBabylon
				}
			}
		}

		let tag: AccountTag?

		let isLedgerAccount: Bool
		let mnemonicHandlingCallToAction: MnemonicHandling?

		let fungibleResourceIcons: [TokenThumbnail.Content]
		let nonFungibleResourcesCount: Int
		let stakedValidatorsCount: Int
		let poolUnitsCount: Int

		var showMoreFungibles: Bool {
			nonFungibleResourcesCount == 0 && stakedValidatorsCount == 0 && poolUnitsCount == 0
		}

		init(state: State) {
			self.name = state.account.displayName.rawValue
			self.address = state.account.address
			self.appearanceID = state.account.appearanceID
			self.isLoadingResources = state.portfolio.isLoading

			self.tag = .init(state: state)
			self.isLedgerAccount = state.isLedgerAccount

			self.mnemonicHandlingCallToAction = state.mnemonicHandlingCallToAction

			// Resources
			guard let portfolio = state.portfolio.wrappedValue else {
				self.fungibleResourceIcons = []
				self.nonFungibleResourcesCount = 0
				self.stakedValidatorsCount = 0
				self.poolUnitsCount = 0

				return
			}

			let fungibleResources = portfolio.fungibleResources
			let xrdIcon: [TokenThumbnail.Content] = fungibleResources.xrdResource != nil ? [.xrd] : []
			let otherIcons: [TokenThumbnail.Content] = fungibleResources.nonXrdResources.map { .known($0.metadata.iconURL) }
			self.fungibleResourceIcons = xrdIcon + otherIcons

			self.nonFungibleResourcesCount = portfolio.nonFungibleResources.count

			self.stakedValidatorsCount = portfolio.poolUnitResources.radixNetworkStakes.count
			self.poolUnitsCount = portfolio.poolUnitResources.poolUnits.count
		}
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<Home.AccountRow>

		public init(store: StoreOf<Home.AccountRow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: ViewState.init(state:), send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .medium3) {
					VStack(alignment: .leading, spacing: .zero) {
						Text(viewStore.name)
							.lineLimit(1)
							.textStyle(.body1Header)
							.foregroundColor(.app.white)
							.frame(maxWidth: .infinity, alignment: .leading)

						HStack {
							AddressView(
								.address(.account(viewStore.address, isLedgerHWAccount: viewStore.isLedgerAccount))
							)
							.foregroundColor(.app.whiteTransparent)
							.textStyle(.body2HighImportance)

							if let tag = viewStore.tag {
								Text("•")
								Text("\(tag.display)")
							}
						}
						.foregroundColor(.app.whiteTransparent)
					}

					ownedResourcesList(viewStore)

					prompts(
						mnemonicHandlingCallToAction: viewStore.mnemonicHandlingCallToAction
					)
				}
				.padding(.horizontal, .medium1)
				.padding(.vertical, .medium2)
				.background(viewStore.appearanceID.gradient)
				.cornerRadius(.small1)
				.onTapGesture {
					viewStore.send(.tapped)
				}
				.task {
					await store.send(.view(.task)).finish()
				}
			}
		}
	}
}

// MARK: - Account resources view
extension Home.AccountRow.View {
	private enum Constants {
		static let iconSize = HitTargetSize.smaller
		static let borderWidth: CGFloat = 1

		static var diameter: CGFloat {
			iconSize.rawValue + 2 * borderWidth
		}
	}

	@ViewBuilder
	func prompts(mnemonicHandlingCallToAction: MnemonicHandling?) -> some SwiftUI.View {
		if let mnemonicHandlingCallToAction {
			switch mnemonicHandlingCallToAction {
			case .mustBeImported:
				importMnemonicPromptView {
					store.send(.view(.importMnemonicButtonTapped))
				}
			case .shouldBeExported:
				exportMnemonicPromptView {
					store.send(.view(.exportMnemonicButtonTapped))
				}
			}
		}
	}

	// Crates the view of the account owned resources
	func ownedResourcesList(_ viewStore: ViewStoreOf<Home.AccountRow>) -> some View {
		GeometryReader { proxy in
			HStack(spacing: .small1) {
				if !viewStore.fungibleResourceIcons.isEmpty {
					// FIXME: Workaround to avoid ViewThatFits
					let limit = viewStore.state.itemLimit(
						iconSize: Constants.diameter,
						width: proxy.size.width
					)

					FungibleResourcesSection(fungibles: viewStore.fungibleResourceIcons, itemLimit: limit)

					// FIXME: ViewThatFits is better, but it causes issues with @MainActor, which probably shouldn't be used in the first place
					//	if viewStore.showMoreFungibles {
					//		ViewThatFits(in: .horizontal) {
					//			FungibleResourcesSection(fungibles: icons, itemLimit: nil)
					//			FungibleResourcesSection(fungibles: icons, itemLimit: 10)
					//		}
					//	} else {
					//		ViewThatFits(in: .horizontal) {
					//			FungibleResourcesSection(fungibles: icons, itemLimit: 5)
					//			FungibleResourcesSection(fungibles: icons, itemLimit: 4)
					//			FungibleResourcesSection(fungibles: icons, itemLimit: 3)
					//		}
					//	}
				}

				if viewStore.nonFungibleResourcesCount > 0 {
					LabelledIcon(rectIcon: AssetResource.nft, label: "\(viewStore.nonFungibleResourcesCount)")
				}

				if viewStore.stakedValidatorsCount > 0 {
					LabelledIcon(roundIcon: AssetResource.stakes, label: "\(viewStore.stakedValidatorsCount)")
				}

				if viewStore.poolUnitsCount > 0 {
					LabelledIcon(roundIcon: AssetResource.poolUnit, label: "\(viewStore.poolUnitsCount)")
				}
			}
		}
		.frame(height: Constants.diameter)
		.shimmer(active: viewStore.isLoadingResources, config: .accountResourcesLoading)
		.cornerRadius(Constants.iconSize.rawValue / 4)
	}

	struct FungibleResourcesSection: View {
		let fungibles: [TokenThumbnail.Content]
		let itemLimit: Int?

		var body: some View {
			let displayedIconCount = min(fungibles.count, itemLimit ?? .max)
			let displayedIcons = fungibles.prefix(displayedIconCount).identifiablyEnumerated()
			let hiddenCount = fungibles.count - displayedIconCount
			let label = hiddenCount > 0 ? "+\(hiddenCount)" : nil

			HStack(alignment: .center, spacing: -Constants.diameter / 3) {
				ForEach(displayedIcons) { item in
					ZStack(alignment: .leading) {
						if item.offset == displayedIconCount - 1, let label {
							ResourceLabel(text: label, tighten: true)
								.padding([.leading, .vertical], Constants.borderWidth)
						}
						TokenIcon(icon: item.element)
					}
					.zIndex(Double(-item.offset))
				}
			}
		}
	}

	struct TokenIcon: View {
		let icon: TokenThumbnail.Content

		var body: some View {
			ZStack {
				Circle()
					.fill(.app.whiteTransparent2)

				TokenThumbnail(icon, size: Constants.iconSize)
					.frame(Constants.iconSize)
					.padding(Constants.borderWidth)
			}
		}
	}

	struct LabelledIcon<S: Shape>: View {
		private let icon: ImageAsset
		private let label: String
		private let tighten: Bool
		private let innerShape: S
		private let outerShape: S

		init(roundIcon: ImageAsset, label: String) where S == Circle {
			self.icon = roundIcon
			self.label = label
			self.tighten = true
			self.innerShape = Circle()
			self.outerShape = Circle()
		}

		init(rectIcon: ImageAsset, label: String) where S == RoundedRectangle {
			self.icon = rectIcon
			self.label = label
			self.tighten = false
			self.innerShape = RoundedRectangle(cornerRadius: .small2)
			self.outerShape = RoundedRectangle(cornerRadius: .small2 + Constants.borderWidth)
		}

		var body: some View {
			ZStack(alignment: .leading) {
				ResourceLabel(text: label, tighten: tighten)
					.padding([.leading, .vertical], Constants.borderWidth)

				outerShape
					.fill(.app.whiteTransparent2)
					.frame(width: Constants.diameter, height: Constants.diameter)

				innerShape
					.fill(.app.whiteTransparent)
					.frame(Constants.iconSize)
					.padding(Constants.borderWidth)

				Image(asset: icon)
					.resizable()
					.frame(Constants.iconSize)
					.padding(Constants.borderWidth)
			}
		}
	}

	struct ResourceLabel: View {
		let text: String
		let tighten: Bool

		var body: some View {
			Text(text)
				.lineLimit(1)
				.textStyle(.resourceLabel)
				.fixedSize()
				.foregroundColor(.white)
				.padding(.horizontal, .small2)
				.frame(minWidth: .medium1, minHeight: Constants.iconSize.rawValue)
				.padding(.leading, Constants.diameter - Constants.borderWidth - (tighten ? .small3 : 0))
				.background(.app.whiteTransparent2)
				.cornerRadius(Constants.iconSize.rawValue / 2)
				.layoutPriority(100)
		}
	}
}

// FIXME: Workaround to avoid ViewThatFits
private extension Home.AccountRow.ViewState {
	func itemLimit(iconSize: CGFloat, width: CGFloat) -> Int? {
		itemLimit(trying: showMoreFungibles ? [nil, 10] : [5, 4, 3], iconSize: iconSize, width: width)
	}

	func itemLimit(trying limits: [Int?], iconSize: CGFloat, width: CGFloat) -> Int? {
		for limit in limits {
			if usedWidth(itemLimit: limit, iconSize: iconSize) < width {
				return limit
			}
		}

		return 3
	}

	func usedWidth(itemLimit: Int?, iconSize: CGFloat) -> CGFloat {
		let itemsShown = min(fungibleResourceIcons.count, itemLimit ?? .max)
		let itemsNotShown = fungibleResourceIcons.count - itemsShown
		let showFungibleLabel = itemsNotShown > 0

		let hasItems = itemsShown > 0
		let hasPoolUnits = poolUnitsCount > 0
		let hasStakedValidators = stakedValidatorsCount > 0
		let hasNFTs = nonFungibleResourcesCount > 0

		let sections = [hasItems, hasPoolUnits, hasStakedValidators, hasNFTs].count(of: true)

		var width: CGFloat = 0

		if hasItems {
			let extraWidth = 2 * iconSize / 3
			width += iconSize + CGFloat(itemsShown - 1) * extraWidth
		}
		if showFungibleLabel {
			width += fungibleLabelWidthForCount(itemsNotShown)
		}
		if hasPoolUnits {
			width += iconSize + labelWidthForCount(poolUnitsCount)
		}
		if hasStakedValidators {
			width += iconSize + labelWidthForCount(stakedValidatorsCount)
		}
		if hasNFTs {
			width += iconSize + labelWidthForCount(nonFungibleResourcesCount)
		}

		return width + max(CGFloat(sections - 1) * .small1, 0)
	}

	func fungibleLabelWidthForCount(_ count: Int) -> CGFloat {
		labelWidthForCount(count) + (count <= 9 ? 2 : .small3)
	}

	func labelWidthForCount(_ count: Int) -> CGFloat {
		switch count {
		case ...9:
			.medium1
		case ...99:
			.large3
		case ...999:
			.large2 + .small3
		default:
			.large1
		}
	}
}

extension Home.AccountRow.ViewState.AccountTag {
	var display: String {
		switch self {
		case .dAppDefinition:
			L10n.HomePage.AccountsTag.dAppDefinition
		case .legacySoftware:
			L10n.HomePage.AccountsTag.legacySoftware
		case .ledgerLegacy:
			L10n.HomePage.AccountsTag.ledgerLegacy
		case .ledgerBabylon:
			L10n.HomePage.AccountsTag.ledgerBabylon
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct Row_Preview: PreviewProvider {
	static var previews: some View {
		Home.AccountRow.View(
			store: .init(
				initialState: .previewValue,
				reducer: Home.AccountRow.init
			)
		)
	}
}

extension Home.AccountRow.State {
	public static let previewValue = Self(account: .previewValue0)
}
#endif
