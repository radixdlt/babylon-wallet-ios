import ComposableArchitecture
import SwiftUI
extension AdvancedManageSecurityStructureFlow.State {
	var viewState: AdvancedManageSecurityStructureFlow.ViewState {
		.init(state: self)
	}
}

// MARK: - AdvancedManageSecurityStructureFlow.View
extension AdvancedManageSecurityStructureFlow {
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

		let numberOfDaysUntilAutoConfirmationString: String
		let primaryRole: SecurityStructureConfigurationDetailed.Configuration.Primary?
		let recoveryRole: SecurityStructureConfigurationDetailed.Configuration.Recovery?
		let confirmationRole: SecurityStructureConfigurationDetailed.Configuration.Confirmation?

		var numberOfDaysUntilAutoConfirmationHint: Hint? {
			// FIXME: future strings
			guard let _ = numberOfDaysUntilAutoConfirmation else {
				return .error(numberOfDaysUntilAutoConfirmationErrorNotInt)
			}
			return .info(numberOfDaysUntilAutoConfirmationHintInfo)
		}

		init(state: AdvancedManageSecurityStructureFlow.State) {
			self.numberOfDaysUntilAutoConfirmationString = state.numberOfDaysUntilAutoConfirmation.description
			self.mode = state.existing == nil ? .new : .existing
			self.primaryRole = state.primaryRole
			self.recoveryRole = state.recoveryRole
			self.confirmationRole = state.confirmationRole
		}

		var numberOfDaysUntilAutoConfirmation: RecoveryAutoConfirmDelayInDays? {
			guard let rawValue = RecoveryAutoConfirmDelayInDays.RawValue(numberOfDaysUntilAutoConfirmationString) else {
				return nil
			}
			return .init(rawValue: rawValue)
		}

		var config: SecurityStructureConfigurationDetailed.Configuration? {
			guard
				let primary = primaryRole,
				let recovery = recoveryRole,
				let confirmation = confirmationRole,
				let numberOfDaysUntilAutoConfirmation
			else {
				return nil
			}

			return .init(
				numberOfDaysUntilAutoConfirmation: numberOfDaysUntilAutoConfirmation,
				primaryRole: primary,
				recoveryRole: recovery,
				confirmationRole: confirmation
			)
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AdvancedManageSecurityStructureFlow>

		public init(store: StoreOf<AdvancedManageSecurityStructureFlow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack {
						FactorsForRoleButton<PrimaryRoleTag>(
							role: .primary,
							roleOfTier: viewStore.primaryRole
						) {
							viewStore.send(.primaryRoleButtonTapped)
						}

						FactorsForRoleButton<RecoveryRoleTag>(
							role: .recovery,
							roleOfTier: viewStore.recoveryRole
						) {
							viewStore.send(.recoveryRoleButtonTapped)
						}

						FactorsForRoleButton<ConfirmationRoleTag>(
							role: .confirmation,
							roleOfTier: viewStore.confirmationRole
						) {
							viewStore.send(.confirmationRoleButtonTapped)
						}

						AppTextField(
							primaryHeading: .init(text: numberOfDaysUntilAutoConfirmationTitlePlaceholder),
							secondaryHeading: numberOfDaysUntilAutoConfirmationSecondary,
							placeholder: numberOfDaysUntilAutoConfirmationTitlePlaceholder,
							text: viewStore.binding(
								get: \.numberOfDaysUntilAutoConfirmationString,
								send: { .changedNumberOfDaysUntilAutoConfirmation($0) }
							),
							hint: viewStore.numberOfDaysUntilAutoConfirmationHint,
							showClearButton: false
						)
						.keyboardType(.numberPad)
						.padding()
					}
					.padding()
				}
				.navigationTitle("Advanced Multifactor") // FIXME: future strings
				.footer {
					WithControlRequirements(
						viewStore.config,
						forAction: { config in
							viewStore.send(.finished(config))
						},
						control: { action in
							// FIXME: future strings
							let title = viewStore.mode.isExisting ? "Update setup" : "Create new setup"
							Button(title, action: action)
								.buttonStyle(.primaryRectangular)
						}
					)
				}
			}
			.destinations(with: store)
		}
	}
}

private extension StoreOf<AdvancedManageSecurityStructureFlow> {
	var destination: PresentationStoreOf<AdvancedManageSecurityStructureFlow.Destination> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AdvancedManageSecurityStructureFlow>) -> some View {
		let destinationStore = store.destination
		return primary(with: destinationStore)
			.recovery(with: destinationStore)
			.confirmation(with: destinationStore)
	}

	private func primary(with destinationStore: PresentationStoreOf<AdvancedManageSecurityStructureFlow.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /AdvancedManageSecurityStructureFlow.Destination.State.factorsForPrimaryRole,
			action: AdvancedManageSecurityStructureFlow.Destination.Action.factorsForPrimaryRole,
			content: { FactorsForRole<PrimaryRoleTag>.View(store: $0).inNavigationView }
		)
	}

	private func recovery(with destinationStore: PresentationStoreOf<AdvancedManageSecurityStructureFlow.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /AdvancedManageSecurityStructureFlow.Destination.State.factorsForRecoveryRole,
			action: AdvancedManageSecurityStructureFlow.Destination.Action.factorsForRecoveryRole,
			content: { FactorsForRole<RecoveryRoleTag>.View(store: $0).inNavigationView }
		)
	}

	private func confirmation(with destinationStore: PresentationStoreOf<AdvancedManageSecurityStructureFlow.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /AdvancedManageSecurityStructureFlow.Destination.State.factorsForConfirmationRole,
			action: AdvancedManageSecurityStructureFlow.Destination.Action.factorsForConfirmationRole,
			content: { FactorsForRole<ConfirmationRoleTag>.View(store: $0).inNavigationView }
		)
	}
}

extension RoleOfTier {
	var isEmpty: Bool {
		superAdminFactors.isEmpty && thresholdFactors.isEmpty
	}
}

// MARK: - FactorsForRoleButton
struct FactorsForRoleButton<R: RoleProtocol>: SwiftUI.View {
	let role: SecurityStructureRole
	let roleOfTier: RoleOfTier<R, FactorSource>?
	let action: () -> Void

	init(
		role: SecurityStructureRole,
		roleOfTier: RoleOfTier<R, FactorSource>?,
		action: @escaping () -> Void
	) {
		self.role = role
		self.roleOfTier = roleOfTier
		self.action = action
	}

	var buttonTitle: String {
		let none = "None set"
		guard let roleOfTier else { return none }

		switch (roleOfTier.superAdminFactors.isEmpty, roleOfTier.thresholdFactors.isEmpty) {
		case (true, true): return none
		case (false, false): return "Threshold & admin factors set"
		case (true, false): return "\(roleOfTier.thresholdFactors.count) threshold factors set"
		case (false, true): return "\(roleOfTier.superAdminFactors.count) admin factors set"
		}
	}

	var body: some View {
		VStack(alignment: .leading, spacing: .medium2) {
			Text(role.titleAdvancedFlow)
				.font(.app.sectionHeader)

			Text(role.subtitleAdvancedFlow)
				.font(.app.body2Header)
				.foregroundColor(.app.gray3)

			Button(action: action) {
				HStack {
					Text(buttonTitle)
						.font(.app.body1Header)
						.foregroundColor(roleOfTier == nil ? .app.gray3 : .app.gray1)

					Spacer(minLength: 0)

					Image(asset: AssetResource.chevronRight)
				}
			}
			.cornerRadius(.medium2)
			.frame(maxWidth: .infinity)
			.padding()
			.background(.app.gray5)
		}
	}
}

// #if DEBUG
// import SwiftUI
import ComposableArchitecture //
//// MARK: - AdvancedManageSecurityStructureFlow_Preview
// struct AdvancedManageSecurityStructureFlow_Preview: PreviewProvider {
//	static var previews: some View {
//		AdvancedManageSecurityStructureFlow.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: AdvancedManageSecurityStructureFlow.init
//			)
//		)
//	}
// }
//
// extension AdvancedManageSecurityStructureFlow.State {
//	public static let previewValue = Self()
// }
// #endif
