import FeaturePrelude

// MARK: - NewEntityCompletion.View
public extension NewEntityCompletion {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<NewEntityCompletion>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension NewEntityCompletion.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack(spacing: .medium2) {
					Spacer()

					accountsStackView(with: viewStore)

					Spacer()

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

					Button(L10n.CreateEntity.Completion.goToDestination(viewStore.destinationDisplayText)) {
						viewStore.send(.goToDestination)
					}
					.buttonStyle(.primaryRectangular)
				}
				.padding(.medium1)
			}
		}
	}
}

private extension NewEntityCompletion.View {
	@ViewBuilder
	func accountsStackView(with viewStore: CompletionViewStore) -> some View {
		if let accountAddress = viewStore.accountAddress, let appearanceID = viewStore.appearanceID {
			ZStack {
				VStack(spacing: .small2) {
					Text(viewStore.entityName)
						.foregroundColor(.app.white)
						.textStyle(.body1Header)
						.multilineTextAlignment(.center)

					AddressView(accountAddress)
						.foregroundColor(.app.whiteTransparent)
				}
				.frame(width: Constants.cardFrame.width, height: Constants.cardFrame.height)
				.background(appearanceID.gradient)
				.cornerRadius(.small1)
				.padding(.horizontal, .medium1)
				.zIndex(4)

				Group {
					ForEach(0 ..< Constants.transparentCardsCount, id: \.self) { index in
						nextAppearanceId(from: viewStore.entityIndex + index).gradient.opacity(0.2)
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
	}

	func scale(index: Int) -> CGFloat {
		1 - (CGFloat(index + 1) * 0.05)
	}

	func reversedZIndex(count: Int, index: Int) -> Double {
		Double(count - index)
	}

	func nextAppearanceId(from accountIndex: OnNetwork.Account.Index) -> OnNetwork.Account.AppearanceID {
		OnNetwork.Account.AppearanceID.fromIndex(accountIndex + 1)
	}

	func subtitleText(with viewStore: CompletionViewStore) -> String {
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

// MARK: - NewEntityCompletion.View.CompletionViewStore
private extension NewEntityCompletion.View {
	typealias CompletionViewStore = ViewStore<NewEntityCompletion.View.ViewState, NewEntityCompletion.Action.ViewAction>
}

// MARK: - NewEntityCompletion.View.ViewState
extension NewEntityCompletion.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let entityKind: String
		let entityName: String
		let entityIndex: Int
		let destinationDisplayText: String
		let isFirstOnNetwork: Bool
		let explaination: String

		// Account only
		let accountAddress: AddressView.ViewState?
		let appearanceID: OnNetwork.Account.AppearanceID?

		init(state: NewEntityCompletion.State) {
			let entityKind = state.entity.kind == .account ? L10n.Common.Account.kind : L10n.Common.Persona.kind
			self.entityKind = entityKind
			entityName = state.displayName
			entityIndex = state.index

			destinationDisplayText = {
				switch state.navigationButtonCTA {
				case .goHome:
					return L10n.CreateEntity.Completion.Destination.home
				case .goBackToChooseEntities:
					return L10n.CreateEntity.Completion.Destination.chooseEntities(entityKind)
				}
			}()

			isFirstOnNetwork = state.isFirstOnNetwork

			if let account = state.entity as? OnNetwork.Account {
				self.accountAddress = .init(address: account.address.address, format: .short())
				self.appearanceID = account.appearanceID
				self.explaination = L10n.CreateEntity.Completion.Explanation.Specific.account
			} else {
				self.explaination = L10n.CreateEntity.Completion.Explanation.Specific.persona
				self.accountAddress = nil
				self.appearanceID = nil
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct AccountCompletion_Preview: PreviewProvider {
//	static var previews: some View {
//		NewEntityCompletion.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: NewEntityCompletion()
//			)
//		)
//	}
// }
//
// #endif
