import EngineKit
import FeaturePrelude

// MARK: - AccountList.Row.View
extension AccountList.Row {
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

			init?(state: AccountList.Row.State) {
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

		let shouldShowSecurityPrompt: Bool
		let fungibleResourceIcons: [TokenThumbnail.Content]
		let nonFungibleResourcesCount: Int
		let poolUnitsCount: Int

		var showMoreFungibles: Bool {
			nonFungibleResourcesCount == 0 && poolUnitsCount == 0
		}

		init(state: State) {
			self.name = state.account.displayName.rawValue + state.account.displayName.rawValue + state.account.displayName.rawValue
			self.address = state.account.address
			self.appearanceID = state.account.appearanceID
			self.isLoadingResources = state.portfolio.isLoading

			self.tag = .init(state: state)

			// Show the prompt if the account has any XRD
			// FIXME: Enable back after apple review release
			self.shouldShowSecurityPrompt = false // state.shouldShowSecurityPrompt

			// Resources
			guard let portfolio = state.portfolio.wrappedValue else {
				self.fungibleResourceIcons = []
				self.nonFungibleResourcesCount = 0
				self.poolUnitsCount = 0

				return
			}

			let fungibleResources = portfolio.fungibleResources
			let xrdIcon: [TokenThumbnail.Content] = fungibleResources.xrdResource != nil ? [.xrd] : []
			let otherIcons: [TokenThumbnail.Content] = fungibleResources.nonXrdResources.map { .known($0.iconURL) }
			self.fungibleResourceIcons = xrdIcon + otherIcons

			self.nonFungibleResourcesCount = portfolio.nonFungibleResources.count

			self.poolUnitsCount = portfolio.poolUnitResources.radixNetworkStakes.count + portfolio.poolUnitResources.poolUnits.count
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AccountList.Row>

		public init(store: StoreOf<AccountList.Row>) {
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
							AddressView(.address(.account(viewStore.address)))
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

					if viewStore.shouldShowSecurityPrompt {
						securityPromptView(viewStore)
					}
				}
				.padding(.horizontal, .medium1)
				.padding(.vertical, .medium2)
				.background(viewStore.appearanceID.gradient)
				.cornerRadius(.small1)
				.onTapGesture {
					viewStore.send(.tapped)
				}
				.task { @MainActor in
					await ViewStore(store.stateless).send(.view(.task)).finish()
				}
			}
		}
	}
}

// MARK: - Account resources view
extension AccountList.Row.View {
	private enum Constants {
		static let iconSize = HitTargetSize.smaller
	}

	// Crates the view of the account owned resources
	func ownedResourcesList(_ viewStore: ViewStoreOf<AccountList.Row>) -> some View {
		HStack(spacing: .small1) {
			if !viewStore.fungibleResourceIcons.isEmpty {
				let icons = viewStore.fungibleResourceIcons
				if viewStore.showMoreFungibles {
					ViewThatFits(in: .horizontal) {
						fungibleResourcesSection(icons, itemLimit: nil)
						fungibleResourcesSection(icons, itemLimit: 10)
					}
					.layoutPriority(-100)
				} else {
					ViewThatFits(in: .horizontal) {
						fungibleResourcesSection(icons, itemLimit: 5)
						fungibleResourcesSection(icons, itemLimit: 4)
						fungibleResourcesSection(icons, itemLimit: 3)
					}
					.layoutPriority(-100)
				}
			}

			if viewStore.nonFungibleResourcesCount > 0 {
				withLabel("\(viewStore.nonFungibleResourcesCount)") {
					Image(asset: AssetResource.nft)
						.resizable()
						.frame(Constants.iconSize)
				}
			}

			if viewStore.poolUnitsCount > 0 {
				withLabel("\(viewStore.poolUnitsCount)") {
					Image(asset: AssetResource.poolUnit)
						.resizable()
						.frame(Constants.iconSize)
				}
			}
		}
		.frame(height: Constants.iconSize.rawValue)
		.shimmer(active: viewStore.isLoadingResources, config: .accountResourcesLoading)
		.cornerRadius(Constants.iconSize.rawValue / 4)
	}

	@MainActor
	private func fungibleResourcesSection(_ fungibles: [TokenThumbnail.Content], itemLimit: Int?) -> some View {
		let displayedIconCount = min(fungibles.count, itemLimit ?? .max)
		let displayedIcons = fungibles.prefix(displayedIconCount)
		let hiddenCount = fungibles.count - displayedIconCount
		let label = hiddenCount > 0 ? "+\(hiddenCount)" : nil

		return HStack(alignment: .center, spacing: -Constants.iconSize.rawValue / 3) {
			ForEach(displayedIcons.identifiablyEnumerated()) { item in
				withLabel(item.offset == displayedIconCount - 1 ? label : nil, isFungible: true) {
					TokenThumbnail(item.element, size: Constants.iconSize)
				}
				.zIndex(Double(-item.offset))
			}
		}
	}

	// Resources container to display a combination of any View + additional text. Tighten when used on round icons.
	private func withLabel(_ text: String?, isFungible: Bool = false, content: () -> some View) -> some View {
		Group {
			if let text {
				textContainer(text, tightenLeading: isFungible)
					.overlay(alignment: .leading, content: content)
			} else {
				content()
			}
		}
	}

	// The container displaying the resources number.
	private func textContainer(_ text: String, tightenLeading: Bool) -> some View {
		Text(text)
			.lineLimit(1)
			.layoutPriority(100)
			.textStyle(.resourceLabel)
			.foregroundColor(.white)
			.padding(.horizontal, .small2)
			.frame(minWidth: .medium1, minHeight: Constants.iconSize.rawValue)
			.padding(.leading, Constants.iconSize.rawValue - (tightenLeading ? .small3 : 0))
			.background(.app.whiteTransparent2)
			.cornerRadius(Constants.iconSize.rawValue / 2)
	}
}

extension AccountList.Row.View {
	func securityPromptView(_ viewStore: ViewStoreOf<AccountList.Row>) -> some View {
		HStack {
			Image(asset: AssetResource.homeAccountSecurity)

			Text(L10n.HomePage.applySecuritySettings)
				.foregroundColor(.white)
				.textStyle(.body2HighImportance)

			Spacer()

			Circle()
				.fill()
				.foregroundColor(.red)
				.frame(width: .small2, height: .small2)
		}
		.padding(.small2)
		.background(.app.whiteTransparent2)
		.cornerRadius(.small2)
		.onTapGesture {
			viewStore.send(.securityPromptTapped)
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

extension AccountList.Row.ViewState.AccountTag {
	var display: String {
		switch self {
		case .dAppDefinition:
			return L10n.HomePage.AccountsTag.dAppDefinition
		case .legacySoftware:
			return L10n.HomePage.AccountsTag.legacySoftware
		case .ledgerLegacy:
			return L10n.HomePage.AccountsTag.ledgerLegacy
		case .ledgerBabylon:
			return L10n.HomePage.AccountsTag.ledgerBabylon
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Row_Preview: PreviewProvider {
	static var previews: some View {
		AccountList.Row.View(
			store: .init(
				initialState: .previewValue,
				reducer: AccountList.Row()
			)
		)
	}
}

extension AccountList.Row.State {
	public static let previewValue = Self(account: .previewValue0)
}
#endif
