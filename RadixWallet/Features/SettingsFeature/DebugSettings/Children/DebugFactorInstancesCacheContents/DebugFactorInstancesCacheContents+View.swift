import Sargon
import SwiftUI

// MARK: - DebugFactorInstancesCacheContents.View
extension DebugFactorInstancesCacheContents {
	struct View: SwiftUI.View {
		let store: StoreOf<DebugFactorInstancesCacheContents>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .small2) {
					Button("Delete Cache File") {
						store.send(.view(.deleteButtonTapped))
					}
					.buttonStyle(.primaryRectangular(isDestructive: true))
					loadable(store.factorInstances) {
						ProgressView()
					} successContent: { instances in
						content(instances: instances)
					}
				}
				.padding()
				.navigationTitle("FactorInstances cache")
			}.task {
				store.send(.view(.task))
			}
		}

		@ViewBuilder
		private func content(instances: Instances) -> some SwiftUI.View {
			ScrollView {
				VStack(alignment: .leading) {
					ForEach(Array(instances.keys), id: \.self) { (key: FactorSourceIDFromHash) in
						Section {
							let listOfList: [[FactorInstanceForDebugPurposes]] = instances[key]!
							ForEach(listOfList, id: \.self) { (instancesForFactorForPath: [FactorInstanceForDebugPurposes]) in
								if let firstInstance = instancesForFactorForPath.first {
									Section {
										ForEach(instancesForFactorForPath, id: \.self) { (instance: FactorInstanceForDebugPurposes) in
											VStack(alignment: .leading) {
												Text("Index `\(instance.derivationEntityIndex)`")

												Text("PublicKey `\(String(reflecting: instance.publicKeyHex.prefix(8)))`")
											}
											.frame(maxWidth: .infinity)
											.padding(.horizontal, .medium3)
											.padding(.vertical, .small2)
											.border(Color.gray, width: 1)
										}
									} header: {
										VStack {
											Text("Agnostic `\(firstInstance.indexAgnosticDerivationPath)`").font(.title)
											Text("#\(instancesForFactorForPath.count) instances")
										}
										.padding()
									}
								}
							}
						} header: {
							Text("Source `\(key.idPrefix())`")
								.font(.largeTitle)
						}
					}
				}
			}
		}
	}
}

extension FactorSourceIDFromHash {
	fileprivate func idPrefix() -> String {
		String(toString().prefix(10))
	}
}
