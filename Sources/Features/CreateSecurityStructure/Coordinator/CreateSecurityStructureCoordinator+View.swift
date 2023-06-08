import AddTrustedContactFactorSourceFeature
import AnswerSecurityQuestionsFeature
import DesignSystem
import FeaturePrelude
import Profile

// MARK: - CreateSecurityStructureCoordinator.View
extension CreateSecurityStructureCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CreateSecurityStructureCoordinator>

		public init(store: StoreOf<CreateSecurityStructureCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				IfLetStore(
					store.scope(state: \.root, action: { .child(.root($0)) })
				) {
					path(for: $0)
				}
				// This is required to disable the animation of internal components during transition
				.transaction { $0.animation = nil }
			} destination: {
				path(for: $0)
			}
			.modalDestination(store: self.store)
		}

		func path(
			for store: StoreOf<CreateSecurityStructureCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /CreateSecurityStructureCoordinator.Path.State.start,
					action: CreateSecurityStructureCoordinator.Path.Action.start,
					then: { CreateSecurityStructureStart.View(store: $0) }
				)
				CaseLet(
					state: /CreateSecurityStructureCoordinator.Path.State.simpleSetupFlow,
					action: CreateSecurityStructureCoordinator.Path.Action.simpleSetupFlow,
					then: { SimpleCreateSecurityStructureFlow.View(store: $0) }
				)
				CaseLet(
					state: /CreateSecurityStructureCoordinator.Path.State.advancedSetupFlow,
					action: CreateSecurityStructureCoordinator.Path.Action.advancedSetupFlow,
					then: { AdvancedCreateSecurityStructureFlow.View(store: $0) }
				)
			}
		}
	}
}

extension View {
	@MainActor
	fileprivate func modalDestination(store: StoreOf<CreateSecurityStructureCoordinator>) -> some View {
		let destinationStore = store.scope(state: \.$modalDestinations, action: { .child(.modalDestinations($0)) })
		return lostPhoneHelper(with: destinationStore)
			.newPhoneConfirmer(with: destinationStore)
	}

	@MainActor
	private func lostPhoneHelper(with destinationStore: PresentationStoreOf<CreateSecurityStructureCoordinator.ModalDestinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /CreateSecurityStructureCoordinator.ModalDestinations.State.simpleLostPhoneHelper,
			action: CreateSecurityStructureCoordinator.ModalDestinations.Action.simpleLostPhoneHelper,
			content: { AddTrustedContactFactorSource.View(store: $0) }
		)
	}

	@MainActor
	private func newPhoneConfirmer(with destinationStore: PresentationStoreOf<CreateSecurityStructureCoordinator.ModalDestinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /CreateSecurityStructureCoordinator.ModalDestinations.State.simpleNewPhoneConfirmer,
			action: CreateSecurityStructureCoordinator.ModalDestinations.Action.simpleNewPhoneConfirmer,
			content: { AnswerSecurityQuestionsCoordinator.View(store: $0) }
		)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - CreateSecurityStructure_Preview
struct CreateSecurityStructure_Preview: PreviewProvider {
	static var previews: some View {
		CreateSecurityStructureCoordinator.View(
			store: .init(
				initialState: .previewValue,
				reducer: CreateSecurityStructureCoordinator()
			)
		)
	}
}

extension CreateSecurityStructureCoordinator.State {
	public static let previewValue = Self()
}
#endif
