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
		let needToExportMnemonic: Bool
		let needToImportMnemonic: Bool

		let fungibleResourceIcons: [TokenThumbnail.Content]
		let nonFungibleResourcesCount: Int
		let poolUnitsCount: Int

		var showMoreFungibles: Bool {
			nonFungibleResourcesCount == 0 && poolUnitsCount == 0
		}

		init(state: State) {
			self.name = state.account.displayName.rawValue
			self.address = state.account.address
			self.appearanceID = state.account.appearanceID
			self.isLoadingResources = state.portfolio.isLoading

			self.tag = .init(state: state)
			self.isLedgerAccount = state.isLedgerAccount

			self.needToExportMnemonic = state.importMnemonicNeeded
			self.needToImportMnemonic = state.exportMnemonicNeeded

			// Resources
			guard let portfolio = state.portfolio.wrappedValue else {
				self.fungibleResourceIcons = []
				self.nonFungibleResourcesCount = 0
				self.poolUnitsCount = 0

				return
			}

			let fungibleResources = portfolio.fungibleResources
			let xrdIcon: [TokenThumbnail.Content] = fungibleResources.xrdResource != nil ? [.xrd] : []
			let otherIcons: [TokenThumbnail.Content] = fungibleResources.nonXrdResources.map { .known($0.metadata.iconURL) }
			self.fungibleResourceIcons = xrdIcon + otherIcons

			self.nonFungibleResourcesCount = portfolio.nonFungibleResources.count

			self.poolUnitsCount = portfolio.poolUnitResources.radixNetworkStakes.count + portfolio.poolUnitResources.poolUnits.count
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

					if viewStore.needToImportMnemonic {
						importMnemonicPromptView(viewStore)
					}

					if !viewStore.needToImportMnemonic, viewStore.needToExportMnemonic {
						exportMnemonicPromptView(viewStore)
					}
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
	}

	// Crates the view of the account owned resources
	func ownedResourcesList(_ viewStore: ViewStoreOf<Home.AccountRow>) -> some View {
		GeometryReader { proxy in
			HStack(spacing: .small1) {
				if !viewStore.fungibleResourceIcons.isEmpty {
					// FIXME: Workaround to avoid ViewThatFits
					let limit = viewStore.state.itemLimit(
						iconSize: Constants.iconSize.rawValue,
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
					Labeled(text: "\(viewStore.nonFungibleResourcesCount)") {
						Image(asset: AssetResource.nft)
							.resizable()
							.frame(Constants.iconSize)
					}
				}

				if viewStore.poolUnitsCount > 0 {
					Labeled(text: "\(viewStore.poolUnitsCount)") {
						Image(asset: AssetResource.poolUnit)
							.resizable()
							.frame(Constants.iconSize)
					}
				}
			}
		}
		.frame(height: Constants.iconSize.rawValue)
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

			HStack(alignment: .center, spacing: -Constants.iconSize.rawValue / 3) {
				ForEach(displayedIcons) { item in
					Labeled(text: item.offset == displayedIconCount - 1 ? label : nil, isFungible: true) {
						TokenThumbnail(item.element, size: Constants.iconSize)
					}
					.zIndex(Double(-item.offset))
				}
			}
		}
	}

	// Resources container to display a combination of any View + additional text. Tighten when used on round icons.
	struct Labeled<Content: View>: View {
		let text: String?
		var isFungible: Bool = false
		let content: () -> Content

		var body: some View {
			if let text {
				ResourceLabel(text: text, isFungible: isFungible)
					.overlay(alignment: .leading, content: content)
			} else {
				content()
			}
		}
	}

	struct ResourceLabel: View {
		let text: String
		let isFungible: Bool

		var body: some View {
			Text(text)
				.lineLimit(1)
				.textStyle(.resourceLabel)
				.fixedSize()
				.foregroundColor(.white)
				.padding(.horizontal, .small2)
				.frame(minWidth: .medium1, minHeight: Constants.iconSize.rawValue)
				.padding(.leading, Constants.iconSize.rawValue - (isFungible ? .small3 : 0))
				.background(.app.whiteTransparent2)
				.cornerRadius(Constants.iconSize.rawValue / 2)
				.layoutPriority(100)
		}
	}
}

extension Home.AccountRow.View {
	func importMnemonicPromptView(_ viewStore: ViewStoreOf<Home.AccountRow>) -> some View {
		importMnemonicPromptView { viewStore.send(.importMnemonic) }
	}

	func exportMnemonicPromptView(_ viewStore: ViewStoreOf<Home.AccountRow>) -> some View {
		exportMnemonicPromptView { viewStore.send(.backUpMnemonic) }
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
		let hasNFTs = nonFungibleResourcesCount > 0
		let sections = (hasItems ? 1 : 0) + (hasPoolUnits ? 1 : 0) + (hasNFTs ? 1 : 0)

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

extension Collection {
	public func identifiablyEnumerated() -> [OffsetIdentified<Element>] {
		enumerated().map(OffsetIdentified.init)
	}
}

extension Collection where Element: Identifiable {
	public func identified() throws -> IdentifiedArrayOf<Element> {
		guard Set(map(\.id)).count == count else {
			throw IdentifiedArrayError.clashingIDs
		}
		return .init(uniqueElements: self)
	}

	public func uniqueIdentified() -> IdentifiedArrayOf<Element> {
		.init(uncheckedUniqueElements: self)
	}
}

// MARK: - IdentifiedArrayError
public enum IdentifiedArrayError: Error {
	case clashingIDs
}

// MARK: - OffsetIdentified
public struct OffsetIdentified<Element>: Identifiable {
	public var id: Int { offset }

	public let offset: Int
	public let element: Element
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
