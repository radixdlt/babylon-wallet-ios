import Common
import ComposableArchitecture
import DesignSystem
import Profile
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
			store.actionless,
			observe: ViewState.init(state:)
		) { viewStore in
			VStack(spacing: .medium2) {
				Spacer()

				Image(asset: Asset.createAccountSafe)

				Text(L10n.CreateAccount.Completion.title)
					.foregroundColor(.app.buttonTextBlack)
					.textStyle(.sectionHeader)

				Text(L10n.CreateAccount.Completion.subtitle)
					.foregroundColor(.app.gray1)
					.textStyle(.body1Regular)

				Spacer()

				VStack(spacing: .medium3) {
					Text(viewStore.accountName)
						.foregroundColor(.app.buttonTextBlack)
						.textStyle(.secondaryHeader)
						.multilineTextAlignment(.center)

					HStack {
						Text(viewStore.accountAddress.address)
							.foregroundColor(.app.buttonTextBlackTransparent)
							.textStyle(.body2Regular)

						Image(asset: Asset.copy)
					}
				}
				.frame(maxWidth: .infinity)
				.padding(.large2)
				.background(Color.app.gray3)
				.cornerRadius(.small2)

				Text(L10n.CreateAccount.Completion.explanation)
					.foregroundColor(.app.gray1)
					.textStyle(.body1Regular)
					.textStyle(.sheetTitle)
					.multilineTextAlignment(.center)
					.padding(.horizontal, .medium1)

				Spacer()

				Button(L10n.CreateAccount.Completion.returnToOrigin(viewStore.origin.displayText)) {
					/* TODO: implement */
				}
				.buttonStyle(.primary)
			}
			.padding(.medium1)
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
