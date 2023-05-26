import FeaturePrelude

extension NameAccount.State {
	var viewState: NameAccount.ViewState {
		.init(state: self)
	}
}

extension NameAccount {
	public struct ViewState: Equatable {
		public let namePlaceholder: String
		public let titleText: String
		public let subtitleText: String
		public let entityName: String
		public let sanitizedNameRequirement: SanitizedNameRequirement?
		public let focusedField: State.Field?
		public let useLedgerAsFactorSource: Bool

		public struct SanitizedNameRequirement: Equatable {
			public let sanitizedName: NonEmptyString
		}

		init(state: State) {
			self.namePlaceholder = L10n.CreateAccount.NameNewAccount.placeholder
			self.titleText = state.isFirst ? L10n.CreateAccount.titleFirst : L10n.CreateAccount.titleNotFirst
			self.subtitleText = L10n.CreateAccount.NameNewAccount.subtitle

			self.useLedgerAsFactorSource = state.useLedgerAsFactorSource
			self.entityName = state.inputtedName
			if let sanitizedName = state.sanitizedName {
				self.sanitizedNameRequirement = .init(sanitizedName: sanitizedName)
			} else {
				self.sanitizedNameRequirement = nil
			}
			self.focusedField = state.focusedField
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NameAccount>
		@FocusState private var focusedField: State.Field?

		public init(store: StoreOf<NameAccount>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: 0) {
						title(with: viewStore.state)
							.padding(.bottom, .medium1)

						subtitle(with: viewStore.state)
							.padding(.bottom, .large1)

						let nameBinding = viewStore.binding(
							get: \.entityName,
							send: { .textFieldChanged($0) }
						)

						let focusBinding = viewStore.binding(
							get: \.focusedField,
							send: { .textFieldFocused($0) }
						)

						AppTextField(
							placeholder: viewStore.namePlaceholder,
							text: nameBinding,
							hint: .info(L10n.CreateEntity.NameNewEntity.explanation),
							focus: .on(
								.entityName,
								binding: focusBinding,
								to: $focusedField
							)
						)
						#if os(iOS)
						.textFieldCharacterLimit(Profile.Network.Account.nameMaxLength, forText: nameBinding)
						#endif
						.autocorrectionDisabled()
						.padding(.bottom, .medium3)

						useLedgerAsFactorSource(with: viewStore)
					}
					.padding([.bottom, .horizontal], .medium1)
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

extension NameAccount.View {
	private func title(with viewState: NameAccount.ViewState) -> some View {
		Text(viewState.titleText)
			.foregroundColor(.app.gray1)
			.textStyle(.sheetTitle)
	}

	private func subtitle(with viewState: NameAccount.ViewState) -> some View {
		Text(viewState.subtitleText)
			.fixedSize(horizontal: false, vertical: true)
			.padding(.horizontal, .large1)
			.multilineTextAlignment(.center)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
	}

	private func useLedgerAsFactorSource(
		with viewStore: ViewStoreOf<NameAccount>
	) -> some SwiftUI.View {
		ToggleView(
			title: "Create with Ledger Hardware Wallet", // FIXME: Strings -> L10n.CreateEntity.NameNewEntity.ledgerTitle
			subtitle: L10n.CreateEntity.NameNewEntity.ledgerSubtitle,
			isOn: viewStore.binding(
				get: \.useLedgerAsFactorSource,
				send: { .useLedgerAsFactorSourceToggled($0) }
			)
		)
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct NameAccount_Previews: PreviewProvider {
//	static var previews: some View {
//		NameAccount.View(
//			store: .init(
//				initialState: .init(isFirst: true),
//				reducer: NameNewEntity()
//			)
//		)
//	}
// }
// #endif
