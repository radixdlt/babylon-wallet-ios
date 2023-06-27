import FeaturePrelude

extension FactorsForRole.State {
	var viewState: FactorsForRole.ViewState {
		.init(
			role: role,
			thresholdString: thresholdString,
			thresholdFactors: .init(thresholdFactorSources),
			adminFactors: .init(adminFactorSources)
		)
	}
}

// MARK: - ThresholdNotAnInteger
struct ThresholdNotAnInteger: Swift.Error {}

// MARK: - ThresholdGreaterThanNumberOfThresholdFactors
struct ThresholdGreaterThanNumberOfThresholdFactors: Swift.Error {}

// MARK: - FactorsForRole.View
extension FactorsForRole {
	public struct ViewState: Equatable {
		let role: SecurityStructureRole
		let thresholdString: String
		let thresholdFactors: [FactorSource]
		let adminFactors: [FactorSource]

		var roleWithFactors: RoleWithFactors? {
			try? createRoleWithFactors()
		}

		var thresholdHint: Hint? {
			do {
				guard
					try thresholdInt() <= thresholdFactors.count
				else {
					throw ThresholdGreaterThanNumberOfThresholdFactors()
				}
				return nil
			} catch {
				return .error("\(String(describing: error))")
			}
		}

		var thresholdAsInt: Int? {
			try? thresholdInt()
		}

		func thresholdInt() throws -> Int {
			guard
				let thresholdInt = Int(thresholdString)
			else {
				throw ThresholdNotAnInteger()
			}
			return thresholdInt
		}

		func createRoleWithFactors() throws -> RoleWithFactors {
			guard !thresholdFactors.isEmpty else {
				return try .init(role: role, factors: RoleOfTier<FactorSource>(
					role: role,
					thresholdFactors: [],
					threshold: 0,
					superAdminFactors: .init(validating: adminFactors)
				))
			}

			let thresholdInt_ = try thresholdInt()

			guard
				thresholdInt_ <= thresholdFactors.count
			else {
				throw ThresholdGreaterThanNumberOfThresholdFactors()
			}

			return try .init(role: role, factors: RoleOfTier<FactorSource>(
				role: role,
				thresholdFactors: .init(validating: thresholdFactors),
				threshold: .init(thresholdInt_),
				superAdminFactors: .init(validating: adminFactors)
			))
		}

		var validationErrorMsg: String? {
			do {
				_ = try createRoleWithFactors()
				return nil
			} catch {
				return "Error: \(String(describing: error))"
			}
		}

		init(
			role: SecurityStructureRole,
			thresholdString: String,
			thresholdFactors: [FactorSource],
			adminFactors: [FactorSource]
		) {
			self.role = role
			self.thresholdString = thresholdString
			self.thresholdFactors = thresholdFactors
			self.adminFactors = adminFactors
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FactorsForRole>

		public init(store: StoreOf<FactorsForRole>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(alignment: .leading, spacing: .large1) {
						// FIXME: strings
						FactorsListView(
							title: "Admin",
							subtitle: "Factors which can be used standalone",
							factors: viewStore.adminFactors,
							addFactorAction: { viewStore.send(.addAdminFactor) },
							removeFactorAction: {
								viewStore.send(.removeAdminFactor($0))
							}
						)

						// FIXME: strings
						FactorsListView(
							title: "Threshold",
							subtitle: viewStore.thresholdAsInt.map {
								"Requires >=\($0) (threshold) factors to be used together."
							} ?? "",
							factors: viewStore.thresholdFactors,
							addFactorAction: { viewStore.send(.addThresholdFactor) },
							removeFactorAction: {
								viewStore.send(.removeThresholdFactor($0))
							}
						)

						// FIXME: strings
						AppTextField(
							primaryHeading: "Threshold",
							placeholder: "Threshold",
							text: viewStore.binding(
								get: \.thresholdString,
								send: { .thresholdChanged($0) }
							),
							hint: viewStore.thresholdHint,
							showClearButton: false
						)
					}
					.multilineTextAlignment(.leading)
				}
				.footer {
					WithControlRequirements(
						viewStore.roleWithFactors,
						forAction: { viewStore.send(.confirmedRoleWithFactors($0)) }
					) { action in
						// FIXME: strings
						Button("Confirm", action: action)
							.buttonStyle(.primaryRectangular)
						if let validationErrorMsg = viewStore.validationErrorMsg {
							Text(validationErrorMsg)
								.font(.app.body3HighImportance)
								.foregroundColor(.app.red1)
						}
					}
				}
				.destinations(with: store)
				.confirmationDialog(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /FactorsForRole.Destinations.State.existingRoleMadeLessSafeConfirmationDialog,
					action: FactorsForRole.Destinations.Action.existingRoleMadeLessSafeConfirmationDialog
				)
				.navigationTitle(viewStore.role.titleAdvancedFlow)
				.padding()
				.frame(maxWidth: .infinity)
			}
		}
	}
}

extension View {
	@MainActor
	fileprivate func destinations(with store: StoreOf<FactorsForRole>) -> some SwiftUI.View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return addThresholdFactorSheet(with: destinationStore)
			.addAdminFactorSheet(with: destinationStore)
	}

	@MainActor
	private func addThresholdFactorSheet(with destinationStore: PresentationStoreOf<FactorsForRole.Destinations>) -> some SwiftUI.View {
		sheet(
			store: destinationStore,
			state: /FactorsForRole.Destinations.State.addThresholdFactor,
			action: FactorsForRole.Destinations.Action.addThresholdFactor,
			content: { store in NavigationView { SelectFactorKindThenFactor.View(store: store) } }
		)
	}

	@MainActor
	private func addAdminFactorSheet(with destinationStore: PresentationStoreOf<FactorsForRole.Destinations>) -> some SwiftUI.View {
		sheet(
			store: destinationStore,
			state: /FactorsForRole.Destinations.State.addAdminFactor,
			action: FactorsForRole.Destinations.Action.addAdminFactor,
			content: { store in NavigationView { SelectFactorKindThenFactor.View(store: store) } }
		)
	}
}

// MARK: - FactorsListView
public struct FactorsListView: SwiftUI.View {
	let title: String
	let subtitle: String
	let factors: [FactorSource]
	let addFactorAction: () -> Void
	let removeFactorAction: (FactorSourceID) -> Void

	public var body: some View {
		VStack(alignment: .leading) {
			Text(title)
				.font(.app.sheetTitle)

			Text(subtitle)
				.font(.app.body1Regular)

			ForEach(factors) { factor in
				Card {
					HStack(spacing: .small3) {
						Text(factor.kind.selectedFactorDisplay)
							.font(.app.secondaryHeader)

						Spacer(minLength: 0)

						VStack(alignment: .leading) {
							// FIXME: strings
							HPair(
								label: "Added",
								item: formatDate(factor.addedOn)
							)

							// FIXME: strings
							HPair(
								label: "Last used",
								item: formatDate(factor.lastUsedOn)
							)
						}

						Button(action: {
							removeFactorAction(factor.id)
						}, label: {
							Image(systemName: "minus.circle.fill")
								.resizable()
								.frame(width: .large3, height: .large3)
								.tint(.app.red1)
						})
					}
					.padding()
				}
			}

			// FIXME: strings
			Button("Add \(title) factor", action: addFactorAction)
				.buttonStyle(.primaryRectangular)
		}
		.multilineTextAlignment(.leading)
	}

	@MainActor
	func formatDate(_ date: Date) -> String {
		date.ISO8601Format(.iso8601Date(timeZone: .current))
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - FactorsForRole_Preview
// struct FactorsForRole_Preview: PreviewProvider {
//	static var previews: some View {
//		FactorsForRole.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: FactorsForRole()
//			)
//		)
//	}
// }
//
// extension FactorsForRole.State {
//	public static let previewValue = Self()
// }
// #endif
