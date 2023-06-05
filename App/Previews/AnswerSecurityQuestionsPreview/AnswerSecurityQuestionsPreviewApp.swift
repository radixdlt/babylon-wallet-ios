import AnswerSecurityQuestionsFeature
import FeaturePrelude

// MARK: - AnswerSecurityQuestions.State + EmptyInitializable
extension AnswerSecurityQuestions.State: EmptyInitializable {}

// MARK: - AnswerSecurityQuestions.View + FeatureViewProtocol
extension AnswerSecurityQuestions.View: FeatureViewProtocol {
	public typealias Feature = AnswerSecurityQuestions
}

// MARK: - AnswerSecurityQuestions + PreviewedFeature
extension AnswerSecurityQuestions: PreviewedFeature {
	public typealias ResultFromFeature = SecurityQuestionsFactorSource
}

// MARK: - AnswerSecurityQuestionsApp_
@main
struct AnswerSecurityQuestionsApp_: SwiftUI.App {
	var body: some Scene {
		PreviewAppOf<AnswerSecurityQuestions>.scene()
	}
}

// MARK: - EmptyInitializable
public protocol EmptyInitializable {
	init()
}

// MARK: - FeatureViewProtocol
public protocol FeatureViewProtocol: SwiftUI.View where Feature.View == Self {
	associatedtype Feature: FeatureReducer

	@MainActor
	init(store: StoreOf<Feature>)
}

// MARK: - PreviewAppOf
public struct PreviewAppOf<Feature>
	where
	Feature: PreviewedFeature
{
	public static func scene() -> some Scene {
		WindowGroup {
			PreviewOfSomeFeatureReducer<Feature>.View(
				store: Store(
					initialState: PreviewOfSomeFeatureReducer<Feature>.State(),
					reducer: PreviewOfSomeFeatureReducer<Feature>()
						._printChanges()
				)
			)
		}
	}
}

// MARK: - PreviewedFeature
public protocol PreviewedFeature: FeatureReducer where View: FeatureViewProtocol, View.Feature == Self, State: EmptyInitializable {
	associatedtype ResultFromFeature: Hashable & Sendable
}

// MARK: - PreviewOfSomeFeatureReducer
public struct PreviewOfSomeFeatureReducer<Feature>: FeatureReducer where Feature: PreviewedFeature {
	public typealias F = Self
	public struct View: SwiftUI.View {
		private let store: StoreOf<F>
		public init(store: StoreOf<F>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /F.State.previewOf,
					action: { F.Action.child(.previewOf($0)) },
					then: { Feature.View(store: $0) }
				)

				CaseLet(
					state: /F.State.previewResult,
					action: { F.Action.child(.previewResult($0)) },
					then: { PreviewResult<Feature.ResultFromFeature>.View(store: $0) }
				)
			}
		}
	}

	public enum State: Sendable, Hashable, EmptyInitializable {
		public init() {
			self = .previewOf(.init())
		}

		case previewOf(Feature.State)
		case previewResult(PreviewResult<Feature.ResultFromFeature>.State)
	}

	public enum ChildAction: Sendable, Equatable {
		case previewOf(Feature.Action)
		case previewResult(PreviewResult<Feature.ResultFromFeature>.Action)
	}

	public init() {}
}

// MARK: - PreviewResult
public struct PreviewResult<ResultFromFeature>: FeatureReducer where ResultFromFeature: Hashable & Sendable {
	public struct View: SwiftUI.View {
		private let store: StoreOf<PreviewResult<ResultFromFeature>>
		public init(store: StoreOf<PreviewResult<ResultFromFeature>>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			Text("impl me: result")
		}
	}

	public struct State: Sendable, Hashable {
		public let previewResult: ResultFromFeature
	}

	public init() {}
}
