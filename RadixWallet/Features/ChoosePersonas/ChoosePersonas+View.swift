import ComposableArchitecture
import SwiftUI

// MARK: - ChoosePersonas.View
extension ChoosePersonas {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ChoosePersonas>

		init(store: StoreOf<ChoosePersonas>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .small1) {
						Selection(
							$store.selectedPersonas.sending(\.view.selectedPersonasChanged),
							from: store.availablePersonas,
							requiring: store.selectionRequirement,
							showSelectAll: store.showSelectAllPersonas
						) { item in
							PersonaRow.View(
								viewState: .init(state: item.value),
								selectionType: .checkmark,
								isSelected: item.isSelected,
								action: item.action
							)
						}
					}
				}
				.onAppear {
					store.send(.view(.appeared))
				}
				.cardShadow
			}
		}
	}
}
