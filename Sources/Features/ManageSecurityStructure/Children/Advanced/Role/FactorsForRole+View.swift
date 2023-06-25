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
				VStack {
					// FIXME: strings
					AppTextField(
						primaryHeading: "Threshold",
						secondaryHeading: "Greater than zero",
						placeholder: "Threshold",
						text: viewStore.binding(
							get: \.threshold,
							send: { .thresholdChanged($0) }
						),
						hint: nil,
						showClearButton: false
					)

					FactorsListView(
						title: "Threshold",
						subtitle: "Requires >=\(viewStore.threshold) (threshold) factors to be used together.",
						factors: viewStore.adminFactors,
						addFactorAction: { viewStore.send(.addThresholdFactor) },
						removeFactorAction: {
							viewStore.send(.removeThresholdFactor($0))
						}
					)

					FactorsListView(
						title: "Admin",
						subtitle: "Factors which can be used standalone",
						factors: viewStore.adminFactors,
						addFactorAction: { viewStore.send(.addAdminFactor) },
						removeFactorAction: {
							viewStore.send(.removeAdminFactor($0))
						}
					)
				}
				.navigationTitle(viewStore.role.titleAdvancedFlow)
				.padding()
				.frame(maxWidth: .infinity)
			}
		}
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
				.font(.app.sectionHeader)

			Text(subtitle)
				.font(.app.body2Header)

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
