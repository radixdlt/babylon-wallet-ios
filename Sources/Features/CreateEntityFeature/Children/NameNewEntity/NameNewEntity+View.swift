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
			WithViewStore(
				store,
				observe: ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				VStack(spacing: .zero) {
					//                    if viewStore.isDismissButtonVisible {
					//                        NavigationBar(
					//                            leadingItem: CloseButton {
					//                                viewStore.send(.closeButtonTapped)
					//                            }
					//                        )
					//                        .foregroundColor(.app.gray1)
					//                        .padding([.horizontal, .top], .medium3)
					//                    } else {
					Spacer()
						.frame(minHeight: .small2, maxHeight: .large1)
					//                    }
					VStack {
						title(with: viewStore)

						Spacer()
							.frame(minHeight: .small2, maxHeight: .large1)

						VStack(spacing: .large1) {
							subtitle(with: viewStore)

							let nameBinding = viewStore.binding(
								get: \.entityName,
								send: { .textFieldChanged($0) }
							)

							AppTextField(
								placeholder: viewStore.namePlaceholder,
								text: nameBinding,
								hint: L10n.CreateEntity.NameNewEntity.Name.Field.explanation,
								binding: $focusedField,
								equals: .accountName,
								first: viewStore.binding(
									get: \.focusedField,
									send: { .textFieldFocused($0) }
								)
							)
							#if os(iOS)
							.textFieldCharacterLimit(30, forText: nameBinding)
							#endif
							.autocorrectionDisabled()
						}

						Spacer(minLength: .small2)

						//                        if viewStore.isLoaderVisible {
						//                            ProgressView()
						//                        }

						Spacer()

						Button(L10n.CreateEntity.NameNewEntity.Name.Button.title) {
							viewStore.send(.confirmNameButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
						.controlState(viewStore.createEntityButtonState)
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

// MARK: - NameNewEntity.View.ViewState
extension NameNewEntity.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		public let namePlaceholder: String
		public var titleText: String
		public var entityName: String
		public let entityKindName: String
		public var createEntityButtonState: ControlState
		@BindingState public var focusedField: NameNewEntity.State.Field?

		init(state: NameNewEntity.State) {
			let entityKind = Entity.entityKind
			let entityKindName = entityKind == .account ? L10n.Common.Account.kind : L10n.Common.Persona.kind
			self.entityKindName = entityKindName
			self.namePlaceholder = entityKind == .account ? L10n.CreateEntity.NameNewEntity.Name.Field.Placeholder.Specific.account : L10n.CreateEntity.NameNewEntity.Name.Field.Placeholder.Specific.persona
			titleText = state.isFirst ? L10n.CreateEntity.NameNewEntity.Title.first(entityKindName) : L10n.CreateEntity.NameNewEntity.Title.notFirst(entityKindName)
			entityName = state.inputtedName
			let isNameValid = state.sanitizedName != nil
			createEntityButtonState = isNameValid ? .enabled : .disabled
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

	func subtitle(with viewStore: ViewStore) -> some View {
		Text(L10n.CreateEntity.NameNewEntity.subtitle(viewStore.entityKindName.lowercased()))
			.fixedSize(horizontal: false, vertical: true)
			.padding(.horizontal, .large1)
			.multilineTextAlignment(.center)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
	}
}

//
// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct NameNewEntity_Previews: PreviewProvider {
//	static var previews: some View {
//		NameNewEntity.View(
//			store: .init(
//				initialState: .init(shouldCreateProfile: false),
//				reducer: NameNewEntity()
//			)
//		)
//	}
// }
// #endif
