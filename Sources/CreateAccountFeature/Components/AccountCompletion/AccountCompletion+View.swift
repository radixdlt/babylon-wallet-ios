import Address
import Common
import ComposableArchitecture
import SwiftUI

// MARK: - AccountCompletion.View
public extension AccountCompletion {
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountCompletion>
		@ObservedObject private var viewStore: ViewStoreOf<AccountCompletion>

		public init(
			store: StoreOf<AccountCompletion>
		) {
			self.store = store
			viewStore = ViewStore(self.store)
		}
	}
}

public extension AccountCompletion.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AccountCompletion.Action.init
			)
		) { _ in
			VStack(spacing: 20) {
				Spacer()

				Image("createAccount-safe")

				Text("Congratulations")
					.foregroundColor(.app.buttonTextBlack)
					.font(.app.sectionHeader)

				Text("You’ve created your account.")
					.foregroundColor(.app.gray1)
					.font(.app.body1Regular)

				Spacer()

				VStack(spacing: 15) {
					Text(viewStore.accountName)
						.foregroundColor(.app.buttonTextBlack)
						.font(.app.secondaryHeader)
						.multilineTextAlignment(.center)

					HStack {
						Text(viewStore.accountAddress)
							.foregroundColor(.app.buttonTextBlack.opacity(0.6))
							.font(.app.body2Regular)

						Image("copy")
					}
				}
				.frame(maxWidth: .infinity)
				.padding(30)
				.background(Color.app.gray3)
				.cornerRadius(8)

				Text("Your account lives on the Radar Network and you can access it anytime in Radar Wallet.")
					.foregroundColor(.app.gray1)
					.font(.app.body2Regular)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 24)

				Spacer()

				// TODO: make button reusable - Primary button probably
				Button(
					action: { /* TODO: implement */ },
					label: {
						Text("Go to \(viewStore.origin.displayText)")
							.foregroundColor(.app.buttonTextWhite)
							.font(.app.body1Header)
							.frame(maxWidth: .infinity)
							.frame(height: 44)
							.background(Color.app.gray1)
							.cornerRadius(4)
							.shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
					}
				)
			}
			.padding(24)
		}
	}
}

// MARK: - AccountCompletion.View.ViewAction
extension AccountCompletion.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension AccountCompletion.Action {
	init(action: AccountCompletion.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

// MARK: - AccountCompletion.View.ViewState
extension AccountCompletion.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountCompletion.State) {
			// TODO: implement
		}
	}
}

// MARK: - AccountCompletion_Preview
struct AccountCompletion_Preview: PreviewProvider {
	static var previews: some View {
		AccountCompletion.View(
			store: .init(
				initialState: .init(
					accountName: "My main account",
					accountAddress: .random,
					origin: .home
				),
				reducer: AccountCompletion()
			)
		)
	}
}
