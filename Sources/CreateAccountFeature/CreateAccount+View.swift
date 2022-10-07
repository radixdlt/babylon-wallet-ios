import Common
import ComposableArchitecture
import SwiftUI

// MARK: - CreateAccount.View
public extension CreateAccount {
	struct View: SwiftUI.View {
		private let store: StoreOf<CreateAccount>
		@ObservedObject private var viewStore: ViewStoreOf<CreateAccount>
		@FocusState private var focusedField: CreateAccount.State.Field?

		public init(
			store: StoreOf<CreateAccount>
		) {
			self.store = store
			viewStore = ViewStore(self.store)
		}
	}
}

public extension CreateAccount.View {
	var body: some View {
		ForceFullScreen {
			VStack {
				HStack {
					Button(
						action: { viewStore.send(.internal(.user(.closeButtonTapped))) },
						label: { Image("close") }
					)
					Spacer()
				}

				VStack(spacing: 15) {
					Image("createAccount-safe")

					Text(titleText)
						.foregroundColor(.app.buttonTextBlack)
						.font(.app.title2Bold)
				}

				Spacer()
					.frame(minHeight: 10, maxHeight: 40)

				VStack(spacing: 40) {
					Text(L10n.CreateAccount.subtitle)
						.fixedSize(horizontal: false, vertical: true)
						.padding(.horizontal, 40)
						.multilineTextAlignment(.center)
						.foregroundColor(.app.subtitleGray)
						.font(.app.textFieldRegular)

					VStack(alignment: .leading, spacing: 10) {
						TextField(
							L10n.CreateAccount.placeholder,
							text: viewStore.binding(
								get: \.accountName,
								send: { .internal(.user(.accountNameChanged($0))) }
							)
							.removeDuplicates()
						)
						.focused($focusedField, equals: .accountName)
						.synchronize(
							viewStore.binding(
								get: \.focusedField,
								send: .internal(.user(.textFieldDidFocus))
							),
							self.$focusedField
						)
						.padding()
						.frame(height: 50)
						.background(Color.app.textFieldGray)
						.foregroundColor(.app.buttonTextBlack)
						.font(.app.textFieldRegular)
						.cornerRadius(4)
						.overlay(
							RoundedRectangle(cornerRadius: 4)
								.stroke(Color.app.buttonTextBlack, lineWidth: 1)
						)

						Text(L10n.CreateAccount.explanation)
							.foregroundColor(.app.secondary)
							.font(.app.body)
					}
				}

				Spacer(minLength: 10)

				Button(
					action: { /* TODO: implement */ },
					label: {
						Text(L10n.CreateAccount.continueButtonTitle)
							.foregroundColor(.app.buttonTextWhite)
							.font(.app.buttonBody)
							.frame(maxWidth: .infinity)
							.frame(height: 44)
							.background(viewStore.isValid ? Color.app.buttonBackgroundDark2 : Color.app.buttonDisabledGray)
							.cornerRadius(4)
							.shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
					}
				)
				.disabled(!viewStore.isValid)
			}
			.onAppear {
				viewStore.send(.internal(.system(.viewDidAppear)))
			}
			.padding(24)
		}
	}
}

private extension CreateAccount.View {
	var titleText: String {
		// TODO: calculate depending on the wallet.profile.accounts.count
		let bool = false
		return bool ? L10n.CreateAccount.createNewAccount : L10n.CreateAccount.createFirstAccount
	}
}

// MARK: - CreateAccount_Previews
struct CreateAccount_Previews: PreviewProvider {
	static var previews: some View {
		CreateAccount.View(
			store: .init(
				initialState: .init(),
				reducer: CreateAccount()
			)
		)
	}
}
