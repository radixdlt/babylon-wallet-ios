import ComposableArchitecture
import SwiftUI

// TODO: move to Sargon
extension FactorSourceKind {
	var displayOrder: Int {
		switch self {
		case .device: 0
		case .arculusCard: 1
		case .ledgerHqHardwareWallet: 2
		case .password: 3
		case .offDeviceMnemonic: 4
		case .trustedContact: 5
		case .securityQuestions: 6
		}
	}
}

extension SelectFactorSources.State {
	var sortedFactorSources: [FactorSource] {
		factorSources.sorted(by: {
			$0.factorSourceKind.displayOrder < $1.factorSourceKind.displayOrder
		})
	}

	var statusMessageInfo: (type: StatusMessageView.ViewType, text: String)? {
		if (selectedFactorSources ?? []).isEmpty {
			(.error, "You need to select at least 1 factor for signing transactions")
		} else if selectedFactorSources?.count == 1 {
			(.warning, "Choosing 2 factors will make your Shield more secure and reliable")
		} else {
			nil
		}
	}
}

// MARK: - SelectFactorSources.View
extension SelectFactorSources {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<SelectFactorSources>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.horizontal, .medium3)
				}
				.footer {
					WithControlRequirements(
						store.selectedFactorSources,
						forAction: { store.send(.view(.buildButtonTapped($0))) }
					) { action in
						Button("Build Shield", action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.task {
					store.send(.view(.task))
				}
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .small1) {
				VStack(spacing: .small1) {
					Image(.selectFactorSources)

					Text("Select Factors for Transactions")
						.textStyle(.sheetTitle)
						.padding(.horizontal, .medium3)

					Text(markdown: "Choose the factors you’ll use to sign transactions. You’ll use **all** of these factors every time you send assets or log in to dApps.", emphasizedColor: .app.gray1, emphasizedFont: .app.body1Header)
						.textStyle(.body1Regular)
						.padding(.horizontal, .medium2)
						.padding(.top, .medium3)

					if let statusMessage = store.statusMessageInfo {
						StatusMessageView(
							text: statusMessage.text,
							type: statusMessage.type,
							useNarrowSpacing: true,
							useSmallerFontSize: true
						)
						.padding(.horizontal, .small1)
						.padding(.top, .small1)
						.flushedLeft
					}
				}
				.foregroundStyle(.app.gray1)
				.multilineTextAlignment(.center)
				.padding(.bottom, .medium2)

				Selection(
					$store.selectedFactorSources.sending(\.view.selectedFactorSourcesChanged),
					from: store.sortedFactorSources,
					requiring: .atLeast(1)
				) { item in
					VStack {
						let isFirstOfKind = store.sortedFactorSources.first(where: { $0.factorSourceKind == item.value.factorSourceKind }) == item.value
						if isFirstOfKind, item.value.factorSourceKind.isSupported {
							VStack(alignment: .leading, spacing: .zero) {
								Text(item.value.factorSourceKind.title)
									.textStyle(.body1HighImportance)
								Text(item.value.factorSourceKind.details)
									.textStyle(.body1Regular)
							}
							.foregroundStyle(.app.gray2)
							.padding(.top, .medium3)
							.flushedLeft
						}

						FactorSourceCard(
							kind: .instance(factorSource: item.value, kind: .short(showDetails: false)),
							mode: .selection(
								type: .checkmark,
								isSelected: item.isSelected
							)
						)?
							.embedInButton(when: item.action)
							.buttonStyle(.inert)
					}
				}

				Spacer()
			}
		}
	}
}
