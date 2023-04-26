import FeaturePrelude

// MARK: - AccountList.Row.View
extension AccountList.Row {
	public struct ViewState: Equatable {
		struct FungibleResources: Equatable {
			struct Icon: Equatable {
				let url: URL?
				let placeholder: ImageAsset
			}

			static let maxNumberOfIcons = 5

			let icons: [Icon]
			let additionalItemsText: String?
		}

		let name: String
		let address: AddressView.ViewState
		let appearanceID: Profile.Network.Account.AppearanceID
		let isLoadingResources: Bool
		let isLegacyAccount: Bool
		let shouldShowSecurityPrompt: Bool
		let nonFungibleResourcesCount: Int
		let fungibleResourceIcons: FungibleResources

		init(state: State) {
			self.name = state.account.displayName.rawValue
			self.address = .init(address: state.account.address.address, format: .default)
			self.appearanceID = state.account.appearanceID
			self.isLoadingResources = state.portfolio.isLoading

			// Olympia accounts are legacy
			self.isLegacyAccount = true // state.account.isOlympiaAccount

			// Show the prompt if the account has any XRD
			self.shouldShowSecurityPrompt = {
				guard let xrdResource = state.portfolio.wrappedValue?.fungibleResources.xrdResource else {
					return false
				}

				return xrdResource.amount > .zero
			}()

			// Resources
			self.nonFungibleResourcesCount = state.portfolio.wrappedValue?.nonFungibleResources.count ?? 0
			self.fungibleResourceIcons = {
				guard let portfolio = state.portfolio.wrappedValue else {
					return .init(icons: [], additionalItemsText: nil)
				}

				var icons: [FungibleResources.Icon] = []
				if let xrdToken = portfolio.fungibleResources.xrdResource {
					icons.append(.init(url: xrdToken.iconURL, placeholder: .placeholderImage(isXRD: true)))
				}

				portfolio.fungibleResources
					.nonXrdResources
					.forEach {
						icons.append(.init(url: $0.iconURL, placeholder: .placeholderImage(isXRD: false)))
					}

				let additionalItemsCount = icons.count - FungibleResources.maxNumberOfIcons
				let additionalItems = additionalItemsCount > 0 ? "+\(additionalItemsCount)" : nil

				return .init(
					icons: Array(icons.prefix(FungibleResources.maxNumberOfIcons)),
					additionalItemsText: additionalItems
				)
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
				VStack(alignment: .leading, spacing: .medium3) {
					VStack(alignment: .leading, spacing: .zero) {
						HeaderView(name: viewStore.name)
						HStack {
							AddressView(
								viewStore.address,
								copyAddressAction: {
									viewStore.send(.copyAddressButtonTapped)
								}
							)
							if viewStore.isLegacyAccount {
								Text("•")
								Text("\(L10n.AccountList.Row.legacyAccount)")
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
			.background(Color.app.whiteTransparent2)
			.cornerRadius(Constants.iconSize.rawValue / 2)
	}

	// The list of fungible resources
	private func fungibleResourcesList(_ viewStore: ViewStoreOf<AccountList.Row>) -> some View {
		HStack(alignment: .center, spacing: -Constants.iconSize.rawValue / 3) {
			ForEach(
				Array(viewStore.fungibleResourceIcons.icons.enumerated()),
				id: \.offset
			) { offset, item in
				ZStack {
					AsyncImage(url: item.url) {
						fungibleResourceIcon($0)
					} placeholder: {
						fungibleResourceIcon(
							Image(asset: item.placeholder)
						)
					}
				}
				.zIndex(Double(-offset))
			}
		}
	}

	private func fungibleResourceIcon(_ image: Image) -> some View {
		image.resizable()
			.frame(Constants.iconSize)
			.clipShape(Circle())
	}
}

extension AccountList.Row.View {
	func securityPromptView(_ viewStore: ViewStoreOf<AccountList.Row>) -> some View {
		HStack {
			Image(asset: AssetResource.homeAccountSecurity)
			Text(L10n.AccountList.Row.securityPrompt)
				.foregroundColor(.white)
			Spacer()
			Circle()
				.fill()
				.foregroundColor(.red)
				.frame(width: .small2, height: .small2)
		}
		.padding(.small2)
		.background(Color.app.whiteTransparent2)
		.cornerRadius(.small2)
		.onTapGesture {
			viewStore.send(.securityPromptTapped)
		}
	}
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
