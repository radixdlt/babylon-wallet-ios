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
		let address: AddressView.ViewState
		let appearanceID: Profile.Network.Account.AppearanceID
		let isLoadingResources: Bool
		let fungbielResourceIcons: FungibleResources
		let nonFungibleResourcesCount: Int

		init(state: State) {
			self.name = state.account.displayName.rawValue
			self.address = .init(address: state.account.address.address, format: .default)
			self.appearanceID = state.account.appearanceID
			self.isLoadingResources = state.portfolio.isLoading
			self.nonFungibleResourcesCount = state.portfolio.wrappedValue?.nonFungibleResources.count ?? 0
			self.fungbielResourceIcons = {
				guard let fungibleResources = state.portfolio.wrappedValue?.fungibleResources else {
					return .init(icons: [], additionalItemsText: nil)
				}

				let xrdIcon: [TokenThumbnail.Content] = fungibleResources.xrdResource.map { _ in [.xrd] } ?? []
				let otherIcons: [TokenThumbnail.Content] = fungibleResources.nonXrdResources.map { .known($0.iconURL) }
				let icons = xrdIcon + otherIcons
				let hiddenCount = icons.count - FungibleResources.maxNumberOfIcons
				let additionalItems = hiddenCount > 0 ? "+\(hiddenCount)" : nil

				return .init(icons: icons.dropLast(hiddenCount), additionalItemsText: additionalItems)
			}()
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
				VStack(alignment: .leading) {
					VStack(alignment: .leading, spacing: .zero) {
						HeaderView(name: viewStore.name)
						AddressView(
							viewStore.address,
							copyAddressAction: {
								viewStore.send(.copyAddressButtonTapped)
							}
						)
						.foregroundColor(.app.whiteTransparent)
					}

					ownedResourcesList(viewStore)
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
		static let resourcesNumberContainerOpacity = 0.3
	}

	// Crates the view of the account owned resources
	func ownedResourcesList(_ viewStore: ViewStoreOf<AccountList.Row>) -> some View {
		HStack(spacing: .medium1) {
			if !viewStore.fungbielResourceIcons.icons.isEmpty {
				resourcesContainer(
					text: viewStore.fungbielResourceIcons.additionalItemsText
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

			// TODO: Add PoolUnits when available
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
			.background(Color.white.opacity(Constants.resourcesNumberContainerOpacity))
			.cornerRadius(Constants.iconSize.rawValue / 2)
	}

	// The list of fungible resources
	private func fungibleResourcesList(_ viewStore: ViewStoreOf<AccountList.Row>) -> some View {
		HStack(alignment: .center, spacing: -Constants.iconSize.rawValue / 3) {
			ForEach(viewStore.fungbielResourceIcons.icons.identifiablyEnumerated()) { item in
				TokenThumbnail(item.element, size: .smaller)
					.zIndex(Double(-item.offset))
			}
		}
	}

	private func fungibleResourceIcon(_ image: Image) -> some View {
		image.resizable()
			.frame(Constants.iconSize)
			.clipShape(Circle())
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

// MARK: - HeaderView
private struct HeaderView: View {
	let name: String?
	var body: some View {
		HStack {
			if let name {
				Text(name)
					.foregroundColor(.app.white)
					.textStyle(.body1Header)
					.fixedSize()
			}
			Spacer()
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
