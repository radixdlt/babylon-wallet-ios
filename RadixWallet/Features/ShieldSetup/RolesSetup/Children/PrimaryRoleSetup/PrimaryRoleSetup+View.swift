extension PrimaryRoleSetup.State {
	var validatedRoleStatus: SecurityShieldBuilderInvalidReason? {
		shieldBuilder.validate()
	}

	var statusMessageInfo: ShieldStatusMessageInfo? {
		switch validatedRoleStatus {
		case .none:
			nil
		case .PrimaryRoleMustHaveAtLeastOneFactor:
			.init(type: .error, text: L10n.ShieldSetupStatus.Roles.atLeastOneFactor)
		default:
			.init(type: .warning, text: L10n.ShieldSetupStatus.invalidCombination)
		}
	}

	// TODO: Move to Sargon
	var canContinue: Bool {
		validatedRoleStatus != .PrimaryRoleMustHaveAtLeastOneFactor && validatedRoleStatus != .MissingAuthSigningFactor
	}

	var thresholdFactors: [FactorSource] {
		factorSourcesFromProfile.filter { shieldBuilder.primaryRoleThresholdFactors.contains($0.factorSourceID) }
	}

	var overrideFactors: [FactorSource] {
		factorSourcesFromProfile.filter { shieldBuilder.primaryRoleOverrideFactors.contains($0.factorSourceID) }
	}

	var authenticationSigningFactor: FactorSource? {
		factorSourcesFromProfile.first { $0.factorSourceID == shieldBuilder.getAuthenticationSigningFactor() }
	}

	var threshold: Threshold {
		// TODO: Use Sargon - https://radixdlt.atlassian.net/browse/ABW-4047
		let threshold = Int(shieldBuilder.getPrimaryThreshold())
		if threshold == shieldBuilder.primaryRoleThresholdFactors.count {
			return .all
		} else {
			return .specific(threshold)
		}
	}
}

// MARK: - PrimaryRoleSetup.View
extension PrimaryRoleSetup {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<PrimaryRoleSetup>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.top, .small2)
						.padding(.bottom, .medium1)
						.animation(.default, value: store.thresholdFactors)
						.animation(.default, value: store.overrideFactors)
						.animation(.default, value: store.authenticationSigningFactor)
						.animation(.default, value: store.isOverrideSectionExpanded)
				}
				.radixToolbar(title: L10n.ShieldWizardRegularAccess.Step.title)
				.footer {
					Button(L10n.Common.continue) {
						store.send(.view(.continueButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.canContinue ? .enabled : .disabled)
				}
				.task {
					store.send(.view(.task))
				}
			}
			.destination(store: store)
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			VStack(spacing: .medium2) {
				VStack(spacing: .small1) {
					topView
					thresholdFactorsView

					if store.isOverrideSectionExpanded {
						VStack(spacing: .small2) {
							Text(L10n.ShieldWizardRegularAccess.Combination.label)
								.textStyle(.body1Link)
								.foregroundStyle(.app.gray1)

							overrideFactorsView
						}
						.padding(.bottom, .small2)
					} else {
						Button {
							store.send(.view(.showOverrideSectionButtonTapped))
						} label: {
							Label(L10n.ShieldWizardRegularAccess.Override.button, asset: AssetResource.addAccount)
								.font(.app.body1Header)
								.foregroundColor(.app.blue2)
								.padding([.vertical, .leading], .small2)
						}
						.flushedRight
					}
				}
				.padding(.horizontal, .medium2)
				.padding(.bottom, .small3)

				Separator(color: .app.gray3)

				authenticationSigningFactorView
					.padding(.horizontal, .medium2)
			}
			.frame(maxWidth: .infinity)
		}

		private var topView: some SwiftUI.View {
			VStack(spacing: .medium3) {
				Image(.regularAccessSetup)
					.padding(.bottom, .small3)

				Text(L10n.ShieldWizardRegularAccess.title)
					.textStyle(.sheetTitle)
					.multilineTextAlignment(.center)

				Text(L10n.ShieldWizardRegularAccess.subtitle)
					.textStyle(.body1Regular)
					.multilineTextAlignment(.leading)
					.flushedLeft

				if let statusMessage = store.statusMessageInfo {
					StatusMessageView(
						text: statusMessage.text,
						type: statusMessage.type,
						useNarrowSpacing: true,
						useSmallerFontSize: true,
						emphasizedTextStyle: .body2Header
					)
					.padding(.horizontal, .small1)
					.padding(.vertical, .medium3)
					.flushedLeft
					.onTapGesture {
						if statusMessage.type == .warning {
							store.send(.view(.invalidCombinationReadMoreTapped))
						}
					}
				}
			}
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .medium2)
		}

		private var thresholdFactorsView: some SwiftUI.View {
			VStack(spacing: .small1) {
				thresholdSelectorView
					.flushedLeft

				ForEach(store.thresholdFactors, id: \.self) { factorSource in
					FactorSourceCard(
						kind: .instance(
							factorSource: factorSource,
							kind: .short(showDetails: true)
						),
						mode: .removal
					) { action in
						switch action {
						case .removeTapped:
							store.send(.view(.removeThresholdFactorTapped(factorSource.factorSourceID)))
						case .messageTapped:
							break
						}
					}
				}

				Button("+") {
					store.send(.view(.addFactorSourceButtonTapped(.primaryThreshold)))
				}
				.buttonStyle(.secondaryRectangular(font: .app.sectionHeader, shouldExpand: true))
			}
			.frame(maxWidth: .infinity)
			.embedInContainer
		}

		private var thresholdSelectorView: some SwiftUI.View {
			HStack(spacing: .zero) {
				// TODO: Add a new key for "**%@**"
				let thresholdTitle = store.threshold.titleShort
				let title = L10n.ShieldWizardRegularAccess.ThresholdDescription.title(thresholdTitle)
				let parts = title.components(separatedBy: "**\(thresholdTitle)**")

				if parts.count == 2 {
					Text(parts[0])

					Button {
						store.send(.view(.thresholdSelectorButtonTapped))
					} label: {
						HStack(spacing: .small3) {
							Text(thresholdTitle)
								.textStyle(.body2Link)
							Image(.chevronDown)
						}
					}
					.foregroundStyle(.app.blue2)

					Text(parts[1])
				}
			}
			.textStyle(.body2Regular)
			.foregroundStyle(.app.gray1)
		}

		private var overrideFactorsView: some SwiftUI.View {
			VStack(spacing: .zero) {
				HStack {
					Text(L10n.ShieldWizardRegularAccess.Override.title)
						.textStyle(.body1Header)
						.foregroundStyle(.app.white)

					Spacer()

					Button {
						store.send(.view(.hideOverrideSectionButtonTapped))
					} label: {
						Image(.close)
							.frame(.smallest)
					}
					.foregroundColor(.app.gray2)
				}
				.padding(.horizontal, .medium3)
				.padding(.vertical, .small1)
				.background(.app.gray1)

				VStack(spacing: .small1) {
					Text(L10n.ShieldWizardRegularAccess.Override.description)
						.textStyle(.body2Regular)
						.foregroundStyle(.app.gray1)
						.flushedLeft

					ForEach(store.overrideFactors, id: \.self) { factorSource in
						FactorSourceCard(
							kind: .instance(
								factorSource: factorSource,
								kind: .short(showDetails: true)
							),
							mode: .removal
						) { action in
							switch action {
							case .removeTapped:
								store.send(.view(.removeOverrideFactorTapped(factorSource.factorSourceID)))
							case .messageTapped:
								break
							}
						}

						let isLastFactor = factorSource == store.overrideFactors.last
						if !isLastFactor {
							Text(L10n.ShieldWizardRegularAccess.OverrideCombination.label)
								.textStyle(.body1Link)
								.foregroundStyle(.app.gray1)
						}
					}

					Button("+") {
						store.send(.view(.addFactorSourceButtonTapped(.primaryOverride)))
					}
					.buttonStyle(.secondaryRectangular(font: .app.sectionHeader, shouldExpand: true))
				}
				.padding([.horizontal, .bottom], .medium3)
				.padding(.top, .medium3)
				.background(Color.containerContentBackground)
			}
			.frame(maxWidth: .infinity)
			.roundedCorners(radius: .small1)
		}

		private var authenticationSigningFactorView: some SwiftUI.View {
			VStack(spacing: .small1) {
				Text(L10n.ShieldWizardRegularAccess.Authentication.title)
					.textStyle(.body1Regular)
					.multilineTextAlignment(.leading)
					.flushedLeft

				if let factorSource = store.authenticationSigningFactor {
					FactorSourceCard(
						kind: .instance(
							factorSource: factorSource,
							kind: .short(showDetails: true)
						),
						mode: .removal
					) { action in
						switch action {
						case .removeTapped:
							store.send(.view(.removeAuthenticationSigningFactorTapped))
						case .messageTapped:
							break
						}
					}
					.frame(maxWidth: .infinity)
					.embedInContainer
				} else {
					StatusMessageView(
						text: L10n.ShieldSetupStatus.Roles.atLeastOneFactor,
						type: .error,
						useNarrowSpacing: true,
						useSmallerFontSize: true
					)
					.padding(.vertical, .small2)
					.flushedLeft

					Button("+") {
						store.send(.view(.addFactorSourceButtonTapped(.authenticationSigning)))
					}
					.buttonStyle(.secondaryRectangular(font: .app.sectionHeader, shouldExpand: true))
					.embedInContainer
				}
			}
		}
	}
}

extension View {
	var embedInContainer: some View {
		self
			.padding(.medium3)
			.background(Color.containerContentBackground)
			.roundedCorners(radius: .small1)
	}
}

private extension Threshold {
	var titleShort: String {
		switch self {
		case .all:
			L10n.ShieldWizardRegularAccess.ThresholdDescription.all
		case let .specific(value):
			"\(value)"
		}
	}
}

private extension StoreOf<PrimaryRoleSetup> {
	var destination: PresentationStoreOf<PrimaryRoleSetup.Destination> {
		func scopeState(state: State) -> PresentationState<PrimaryRoleSetup.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<PrimaryRoleSetup>) -> some View {
		let destinationStore = store.destination
		return selectNumberOfFactors(with: destinationStore, store: store)
	}

	private func selectNumberOfFactors(with destinationStore: PresentationStoreOf<PrimaryRoleSetup.Destination>, store: StoreOf<PrimaryRoleSetup>) -> some View {
		WithPerceptionTracking {
			sheet(store: destinationStore.scope(state: \.selectNumberOfFactorsView, action: \.selectNumberOfFactorsView)) { _ in
				SelectNumberOfFactorsView(
					selectedNumberOfFactors: store.threshold,
					maxAvailableFactors: store.thresholdFactors.count
				) { action in
					store.send(.destination(.presented(.selectNumberOfFactorsView(action))))
				}
			}
		}
	}
}
