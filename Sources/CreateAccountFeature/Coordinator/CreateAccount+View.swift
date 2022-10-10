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
						.font(.app.sectionHeader)
				}

				Spacer()
					.frame(minHeight: 10, maxHeight: 40)

				VStack(spacing: 40) {
					Text(L10n.CreateAccount.subtitle)
						.fixedSize(horizontal: false, vertical: true)
						.padding(.horizontal, 40)
						.multilineTextAlignment(.center)
						.foregroundColor(.app.gray1)
						.font(.app.body1Regular)

					VStack(alignment: .leading, spacing: 10) {
						TextField(
							L10n.CreateAccount.placeholder,
							text: viewStore.binding(
								get: \.accountName,
								send: { .internal(.user(.textFieldDidChange($0))) }
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
						.background(Color.app.gray5)
						.foregroundColor(.app.buttonTextBlack)
						.font(.app.body1Regular)
						.cornerRadius(4)
						.overlay(
							RoundedRectangle(cornerRadius: 4)
								.stroke(Color.app.buttonTextBlack, lineWidth: 1)
						)

						Text(L10n.CreateAccount.explanation)
							.foregroundColor(.app.gray2)
							.font(.app.body1Regular)
					}
				}

				Spacer(minLength: 10)

				PrimaryButton(
					title: L10n.CreateAccount.continueButtonTitle,
					isEnabled: viewStore.isValid,
					action: { /* TODO: implement */ }
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

// MARK: - Private Computed Properties
private extension CreateAccount.View {
	var titleText: String {
		viewStore.numberOfExistingAccounts == 0 ? L10n.CreateAccount.createFirstAccount : L10n.CreateAccount.createNewAccount
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
