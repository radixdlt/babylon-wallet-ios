import EngineKit
import FeaturePrelude

extension NewAccountCompletion.State {
	var viewState: NewAccountCompletion.ViewState {
		.init(state: self)
	}
}

extension NewAccountCompletion {
	public struct ViewState: Equatable {
		let entityName: String
		let destinationDisplayText: String
		let isFirstOnNetwork: Bool
		let explanation: String
		let subtitle: String

		let accountAddress: AccountAddress
		let appearanceID: Profile.Network.Account.AppearanceID

		init(state: NewAccountCompletion.State) {
			self.entityName = state.account.displayName.rawValue

			self.destinationDisplayText = {
				switch state.navigationButtonCTA {
				case .goHome:
					return L10n.CreateEntity.Completion.destinationHome
				case .goBackToChooseAccounts:
					return L10n.CreateEntity.Completion.destinationChooseAccounts
				case .goBackToGateways:
					return L10n.CreateEntity.Completion.destinationGateways
				}
			}()

			self.isFirstOnNetwork = state.isFirstOnNetwork

			self.accountAddress = state.account.address
			self.appearanceID = state.account.appearanceID
			self.explanation = L10n.CreateAccount.Completion.explanation

			self.subtitle = state.isFirstOnNetwork ? L10n.CreateAccount.Completion.subtitleFirst : L10n.CreateAccount.Completion.subtitleNotFirst
		}
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<NewAccountCompletion>

		public init(store: StoreOf<NewAccountCompletion>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium2) {
					Spacer()
					accountsStackView(with: viewStore)
					Spacer()

					VStack(spacing: .medium1) {
						Text(L10n.CreateEntity.Completion.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)

						Text(viewStore.subtitle)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)

						Text(viewStore.explanation)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .small1)

					Spacer()
				}
				.padding(.medium1)
				.safeAreaInset(edge: .bottom, spacing: 0) {
					Button(L10n.CreateEntity.Completion.goToDestination(viewStore.destinationDisplayText)) {
						viewStore.send(.goToDestination)
					}
					.buttonStyle(.primaryRectangular)
					.padding(.medium1)
				}
			}
		}
	}
}

private extension NewAccountCompletion.View {
	@ViewBuilder
	func accountsStackView(
		with viewStore: ViewStoreOf<NewAccountCompletion>
	) -> some View {
		ZStack {
			ForEach(0 ..< Constants.transparentCardsCount, id: \.self) { index in
				Profile.Network.Account.AppearanceID.fromIndex(Int(viewStore.appearanceID.rawValue) + index).gradient.opacity(0.2)
					.frame(width: Constants.cardFrame.width, height: Constants.cardFrame.height)
					.cornerRadius(.small1)
					.scaleEffect(scale(index: index))
					.zIndex(reversedZIndex(count: Constants.transparentCardsCount, index: index))
					.offset(y: Constants.transparentCardOffset * CGFloat(index + 1))
			}

			VStack(spacing: .small2) {
				Text(viewStore.entityName)
					.foregroundColor(.app.white)
					.textStyle(.body1Header)
					.multilineTextAlignment(.center)

				AddressView(.address(.account(viewStore.accountAddress)), isTappable: false)
					.foregroundColor(.app.whiteTransparent)
					.textStyle(.body2HighImportance)
			}
			.frame(width: Constants.cardFrame.width, height: Constants.cardFrame.height)
			.background(viewStore.appearanceID.gradient)
			.cornerRadius(.small1)
			.padding(.horizontal, .medium1)
		}
	}

	func scale(index: Int) -> CGFloat {
		1 - (CGFloat(index + 1) * 0.05)
	}

	func reversedZIndex(count: Int, index: Int) -> Double {
		Double(count - index)
	}
}

// MARK: - Constants
private enum Constants {
	static let cardFrame: CGSize = .init(width: 277, height: 85)
	static let transparentCardsCount: Int = 3
	static let transparentCardOffset: CGFloat = .small1
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct AccountCompletion_Preview: PreviewProvider {
//	static var previews: some View {
//		NewEntityCompletion<Profile.Network.Account>.View(
//			store: .init(
//				initialState: .init(
//					entity: .previewValue0,
//					config: .init(purpose: .newAccountFromHome)
//				),
//				reducer: NewEntityCompletion.init
//			)
//		)
//	}
// }
//
// #endif
