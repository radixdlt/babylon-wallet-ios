extension RecoveryRoleSetup.State {
	var validatedRoleStatus: SecurityShieldBuilderInvalidReason? {
		shieldBuilder.validate()
	}

	// TODO: Move to Sargon & adapt to weak shields
	var statusMessageInfo: ShieldStatusMessageInfo? {
		switch validatedRoleStatus {
		case .none:
			nil
		case .RecoveryRoleMustHaveAtLeastOneFactor, .ConfirmationRoleMustHaveAtLeastOneFactor:
			.init(type: .error, text: L10n.ShieldSetupStatus.Transactions.atLeastOneFactor)
		default:
			.init(type: .warning, text: L10n.ShieldSetupStatus.invalidCombination)
		}
	}

	// TODO: Move to Sargon & adapt to weak shields
	var canContinue: Bool {
		validatedRoleStatus == nil
	}

	var recoveryFactors: [FactorSource] {
		factorSourcesFromProfile.filter { shieldBuilder.recoveryRoleFactors.contains($0.factorSourceID) }
	}

	var confirmationFactors: [FactorSource] {
		factorSourcesFromProfile.filter { shieldBuilder.confirmationRoleFactors.contains($0.factorSourceID) }
	}

	var periodUntilAutoConfirm: TimePeriod {
		shieldBuilder.timePeriodUntilAutoConfirm
	}
}

// MARK: - RecoveryRoleSetup.View
extension RecoveryRoleSetup {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<RecoveryRoleSetup>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView
						.padding(.top, .small2)
						.padding(.bottom, .medium1)
						.animation(.default, value: store.recoveryFactors)
						.animation(.default, value: store.confirmationFactors)
				}
				.radixToolbar(title: L10n.ShieldWizardRecovery.Step.title)
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
				VStack(spacing: .medium1) {
					topView
					recoverySection
				}
				.padding(.horizontal, .medium2)
				.padding(.bottom, .small3)

				Separator(color: .app.gray3)

				confirmationSection
					.padding(.horizontal, .medium2)
			}
			.frame(maxWidth: .infinity)
		}

		private var topView: some SwiftUI.View {
			VStack(spacing: .medium3) {
				Image(.recoverySetup)
					.padding(.bottom, .small3)

				Text(L10n.ShieldWizardRecovery.title)
					.textStyle(.sheetTitle)
					.multilineTextAlignment(.center)
			}
			.foregroundStyle(.app.gray1)
			.padding(.bottom, .medium2)
		}

		private var recoverySection: some SwiftUI.View {
			VStack(spacing: .small1) {
				sectionHeader(
					title: L10n.ShieldWizardRecovery.Start.title,
					subtitle: L10n.ShieldWizardRecovery.Start.subtitle
				)
				.padding(.bottom, .small2)

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

				factorSourcesContainer(factorSources: store.recoveryFactors, section: .recovery)
			}
		}

		private var confirmationSection: some SwiftUI.View {
			VStack(spacing: .small1) {
				sectionHeader(
					title: L10n.ShieldWizardRecovery.Confirm.title,
					subtitle: L10n.ShieldWizardRecovery.Confirm.subtitle
				)
				.padding(.bottom, .small2)

				factorSourcesContainer(factorSources: store.confirmationFactors, section: .confirmation)

				Text(L10n.ShieldWizardRecovery.Combination.label)
					.textStyle(.body1Link)
					.foregroundStyle(.app.gray1)

				emergencyFallbackView
			}
		}

		private func sectionHeader(title: String, subtitle: String) -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .small2) {
				Text(title)
					.textStyle(.sectionHeader)

				Text(subtitle)
					.textStyle(.body2Regular)
			}
			.multilineTextAlignment(.leading)
			.foregroundStyle(.app.gray1)
		}

		private func factorSourcesContainer(
			factorSources: [FactorSource],
			section: SectionType
		) -> some SwiftUI.View {
			VStack(spacing: .small1) {
				ForEach(factorSources, id: \.self) { factorSource in
					FactorSourceCard(
						kind: .instance(
							factorSource: factorSource,
							kind: .short(showDetails: true)
						),
						mode: .removal
					) { action in
						switch action {
						case .removeTapped:
							switch section {
							case .recovery:
								store.send(.view(.removeRecoveryFactorTapped(factorSource.factorSourceID)))
							case .confirmation:
								store.send(.view(.removeConfirmationFactorTapped(factorSource.factorSourceID)))
							}
						case .messageTapped:
							break
						}
					}

					let isLastFactor = factorSource == factorSources.last
					if !isLastFactor {
						Text(L10n.ShieldWizardRecovery.Combination.label)
							.textStyle(.body1Link)
							.foregroundStyle(.app.gray1)
					}
				}

				Button("+") {
					store.send(.view(.addFactorSourceButtonTapped(section.chooseFactorSourceContext)))
				}
				.buttonStyle(.secondaryRectangular(font: .app.sectionHeader, shouldExpand: true))
			}
			.frame(maxWidth: .infinity)
			.embedInContainer
		}

		private var emergencyFallbackView: some SwiftUI.View {
			VStack(spacing: .zero) {
				HStack {
					Text(L10n.ShieldWizardRecovery.Fallback.title)
						.textStyle(.body1Header)

					Spacer()

					Button {
						store.send(.view(.fallbackInfoButtonTapped))
					} label: {
						Image(.info)
							.resizable()
							.frame(.smallest)
					}
				}
				.padding(.horizontal, .medium3)
				.padding(.vertical, .small1)
				.foregroundStyle(.app.white)
				.background(.app.red1)

				VStack(spacing: .medium2) {
					Text(
						markdown: L10n.ShieldWizardRecovery.Fallback.subtitle,
						emphasizedColor: .app.gray1,
						emphasizedFont: .app.body2Header
					)
					.textStyle(.body2Regular)
					.foregroundStyle(.app.gray1)
					.flushedLeft

					Label(store.periodUntilAutoConfirm.title, asset: AssetResource.emergencyFallbackCalendar)
						.textStyle(.body1Header)
						.foregroundStyle(.app.gray1)
						.flushedLeft
						.padding(.horizontal, .medium3)
						.padding(.vertical, .small1)
						.background(.app.white)
						.roundedCorners(radius: .small2)
						.cardShadow
						.onTapGesture {
							store.send(.view(.selectFallbackButtonTapped))
						}

					Text(L10n.ShieldWizardRecovery.Fallback.note)
						.textStyle(.body2HighImportance)
						.foregroundStyle(.app.error)
						.flushedLeft
				}
				.padding([.horizontal, .bottom], .medium3)
				.padding(.top, .medium3)
				.background(.app.lightError)
			}
			.frame(maxWidth: .infinity)
			.roundedCorners(radius: .small1)
		}
	}
}

// MARK: - RecoveryRoleSetup.View.SectionType
private extension RecoveryRoleSetup.View {
	enum SectionType {
		case recovery
		case confirmation

		var chooseFactorSourceContext: ChooseFactorSourceContext {
			switch self {
			case .recovery:
				.recovery
			case .confirmation:
				.confirmation
			}
		}
	}
}

private extension TimePeriod {
	// TODO: Add new Crowdin keys: "%d <unit_name>"
	var title: String {
		switch (value, unit) {
		case (1, .days):
			"\(value) " + L10n.ShieldWizardRecovery.Fallback.Day.label // "shieldWizardRecovery_fallback_day_period"
		case (_, .days):
			"\(value) " + L10n.ShieldWizardRecovery.Fallback.Days.label // "shieldWizardRecovery_fallback_days_period"
		case (1, .weeks):
			"\(value) " + L10n.ShieldWizardRecovery.Fallback.Week.label // "shieldWizardRecovery_fallback_week_period"
		case (_, .weeks):
			"\(value) " + L10n.ShieldWizardRecovery.Fallback.Weeks.label // "shieldWizardRecovery_fallback_weeks_period"
		case (1, .years):
			"\(value) " + "L10n.ShieldWizardRecovery.Fallback.Year.label" // "shieldWizardRecovery_fallback_year_period"
		case (_, .years):
			"\(value) " + "L10n.ShieldWizardRecovery.Fallback.Years.label" // "shieldWizardRecovery_fallback_years_period"
		}
	}
}

private extension StoreOf<RecoveryRoleSetup> {
	var destination: PresentationStoreOf<RecoveryRoleSetup.Destination> {
		func scopeState(state: State) -> PresentationState<RecoveryRoleSetup.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destination(store: StoreOf<RecoveryRoleSetup>) -> some View {
		let destinationStore = store.destination
		return selectEmergencyFallback(with: destinationStore, store: store)
	}

	private func selectEmergencyFallback(with destinationStore: PresentationStoreOf<RecoveryRoleSetup.Destination>, store: StoreOf<RecoveryRoleSetup>) -> some View {
		WithPerceptionTracking {
			sheet(store: destinationStore.scope(state: \.selectEmergencyFallbackPeriod, action: \.selectEmergencyFallbackPeriod)) { _ in
				SelectEmergencyFallbackPeriodView(
					selectedPeriod: store.periodUntilAutoConfirm
				) { action in
					store.send(.destination(.presented(.selectEmergencyFallbackPeriod(action))))
				}
			}
		}
	}
}
