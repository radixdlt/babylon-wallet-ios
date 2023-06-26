import FeaturePrelude

extension FactorsForRole.State {
	var viewState: FactorsForRole.ViewState {
		.init(
			role: role,
			threshold: threshold?.description ?? "",
			thresholdFactors: .init(thresholdFactorSources),
			adminFactors: .init(adminFactorSources)
		)
	}
}

// MARK: - FactorsForRole.View
extension FactorsForRole {
	public struct ViewState: Equatable {
		let role: SecurityStructureRole
		let threshold: String
		let thresholdFactors: [FactorSource]
		let adminFactors: [FactorSource]

		var roleWithFactors: RoleWithFactors? {
			if !thresholdFactors.isEmpty {
				guard
					let thresholdInt = Int(threshold),
					thresholdInt <= thresholdFactors.count
				else {
					return nil
				}
				guard let factors = try? RoleOfTier<FactorSource>(
					role: role,
					thresholdFactors: .init(validating: thresholdFactors),
					threshold: .init(thresholdInt),
					superAdminFactors: .init(validating: adminFactors)
				) else {
					return nil
				}
				return .init(role: role, factors: factors)
			} else {
				guard let factors = try? RoleOfTier<FactorSource>(
					role: role,
					thresholdFactors: [],
					threshold: 0,
					superAdminFactors: .init(validating: adminFactors)
				) else {
					return nil
				}
				return .init(role: role, factors: factors)
			}
		}

		init(
			role: SecurityStructureRole,
			threshold: String,
			thresholdFactors: [FactorSource],
			adminFactors: [FactorSource]
		) {
			self.role = role
			self.threshold = threshold
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
					VStack {
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
							subtitle: "Requires >=\(viewStore.threshold) (threshold) factors to be used together.",
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
								get: \.threshold,
								send: { .thresholdChanged($0) }
							),
							hint: nil,
							showClearButton: false
						)
					}
				}
				.footer {
					WithControlRequirements(
						viewStore.roleWithFactors,
						forAction: { viewStore.send(.confirmedRoleWithFactors($0)) }
					) { action in
						// FIXME: strings
						Button("Confirm", action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.destinations(with: store)
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
			content: { SelectFactorKindThenFactor.View(store: $0) }
		)
	}

	@MainActor
	private func addAdminFactorSheet(with destinationStore: PresentationStoreOf<FactorsForRole.Destinations>) -> some SwiftUI.View {
		sheet(
			store: destinationStore,
			state: /FactorsForRole.Destinations.State.addAdminFactor,
			action: FactorsForRole.Destinations.Action.addAdminFactor,
			content: { SelectFactorKindThenFactor.View(store: $0) }
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
		VStack {
			Text(title)
				.font(.app.sheetTitle)

			Text(subtitle)
				.font(.app.body1Regular)

			ForEach(factors) { factor in
				VStack {
					HPair(label: "kind", item: factor.kind.rawValue)
					HPair(label: "last used", item: factor.lastUsedOn.ISO8601Format())
					Button("Remove factor", action: { removeFactorAction(factor.id) })
						.buttonStyle(.secondaryRectangular(isDestructive: true))
				}
			}

			Button("Add \(title) factor", action: addFactorAction)
				.buttonStyle(.borderedProminent)
		}
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
