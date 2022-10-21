import Common
import ComposableArchitecture
import ImportProfileFeature
import SwiftUI

// MARK: - Onboarding.View
public extension Onboarding {
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
			observe: { $0 },
			send: Onboarding.Action.init
		) { viewStore in
			ZStack {
				ForceFullScreen {
					VStack {
						Button {
							viewStore.send(.newProfileButtonTapped)
						} label: {
							Text("New Profile")
								.foregroundColor(.white)
								.frame(maxWidth: .infinity)
						}

						LabelledDivider(label: "or")

						Button {
							viewStore.send(.importProfileButtonTapped)
						} label: {
							Text("Import Profile")
								.foregroundColor(.white)
								.frame(maxWidth: .infinity)
						}
					}
					.padding()
					.buttonStyle(.borderedProminent)
					.textFieldStyle(.roundedBorder)
				}
				.zIndex(0)

				IfLetStore(
					store.scope(
						state: \.newProfile,
						action: Onboarding.Action.newProfile
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
						action: Onboarding.Action.importProfile
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
						action: Onboarding.Action.importMnemonic
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

// MARK: - Onboarding.View.ViewAction
extension Onboarding.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case newProfileButtonTapped
		case importProfileButtonTapped
	}
}

extension Onboarding.Action {
	init(action: Onboarding.View.ViewAction) {
		switch action {
		case .importProfileButtonTapped:
			self = .internal(.user(.importProfile))
		case .newProfileButtonTapped:
			self = .internal(.user(.newProfile))
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
