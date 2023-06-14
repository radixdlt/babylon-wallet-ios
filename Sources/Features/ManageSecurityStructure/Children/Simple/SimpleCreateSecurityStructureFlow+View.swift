import AnswerSecurityQuestionsFeature
import FeaturePrelude
import Logging
import ManageTrustedContactFactorSourceFeature

extension SimpleManageSecurityStructureFlow.State {
	var viewState: SimpleManageSecurityStructureFlow.ViewState {
		.init(state: self)
	}
}

// MARK: - RecoveryAndConfirmationFactors
public struct RecoveryAndConfirmationFactors: Sendable, Hashable {
	let singleRecoveryFactor: TrustedContactFactorSource
	let singleConfirmationFactor: SecurityQuestionsFactorSource
}

// MARK: - SimpleManageSecurityStructureFlow.View
extension SimpleManageSecurityStructureFlow {
	public struct ViewState: Equatable {
		public enum Mode: Equatable {
			case new
			case existing
			var isExisting: Bool {
				guard case .existing = self else {
					return false
				}
				return true
			}
		}

		let mode: Mode
		let confirmerOfNewPhone: SecurityQuestionsFactorSource?
		let lostPhoneHelper: TrustedContactFactorSource?
		var simpleSecurityStructure: RecoveryAndConfirmationFactors? {
			guard let lostPhoneHelper, let confirmerOfNewPhone else {
				return nil
			}
			return .init(
				singleRecoveryFactor: lostPhoneHelper,
				singleConfirmationFactor: confirmerOfNewPhone
			)
		}

		init(state: SimpleManageSecurityStructureFlow.State) {
			switch state.mode {
			case let .existing(existing):
				precondition(existing.isSimple)
				self.confirmerOfNewPhone = try! existing.configuration.confirmationRole.thresholdFactors[0].extract(as: SecurityQuestionsFactorSource.self)
				self.lostPhoneHelper = try! existing.configuration.recoveryRole.thresholdFactors[0].extract(as: TrustedContactFactorSource.self)
				self.mode = .existing
			case let .new(new):
				self.confirmerOfNewPhone = new.confirmerOfNewPhone?.factorSource
				self.lostPhoneHelper = new.lostPhoneHelper
				self.mode = .new
			}
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SimpleManageSecurityStructureFlow>

		public init(store: StoreOf<SimpleManageSecurityStructureFlow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					ScrollView {
						SecurityStructureTutorialHeader()

						NewPhoneConfirmer(factorSet: viewStore.confirmerOfNewPhone) {
							viewStore.send(.confirmerOfNewPhoneButtonTapped)
						}

						LostPhoneHelper(factorSet: viewStore.lostPhoneHelper) {
							viewStore.send(.lostPhoneHelperButtonTapped)
						}
					}
				}
				.navigationTitle("Multi-Factor Setup") // FIXME: Strings
				.footer {
					WithControlRequirements(
						viewStore.simpleSecurityStructure,
						forAction: { simpleStructure in
							viewStore.send(.finished(simpleStructure))
						},
						control: { action in
							// FIXME: Strings
							let title = viewStore.mode.isExisting ? "Update setup" : "Create new setup"
							Button(title, action: action)
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
	fileprivate func modalDestination(store: StoreOf<SimpleManageSecurityStructureFlow>) -> some View {
		let destinationStore = store.scope(state: \.$modalDestinations, action: { .child(.modalDestinations($0)) })
		return lostPhoneHelper(with: destinationStore)
			.newPhoneConfirmer(with: destinationStore)
	}

	@MainActor
	private func newPhoneConfirmer(with destinationStore: PresentationStoreOf<SimpleManageSecurityStructureFlow.ModalDestinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /SimpleManageSecurityStructureFlow.ModalDestinations.State.simpleNewPhoneConfirmer,
			action: SimpleManageSecurityStructureFlow.ModalDestinations.Action.simpleNewPhoneConfirmer,
			content: { AnswerSecurityQuestionsCoordinator.View(store: $0) }
		)
	}

	@MainActor
	private func lostPhoneHelper(with destinationStore: PresentationStoreOf<SimpleManageSecurityStructureFlow.ModalDestinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /SimpleManageSecurityStructureFlow.ModalDestinations.State.simpleLostPhoneHelper,
			action: SimpleManageSecurityStructureFlow.ModalDestinations.Action.simpleLostPhoneHelper,
			content: { store in
				NavigationStack {
					ManageTrustedContactFactorSource.View(store: store)
				}
			}
		)
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - SimpleManageSecurityStructureFlow_Preview
// struct SimpleManageSecurityStructureFlow_Preview: PreviewProvider {
//	static var previews: some View {
//		SimpleManageSecurityStructureFlow.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SimpleManageSecurityStructureFlow()
//			)
//		)
//	}
// }
//
// extension SimpleManageSecurityStructureFlow.State {
//	public static let previewValue = Self(
//		newPhoneConfirmer: nil,
//		lostPhoneHelper: nil
//	)
// }
// #endif
