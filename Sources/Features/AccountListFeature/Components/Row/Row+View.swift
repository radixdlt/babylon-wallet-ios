import AccountDetailsFeature
import EngineKit
import FeaturePrelude

// MARK: - AccountList.Row.View
extension AccountList.Row {
	public struct ViewState: Equatable {
		struct FungibleResources: Equatable {
			static let maxNumberOfIcons = 5

			let icons: [TokenThumbnail.Content]
			let additionalItemsText: String?
		}

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

		let needToBackupMnemonicForThisAccount: Bool
		let needToImportMnemonicForThisAccount: Bool

		let fungibleResourceIcons: FungibleResources
		let nonFungibleResourcesCount: Int
		let poolUnitsCount: Int

		init(state: State) {
			self.name = state.account.displayName.rawValue
			self.address = state.account.address
			self.appearanceID = state.account.appearanceID
			self.isLoadingResources = state.portfolio.isLoading

			self.tag = .init(state: state)

			// Show the prompt if the account has any XRD
			self.needToBackupMnemonicForThisAccount = state.needToBackupMnemonicForThisAccount

			// Show the prompt if keychain does not contain the mnemonic for this account
			self.needToImportMnemonicForThisAccount = state.needToImportMnemonicForThisAccount

			// Resources
			guard let portfolio = state.portfolio.wrappedValue else {
				self.fungibleResourceIcons = .init(icons: [], additionalItemsText: nil)
				self.nonFungibleResourcesCount = 0
				self.poolUnitsCount = 0

				return
			}

			self.fungibleResourceIcons = {
				let fungibleResources = portfolio.fungibleResources
				let xrdIcon: [TokenThumbnail.Content] = fungibleResources.xrdResource != nil ? [.xrd] : []

				let otherIcons: [TokenThumbnail.Content] = fungibleResources.nonXrdResources
					.map { .known($0.iconURL) }
				let icons = xrdIcon + otherIcons
				let hiddenCount = max(icons.count - FungibleResources.maxNumberOfIcons, 0)
				let additionalItems = hiddenCount > 0 ? "+\(hiddenCount)" : nil

				return .init(icons: icons.dropLast(hiddenCount), additionalItemsText: additionalItems)
			}()

			self.nonFungibleResourcesCount = portfolio.nonFungibleResources.count

			self.poolUnitsCount = portfolio.poolUnitResources.radixNetworkStakes.count
				+ portfolio.poolUnitResources.poolUnits.count
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
						headerView(with: viewStore.name)
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

					if viewStore.needToImportMnemonicForThisAccount {
						importMnemonicPromptView(viewStore)
					}

					if !viewStore.needToImportMnemonicForThisAccount, viewStore.needToBackupMnemonicForThisAccount {
						backupMnemonicPromptView(viewStore)
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
		HStack(spacing: .medium1) {
			if !viewStore.fungibleResourceIcons.icons.isEmpty {
				resourcesContainer(
					text: viewStore.fungibleResourceIcons.additionalItemsText
				) {
					fungibleResourcesList(viewStore)
				}
			}

			if viewStore.nonFungibleResourcesCount > 0 {
				resourcesContainer(text: "\(viewStore.nonFungibleResourcesCount)") {
					Image(asset: AssetResource.nft)
						.resizable()
						.frame(Constants.iconSize)
				}
			}

			if viewStore.poolUnitsCount > 0 {
				resourcesContainer(text: "\(viewStore.poolUnitsCount)") {
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

	// Resources container to display a combination of any View + additional text (aka +10)
	private func resourcesContainer(text: String?, @ViewBuilder content: () -> some View) -> some View {
		// Negative spacing, so that the text number starts from the last icon.
		// Need to be sure that the background of the text is properly displayed.
		HStack(spacing: -Constants.iconSize.rawValue) {
			content()
			if let text {
				// The text background needs to go behind the `content`
				textContainer(text).zIndex(-1)
			}
		}
	}

	// The container displaying the resources number
	private func textContainer(_ text: String) -> some View {
		Text(text)
			.foregroundColor(.white)
			.padding(.leading, Constants.iconSize.rawValue + 4) // Padding so that the text is visible
			.padding(.trailing, 4)
			.frame(
				minWidth: Constants.iconSize.rawValue * 2,
				minHeight: Constants.iconSize.rawValue
			)
			.background(.app.whiteTransparent2)
			.cornerRadius(Constants.iconSize.rawValue / 2)
	}

	// The list of fungible resources
	private func fungibleResourcesList(_ viewStore: ViewStoreOf<AccountList.Row>) -> some View {
		HStack(alignment: .center, spacing: -Constants.iconSize.rawValue / 3) {
			ForEach(viewStore.fungibleResourceIcons.icons.identifiablyEnumerated()) { item in
				TokenThumbnail(item.element, size: Constants.iconSize)
					.zIndex(Double(-item.offset))
			}
		}
	}
}

extension AccountList.Row.View {
	func importMnemonicPromptView(_ viewStore: ViewStoreOf<AccountList.Row>) -> some View {
		importMnemonicPromptView { viewStore.send(.importMnemonic) }
	}

	func backupMnemonicPromptView(_ viewStore: ViewStoreOf<AccountList.Row>) -> some View {
		backupMnemonicPromptView { viewStore.send(.backUpMnemonic) }
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

extension AccountList.Row.View {
	@ViewBuilder
	private func headerView(
		with name: String
	) -> some SwiftUI.View {
		HStack {
			Text(name)
				.foregroundColor(.app.white)
				.textStyle(.body1Header)
				.fixedSize()
			Spacer()
		}
	}
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
