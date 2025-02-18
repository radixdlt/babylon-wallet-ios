import SwiftUI

// MARK: - InteractionProgressBar
struct InteractionProgressBar: View {
	@Binding var status: Status
	@State private var currentProgress: CGFloat = Status.queued.progress
	@State private var timer: Timer?

	var body: some View {
		GeometryReader { gr in
			ZStack(alignment: .leading) {
				Rectangle()
					.fill(Color.app.gray4)
					.frame(maxWidth: .infinity)

				Rectangle()
					.fill(status.color)
					.frame(width: gr.size.width * currentProgress)
					.animation(.easeInOut(duration: 0.75), value: currentProgress)
			}
		}
		.frame(height: .small1)
		.cornerRadius(10)
		.onAppear {
			updateProgress()
		}
		.onChange(of: status) { _ in
			updateProgress()
		}
	}

	private func updateProgress() {
		timer?.invalidate()

		switch status {
		case .queued, .finished:
			currentProgress = status.progress

		case let .next(delay):
			startProgressAnimation(from: .queued, to: status, duration: delay)

		case let .inProgress(expiration):
			guard let expiration else {
				currentProgress = status.progress
				return
			}

			let duration = expiration.timeIntervalSince(Date())
			startProgressAnimation(from: .next(delay: 0), to: status, duration: duration) {
				status = .finished(success: false)
			}
		}
	}

	private func startProgressAnimation(
		from startStatus: Status,
		to endStatus: Status,
		duration: TimeInterval,
		completion: (() -> Void)? = nil
	) {
		let start = startStatus.progress
		let end = endStatus.progress
		let completeProgress = end - start

		let startTime = Date()
		let timeInterval = duration / 100

		timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
			let elapsedTime = Date().timeIntervalSince(startTime)
			let progress = start + (completeProgress * (elapsedTime / duration))

			if progress >= end {
				currentProgress = end
				timer?.invalidate()
				completion?()
			} else {
				currentProgress = progress
			}
		}
	}
}

// MARK: InteractionProgressBar.Status
extension InteractionProgressBar {
	enum Status: Equatable {
		case queued
		case next(delay: TimeInterval)
		case inProgress(expiration: Date?)
		case finished(success: Bool)

		var progress: CGFloat {
			switch self {
			case .queued: 0.05
			case .next: 0.25
			case .inProgress: 0.80
			case .finished: 1.00
			}
		}

		var color: LinearGradient {
			switch self {
			case .queued, .next, .inProgress:
				LinearGradient(gradient: Gradient.approvalSlider, startPoint: .leading, endPoint: .trailing)
			case .finished(true):
				LinearGradient(colors: [.app.green2], startPoint: .leading, endPoint: .trailing)
			case .finished(false):
				LinearGradient(colors: [.app.alert], startPoint: .leading, endPoint: .trailing)
			}
		}
	}
}
