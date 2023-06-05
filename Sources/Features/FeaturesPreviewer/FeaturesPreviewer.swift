@_exported import FeaturePrelude

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

// MARK: - FeaturesPreviewer
public struct FeaturesPreviewer<Feature>
	where
	Feature: PreviewedFeature
{
	public static func scene(
		resultFrom: @escaping (Feature.DelegateAction) -> Feature.ResultFromFeature?
	) -> some Scene {
		WindowGroup {
			PreviewOfSomeFeatureReducer<Feature>.View(
				store: Store(
					initialState: PreviewOfSomeFeatureReducer<Feature>.State(),
					reducer: PreviewOfSomeFeatureReducer<Feature>(resultFrom: resultFrom)
						._printChanges()
				)
			)
		}
	}
}

// MARK: - PreviewedFeature
public protocol PreviewedFeature: FeatureReducer & EmptyInitializable where View: FeatureViewProtocol, View.Feature == Self, State: EmptyInitializable {
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
			NavigationView {
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

	public let resultFromAction: (Feature.DelegateAction) -> Feature.ResultFromFeature?
	public init(
		resultFrom resultFromAction: @escaping (Feature.DelegateAction) -> Feature.ResultFromFeature?
	) {
		self.resultFromAction = resultFromAction
	}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: /F.State.previewOf, action: /F.Action.child .. ChildAction.previewOf) {
			Feature()
		}
		Scope(state: /F.State.previewResult, action: /F.Action.child .. ChildAction.previewResult) {
			PreviewResult<Feature.ResultFromFeature>()
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .previewOf(.delegate(previewDelegate)):
			if let result = resultFromAction(previewDelegate) {
				state = .previewResult(.init(previewResult: result))
			}
			return .none

		case .previewResult(.delegate(.restart)):
			state = .previewOf(.init())
			return .none

		default: return .none
		}
	}
}

// MARK: - PreviewResult
public struct PreviewResult<ResultFromFeature>: FeatureReducer where ResultFromFeature: Hashable & Sendable {
	public struct View: SwiftUI.View {
		private let store: StoreOf<PreviewResult<ResultFromFeature>>
		public init(store: StoreOf<PreviewResult<ResultFromFeature>>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				GeometryReader { geoProxy in
					ScrollView {
						VStack {
							if let json = viewStore.json {
								VStack {
									Text("JSON").font(.app.sectionHeader)

									Toggle(
										isOn: viewStore.binding(
											get: \.isShowingJSON,
											send: { .view(.showJSONToggled($0)) }
										),
										label: { Text("Show JSON") }
									)

									if viewStore.isShowingJSON {
										JSONView(jsonString: json)
											.frame(
												maxWidth: .infinity,
												idealHeight: geoProxy.frame(in: .global).height
											)
									}
								}
							}
						}

						VStack {
							Text("Debug").font(.app.sectionHeader)

							Toggle(
								isOn: viewStore.binding(
									get: \.isShowingDebugDescription,
									send: { .view(.showDebugDescriptionToggled($0)) }
								),
								label: { Text("Show Debug") }
							)

							if viewStore.isShowingDebugDescription {
								Text("\(String(describing: viewStore.previewResult))")
							}
						}
					}
					.padding()
				}
				.footer {
					Button("Restart Preview app") {
						viewStore.send(.view(.restart))
					}
					.buttonStyle(.primaryRectangular)
				}
				.navigationTitle("Feature Result")
			}
		}
	}

	public enum ViewAction: Sendable, Hashable {
		case restart
		case showJSONToggled(Bool)
		case showDebugDescriptionToggled(Bool)
	}

	public enum DelegateAction: Sendable, Hashable {
		case restart
	}

	public struct State: Sendable, Hashable {
		public let previewResult: ResultFromFeature
		public var isShowingJSON: Bool = true
		public var isShowingDebugDescription: Bool = true

		public var json: String? {
			@Dependency(\.jsonEncoder) var jsonEncoder
			let encoder = jsonEncoder()
			encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
			guard
				let encodable = previewResult as? Encodable,
				let json = try? encoder.encode(encodable),
				let jsonString = String(data: json, encoding: .utf8)
			else { return nil }
			return jsonString
		}
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .showJSONToggled(showJSON):
			state.isShowingJSON = showJSON
			return .none

		case let .showDebugDescriptionToggled(showDebugDescription):
			state.isShowingDebugDescription = showDebugDescription
			return .none

		case .restart:
			return .send(.delegate(.restart))
		}
	}
}
