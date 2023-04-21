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
		public let titleText: String
		public let entityName: String
		public let entityKindName: String
		public let sanitizedNameRequirement: SanitizedNameRequirement?
		public struct SanitizedNameRequirement: Equatable {
			public let sanitizedName: NonEmptyString
		}

		public let focusedField: State.Field?
		public let useLedgerAsFactorSource: Bool

		init(state: State) {
			let entityKind = Entity.entityKind
			let entityKindName = entityKind == .account ? L10n.Common.Account.kind : L10n.Common.Persona.kind
			self.entityKindName = entityKindName
			self.namePlaceholder = entityKind == .account ? L10n.CreateEntity.NameNewEntity.Name.Field.Placeholder.Specific.account : L10n.CreateEntity.NameNewEntity.Name.Field.Placeholder.Specific.persona
			titleText = {
				switch entityKind {
				case .account:
					return state.isFirst ?
						L10n.CreateEntity.NameNewEntity.Account.Title.first :
						L10n.CreateEntity.NameNewEntity.Account.Title.notFirst
				case .identity:
					return L10n.CreateEntity.NameNewEntity.Persona.title
				}
			}()
			useLedgerAsFactorSource = state.useLedgerAsFactorSource
			entityName = state.inputtedName
			if let sanitizedName = state.sanitizedName {
				sanitizedNameRequirement = .init(sanitizedName: sanitizedName)
			} else {
				sanitizedNameRequirement = nil
			}
			focusedField = state.focusedField
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NameNewEntity>
		@FocusState private var focusedField: State.Field?

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

								useLedgerAsFactorSource(with: viewStore)

								let nameBinding = viewStore.binding(
									get: \.entityName,
									send: { .textFieldChanged($0) }
								)

								AppTextField(
									placeholder: viewStore.namePlaceholder,
									text: nameBinding,
									hint: .info(L10n.CreateEntity.NameNewEntity.Name.Field.explanation),
									focus: .on(
										.entityName,
										binding: viewStore.binding(
											get: \.focusedField,
											send: { .textFieldFocused($0) }
										),
										to: $focusedField
									)
								)
								#if os(iOS)
								.textFieldCharacterLimit(Profile.Network.Account.nameMaxLength, forText: nameBinding)
								#endif
								.autocorrectionDisabled()
							}
						}
						.padding([.horizontal, .bottom], .medium1)
					}
					#if os(iOS)
					.toolbar(.visible, for: .navigationBar)
					#endif
					.footer {
						WithControlRequirements(
							viewStore.sanitizedNameRequirement,
							forAction: { viewStore.send(.confirmNameButtonTapped($0.sanitizedName)) }
						) { action in
							Button(L10n.CreateEntity.NameNewEntity.Name.Button.title, action: action)
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

	private func useLedgerAsFactorSource(
		with viewStore: ViewStoreOf<NameNewEntity>
	) -> some SwiftUI.View {
		ToggleView(
			title: "Create with Ledger hardware wallet",
			subtitle: "Requires you to sign transactions using your Ledger",
			isOn: viewStore.binding(
				get: \.useLedgerAsFactorSource,
				send: { .useLedgerAsFactorSourceToggled($0) }
			)
		)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct NameNewEntity_Previews: PreviewProvider {
	static var previews: some View {
		NameNewEntity<Profile.Network.Account>.View(
			store: .init(
				initialState: .init(isFirst: true),
				reducer: NameNewEntity()
			)
		)
	}
}
#endif
