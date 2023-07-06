import FeaturePrelude

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

		let numberOfMinutesUntilAutoConfirmationString: String
		let primaryRole: SecurityStructureConfigurationDetailed.Configuration.Primary?
		let recoveryRole: SecurityStructureConfigurationDetailed.Configuration.Recovery?
		let confirmationRole: SecurityStructureConfigurationDetailed.Configuration.Confirmation?

		var numberOfMinutesUntilAutoConfirmationHint: Hint? {
			// FIXME: strings
			guard let _ = numberOfMinutesUntilAutoConfirmation else {
				return .error(numberOfMinutesUntilAutoConfirmationErrorNotInt)
			}
			return .info(numberOfMinutesUntilAutoConfirmationHintInfo)
		}

		init(state: AdvancedManageSecurityStructureFlow.State) {
			self.numberOfMinutesUntilAutoConfirmationString = state.numberOfMinutesUntilAutoConfirmation.description
			self.mode = state.existing == nil ? .new : .existing
			self.primaryRole = state.primaryRole
			self.recoveryRole = state.recoveryRole
			self.confirmationRole = state.confirmationRole
		}

		var numberOfMinutesUntilAutoConfirmation: RecoveryAutoConfirmDelayInMinutes? {
			guard let rawValue = RecoveryAutoConfirmDelayInMinutes.RawValue(numberOfMinutesUntilAutoConfirmationString) else {
				return nil
			}
			return .init(rawValue: rawValue)
		}

		var config: SecurityStructureConfigurationDetailed.Configuration? {
			guard
				let primary = primaryRole,
				let recovery = recoveryRole,
				let confirmation = confirmationRole,
				let numberOfMinutesUntilAutoConfirmation
			else {
				return nil
			}

			return .init(
				numberOfMinutesUntilAutoConfirmation: numberOfMinutesUntilAutoConfirmation,
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
							primaryHeading: .init(text: numberOfMinutesUntilAutoConfirmationTitlePlaceholder),
							secondaryHeading: numberOfMinutesUntilAutoConfirmationSecondary,
							placeholder: numberOfMinutesUntilAutoConfirmationTitlePlaceholder,
							text: viewStore.binding(
								get: \.numberOfMinutesUntilAutoConfirmationString,
								send: { .changedNumberOfDaysUntilAutoConfirmation($0) }
							),
							hint: viewStore.numberOfMinutesUntilAutoConfirmationHint,
							showClearButton: false
						)
						.keyboardType(.numberPad)
						.padding()
					}
					.padding()
				}
				.navigationTitle("Advanced Multifactor")
				.footer {
					WithControlRequirements(
						viewStore.config,
						forAction: { config in
							viewStore.send(.finished(config))
						},
						control: { action in
							// FIXME: Strings
							let title = viewStore.mode.isExisting ? "Update setup" : "Create new setup"
							Button(title, action: action)
								.buttonStyle(.primaryRectangular)
						}
					)
				}
				.destinations(store: store)
			}
		}
	}
}

extension View {
	@MainActor
	fileprivate func destinations(store: StoreOf<AdvancedManageSecurityStructureFlow>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return primary(destinationStore).recovery(destinationStore).confirmation(destinationStore)
	}

	@MainActor
	private func primary(_ destinationStore: PresentationStoreOf<AdvancedManageSecurityStructureFlow.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /AdvancedManageSecurityStructureFlow.Destinations.State.factorsForPrimaryRole,
			action: AdvancedManageSecurityStructureFlow.Destinations.Action.factorsForPrimaryRole,
			content: { store in NavigationView { FactorsForRole<PrimaryRoleTag>.View(store: store) } }
		)
	}

	@MainActor
	private func recovery(_ destinationStore: PresentationStoreOf<AdvancedManageSecurityStructureFlow.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /AdvancedManageSecurityStructureFlow.Destinations.State.factorsForRecoveryRole,
			action: AdvancedManageSecurityStructureFlow.Destinations.Action.factorsForRecoveryRole,
			content: { store in NavigationView { FactorsForRole<RecoveryRoleTag>.View(store: store) } }
		)
	}

	@MainActor
	private func confirmation(_ destinationStore: PresentationStoreOf<AdvancedManageSecurityStructureFlow.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /AdvancedManageSecurityStructureFlow.Destinations.State.factorsForConfirmationRole,
			action: AdvancedManageSecurityStructureFlow.Destinations.Action.factorsForConfirmationRole,
			content: { store in NavigationView { FactorsForRole<ConfirmationRoleTag>.View(store: store) } }
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

	var buttonTitle: LocalizedStringKey {
		let none: LocalizedStringKey = "None set"
		guard
			let roleOfTier
		else {
			return none
		}

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
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - AdvancedManageSecurityStructureFlow_Preview
// struct AdvancedManageSecurityStructureFlow_Preview: PreviewProvider {
//	static var previews: some View {
//		AdvancedManageSecurityStructureFlow.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: AdvancedManageSecurityStructureFlow()
//			)
//		)
//	}
// }
//
// extension AdvancedManageSecurityStructureFlow.State {
//	public static let previewValue = Self()
// }
// #endif
