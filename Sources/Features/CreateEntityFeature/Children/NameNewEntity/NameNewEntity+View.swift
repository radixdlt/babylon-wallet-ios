import FeaturePrelude

extension NameNewEntity.State {
	var viewState: NameNewEntity.ViewState {
		.init(state: self)
	}
}

// MARK: - NameNewEntity.View
extension NameNewEntity {
	public struct ViewState: Equatable {
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
			titleText = {
				switch entityKind {
				case .account:
					return state.isFirst ? L10n.CreateEntity.NameNewEntity.Account.Title.first : L10n.CreateEntity.NameNewEntity.Account.Title.notFirst
				case .identity:
					return L10n.CreateEntity.NameNewEntity.Persona.title
				}
			}()
			entityName = state.inputtedName
			let isNameValid = state.sanitizedName != nil
			createEntityButtonState = isNameValid ? .enabled : .disabled
			focusedField = state.focusedField
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NameNewEntity>
		@FocusState private var focusedField: NameNewEntity.State.Field?

		public init(store: StoreOf<NameNewEntity>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ForceFullScreen {
				WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
					ScrollView {
						VStack(spacing: .medium1) {
							title(with: viewStore)

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
									equals: .entityName,
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
						}
						.padding([.horizontal, .bottom], .medium1)
					}
					#if os(iOS)
					.toolbar(.visible, for: .navigationBar)
					#endif
					.safeAreaInset(edge: .bottom, spacing: 0) {
						Button(L10n.CreateEntity.NameNewEntity.Name.Button.title) {
							viewStore.send(.confirmNameButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
						.controlState(viewStore.createEntityButtonState)
						.padding([.horizontal, .bottom], .medium1)
					}
					.onAppear {
						viewStore.send(.appeared)
					}
				}
			}
		}
	}
}

extension NameNewEntity.View {
	private func title(with viewStore: ViewStoreOf<NameNewEntity>) -> some View {
		Text(viewStore.titleText)
			.foregroundColor(.app.gray1)
			.textStyle(.sheetTitle)
	}

	private func subtitle(with viewStore: ViewStoreOf<NameNewEntity>) -> some View {
		Text(L10n.CreateEntity.NameNewEntity.subtitle(viewStore.entityKindName.lowercased()))
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
		NameNewEntity<OnNetwork.Account>.View(
			store: .init(
				initialState: .init(isFirst: true),
				reducer: NameNewEntity()
			)
		)
	}
}
#endif
