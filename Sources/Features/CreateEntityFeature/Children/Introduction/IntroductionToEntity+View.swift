import FeaturePrelude

// MARK: - IntroductionToEntity.View
extension IntroductionToEntity {
	public struct ViewState: Equatable {
		let kind: EntityKind
		let titleText: String
		let entityKindName: String
		init(state: IntroductionToEntity.State) {
			let entityKind = Entity.entityKind
			let entityKindName = entityKind == .account ? L10n.Common.Account.kind : L10n.Common.Persona.kind
			self.entityKindName = entityKindName
			self.kind = entityKind
			self.titleText = {
				switch entityKind {
				case .account:
					return
						L10n.CreateEntity.NameNewEntity.Account.Title.first
				case .identity:
					return L10n.CreateEntity.NameNewEntity.Persona.title
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
			WithViewStore(store, observe: ViewState.init(state:), send: { .view($0) }) { viewStore in
				VStack(alignment: .center, spacing: 30) {
					switch viewStore.kind {
					case .account: introToAccounts(with: viewStore)
					case .identity: introToPersona(with: viewStore)
					}

					Button("Continue") {
						viewStore.send(.continueButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.padding(.horizontal, .large1)
				.multilineTextAlignment(.center)
				.onAppear { viewStore.send(.appeared) }
			}
		}

		@ViewBuilder
		private func introToAccounts(with viewStore: ViewStoreOf<IntroductionToEntity>) -> some SwiftUI.View {
			Text("Accounts are cool")
		}

		@ViewBuilder
		private func introToPersona(with viewStore: ViewStoreOf<IntroductionToEntity>) -> some SwiftUI.View {
			// PLACEHOLDER until we get the correct icon.
			Color.app.gray4
				.frame(.huge)
				.cornerRadius(.small2)

			Text(viewStore.titleText)
				.foregroundColor(.app.gray1)
				.textStyle(.sheetTitle)

			Button {
				viewStore.send(.showTutorial)
			} label: {
				HStack {
					Image(asset: AssetResource.info)
					Text(L10n.GatewaySettings.WhatIsAGateway.buttonText)
						.textStyle(.body1StandaloneLink)
				}
				.tint(.app.blue2)
			}

			Text("A Persona is an identity that you own and control. You can have as many as you like.")
				.font(.app.body1Regular)
				.foregroundColor(.app.gray1)

			Text("You will choose Personas to login to dApps and dApps may request access to personal information associated with that Persona.")
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
		IntroductionToEntity<Profile.Network.Persona>.View(
			store: .init(
				initialState: .init(),
				reducer: IntroductionToEntity()
			)
		)
	}
}
#endif
