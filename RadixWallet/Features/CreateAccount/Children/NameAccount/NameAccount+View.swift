import ComposableArchitecture
import SwiftUI

extension NameAccount.State {
	var viewState: NameAccount.ViewState {
		.init(state: self)
	}
}

extension NameAccount {
	struct ViewState: Equatable {
		let namePlaceholder: String
		let titleText: String
		let subtitleText: String
		let entityName: String
		let sanitizedNameRequirement: SanitizedNameRequirement?
		let hint: Hint.ViewState?
		let useLedgerAsFactorSource: Bool

		struct SanitizedNameRequirement: Equatable {
			let sanitizedName: NonEmptyString
		}

		init(state: State) {
			self.namePlaceholder = L10n.CreateAccount.NameNewAccount.placeholder
			self.titleText = state.isFirst ? L10n.CreateAccount.titleFirst : L10n.CreateAccount.titleNotFirst
			self.subtitleText = L10n.CreateAccount.NameNewAccount.subtitle

			self.useLedgerAsFactorSource = state.useLedgerAsFactorSource
			self.entityName = state.inputtedName
			if let sanitizedName = state.sanitizedName {
				if sanitizedName.count > Account.nameMaxLength {
					self.sanitizedNameRequirement = nil
					self.hint = .iconError(L10n.Error.AccountLabel.tooLong)
				} else {
					self.sanitizedNameRequirement = .init(sanitizedName: sanitizedName)
					self.hint = nil
				}
			} else {
				self.sanitizedNameRequirement = nil
				self.hint = nil
			}
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NameAccount>

		init(store: StoreOf<NameAccount>) {
			self.store = store
		}

		var body: some SwiftUI.View {
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

						AppTextField(
							placeholder: viewStore.namePlaceholder,
							text: nameBinding,
							hint: viewStore.hint
						)
						.keyboardType(.asciiCapable)
						.autocorrectionDisabled()
						.padding(.bottom, .large3)

						useLedgerAsFactorSource(with: viewStore)
					}
					.padding([.bottom, .horizontal], .medium1)
				}
				.background(.primaryBackground)
				.toolbar(.visible, for: .navigationBar)
				.footer {
					WithControlRequirements(
						viewStore.sanitizedNameRequirement,
						forAction: { viewStore.send(.confirmNameButtonTapped($0.sanitizedName)) }
					) { action in
						Button(L10n.CreateAccount.NameNewAccount.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}

extension NameAccount.View {
	private func title(with viewState: NameAccount.ViewState) -> some View {
		Text(viewState.titleText)
			.foregroundColor(.primaryText)
			.textStyle(.sheetTitle)
	}

	private func subtitle(with viewState: NameAccount.ViewState) -> some View {
		VStack {
			Text(viewState.subtitleText)
				.fixedSize(horizontal: false, vertical: true)
				.padding(.horizontal, .large1)
				.multilineTextAlignment(.center)
				.foregroundColor(.primaryText)
				.textStyle(.body1Regular)

			Text(L10n.CreateAccount.NameNewAccount.explanation)
				.foregroundColor(.secondaryText)
				.textStyle(.body1Regular)
		}
	}

	private func useLedgerAsFactorSource(
		with viewStore: ViewStoreOf<NameAccount>
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
