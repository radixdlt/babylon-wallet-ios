import Common
import ComposableArchitecture
import DesignSystem
import ImportProfileFeature
import SwiftUI

// MARK: - Onboarding.View
public extension Onboarding {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Onboarding>

		public init(store: StoreOf<Onboarding>) {
			self.store = store
		}
	}
}

public extension Onboarding.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ZStack {
				ForceFullScreen {
					VStack {
						Button(L10n.Onboarding.newAccountButtonTitle) {
							viewStore.send(.newProfileButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
					}
					.padding()
				}
				.zIndex(0)

				IfLetStore(
					store.scope(
						state: \.newProfile,
						action: { .child(.newProfile($0)) }
					),
					then: { newProfileStore in
						ForceFullScreen {
							NewProfile.View(store: newProfileStore)
						}
					}
				)
				.zIndex(1)

				IfLetStore(
					store.scope(
						state: \.importProfile,
						action: { .child(.importProfile($0)) }
					),
					then: { importProfileStore in
						ForceFullScreen {
							ImportProfile.View(store: importProfileStore)
						}
					}
				)
				.zIndex(2)

				IfLetStore(
					store.scope(
						state: \.importMnemonic,
						action: { .child(.importMnemonic($0)) }
					),
					then: { importMnemonicStore in
						ForceFullScreen {
							ImportMnemonic.View(store: importMnemonicStore)
						}
					}
				)
				.zIndex(3)
			}
		}
	}
}

// MARK: - Onboarding.View.ViewState
extension Onboarding.View {
	struct ViewState: Equatable {
		public var newProfile: NewProfile.State?
		public var importProfile: ImportProfile.State?
		public var importMnemonic: ImportMnemonic.State?
		public init(state: Onboarding.State) {
			newProfile = state.newProfile
			importProfile = state.importProfile
			importMnemonic = state.importMnemonic
		}
	}
}
