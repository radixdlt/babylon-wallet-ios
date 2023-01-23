import FeaturePrelude

// MARK: - GatherFactors.State
public extension GatherFactors {
	struct State: Sendable, Equatable {
		public var purpose: GatherFactorPurpose
		public var gatherFactors: IdentifiedArrayOf<GatherFactor.State>
		public var index: IdentifiedArrayOf<GatherFactor.State>.Index
		public var currentFactor: GatherFactor.State {
			get { gatherFactors[index] }
			set {
				self.gatherFactors[id: newValue.id] = newValue
			}
		}

		public var results: OrderedDictionary<GatherFactor.State.ID, GatherFactorResult>

		public init(
			purpose: GatherFactorPurpose,
			gatherFactors: IdentifiedArrayOf<GatherFactor.State>,
			index: IdentifiedArrayOf<GatherFactor.State>.Index = 0,
			results: OrderedDictionary<GatherFactor.State.ID, GatherFactorResult> = [:]
		) {
			precondition(!gatherFactors.isEmpty, "gatherFactors cannot be empty")
			self.purpose = purpose
			self.gatherFactors = gatherFactors
			self.index = index
			self.results = results
		}
	}
}

#if DEBUG
public extension GatherFactors.State {
	static let previewValue: Self = .init(
		purpose: .previewValue,
		gatherFactors: [.previewValue]
	)
}
#endif
