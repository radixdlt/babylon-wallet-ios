import SwiftUI
import Sargon

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
            }.task {
                store.send(.view(.task))
            }
        }
		
		@ViewBuilder
		private func content(instances: Instances) -> some SwiftUI.View {
			ScrollView {
				VStack(alignment: .leading) {
					ForEach(Array(instances.keys), id: \.self) { (key: FactorSourceIDFromHash) in
						Section("Source `\(key.idPrefix())`") {
							let listOfList: [[HierarchicalDeterministicFactorInstance]] = instances[key]!
							ForEach(listOfList, id: \.self) { (instancesForFactorForPath: [HierarchicalDeterministicFactorInstance]) in
								if let firstInstance = instancesForFactorForPath.first {
									Section(firstInstance.indexAgnosticPath()) {
										ForEach(instancesForFactorForPath, id: \.self) { (instance: HierarchicalDeterministicFactorInstance) in
											VStack(alignment: .leading) {
												Text("Index `\(instance.derivationEntityIndex())`")
												
												Text("PublicKey `\(instance.publicKeySuffix())`")
											}
											.border(Color.gray, width: 2)
											.padding()
										}
									}
									.padding()
								}
								
							}
						}
						.padding()
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
extension HierarchicalDeterministicFactorInstance {
	fileprivate func indexAgnosticPath() -> String {
		publicKey.derivationPath.indexAgnosticPath()
	}
	fileprivate func derivationEntityIndex() -> String {
		let index = publicKey.derivationPath.lastPathComponent.indexInLocalKeySpace()
		return String(reflecting: index)
	}
	fileprivate func publicKeySuffix() -> String {
		String(publicKey().suffix(6))
	}
	fileprivate func publicKey() -> String {
		publicKey.publicKey.hex
	}
}
extension DerivationPath {
	fileprivate func indexAgnosticPath() -> String {
		let components = self.path.components
		let network = components[2]
		let entityKind = components[3]
		let keyKind = components[4]
		let entityIndex = components[5]
		let keySpace = entityIndex.keySpace
		let keySpaceStr = switch keySpace {
		case .securified: "S"
		case let .unsecurified(isHardened): isHardened ? "H" : ""
		}
		return "\(network)/\(entityKind)/\(keyKind)/\(keySpaceStr)?"
		
	}
}
