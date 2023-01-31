import FeaturePrelude
import GatherFactorsFeature

// MARK: - NameNewEntity.View
public extension NameNewEntity {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NameNewEntity>
		@FocusState private var focusedField: NameNewEntity.State.Field?

		public init(store: StoreOf<NameNewEntity>) {
			self.store = store
		}
	}
}

public extension NameNewEntity.View {
	var body: some View {
		ForceFullScreen {
			ZStack {
				createAccountView
					.zIndex(0)

				IfLetStore(
					store.scope(
						state: \.gatherFactor,
						action: { .child(.gatherFactor($0)) }
					),
					then: { GatherFactor.View(store: $0) }
				)
				.zIndex(1)
			}
		}
	}
}

internal extension NameNewEntity.View {
	@ViewBuilder
	var createAccountView: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
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

// MARK: - NameNewEntity.View.ViewState
extension NameNewEntity.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		public var titleText: String
		public var accountName: String
		public var isLoaderVisible: Bool
		public var createAccountButtonState: ControlState
		public var isDismissButtonVisible: Bool
		@BindableState public var focusedField: NameNewEntity.State.Field?

		init(state: NameNewEntity.State) {
			titleText = state.isFirstAccount == false ? L10n.CreateAccount.createNewAccount : L10n.CreateAccount.createFirstAccount
			accountName = state.inputtedAccountName
			isLoaderVisible = state.isCreatingAccount
			let isNameValid = !state.sanitizedAccountName.isEmpty
			createAccountButtonState = (isNameValid && !state.isCreatingAccount) ? .enabled : .disabled
			isDismissButtonVisible = !state.shouldCreateProfile && state.factorSources != nil
			focusedField = state.focusedField
		}
	}
}

// MARK: - NameNewEntity.View.ViewStore
private extension NameNewEntity.View {
	typealias ViewStore = ComposableArchitecture.ViewStore<NameNewEntity.View.ViewState, NameNewEntity.Action.ViewAction>
}

private extension NameNewEntity.View {
	func title(with viewStore: ViewStore) -> some View {
		Text(viewStore.titleText)
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

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct NameNewEntity_Previews: PreviewProvider {
	static var previews: some View {
		NameNewEntity.View(
			store: .init(
				initialState: .init(shouldCreateProfile: false),
				reducer: NameNewEntity()
			)
		)
	}
}
#endif
