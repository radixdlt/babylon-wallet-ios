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
			send: CreateAccount.Action.init
		) { viewStore in
			ForceFullScreen {
				VStack {
					HStack {
						Button(
							action: { viewStore.send(.closeButtonTapped) },
							label: { Image("close") }
						)
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
									send: { ViewAction.textFieldDidChange($0) }
								)
								.removeDuplicates()
							)
							.focused($focusedField, equals: .accountName)
							.synchronize(
								viewStore.binding(
									get: \.focusedField,
									send: ViewAction.textFieldDidFocus
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

					PrimaryButton(
						title: L10n.CreateAccount.continueButtonTitle,
						isEnabled: viewStore.isValid,
						action: {
							viewStore.send(.createButtonTapped)
						}
					)
					.disabled(!viewStore.isValid)
				}
				.onAppear {
					viewStore.send(.viewDidAppear)
				}
				.padding(24)
			}
		}
	}
}

// MARK: - CreateAccount.View.ViewAction
extension CreateAccount.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case viewDidAppear
		case createButtonTapped
		case closeButtonTapped
		case textFieldDidFocus
		case textFieldDidChange(String)
	}
}

extension CreateAccount.Action {
	init(action: CreateAccount.View.ViewAction) {
		switch action {
		case .createButtonTapped:
			self = .internal(.user(.createAccount))

		case .viewDidAppear:
			self = .internal(.system(.viewDidAppear))

		case .closeButtonTapped:
			self = .internal(.user(.dismiss))

		case .textFieldDidFocus:
			self = .internal(.user(.textFieldDidFocus))

		case let .textFieldDidChange(value):
			self = .internal(.user(.textFieldDidChange(value)))
		}
	}
}

// MARK: - CreateAccount.View.ViewState
extension CreateAccount.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		public var numberOfExistingAccounts: Int
		public var accountName: String
		public var isValid: Bool
		@BindableState public var focusedField: CreateAccount.State.Field?

		init(state: CreateAccount.State) {
			numberOfExistingAccounts = state.numberOfExistingAccounts
			accountName = state.accountName
			isValid = state.isValid
			focusedField = state.focusedField
		}
	}
}

// MARK: - CreateAccount.View.ViewStore
private extension CreateAccount.View {
	typealias ViewStore = ComposableArchitecture.ViewStore<CreateAccount.View.ViewState, CreateAccount.View.ViewAction>
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
