import ComposableArchitecture
import SwiftUI

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
		public let hint: Hint?
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
				if sanitizedName.count > Sargon.Account.nameMaxLength {
					self.sanitizedNameRequirement = nil
					self.hint = .error(L10n.Error.AccountLabel.tooLong)
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
	public struct View: SwiftUI.View {
		private let store: StoreOf<NameAccount>

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

						AppTextField(
							placeholder: viewStore.namePlaceholder,
							text: nameBinding,
							hint: viewStore.hint
						)
						.keyboardType(.asciiCapable)
						.autocorrectionDisabled()
						.padding(.bottom, .medium3)

						useLedgerAsFactorSource(with: viewStore)
					}
					.padding([.bottom, .horizontal], .medium1)
				}
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
			.foregroundColor(.app.gray1)
			.textStyle(.sheetTitle)
	}

	private func subtitle(with viewState: NameAccount.ViewState) -> some View {
		VStack {
			Text(viewState.subtitleText)
				.fixedSize(horizontal: false, vertical: true)
				.padding(.horizontal, .large1)
				.multilineTextAlignment(.center)
				.foregroundColor(.app.gray1)
				.textStyle(.body1Regular)

			Text(L10n.CreateAccount.NameNewAccount.explanation)
				.foregroundColor(.app.gray2)
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

// #if DEBUG
// import SwiftUI
import ComposableArchitecture //

// struct NameAccount_Previews: PreviewProvider {
//	static var previews: some View {
//		NameAccount.View(
//			store: .init(
//				initialState: .init(isFirst: true),
//				reducer: NameNewEntity.init
//			)
//		)
//	}
// }
// #endif
