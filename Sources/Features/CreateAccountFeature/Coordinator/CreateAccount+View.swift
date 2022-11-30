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

							textField(
								placeholder: L10n.CreateAccount.placeholder,
								text: viewStore.binding(
									get: \.accountName,
									send: { .textFieldChanged($0) }
								),
								hint: L10n.CreateAccount.explanation,
								binding: $focusedField,
								equals: .accountName,
								first: viewStore.binding(
									get: \.focusedField,
									send: { .textFieldFocused($0) }
								)
							)
						}

						Spacer(minLength: .small2)

						if viewStore.isLoaderVisible {
							ProgressView()
						}

						Button(L10n.CreateAccount.createAccountButtonTitle) {
							viewStore.send(.createAccountButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
						.enabled(viewStore.isCreateAccountButtonEnabled)
					}
					.padding([.horizontal, .bottom], .medium1)
				}
                .alert(store.scope(state: \.alert, action: { .view($0) }), dismiss: .alertDismissButtonTapped)
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
		public var isCreateAccountButtonEnabled: Bool
        public var isDismissButtonVisible: Bool
		@BindableState public var focusedField: CreateAccount.State.Field?

		init(state: CreateAccount.State) {
			numberOfExistingAccounts = state.numberOfExistingAccounts
			accountName = state.accountName
			isLoaderVisible = state.isCreatingAccount
			isCreateAccountButtonEnabled = state.isValid && !state.isCreatingAccount
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

	func textField<Value>(
		placeholder: String,
		text: Binding<String>,
		hint: String,
		binding: FocusState<Value>.Binding,
		equals: Value,
		first: Binding<Value>
	) -> some View {
		VStack(alignment: .leading, spacing: .small2) {
			TextField(
				placeholder,
				text: text
					.removeDuplicates()
			)
			.focused(binding, equals: equals)
			.synchronize(first, binding)
			.padding()
			.frame(height: .standardButtonHeight)
			.background(Color.app.gray5)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
			.cornerRadius(.small2)
			.overlay(
				RoundedRectangle(cornerRadius: .small2)
					.stroke(Color.app.gray1, lineWidth: 1)
			)

			Text(hint)
				.foregroundColor(.app.gray2)
				.textStyle(.body2Regular)
		}
	}
}

// MARK: - CreateAccount_Previews
struct CreateAccount_Previews: PreviewProvider {
	static var previews: some View {
		registerFonts()

		return CreateAccount.View(
			store: .init(
                initialState: .init(shouldCreateProfile: false),
				reducer: CreateAccount()
			)
		)
	}
}
