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
						Button("New Account") {
							viewStore.send(.newProfileButtonTapped)
						}
						.buttonStyle(.primary)

						LabelledDivider(label: "or")

						Button("Import Account") {
							viewStore.send(.importProfileButtonTapped)
						}
						.buttonStyle(.secondary(shouldExpand: true))
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

// MARK: - LabelledDivider
struct LabelledDivider: View {
	let label: String
	let horizontalPadding: CGFloat
	let color: Color

	init(label: String, horizontalPadding: CGFloat = 20, color: Color = .gray) {
		self.label = label
		self.horizontalPadding = horizontalPadding
		self.color = color
	}

	var body: some View {
		HStack {
			line
			Text(label).foregroundColor(color)
			line
		}
	}

	var line: some View {
		VStack { Divider().background(color) }.padding(horizontalPadding)
	}
}
