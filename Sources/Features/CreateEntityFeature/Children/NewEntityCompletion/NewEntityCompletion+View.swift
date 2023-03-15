import FeaturePrelude

extension NewEntityCompletion.State {
	var viewState: NewEntityCompletion.ViewState {
		.init(state: self)
	}
}

// MARK: - NewEntityCompletion.View
extension NewEntityCompletion {
	public struct ViewState: Equatable {
		let entityKind: String
		let entityName: String
		let destinationDisplayText: String
		let isFirstOnNetwork: Bool
		let explaination: String

		// Account only
		struct WhenAccount: Equatable {
			let accountAddress: AddressView.ViewState
			let appearanceID: OnNetwork.Account.AppearanceID
		}

		let whenAccount: WhenAccount?

		init(state: NewEntityCompletion.State) {
			let entityKind = state.entity.kind == .account ? L10n.Common.Account.kind : L10n.Common.Persona.kind
			self.entityKind = entityKind
			entityName = state.entity.displayName.rawValue

			destinationDisplayText = {
				switch state.navigationButtonCTA {
				case .goHome:
					return L10n.CreateEntity.Completion.Destination.home
				case .goBackToChooseEntities:
					return L10n.CreateEntity.Completion.Destination.chooseEntities(entityKind)
				case .goBackToPersonaList:
					return L10n.CreateEntity.Completion.Destination.settingsPersonaList
				}
			}()

			isFirstOnNetwork = state.isFirstOnNetwork

			if let account = state.entity as? OnNetwork.Account {
				self.whenAccount = WhenAccount(
					accountAddress: .init(address: account.address.address, format: .default),
					appearanceID: account.appearanceID
				)
				self.explaination = L10n.CreateEntity.Completion.Explanation.Specific.account
			} else {
				self.explaination = L10n.CreateEntity.Completion.Explanation.Specific.persona
				self.whenAccount = nil
			}
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NewEntityCompletion>

		public init(store: StoreOf<NewEntityCompletion>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium2) {
					if let whenAccount = viewStore.whenAccount {
						Spacer()
						accountsStackView(with: viewStore, for: whenAccount)
						Spacer()
					} else {
						Spacer()
					}

					VStack(spacing: .medium1) {
						Text(L10n.CreateEntity.Completion.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)

						Text(subtitleText(with: viewStore))
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)

						Text(viewStore.explaination)
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

private extension NewEntityCompletion.View {
	@ViewBuilder
	func accountsStackView(
		with viewStore: ViewStoreOf<NewEntityCompletion>,
		for whenAccount: NewEntityCompletion.ViewState.WhenAccount
	) -> some View {
		ZStack {
			VStack(spacing: .small2) {
				Text(viewStore.entityName)
					.foregroundColor(.app.white)
					.textStyle(.body1Header)
					.multilineTextAlignment(.center)

				AddressView(whenAccount.accountAddress)
					.foregroundColor(.app.whiteTransparent)
			}
			.frame(width: Constants.cardFrame.width, height: Constants.cardFrame.height)
			.background(whenAccount.appearanceID.gradient)
			.cornerRadius(.small1)
			.padding(.horizontal, .medium1)
			.zIndex(4)

			Group {
				ForEach(0 ..< Constants.transparentCardsCount, id: \.self) { index in
					OnNetwork.Account.AppearanceID.fromIndex(Int(whenAccount.appearanceID.rawValue) + index).gradient.opacity(0.2)
						.frame(width: Constants.cardFrame.width, height: Constants.cardFrame.height)
						.cornerRadius(.small1)
						.scaleEffect(scale(index: index))
						.zIndex(reversedZIndex(count: Constants.transparentCardsCount, index: index))
						.offset(y: Constants.transparentCardOffset * CGFloat(index))
				}
			}
			.offset(y: Constants.transparentCardOffset)
		}
	}

	func scale(index: Int) -> CGFloat {
		1 - (CGFloat(index + 1) * 0.05)
	}

	func reversedZIndex(count: Int, index: Int) -> Double {
		Double(count - index)
	}

	func subtitleText(with viewStore: ViewStoreOf<NewEntityCompletion>) -> String {
		if viewStore.isFirstOnNetwork {
			return L10n.CreateEntity.Completion.Subtitle.first(viewStore.entityKind)
		} else {
			return L10n.CreateEntity.Completion.Subtitle.notFirst(viewStore.entityKind)
		}
	}
}

// MARK: - Constants
private enum Constants {
	static let cardFrame: CGSize = .init(width: 277, height: 85)
	static let transparentCardsCount: Int = 3
	static let transparentCardOffset: CGFloat = .small1
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AccountCompletion_Preview: PreviewProvider {
	static var previews: some View {
		NewEntityCompletion<OnNetwork.Account>.View(
			store: .init(
				initialState: .init(
					entity: .previewValue0,
					config: .init(purpose: .newAccountFromHome)
				),
				reducer: NewEntityCompletion()
			)
		)
	}
}

#endif
