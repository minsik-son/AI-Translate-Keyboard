import UIKit

final class MercuryRippleView: UIView {

    // MARK: - Configuration
    private static let targetFPS: Int = 24
    private static let maxRipples: Int = 15
    private static let rippleSpeed: CGFloat = 180        // pts/sec 확산 속도
    private static let rippleMaxRadius: CGFloat = 200    // 최대 반경
    private static let rippleLifetime: CGFloat = 1.2     // 초

    static let perspectiveY: CGFloat = 0.65               // Y축 압축 비율 (원근감)

    // MARK: - Ripple Snapshot (외부 노출용)
    struct RippleSnapshot {
        let centerX: CGFloat
        let centerY: CGFloat
        let radius: CGFloat
        let ringWidth: CGFloat
        let progress: CGFloat      // 0.0 → 1.0 (수명 진행도)
        let intensity: CGFloat     // 0.3 ~ 1.0
    }

    // MARK: - Ripple State
    private struct Ripple {
        let centerX: CGFloat
        let centerY: CGFloat
        let startTime: CFTimeInterval
        let intensity: CGFloat   // 0.5 ~ 1.0 (일반키 ~ 스페이스바)
    }

    private var ripples: [Ripple] = []
    private var displayLink: CADisplayLink?
    private(set) var isAnimating = false
    private var lastTimestamp: CFTimeInterval = 0

    // MARK: - Color Palette (Deep Space Blue + Ice White ripple)
    // 배경은 KeyboardTheme.keyboardBackground가 처리하므로 여기선 물결만 그림
    private static let rippleColorR: CGFloat = 0.75
    private static let rippleColorG: CGFloat = 0.85
    private static let rippleColorB: CGFloat = 0.95

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isOpaque = false
        backgroundColor = .clear
        contentScaleFactor = 1.0   // 메모리 절약: 1x 해상도
        isUserInteractionEnabled = false
    }

    // MARK: - Public API

    var isActive: Bool { isAnimating }

    /// 터치 위치에 물결 추가
    func addRipple(at point: CGPoint, intensity: CGFloat = 0.7) {
        guard isAnimating else { return }

        // FIFO: 최대 개수 초과 시 오래된 것 제거
        if ripples.count >= Self.maxRipples {
            ripples.removeFirst()
        }

        let ripple = Ripple(
            centerX: point.x,
            centerY: point.y,
            startTime: CACurrentMediaTime(),
            intensity: min(max(intensity, 0.3), 1.0)
        )
        ripples.append(ripple)
    }

    func startAnimation() {
        guard !isAnimating else { return }
        guard !ProcessInfo.processInfo.isLowPowerModeEnabled else { return }

        isAnimating = true
        lastTimestamp = 0
        ripples.removeAll()

        let dl = CADisplayLink(target: self, selector: #selector(animationTick))
        if #available(iOS 15.0, *) {
            dl.preferredFrameRateRange = CAFrameRateRange(minimum: 15, maximum: 30, preferred: Float(Self.targetFPS))
        } else {
            dl.preferredFramesPerSecond = Self.targetFPS
        }
        dl.add(to: .main, forMode: .common)
        displayLink = dl
    }

    func stopAnimation() {
        guard isAnimating else { return }
        isAnimating = false
        displayLink?.invalidate()
        displayLink = nil
        ripples.removeAll()
        setNeedsDisplay()
    }

    func pauseAnimation() {
        guard isAnimating else { return }
        displayLink?.invalidate()
        displayLink = nil
        isAnimating = false
    }

    func resumeAnimation() {
        guard !isAnimating else { return }
        guard !ripples.isEmpty else { startAnimation(); return }

        isAnimating = true
        lastTimestamp = 0

        let dl = CADisplayLink(target: self, selector: #selector(animationTick))
        if #available(iOS 15.0, *) {
            dl.preferredFrameRateRange = CAFrameRateRange(minimum: 15, maximum: 30, preferred: Float(Self.targetFPS))
        } else {
            dl.preferredFramesPerSecond = Self.targetFPS
        }
        dl.add(to: .main, forMode: .common)
        displayLink = dl
    }

    // MARK: - Snapshot API (렌즈 효과용)

    /// 현재 활성 리플들의 기하 정보 스냅샷 반환
    func activeRippleSnapshots() -> [RippleSnapshot] {
        guard isAnimating, !ripples.isEmpty else { return [] }
        let now = CACurrentMediaTime()
        var snapshots: [RippleSnapshot] = []
        snapshots.reserveCapacity(ripples.count)

        for ripple in ripples {
            let age = CGFloat(now - ripple.startTime)
            let progress = age / Self.rippleLifetime
            guard progress >= 0, progress <= 1.0 else { continue }

            let radius = Self.rippleSpeed * age
            guard radius > 0 else { continue }

            let ringWidth = radius * 0.3

            snapshots.append(RippleSnapshot(
                centerX: ripple.centerX,
                centerY: ripple.centerY,
                radius: radius,
                ringWidth: ringWidth,
                progress: progress,
                intensity: ripple.intensity
            ))
        }
        return snapshots
    }

    // MARK: - Animation Loop

    @objc private func animationTick(_ dl: CADisplayLink) {
        guard isAnimating else { return }

        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            stopAnimation()
            return
        }

        let now = CACurrentMediaTime()

        // 수명 초과한 리플 제거
        ripples.removeAll { now - $0.startTime > CFTimeInterval(Self.rippleLifetime) }

        // 리플이 없으면 draw 스킵 (idle 상태에서 CPU 절약)
        if ripples.isEmpty {
            // 마지막 프레임 한 번만 클리어
            if lastTimestamp != 0 {
                lastTimestamp = 0
                setNeedsDisplay()
            }
            return
        }

        lastTimestamp = now
        setNeedsDisplay()
    }

    // MARK: - Draw

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)

        guard !ripples.isEmpty else { return }

        let now = CACurrentMediaTime()
        let r = Self.rippleColorR
        let g = Self.rippleColorG
        let b = Self.rippleColorB

        for ripple in ripples {
            let age = CGFloat(now - ripple.startTime)
            let progress = age / Self.rippleLifetime   // 0.0 → 1.0

            guard progress >= 0, progress <= 1.0 else { continue }

            let radius = Self.rippleSpeed * age
            guard radius > 0 else { continue }

            // 물결 링 두께: 반경의 30%
            let ringWidth = radius * 0.3

            // 알파: 시작 시 밝고 점차 사라짐 (ease-out)
            let baseAlpha = ripple.intensity * (1.0 - progress * progress) * 0.35

            // 주 물결 (원형 도넛)
            let innerRadius = max(radius - ringWidth * 0.5, 0)
            let outerRadius = radius + ringWidth * 0.5
            drawCircularRing(ctx: ctx, cx: ripple.centerX, cy: ripple.centerY,
                             innerR: innerRadius, outerR: outerRadius,
                             r: r, g: g, b: b, alpha: baseAlpha)

            // 외곽 물결 (50% 크기, 40% 알파)
            let outerWaveRadius = radius * 1.5
            let outerRingWidth = ringWidth * 0.6
            let outerInner = max(outerWaveRadius - outerRingWidth * 0.5, 0)
            let outerOuter = outerWaveRadius + outerRingWidth * 0.5
            drawCircularRing(ctx: ctx, cx: ripple.centerX, cy: ripple.centerY,
                             innerR: outerInner, outerR: outerOuter,
                             r: r, g: g, b: b, alpha: baseAlpha * 0.4)
        }
    }

    /// 원형 도넛 링 — 깔끔한 원형 수면파
    private func drawCircularRing(ctx: CGContext,
                                   cx: CGFloat, cy: CGFloat,
                                   innerR: CGFloat, outerR: CGFloat,
                                   r: CGFloat, g: CGFloat, b: CGFloat,
                                   alpha: CGFloat) {
        guard alpha > 0.005 else { return }
        guard outerR > 0 else { return }

        ctx.saveGState()

        // Y축 압축 (수면 원근감): 중심점 기준으로 scaleBy
        ctx.translateBy(x: cx, y: cy)
        ctx.scaleBy(x: 1.0, y: Self.perspectiveY)

        // 도넛 합성: 외곽 타원 + 내곽 타원 → even-odd fill
        let outerRect = CGRect(x: -outerR, y: -outerR, width: outerR * 2, height: outerR * 2)
        let innerRect = CGRect(x: -innerR, y: -innerR, width: innerR * 2, height: innerR * 2)
        ctx.addEllipse(in: outerRect)
        ctx.addEllipse(in: innerRect)
        ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: alpha))
        ctx.fillPath(using: .evenOdd)

        ctx.restoreGState()
    }

    // MARK: - Cleanup
    deinit {
        displayLink?.invalidate()
        displayLink = nil
    }
}
