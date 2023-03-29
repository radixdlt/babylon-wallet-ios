import FeaturePrelude

// MARK: - IntroductionToEntity.View
extension IntroductionToEntity {
	public struct ViewState: Equatable {
		let kind: EntityKind
		let titleText: String
		init(state: IntroductionToEntity.State) {
			let entityKind = Entity.entityKind

			self.kind = entityKind
			self.titleText = {
				switch entityKind {
				case .account:
					return "Create an Account"
				case .identity:
					return L10n.CreateEntity.Introduction.Persona.title
				}
			}()
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<IntroductionToEntity>

		public init(store: StoreOf<IntroductionToEntity>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: IntroductionToEntity.ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(spacing: .large2) {
						switch viewStore.kind {
						case .account: introToAccounts(with: viewStore)
						case .identity: introToPersona(with: viewStore)
						}
					}
					.multilineTextAlignment(.center)
					.padding(.horizontal, .large1)
					.padding(.bottom, .medium2)
				}
				.footer {
					Button(L10n.CreateEntity.Introduction.Button.continue) {
						viewStore.send(.continueButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.onAppear { viewStore.send(.appeared) }
				.sheet(
					store: store.scope(
						state: \.$infoPanel,
						action: { .child(.infoPanel($0)) }
					),
					content: { SlideUpPanel.View(store: $0) }
				)
			}
		}

		@ViewBuilder
		private func introToAccounts(with viewStore: ViewStoreOf<IntroductionToEntity>) -> some SwiftUI.View {
			Text("Accounts on Radix are smart.")
		}

		@ViewBuilder
		private func introToPersona(with viewStore: ViewStoreOf<IntroductionToEntity>) -> some SwiftUI.View {
			// PLACEHOLDER until we get the correct icon.
			Color.app.gray4
				.frame(width: 200, height: 200)
				.cornerRadius(.small2)

			Text(viewStore.titleText)
				.foregroundColor(.app.gray1)
				.textStyle(.sheetTitle)

			Button {
				viewStore.send(.showTutorial)
			} label: {
				HStack {
					Image(asset: AssetResource.info)
					Text(L10n.CreateEntity.Introduction.Persona.Button.tutorial)
						.textStyle(.body1StandaloneLink)
				}
				.tint(.app.blue2)
			}

			Text(L10n.CreateEntity.Introduction.Persona.subtitle0)
				.font(.app.body1Regular)
				.foregroundColor(.app.gray1)

			Text(L10n.CreateEntity.Introduction.Persona.subtitle1)
				.font(.app.body1Regular)
				.foregroundColor(.app.gray1)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - IntroductionToEntity_Preview
struct IntroductionToEntity_Preview: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			IntroductionToEntity<Profile.Network.Persona>.View(
				store: .init(
					initialState: .init(),
					reducer: IntroductionToEntity()
				)
			)
			#if os(iOS)
			.toolbar(.visible, for: .navigationBar)
			#endif
		}
	}
}
#endif
