import FeaturePrelude

extension IntroductionToEntity.State {
	var viewState: IntroductionToEntity.ViewState {
		.init(kind: Entity.entityKind)
	}
}

// MARK: - IntroductionToEntity.View
extension IntroductionToEntity {
	public struct ViewState: Equatable {
		let kind: EntityKind
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<IntroductionToEntity>

		public init(store: StoreOf<IntroductionToEntity>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					switch viewStore.kind {
					case .account: introToAccounts(with: viewStore)
					case .identity: introToPersona(with: viewStore)
					}

					Button("Continue") {
						viewStore.send(.continueButtonTapped)
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: false))
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}

		@ViewBuilder
		private func introToAccounts(with viewStore: ViewStoreOf<IntroductionToEntity>) -> some SwiftUI.View {
			Text("Accounts are cool")
		}

		@ViewBuilder
		private func introToPersona(with viewStore: ViewStoreOf<IntroductionToEntity>) -> some SwiftUI.View {
			Text("Personas are cool")
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
