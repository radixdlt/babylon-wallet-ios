import AddTrustedContactFactorSourceFeature
import AnswerSecurityQuestionsFeature
import FeaturePrelude
import Logging

extension SimpleCreateSecurityStructureFlow.State {
	var viewState: SimpleCreateSecurityStructureFlow.ViewState {
		.init(newPhoneConfirmer: newPhoneConfirmer, lostPhoneHelper: lostPhoneHelper)
	}
}

// MARK: - RecoveryAndConfirmationFactors
public struct RecoveryAndConfirmationFactors: Sendable, Hashable {
	let singleRecoveryFactor: TrustedContactFactorSource
	let singleConfirmationFactor: SecurityQuestionsFactorSource
}

// MARK: - SimpleCreateSecurityStructureFlow.View
extension SimpleCreateSecurityStructureFlow {
	public struct ViewState: Equatable {
		let newPhoneConfirmer: SecurityQuestionsFactorSource?
		let lostPhoneHelper: TrustedContactFactorSource?
		var simpleSecurityStructure: RecoveryAndConfirmationFactors? {
			guard let lostPhoneHelper, let newPhoneConfirmer else {
				return nil
			}
			return .init(
				singleRecoveryFactor: lostPhoneHelper,
				singleConfirmationFactor: newPhoneConfirmer
			)
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SimpleCreateSecurityStructureFlow>

		public init(store: StoreOf<SimpleCreateSecurityStructureFlow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					ScrollView {
						SecurityStructureTutorialHeader()

						NewPhoneConfirmer(factorSet: viewStore.newPhoneConfirmer) {
							viewStore.send(.selectNewPhoneConfirmer)
						}

						LostPhoneHelper(factorSet: viewStore.lostPhoneHelper) {
							viewStore.send(.selectLostPhoneHelper)
						}
					}
				}
				.navigationTitle("Multi-Factor Setup") // FIXME: Strings
				.footer {
					WithControlRequirements(
						viewStore.simpleSecurityStructure,
						forAction: { simpleStructure in
							viewStore.send(.finishSelectingFactors(simpleStructure))
						},
						control: { action in
							// FIXME: Strings
							Button("Confirm Multifactor Settings", action: action)
								.buttonStyle(.primaryRectangular)
						}
					)
				}
			}
			.modalDestination(store: self.store)
		}

		typealias NewPhoneConfirmer = FactorForRoleView<ConfirmationRoleTag, SecurityQuestionsFactorSource>
		typealias LostPhoneHelper = FactorForRoleView<RecoveryRoleTag, TrustedContactFactorSource>
	}
}

extension View {
	@MainActor
	fileprivate func modalDestination(store: StoreOf<SimpleCreateSecurityStructureFlow>) -> some View {
		let destinationStore = store.scope(state: \.$modalDestinations, action: { .child(.modalDestinations($0)) })
		return lostPhoneHelper(with: destinationStore)
			.newPhoneConfirmer(with: destinationStore)
	}

	@MainActor
	private func newPhoneConfirmer(with destinationStore: PresentationStoreOf<SimpleCreateSecurityStructureFlow.ModalDestinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /SimpleCreateSecurityStructureFlow.ModalDestinations.State.simpleNewPhoneConfirmer,
			action: SimpleCreateSecurityStructureFlow.ModalDestinations.Action.simpleNewPhoneConfirmer,
			content: { AnswerSecurityQuestionsCoordinator.View(store: $0) }
		)
	}

	@MainActor
	private func lostPhoneHelper(with destinationStore: PresentationStoreOf<SimpleCreateSecurityStructureFlow.ModalDestinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /SimpleCreateSecurityStructureFlow.ModalDestinations.State.simpleLostPhoneHelper,
			action: SimpleCreateSecurityStructureFlow.ModalDestinations.Action.simpleLostPhoneHelper,
			content: { store in
				NavigationStack {
					AddTrustedContactFactorSource.View(store: store)
				}
			}
		)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SimpleCreateSecurityStructureFlow_Preview
struct SimpleCreateSecurityStructureFlow_Preview: PreviewProvider {
	static var previews: some View {
		SimpleCreateSecurityStructureFlow.View(
			store: .init(
				initialState: .previewValue,
				reducer: SimpleCreateSecurityStructureFlow()
			)
		)
	}
}

extension SimpleCreateSecurityStructureFlow.State {
	public static let previewValue = Self(
		newPhoneConfirmer: nil,
		lostPhoneHelper: nil
	)
}
#endif
