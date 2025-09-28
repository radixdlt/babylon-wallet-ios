extension PrimaryRoleSetup.State {
	var validatedRoleStatus: SecurityShieldBuilderStatus {
		shieldBuilder.status()
	}

	var statusMessageInfo: ShieldStatusMessageInfo? {
		switch validatedRoleStatus {
		case .strong:
			return nil
		case .weak:
			return .init(
				type: .warning,
				text: L10n.ShieldSetupStatus.unsafeCombination,
				contexts: [.general]
			)
		case let .invalid(reason):
			var contexts: [ShieldStatusMessageInfo.Context] = []

			if reason.isPrimaryRoleFactorListEmpty {
				contexts.append(.primaryRole)
			}
			if reason.isAuthSigningFactorMissing {
				contexts.append(.authenticationRole)
			}
			if contexts.isEmpty, reason.isRecoveryRoleFactorListEmpty || reason.isConfirmationRoleFactorListEmpty {
				return .init(
					type: .warning,
					text: L10n.ShieldSetupStatus.notEnoughFactors,
					contexts: [.general]
				)
			}

			return .init(
				type: .error,
				text: L10n.ShieldSetupStatus.Roles.atLeastOneFactor,
				contexts: contexts
			)
		}
	}

	var canContinue: Bool {
		guard case .invalid = validatedRoleStatus, statusMessageInfo?.type == .error else { return true }
		return false
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
		shieldBuilder.getPrimaryThreshold()
	}

	var thresholdValues: [Threshold] {
		shieldBuilder.getPrimaryThresholdValues()
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
				.background(.primaryBackground)
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
								.foregroundStyle(.primaryText)

							overrideFactorsView
						}
						.padding(.bottom, .small2)
					} else {
						Button {
							store.send(.view(.showOverrideSectionButtonTapped))
						} label: {
							Label(L10n.ShieldWizardRegularAccess.Override.button, asset: AssetResource.addAccount)
								.font(.app.body1Header)
								.foregroundColor(.textButton)
								.padding([.vertical, .leading], .small2)
						}
						.flushedRight
					}
				}
				.padding(.horizontal, .medium2)
				.padding(.bottom, .small3)

				Separator()

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

				if let statusMessage = store.statusMessageInfo,
				   statusMessage.contexts.contains(where: [ShieldStatusMessageInfo.Context.general, .primaryRole].contains)
				{
					statusMessageView(statusMessage)
						.padding(.horizontal, .small1)
						.onTapGesture {
							if statusMessage.type == .warning {
								store.send(.view(.unsafeCombinationReadMoreTapped))
							}
						}
				}
			}
			.foregroundStyle(.primaryText)
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
				let thresholdTitle = store.threshold.titleShort
				let separator = L10n.ShieldWizardRegularAccess.ThresholdDescription.selection(thresholdTitle)
				let title = L10n.ShieldWizardRegularAccess.ThresholdDescription.title(separator)
				let parts = title.components(separatedBy: separator)

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
					.foregroundStyle(.textButton)

					Text(parts[1])
				}
			}
			.textStyle(.body2Regular)
			.foregroundStyle(.primaryText)
		}

		private var overrideFactorsView: some SwiftUI.View {
			VStack(spacing: .zero) {
				HStack {
					Text(L10n.ShieldWizardRegularAccess.Override.title)
						.textStyle(.body1Header)
						.foregroundStyle(.primaryTextInverse)

					Spacer()

					Button {
						store.send(.view(.hideOverrideSectionButtonTapped))
					} label: {
						Image(.close)
							.frame(.smallest)
					}
					.foregroundColor(.secondaryText)
				}
				.padding(.horizontal, .medium3)
				.padding(.vertical, .small1)
				.background(.primaryText)

				VStack(spacing: .small1) {
					Text(L10n.ShieldWizardRegularAccess.Override.description)
						.textStyle(.body2Regular)
						.foregroundStyle(.primaryText)
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
								.foregroundStyle(.primaryText)
						}
					}

					Button("+") {
						store.send(.view(.addFactorSourceButtonTapped(.primaryOverride)))
					}
					.buttonStyle(.secondaryRectangular(font: .app.sectionHeader, shouldExpand: true))
				}
				.padding([.horizontal, .bottom], .medium3)
				.padding(.top, .medium3)
				.background(.secondaryBackground)
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

				if let statusMessage = store.statusMessageInfo,
				   statusMessage.contexts.contains(.authenticationRole)
				{
					statusMessageView(statusMessage)
				}

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
					Button("+") {
						store.send(.view(.addFactorSourceButtonTapped(.authenticationSigning)))
					}
					.buttonStyle(.secondaryRectangular(font: .app.sectionHeader, shouldExpand: true))
					.embedInContainer
				}
			}
		}

		private func statusMessageView(_ statusMessage: ShieldStatusMessageInfo) -> some SwiftUI.View {
			StatusMessageView(
				text: statusMessage.text,
				type: statusMessage.type,
				useNarrowSpacing: true,
				useSmallerFontSize: true,
				emphasizedTextStyle: .body2Header
			)
			.padding(.vertical, .small2)
			.flushedLeft
		}
	}
}

extension View {
	var embedInContainer: some View {
		self
			.padding(.medium3)
			.background(.secondaryBackground)
			.roundedCorners(radius: .small1)
	}
}

extension Threshold {
	var titleShort: String {
		switch self {
		case .all:
			L10n.Common.all
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
					thresholdValues: store.thresholdValues
				) { action in
					store.send(.destination(.presented(.selectNumberOfFactorsView(action))))
				}
			}
		}
	}
}
