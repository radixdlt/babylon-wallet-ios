import FeaturePrelude

extension NameNewEntity.State {
	var viewState: NameNewEntity.ViewState {
		.init(state: self)
	}
}

// MARK: - NameNewEntity.View
extension NameNewEntity {
	public struct ViewState: Equatable {
		public let kind: EntityKind
		public let namePlaceholder: String
		public let titleText: String
		public let subtitleText: String
		public let entityName: String
		public let sanitizedNameRequirement: SanitizedNameRequirement?
		public let focusedField: State.Field?
		public let useLedgerAsFactorSource: Bool
		public let canUseLedgerAsFactorSource: Bool

		public struct SanitizedNameRequirement: Equatable {
			public let sanitizedName: NonEmptyString
		}

		init(state: State) {
			let entityKind = Entity.entityKind
			self.kind = entityKind

			switch entityKind {
			case .account:
				self.namePlaceholder = L10n.CreateAccount.NameNewAccount.placeholder
				self.titleText = state.isFirst ? L10n.CreateAccount.titleFirst : L10n.CreateAccount.titleNotFirst
				self.subtitleText = L10n.CreateAccount.NameNewAccount.subtitle

			case .identity:
				self.namePlaceholder = L10n.CreatePersona.NameNewPersona.placeholder
				self.titleText = L10n.CreatePersona.Introduction.title
				self.subtitleText = L10n.CreatePersona.NameNewPersona.subtitle
			}
			self.useLedgerAsFactorSource = state.useLedgerAsFactorSource
			self.entityName = state.inputtedName
			if let sanitizedName = state.sanitizedName {
				self.sanitizedNameRequirement = .init(sanitizedName: sanitizedName)
			} else {
				self.sanitizedNameRequirement = nil
			}
			self.focusedField = state.focusedField
			self.canUseLedgerAsFactorSource = state.canUseLedgerAsFactorSource
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
							title(with: viewStore.state)

							VStack(spacing: .large1) {
								subtitle(with: viewStore.state)

								if viewStore.canUseLedgerAsFactorSource {
									useLedgerAsFactorSource(with: viewStore)
								}

								let nameBinding = viewStore.binding(
									get: \.entityName,
									send: { .textFieldChanged($0) }
								)

								AppTextField(
									placeholder: viewStore.namePlaceholder,
									text: nameBinding,
									hint: .info(L10n.CreateEntity.NameNewEntity.explanation),
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
							Button(L10n.Common.continue, action: action)
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
	private func title(with viewState: NameNewEntity.ViewState) -> some View {
		Text(viewState.titleText)
			.foregroundColor(.app.gray1)
			.textStyle(.sheetTitle)
	}

	private func subtitle(with viewState: NameNewEntity.ViewState) -> some View {
		Text(viewState.subtitleText)
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
			title: L10n.CreateEntity.NameNewEntity.ledgerTitle,
			subtitle: L10n.CreateEntity.NameNewEntity.ledgerSubtitle,
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
