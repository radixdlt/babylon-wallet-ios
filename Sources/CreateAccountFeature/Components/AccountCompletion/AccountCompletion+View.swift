import Address
import Common
import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - AccountCompletion.View
public extension AccountCompletion {
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountCompletion>

		public init(store: StoreOf<AccountCompletion>) {
			self.store = store
		}
	}
}

public extension AccountCompletion.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: AccountCompletion.Action.init
		) { viewStore in
			VStack(spacing: 20) {
				Spacer()

				Image("createAccount-safe")

				Text(L10n.CreateAccount.Completion.title)
					.foregroundColor(.app.buttonTextBlack)
					.textStyle(.sectionHeader)

				Text(L10n.CreateAccount.Completion.subtitle)
					.foregroundColor(.app.gray1)
					.textStyle(.body1Regular)

				Spacer()

				VStack(spacing: 15) {
					Text(viewStore.accountName)
						.foregroundColor(.app.buttonTextBlack)
						.textStyle(.secondaryHeader)
						.multilineTextAlignment(.center)

					HStack {
						Text(viewStore.accountAddress)
							.foregroundColor(.app.buttonTextBlack.opacity(0.6))
							.textStyle(.body2Regular)

						Image("copy")
					}
				}
				.frame(maxWidth: .infinity)
				.padding(30)
				.background(Color.app.gray3)
				.cornerRadius(8)

				Text(L10n.CreateAccount.Completion.explanation)
					.foregroundColor(.app.gray1)
					.textStyle(.body1Regular)
					.lineSpacing(23 / 3)
					.textStyle(.sheetTitle)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 24)

				Spacer()

				PrimaryButton(
					title: L10n.CreateAccount.Completion.returnToOrigin(viewStore.origin.displayText),
					action: { /* TODO: implement */ }
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
		let accountName: String
		let accountAddress: Address
		let origin: AccountCompletion.State.Origin

		init(state: AccountCompletion.State) {
			accountName = state.accountName
			accountAddress = state.accountAddress
			origin = state.origin
		}
	}
}

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
