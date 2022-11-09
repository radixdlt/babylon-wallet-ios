import Common
import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - CreateAccount.View
public extension CreateAccount {
	struct View: SwiftUI.View {
		private let store: StoreOf<CreateAccount>
		@FocusState private var focusedField: CreateAccount.State.Field?

		public init(store: StoreOf<CreateAccount>) {
			self.store = store
		}
	}
}

public extension CreateAccount.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack {
					HStack {
						CloseButton {
							viewStore.send(.closeButtonTapped)
						}
						Spacer()
					}

					VStack(spacing: 15) {
						Image("createAccount-safe")

						Text(titleText(with: viewStore))
							.foregroundColor(.app.buttonTextBlack)
							.textStyle(.sectionHeader)
					}

					Spacer()
						.frame(minHeight: 10, maxHeight: 40)

					VStack(spacing: 40) {
						Text(L10n.CreateAccount.subtitle)
							.fixedSize(horizontal: false, vertical: true)
							.padding(.horizontal, 40)
							.multilineTextAlignment(.center)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)

						VStack(alignment: .leading, spacing: 10) {
							TextField(
								L10n.CreateAccount.placeholder,
								text: viewStore.binding(
									get: \.accountName,
									send: { .textFieldChanged($0) }
								)
								.removeDuplicates()
							)
							.focused($focusedField, equals: .accountName)
							.synchronize(
								viewStore.binding(
									get: \.focusedField,
									send: { .textFieldFocused() }
								),
								self.$focusedField
							)
							.padding()
							.frame(height: 50)
							.background(Color.app.gray5)
							.foregroundColor(.app.buttonTextBlack)
							.textStyle(.body1Regular)
							.cornerRadius(4)
							.overlay(
								RoundedRectangle(cornerRadius: 4)
									.stroke(Color.app.buttonTextBlack, lineWidth: 1)
							)

							Text(L10n.CreateAccount.explanation)
								.foregroundColor(.app.gray2)
								.textStyle(.body1Regular)
						}
					}

					Spacer(minLength: 10)

					if viewStore.isLoaderVisible {
						LoadingView()
					}

					PrimaryButton(
						title: L10n.CreateAccount.createAccountButtonTitle,
						isEnabled: viewStore.isCreateAccountButtonEnabled,
						action: {
							viewStore.send(.createAccountButtonTapped)
						}
					)
				}
				.onAppear {
					viewStore.send(.viewAppeared)
				}
				.padding(24)
			}
		}
	}
}

// MARK: - CreateAccount.View.ViewState
extension CreateAccount.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		public var numberOfExistingAccounts: Int
		public var accountName: String
		public var isLoaderVisible: Bool
		public var isCreateAccountButtonEnabled: Bool
		@BindableState public var focusedField: CreateAccount.State.Field?

		init(state: CreateAccount.State) {
			numberOfExistingAccounts = state.numberOfExistingAccounts
			accountName = state.accountName
			isLoaderVisible = state.isCreatingAccount
			isCreateAccountButtonEnabled = state.isValid && !state.isCreatingAccount
			focusedField = state.focusedField
		}
	}
}

// MARK: - CreateAccount.View.ViewStore
private extension CreateAccount.View {
	typealias ViewStore = ComposableArchitecture.ViewStore<CreateAccount.View.ViewState, CreateAccount.Action.ViewAction>
}

// MARK: - Private Computed Properties
private extension CreateAccount.View {
	func titleText(with viewStore: ViewStore) -> String {
		viewStore.numberOfExistingAccounts == 0 ? L10n.CreateAccount.createFirstAccount : L10n.CreateAccount.createNewAccount
	}
}

// MARK: - CreateAccount_Previews
struct CreateAccount_Previews: PreviewProvider {
	static var previews: some View {
		registerFonts()

		return CreateAccount.View(
			store: .init(
				initialState: .init(),
				reducer: CreateAccount()
			)
		)
	}
}
