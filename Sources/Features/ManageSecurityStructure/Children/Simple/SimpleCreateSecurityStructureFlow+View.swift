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

// FIXME: strings
public let numberOfDaysUntilAutoConfirmationTitlePlaceholder = "Days until auto confirm"
public let numberOfDaysUntilAutoConfirmationSecondary = "Integer"
public let numberOfDaysUntilAutoConfirmationErrorNotInt = "Not and integer"
public let numberOfDaysUntilAutoConfirmationHintInfo = "The phone confirmer is only needed if you want to skip waiting the number of specified days."

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
		let numberOfDaysUntilAutoConfirmation: String
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

		var numberOfDaysUntilAutoConfirmationHint: Hint? {
			// FIXME: strings
			guard let _ = RecoveryAutoConfirmDelayInDays.RawValue(numberOfDaysUntilAutoConfirmation) else {
				return .error(numberOfDaysUntilAutoConfirmationErrorNotInt)
			}
			return .info(numberOfDaysUntilAutoConfirmationHintInfo)
		}

		init(state: SimpleManageSecurityStructureFlow.State) {
			switch state.mode {
			case let .existing(existing):
				precondition(existing.isSimple)
				self.confirmerOfNewPhone = try! existing.configuration.confirmationRole.thresholdFactors[0].extract(as: SecurityQuestionsFactorSource.self)
				self.lostPhoneHelper = try! existing.configuration.recoveryRole.thresholdFactors[0].extract(as: TrustedContactFactorSource.self)
				self.mode = .existing
				self.numberOfDaysUntilAutoConfirmation = existing.configuration.numberOfDaysUntilAutoConfirmation.description
			case let .new(new):
				self.confirmerOfNewPhone = new.confirmerOfNewPhone
				self.lostPhoneHelper = new.lostPhoneHelper
				self.mode = .new
				self.numberOfDaysUntilAutoConfirmation = new.numberOfDaysUntilAutoConfirmation.description
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

						AppTextField(
							primaryHeading: .init(text: numberOfDaysUntilAutoConfirmationTitlePlaceholder),
							secondaryHeading: numberOfDaysUntilAutoConfirmationSecondary,
							placeholder: numberOfDaysUntilAutoConfirmationTitlePlaceholder,
							text: viewStore.binding(
								get: \.numberOfDaysUntilAutoConfirmation,
								send: { .changedNumberOfDaysUntilAutoConfirmation($0) }
							),
							hint: viewStore.numberOfDaysUntilAutoConfirmationHint,
							showClearButton: false
						)
						.keyboardType(.numberPad)
						.padding()

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
		return listConfirmerOfNewPhone(with: destinationStore)
			.listLostPhoneHelper(with: destinationStore)
	}

	@MainActor
	private func listConfirmerOfNewPhone(with destinationStore: PresentationStoreOf<SimpleManageSecurityStructureFlow.ModalDestinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /SimpleManageSecurityStructureFlow.ModalDestinations.State.listConfirmerOfNewPhone,
			action: SimpleManageSecurityStructureFlow.ModalDestinations.Action.listConfirmerOfNewPhone,
			content: { ListConfirmerOfNewPhone.View(store: $0) }
		)
	}

	@MainActor
	private func listLostPhoneHelper(with destinationStore: PresentationStoreOf<SimpleManageSecurityStructureFlow.ModalDestinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /SimpleManageSecurityStructureFlow.ModalDestinations.State.listLostPhoneHelper,
			action: SimpleManageSecurityStructureFlow.ModalDestinations.Action.listLostPhoneHelper,
			content: { ListLostPhoneHelper.View(store: $0) }
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
//				reducer: SimpleManageSecurityStructureFlow.init
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
