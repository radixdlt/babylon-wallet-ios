import DesignSystem
import Resources
import SwiftUI
import UIKit

// MARK: - BannerView
public final class BannerView: UIView {
	private let text: String
	private let label = UILabel()
	private let padding: CGFloat = .small1
	private var shadowLayer: CAShapeLayer?

	override public var intrinsicContentSize: CGSize {
		.init(width: label.intrinsicContentSize.width + .large1,
		      height: label.intrinsicContentSize.height + .medium1)
	}

	public init(text: String) {
		self.text = text
		super.init(frame: .zero)
		setUpLabel()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override public func layoutSubviews() {
		super.layoutSubviews()
		guard shadowLayer == nil else { return }
		setUpShadowLayer()
	}
}

// MARK: - Private Methods
extension BannerView {
	private func setUpLabel() {
		label.text = text
		label.textColor = UIColor(Color.app.gray1)
		label.font = UIFont(name: FontFamily.IBMPlexSans.medium.name, size: 16)
		label.translatesAutoresizingMaskIntoConstraints = false
		addSubview(label)
		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: centerXAnchor),
			label.centerYAnchor.constraint(equalTo: centerYAnchor),
		])
	}

	private func setUpShadowLayer() {
		shadowLayer = CAShapeLayer()
		shadowLayer?.path = UIBezierPath(roundedRect: bounds, cornerRadius: frame.height / 2).cgPath
		shadowLayer?.fillColor = UIColor(Color.app.white).cgColor

		shadowLayer?.shadowColor = UIColor.black.cgColor
		shadowLayer?.shadowPath = shadowLayer?.path
		shadowLayer?.shadowOffset = CGSize(width: 0, height: 2)
		shadowLayer?.shadowOpacity = 0.3
		shadowLayer?.shadowRadius = 5

		guard let shadowLayer = shadowLayer else { return }
		layer.insertSublayer(shadowLayer, at: 0)
	}
}
