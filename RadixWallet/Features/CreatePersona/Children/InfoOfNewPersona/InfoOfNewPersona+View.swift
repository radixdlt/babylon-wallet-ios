import ComposableArchitecture
import SwiftUI
extension NewPersonaInfo.State {
	var viewState: NewPersonaInfo.ViewState {
		.init(state: self)
	}
}

extension NewPersonaInfo {
	public struct ViewState: Equatable {
		public let namePlaceholder: String
		public let titleText: String
		public let subtitleText: String
		public let entityName: String
		public let hint: Hint?
		public let sanitizedNameRequirement: SanitizedNameRequirement?
		public let focusedInputField: State.InputField?

		public struct SanitizedNameRequirement: Equatable {
			// FIXME: Allow input of `PersonaData`!
			public let sanitizedName: NonEmptyString
		}

		init(state: State) {
			self.namePlaceholder = L10n.CreatePersona.NameNewPersona.placeholder
			self.titleText = L10n.CreatePersona.Introduction.title
			self.subtitleText = L10n.CreatePersona.NameNewPersona.subtitle
			self.entityName = state.inputtedName

			let defaultHint: Hint = .info(L10n.CreateEntity.NameNewEntity.explanation)
			if let sanitizedName = state.sanitizedName {
				if sanitizedName.count > Profile.Network.Account.nameMaxLength {
					self.sanitizedNameRequirement = nil
					self.hint = .error(L10n.Error.PersonaLabel.tooLong)
				} else {
					self.sanitizedNameRequirement = .init(sanitizedName: sanitizedName)
					self.hint = defaultHint
				}
			} else {
				self.sanitizedNameRequirement = nil
				self.hint = defaultHint
			}
			self.focusedInputField = state.focusedInputField
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NewPersonaInfo>
		@FocusState private var focusedInputField: State.InputField?

		public init(store: StoreOf<NewPersonaInfo>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ForceFullScreen {
				WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
					ScrollView {
						VStack(spacing: .medium1) {
							title(with: viewStore.state)

							VStack(spacing: .large1) {
								subtitle(with: viewStore.state)

								let nameBinding = viewStore.binding(
									get: \.entityName,
									send: { .textFieldChanged($0) }
								)

								AppTextField(
									placeholder: viewStore.namePlaceholder,
									text: nameBinding,
									hint: viewStore.hint,
									focus: .on(
										.personaName,
										binding: viewStore.binding(
											get: \.focusedInputField,
											send: { .textFieldFocused($0) }
										),
										to: $focusedInputField
									)
								)
								.autocorrectionDisabled()
							}
						}
						.padding([.horizontal, .bottom], .medium1)
					}
					.toolbar(.visible, for: .navigationBar)
					.footer {
						WithControlRequirements(
							viewStore.sanitizedNameRequirement,
							forAction: { viewStore.send(.confirmNameButtonTapped($0.sanitizedName)) }
						) { action in
							Button(L10n.CreatePersona.NameNewPersona.continue, action: action)
								.buttonStyle(.primaryRectangular)
						}
					}
					.onAppear {
						viewStore.send(.appeared)
					}
				}
			}
		}
	}
}

extension NewPersonaInfo.View {
	private func title(with viewState: NewPersonaInfo.ViewState) -> some View {
		Text(viewState.titleText)
			.foregroundColor(.app.gray1)
			.textStyle(.sheetTitle)
	}

	private func subtitle(with viewState: NewPersonaInfo.ViewState) -> some View {
		Text(viewState.subtitleText)
			.fixedSize(horizontal: false, vertical: true)
			.padding(.horizontal, .large1)
			.multilineTextAlignment(.center)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
	}
}

//
// #if DEBUG
// import SwiftUI
import ComposableArchitecture //
// struct InfoOfNewPersona_Previews: PreviewProvider {
//	static var previews: some View {
//		NameNewEntity<Profile.Network.Account>.View(
//			store: .init(
//				initialState: .init(isFirst: true),
//				reducer: NameNewEntity.init
//			)
//		)
//	}
// }
// #endif
