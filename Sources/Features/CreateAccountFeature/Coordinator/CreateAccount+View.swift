import Common
import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - CreateAccount.View
public extension CreateAccount {
	@MainActor
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
				IfLetStore(
					store.scope(
						state: \.accountCompletion,
						action: { .child(.accountCompletion($0)) }
					),
					then: { AccountCompletion.View(store: $0) }
				)
				.zIndex(2)

				VStack(spacing: .zero) {
					if viewStore.isDismissButtonVisible {
						NavigationBar(
							leadingItem: CloseButton {
								viewStore.send(.closeButtonTapped)
							}
						)
						.foregroundColor(.app.gray1)
						.padding([.horizontal, .top], .medium3)
					} else {
						Spacer()
							.frame(minHeight: .small2, maxHeight: .large1)
					}
					VStack {
						title(with: viewStore)

						Spacer()
							.frame(minHeight: .small2, maxHeight: .large1)

						VStack(spacing: .large1) {
							subtitle

							let accountNameBinding = viewStore.binding(
								get: \.accountName,
								send: { .textFieldChanged($0) }
							)

							AppTextField(
								placeholder: L10n.CreateAccount.placeholder,
								text: accountNameBinding,
								hint: L10n.CreateAccount.explanation,
								binding: $focusedField,
								equals: .accountName,
								first: viewStore.binding(
									get: \.focusedField,
									send: { .textFieldFocused($0) }
								)
							)
							#if os(iOS)
							.textFieldCharacterLimit(30, forText: accountNameBinding)
							#endif
							.autocorrectionDisabled()
						}

						Spacer(minLength: .small2)

						if viewStore.isLoaderVisible {
							ProgressView()
						}

						Spacer()

						Button(L10n.CreateAccount.createAccountButtonTitle) {
							viewStore.send(.createAccountButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
						.controlState(viewStore.createAccountButtonState)
					}
					.padding([.horizontal, .bottom], .medium1)
				}
				.onAppear {
					viewStore.send(.viewAppeared)
				}
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
		public var createAccountButtonState: ControlState
		public var isDismissButtonVisible: Bool
		@BindableState public var focusedField: CreateAccount.State.Field?

		init(state: CreateAccount.State) {
			numberOfExistingAccounts = state.numberOfExistingAccounts
			accountName = state.inputtedAccountName
			isLoaderVisible = state.isCreatingAccount
			let isNameValid = !state.sanitizedAccountName.isEmpty
			createAccountButtonState = (isNameValid && !state.isCreatingAccount) ? .enabled : .disabled
			isDismissButtonVisible = !state.shouldCreateProfile
			focusedField = state.focusedField
		}
	}
}

// MARK: - CreateAccount.View.ViewStore
private extension CreateAccount.View {
	typealias ViewStore = ComposableArchitecture.ViewStore<CreateAccount.View.ViewState, CreateAccount.Action.ViewAction>
}

private extension CreateAccount.View {
	func title(with viewStore: ViewStore) -> some View {
		let titleText = viewStore.numberOfExistingAccounts == 0 ? L10n.CreateAccount.createFirstAccount : L10n.CreateAccount.createNewAccount

		return Text(titleText)
			.foregroundColor(.app.gray1)
			.textStyle(.sheetTitle)
	}

	var subtitle: some View {
		Text(L10n.CreateAccount.subtitle)
			.fixedSize(horizontal: false, vertical: true)
			.padding(.horizontal, .large1)
			.multilineTextAlignment(.center)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
	}
}

// MARK: - CreateAccount_Previews
struct CreateAccount_Previews: PreviewProvider {
	static var previews: some View {
		CreateAccount.View(
			store: .init(
				initialState: .init(shouldCreateProfile: false),
				reducer: CreateAccount()
			)
		)
	}
}
