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
			(.error, L10n.ShieldSetupSelectFactors.StatusMessage.atLeastOneFactor)
		} else if selectedFactorSources?.count == 1 {
			(.warning, L10n.ShieldSetupSelectFactors.StatusMessage.recommendedFactors)
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
						.animation(.default, value: store.statusMessageInfo?.type)
				}
				.footer {
					WithControlRequirements(
						store.selectedFactorSources,
						forAction: { store.send(.view(.buildButtonTapped($0))) }
					) { action in
						Button(L10n.ShieldSetupSelectFactors.buildButtonTitle, action: action)
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
				topView

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

		private var topView: some SwiftUI.View {
			VStack(spacing: .small1) {
				Image(.selectFactorSources)

				Text(L10n.ShieldSetupSelectFactors.title)
					.textStyle(.sheetTitle)
					.padding(.horizontal, .medium3)

				Text(markdown: L10n.ShieldSetupSelectFactors.subtitle, emphasizedColor: .app.gray1, emphasizedFont: .app.body1Header)
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
		}
	}
}
