import FeaturePrelude

// MARK: - GatherFactors.State
public extension GatherFactors {
	struct State: Sendable, Equatable {
		public var purpose: Purpose
		public var gatherFactors: IdentifiedArrayOf<GatherFactor<Purpose>.State>
		public var index: IdentifiedArrayOf<GatherFactor<Purpose>.State>.Index
		public var currentFactor: GatherFactor<Purpose>.State {
			get { gatherFactors[index] }
			set {
				self.gatherFactors[id: newValue.id] = newValue
			}
		}

		public var results: OrderedDictionary<GatherFactor<Purpose>.State.ID, Purpose.Produce>

		public init(
			purpose: Purpose,
			gatherFactors: IdentifiedArrayOf<GatherFactor<Purpose>.State>,
			index: IdentifiedArrayOf<GatherFactor<Purpose>.State>.Index = 0,
			results: OrderedDictionary<GatherFactor<Purpose>.State.ID, Purpose.Produce> = [:]
		) {
			precondition(!gatherFactors.isEmpty, "gatherFactors cannot be empty")
			self.purpose = purpose
			self.gatherFactors = gatherFactors
			self.index = index
			self.results = results
		}
	}
}

// #if DEBUG
// public extension GatherFactors.State {
//	static let previewValue: Self = .init(
//		purpose: .previewValue,
//		gatherFactors: [.previewValue]
//	)
// }
// #endif
