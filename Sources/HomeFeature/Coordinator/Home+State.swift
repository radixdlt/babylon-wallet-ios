import Foundation

// MARK: - Home
/// Namespace for HomeFeature
public enum Home {}

public extension Home {
	// MARK: State
	struct State: Equatable {
		public var header: Home.Header.State
		public var aggregatedValue: Home.AggregatedValue.State
		public var visitHub: Home.VisitHub.State

		public init(
			header: Home.Header.State = .init(),
			aggregatedValue: Home.AggregatedValue.State = .init(),
			visitHub: Home.VisitHub.State = .init()
		) {
			self.header = header
			self.aggregatedValue = aggregatedValue
			self.visitHub = visitHub
		}
	}
}
