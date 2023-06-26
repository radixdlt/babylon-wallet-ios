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

		let numberOfDaysUntilAutoConfirmation: String

		let config: SecurityStructureConfigurationDetailed.Configuration?

		var numberOfDaysUntilAutoConfirmationHint: Hint? {
			// FIXME: strings
			guard let _ = RecoveryAutoConfirmDelayInDays.RawValue(numberOfDaysUntilAutoConfirmation) else {
				return .error(numberOfDaysUntilAutoConfirmationErrorNotInt)
			}
			return .info(numberOfDaysUntilAutoConfirmationHintInfo)
		}

		init(state: AdvancedManageSecurityStructureFlow.State) {
			self.numberOfDaysUntilAutoConfirmation = state.numberOfDaysUntilAutoConfirmation.description
			self.mode = state.existing == nil ? .new : .existing
			self.config = state.config
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
						FactorsForRoleButton(role: .primary) {
							viewStore.send(.primaryRoleButtonTapped)
						}

						FactorsForRoleButton(role: .recovery) {
							viewStore.send(.recoveryRoleButtonTapped)
						}

						FactorsForRoleButton(role: .confirmation) {
							viewStore.send(.confirmationRoleButtonTapped)
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
					}
					.padding()
				}
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
		return factorsForRoleSheet(with: destinationStore)
	}

	@MainActor
	private func factorsForRoleSheet(with destinationStore: PresentationStoreOf<AdvancedManageSecurityStructureFlow.Destinations>) -> some View {
		sheet(
			store: destinationStore,
			state: /AdvancedManageSecurityStructureFlow.Destinations.State.factorsForRole,
			action: AdvancedManageSecurityStructureFlow.Destinations.Action.factorsForRole,
			content: { store in NavigationView { FactorsForRole.View(store: store) } }
		)
	}
}

extension RoleOfTier {
	var isEmpty: Bool {
		superAdminFactors.isEmpty && thresholdFactors.isEmpty
	}
}

// MARK: - FactorsForRoleButton
struct FactorsForRoleButton: SwiftUI.View {
	let role: SecurityStructureRole
	let action: () -> Void

	init(
		role: SecurityStructureRole,
		action: @escaping () -> Void
	) {
		self.role = role
		self.action = action
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
					// FIXME: Strings
					Text("None set")
						.font(.app.body1Header)

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
