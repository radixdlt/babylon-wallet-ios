import Common
import ComposableArchitecture
import DesignSystem
import Profile
import SwiftUI

// MARK: - AccountCompletion.View
public extension AccountCompletion {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension AccountCompletion.View {
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
						Text(L10n.CreateAccount.Completion.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)

						Text(subtitleText(with: viewStore))
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)

						Text(L10n.CreateAccount.Completion.explanation)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .small1)

					Spacer()

					Button(L10n.CreateAccount.Completion.goToDestination(viewStore.destination.displayText)) {
						viewStore.send(.goToDestination)
					}
					.buttonStyle(.primaryRectangular)
				}
				.padding(.medium1)
			}
		}
	}
}

private extension AccountCompletion.View {
	func accountsStackView(with viewStore: AccountCompletionViewStore) -> some View {
		ZStack {
			VStack(spacing: .small2) {
				Text(viewStore.accountName)
					.foregroundColor(.app.white)
					.textStyle(.body1Header)
					.multilineTextAlignment(.center)

				AddressView(viewStore.accountAddress)
					.foregroundColor(.app.whiteTransparent)
			}
			.frame(width: Constants.cardFrame.width, height: Constants.cardFrame.height)
			.background(viewStore.appearanceID.gradient)
			.cornerRadius(.small1)
			.padding(.horizontal, .medium1)
			.zIndex(4)

			Group {
				ForEach(0 ..< Constants.transparentCardsCount, id: \.self) { index in
					nextAppearanceId(from: viewStore.accountIndex + index).gradient.opacity(0.2)
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

	func nextAppearanceId(from accountIndex: OnNetwork.Account.Index) -> OnNetwork.Account.AppearanceID {
		OnNetwork.Account.AppearanceID.fromIndex(accountIndex + 1)
	}

	enum Constants {
		static let cardFrame: CGSize = .init(width: 277, height: 85)
		static let transparentCardsCount: Int = 3
		static let transparentCardOffset: CGFloat = .small1
	}

	func subtitleText(with viewStore: AccountCompletionViewStore) -> String {
		if viewStore.isFirstAccount {
			return L10n.CreateAccount.Completion.subtitleFirstAccount
		} else {
			return L10n.CreateAccount.Completion.subtitle
		}
	}
}

// TODO: dzoni delete me
extension Color {
	static var random: Color {
		Color(
			red: .random(in: 0 ... 1),
			green: .random(in: 0 ... 1),
			blue: .random(in: 0 ... 1)
		)
	}
}

// MARK: - AccountCompletion.View.AccountCompletionViewStore
private extension AccountCompletion.View {
	typealias AccountCompletionViewStore = ViewStore<AccountCompletion.View.ViewState, AccountCompletion.Action.ViewAction>
}

// MARK: - AccountCompletion.View.ViewState
extension AccountCompletion.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let accountName: String
		let accountAddress: AddressView.ViewState
		let accountIndex: Int
		let destination: AccountCompletion.State.Destination
		let appearanceID: OnNetwork.Account.AppearanceID
		let isFirstAccount: Bool

		init(state: AccountCompletion.State) {
			accountName = state.accountName
			accountAddress = .init(address: state.accountAddress.address, format: .short())
			accountIndex = state.accountIndex
			destination = state.destination
			appearanceID = state.account.appearanceID
			isFirstAccount = state.isFirstAccount
		}
	}
}

#if DEBUG

// MARK: - AccountCompletion_Preview
struct AccountCompletion_Preview: PreviewProvider {
	static var previews: some View {
		registerFonts()

		return AccountCompletion.View(
			store: .init(
				initialState: .placeholder,
				reducer: AccountCompletion()
			)
		)
	}
}

#endif // DEBUG
