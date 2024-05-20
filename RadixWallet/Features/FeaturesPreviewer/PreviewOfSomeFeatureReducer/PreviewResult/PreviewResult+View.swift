import ComposableArchitecture
import SwiftUI

extension PreviewResult {
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
							if let error = viewStore.failure {
								Text("Failure: \(error)")
							}

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

							if let debugDescription = viewStore.debugDescription {
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
				.radixToolbar(title: "Feature Result")
			}
		}
	}
}
