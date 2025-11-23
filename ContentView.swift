import SwiftUI
import UIKit
import AudioToolbox

// MARK: - 모드 정의
enum TimerMode: Int {
    case timer = 0
    case clock = 1
    case stopwatch = 2
}

// 타이머 종료 시 진동(햅틱) 발생
func triggerTimerFinishedHaptic() {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
}

// MARK: - 메인 타이머 뷰
struct CircularTimerView: View {
    // 모드
    @State private var mode: TimerMode = .timer
    
    // 타이머 관련 상태
    @State private var totalSeconds: Int = 0         // 🔁 300 → 0
    @State private var timeLeft: Int = 0            // 🔁 300 → 0
    
    // 스톱워치 정밀도 (Double)
    @State private var stopwatchTime: Double = 0.0
    
    // 랩 타임 저장용 배열
    @State private var lapTimes: [Double] = []
    
    @State private var isRunning: Bool = false
    @State private var isFinished: Bool = false
    
    // 회전 애니메이션
    @State private var rotation: Double = 0
    @State private var lastRotationTrigger: Int = -1
    
    @State private var secondTick: Int = 0
    
    // 정밀 타이머 계산용 변수들
    @State private var lastTime: Date = Date()
    @State private var timerAccumulator: TimeInterval = 0.0
    @State private var lastClockSecond: Int = -1
    
    // 시계 모드용 현재 시간
    @State private var currentTime: Date = Date()
    
    // 설정 시트
    @State private var inputMinutes: Int = 0        // 🔁 5 → 0
    @State private var inputSeconds: Int = 0
    @State private var showingSettings: Bool = false
    
    // 알람 타이머
    @State private var alarmTimer: Timer?
    
    // 0.01초 간격 타이머
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if geo.size.width > geo.size.height {
                    landscapeLayout
                } else {
                    portraitLayout
                }
                
                // 화면 터치 시 알람 종료 (투명 버튼)
                if alarmTimer != nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            stopAlarm()
                        }
                }
            }
            // 좌우 스와이프 제스처
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 40
                        guard !isRunning else { return }
                        
                        if value.translation.width < -threshold {
                            swipeLeft()
                        } else if value.translation.width > threshold {
                            swipeRight()
                        }
                    }
            )
        }
        .onReceive(timer) { _ in
            handleTick()
        }
        .sheet(isPresented: $showingSettings) {
            TimerPickerSheet(
                minutes: $inputMinutes,
                seconds: $inputSeconds,
                onSave: updateTimerSettings
            )
            .presentationDetents([.height(350)])
        }
    }
}

// ✅ 원 크기 설정 (350 유지)
extension CircularTimerView {
    var circleSize: CGFloat { 350 }
    var circleRadius: CGFloat { circleSize / 2 }
    var circleLineWidth: CGFloat { 12 }
}

// MARK: - 스와이프 모드 전환
extension CircularTimerView {
    func swipeLeft() {
        let nextIndex = mode.rawValue + 1
        if let newMode = TimerMode(rawValue: nextIndex) {
            withAnimation {
                switchMode(to: newMode)
            }
        }
    }
    
    func swipeRight() {
        let prevIndex = mode.rawValue - 1
        if let newMode = TimerMode(rawValue: prevIndex) {
            withAnimation {
                switchMode(to: newMode)
            }
        }
    }
}

// MARK: - 알람 및 랩 타임 로직
extension CircularTimerView {
    func startRepeatingAlarm() {
        guard alarmTimer == nil else { return }
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    func stopAlarm() {
        alarmTimer?.invalidate()
        alarmTimer = nil
    }
    
    func recordLap() {
        lapTimes.insert(stopwatchTime, at: 0)
    }
}

// MARK: - 레이아웃 (세로)
extension CircularTimerView {
    var portraitLayout: some View {
        VStack(spacing: 0) {
            modeSwitchPortrait
                .padding(.top, 32)
            
            Spacer(minLength: 0)
            
            circularTimer
            
            // 스톱워치 모드이고 랩 타임이 있을 때 리스트 표시
            if mode == .stopwatch && !lapTimes.isEmpty {
                lapListView
                    .frame(height: 120)
                    .padding(.top, 20)
            }
            
            Spacer(minLength: 0)
            
            bottomButtons
                .padding(.bottom, 8)
            
            bottomBannerAreaPortrait
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}

// MARK: - 레이아웃 (가로)
extension CircularTimerView {
    var landscapeLayout: some View {
        HStack(spacing: 40) {
            // 왼쪽: 원
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                circularTimer
                Spacer(minLength: 0)
            }
            
            // 오른쪽: 툴바 → 버튼 → 배너
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                // 가로 모드에서도 랩 타임 리스트 표시
                if mode == .stopwatch && !lapTimes.isEmpty {
                    lapListView
                        .frame(height: 80)
                        .padding(.bottom, 8)
                }
                
                modeSwitchLandscape
                    .padding(.bottom, 12)
                
                bottomButtons
                    .padding(.bottom, 8)
                
                bottomBannerAreaLandscape
            }
            .frame(width: 220)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
    }
}

// MARK: - 랩 타임 리스트 뷰
extension CircularTimerView {
    var lapListView: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(Array(lapTimes.enumerated()), id: \.offset) { index, time in
                    HStack {
                        Text("랩 \(lapTimes.count - index)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(formatLapTime(time))
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 30)
                }
            }
            .padding(.vertical, 4)
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
    
    func formatLapTime(_ time: Double) -> String {
        let totalSec = Int(time)
        let m = totalSec / 60
        let s = totalSec % 60
        let cs = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d:%02d", m, s, cs)
    }
}

// MARK: - 배너 / placeholder 영역
extension CircularTimerView {
    var bottomBannerAreaPortrait: some View {
        Group {
            if mode == .timer || mode == .stopwatch {
                BannerAdView()
                    .frame(height: 50)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 24)
            } else {
                Color.clear
                    .frame(height: 50)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 24)
            }
        }
    }
    
    var bottomBannerAreaLandscape: some View {
        Group {
            if mode == .timer || mode == .stopwatch {
                BannerAdView()
                    .frame(height: 50)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            } else {
                Color.clear
                    .frame(height: 50)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Minimal Line Switch
extension CircularTimerView {
    // 메뉴 너비 복구
    var switchWidthPortrait: CGFloat { 200 }
    var switchWidthLandscape: CGFloat { 210 }
    
    var modeSwitchPortrait: some View {
        VStack(spacing: 8) {
            HStack {
                modeLabel(.timer, "타이머")
                Spacer()
                modeLabel(.clock, "시계")
                Spacer()
                modeLabel(.stopwatch, "스톱워치")
            }
            .frame(width: switchWidthPortrait)
            
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: 2)
                
                HStack {
                    Circle()
                        .fill(mode == .timer ? Color.orange : Color.clear)
                        .frame(width: 8, height: 8)
                    Spacer()
                    Circle()
                        .fill(mode == .clock ? Color.orange : Color.clear)
                        .frame(width: 8, height: 8)
                    Spacer()
                    Circle()
                        .fill(mode == .stopwatch ? Color.orange : Color.clear)
                        .frame(width: 8, height: 8)
                }
                .frame(width: switchWidthPortrait)
            }
        }
    }
    
    var modeSwitchLandscape: some View {
        VStack(spacing: 8) {
            HStack {
                modeLabel(.timer, "타이머")
                Spacer()
                modeLabel(.clock, "시계")
                Spacer()
                modeLabel(.stopwatch, "스톱워치")
            }
            .frame(width: switchWidthLandscape)
            
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: 2)
                
                HStack {
                    Circle()
                        .fill(mode == .timer ? Color.orange : Color.clear)
                        .frame(width: 8, height: 8)
                    Spacer()
                    Circle()
                        .fill(mode == .clock ? Color.orange : Color.clear)
                        .frame(width: 8, height: 8)
                    Spacer()
                    Circle()
                        .fill(mode == .stopwatch ? Color.orange : Color.clear)
                        .frame(width: 8, height: 8)
                }
                .frame(width: switchWidthLandscape)
            }
        }
    }
    
    func modeLabel(_ target: TimerMode, _ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(mode == target ? .white : .gray)
            .onTapGesture {
                guard !isRunning else { return }
                switchMode(to: target)
            }
    }
    
    func switchMode(to newMode: TimerMode) {
        stopAlarm()
        
        mode = newMode
        isFinished = false
        lastRotationTrigger = -1
        rotation = 0
        timerAccumulator = 0
        lapTimes.removeAll()
        
        switch newMode {
        case .timer:
            timeLeft = totalSeconds
        case .stopwatch:
            stopwatchTime = 0.0
        case .clock:
            currentTime = Date()
        }
    }
}

// MARK: - 원형 타이머 + 회전 텍스트
extension CircularTimerView {
    var circularTimer: some View {
        ZStack {
            // 바탕 원
            Circle()
                .stroke(Color.orange.opacity(0.2), lineWidth: circleLineWidth)
                .frame(width: circleSize, height: circleSize)

            if mode == .timer || mode == .stopwatch {
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: circleLineWidth, lineCap: .round)
                    )
                    .frame(width: circleSize, height: circleSize)
                    .rotationEffect(.degrees(-90))
            }

            if mode == .clock {
                clockSecondArc
            }

            CircularTextCanvas(
                text: circularText,
                radius: 155,
                glow: glowColor
            )
            .frame(width: 350, height: 350)
            .rotationEffect(.degrees(rotation))
            
            VStack(spacing: 6) {
                Text(displayTime)
                    .font(.system(size: 55,
                                  weight: .bold,
                                  design: .monospaced))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                Text(statusText)
                    .font(.system(size: 16))
                    .foregroundColor(glowColor)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 360)
    }
}

extension CircularTimerView {
    var clockSecondArc: some View {
        let angle = Double(secondTick) * 6.0
        
        return Circle()
            .trim(from: 0, to: 1.0 / 60.0)
            .stroke(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: circleLineWidth,
                                   lineCap: .round)
            )
            .frame(width: circleSize, height: circleSize)
            .rotationEffect(.degrees(-90 + angle))
            .animation(.linear(duration: 1.0), value: secondTick)
    }
}

// MARK: - Canvas 기반 원형 텍스트
struct CircularTextCanvas: View {
    let text: String
    let radius: CGFloat
    let glow: Color
    
    var body: some View {
        Canvas { context, size in
            let chars = Array(text)
            let count = chars.count
            guard count > 0 else { return }
            
            let angle = 2 * .pi / Double(count)
            
            for (i, c) in chars.enumerated() {
                let theta = Double(i) * angle
                
                var t = CGAffineTransform.identity
                t = t.translatedBy(x: size.width / 2, y: size.height / 2)
                t = t.rotated(by: theta)
                t = t.translatedBy(x: 0, y: -radius)
                
                context.concatenate(t)
                
                let draw = Text(String(c))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(glow)
                
                context.draw(draw, at: .zero)
                context.concatenate(t.inverted())
            }
        }
    }
}

// MARK: - 버튼들
extension CircularTimerView {
    @ViewBuilder
    var bottomButtons: some View {
        HStack(spacing: 20) {
            if mode == .timer {
                timeSetButton
                playPauseButton
                resetButton
            } else if mode == .stopwatch {
                Spacer().frame(width: 50, height: 50)
                playPauseButton
                if isRunning { lapButton } else { resetButton }
            } else {
                Spacer().frame(width: 50, height: 50)
                Spacer().frame(width: 70, height: 70)
                Spacer().frame(width: 50, height: 50)
            }
        }
        .frame(height: 80)
    }
    
    var timeSetButton: some View {
        Button(action: {
            if !isRunning && mode == .timer {
                showingSettings = true
            }
        }) {
            Text("SET")
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    var lapButton: some View {
        Button(action: { recordLap() }) {
            Text("LAP")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.5))
                .clipShape(Circle())
        }
    }
    
    var playPauseButton: some View {
        Button(action: { toggleTimer() }) {
            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
        }
        .disabled(mode == .clock)
        .opacity(mode == .clock ? 0.3 : 1.0)
    }
    
    var resetButton: some View {
        Button(action: { resetTimer() }) {
            Image(systemName: "arrow.counterclockwise")
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.3))
                .clipShape(Circle())
        }
        .disabled(mode == .clock)
        .opacity(mode == .clock ? 0.3 : 1.0)
    }
}

// 초 단위 값을 "HH:mm:ss" 문자열로 변환 (타이머용)
func hmsString(from seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    return String(format: "%02d:%02d:%02d", h, m, s)
}

// MARK: - 계산 프로퍼티
extension CircularTimerView {
    var progressValue: CGFloat {
        switch mode {
        case .timer:
            guard totalSeconds > 0 else { return 0 }
            return CGFloat(Double(totalSeconds - timeLeft) / Double(totalSeconds))
        case .stopwatch:
            return CGFloat(stopwatchTime.truncatingRemainder(dividingBy: 60)) / 60.0
        case .clock:
            let sec = Calendar.current.component(.second, from: currentTime)
            return CGFloat(sec) / 60.0
        }
    }
    
    var displayTime: String {
        switch mode {
        case .timer:
            let m = timeLeft / 60
            let s = timeLeft % 60
            return String(format: "%02d:%02d", m, s)
        case .stopwatch:
            let totalSec = Int(stopwatchTime)
            let m = totalSec / 60
            let s = totalSec % 60
            let cs = Int((stopwatchTime.truncatingRemainder(dividingBy: 1)) * 100)
            return String(format: "%02d:%02d:%02d", m, s, cs)
        case .clock:
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: currentTime)
        }
    }
    
    var circularText: String {
        let t: String
        
        switch mode {
        case .timer:
            t = hmsString(from: timeLeft)
        case .stopwatch:
            let totalSec = Int(stopwatchTime)
            t = hmsString(from: totalSec)
        case .clock:
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            t = formatter.string(from: currentTime)
        }
        
        return "\(t)    \(t)    \(t)    \(t)    "
    }

    var statusText: String {
        switch mode {
        case .timer:
            if isFinished { return "완료!" }
            return isRunning ? "진행 중" : "대기 중"
        case .stopwatch:
            return isRunning ? "측정 중" : "대기 중"
        case .clock:
            return "현재 시각"
        }
    }
    
    var glowColor: Color {
        switch mode {
        case .timer:
            return isFinished ? .red : .orange
        case .stopwatch:
            return .orange
        case .clock:
            return .orange
        }
    }
}

// MARK: - 타이머 로직 / 애니메이션
extension CircularTimerView {
    func handleTick() {
        let now = Date()
        let deltaTime = now.timeIntervalSince(lastTime)
        lastTime = now
        
        currentTime = now
        
        var triggerValue: Int? = nil
        
        switch mode {
        case .timer:
            guard isRunning else { break }
            
            timerAccumulator += deltaTime
            if timerAccumulator >= 1.0 {
                timerAccumulator -= 1.0
                triggerValue = timeLeft
                
                if timeLeft > 0 {
                    timeLeft -= 1
                } else {
                    isFinished = true
                    isRunning = false
                    startRepeatingAlarm()
                }
            }
            
        case .stopwatch:
            guard isRunning else { break }
            stopwatchTime += deltaTime
            triggerValue = Int(stopwatchTime)
            
        case .clock:
            let sec = Calendar.current.component(.second, from: currentTime)
            if sec != lastClockSecond {
                lastClockSecond = sec
                triggerValue = sec
                secondTick += 1
            }
        }
        
        if let v = triggerValue {
            if v % 7 == 0 && v != lastRotationTrigger {
                lastRotationTrigger = v
                withAnimation(.easeInOut(duration: 2.5)) {
                    rotation += 360
                }
            }
        }
    }
    
    func toggleTimer() {
        switch mode {
        case .timer:
            if totalSeconds == 0 { return }
            if timeLeft == 0 { resetTimer() }
            isRunning.toggle()
            if isRunning { isFinished = false }
        case .stopwatch:
            isRunning.toggle()
        case .clock:
            break
        }
    }
    
    func resetTimer() {
        stopAlarm()
        
        isRunning = false
        isFinished = false
        lastRotationTrigger = -1
        rotation = 0
        timerAccumulator = 0
        
        lapTimes.removeAll()
        
        switch mode {
        case .timer:
            timeLeft = totalSeconds
        case .stopwatch:
            stopwatchTime = 0.0
        case .clock:
            break
        }
    }
    
    func updateTimerSettings() {
        let newTotal = max(inputMinutes * 60 + inputSeconds, 0)
        totalSeconds = newTotal
        timeLeft = newTotal
        isFinished = false
        timerAccumulator = 0
    }
}

// MARK: - 설정 시트
struct TimerPickerSheet: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 6)
                .padding(.top, 10)
            
            Text("타이머 설정")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 0) {
                PickerWheel(title: "분", value: $minutes, range: 0...99)
                Text(":")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                PickerWheel(title: "초", value: $seconds, range: 0...59)
            }
            
            Button(action: {
                onSave()
                dismiss()
            }) {
                Text("완료")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
        }
        .background(Color.black)
    }
}

struct PickerWheel: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.orange)
                .padding(.bottom, 6)
            
            Picker(title, selection: $value) {
                ForEach(range, id: \.self) { num in
                    Text("\(num)")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .tag(num)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
        }
    }
}

// MARK: - 배너 광고 플레이스홀더
struct BannerAdView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
            Text("Banner Ad")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - 엔트리 포인트
struct ContentView: View {
    var body: some View {
        CircularTimerView()
    }
}

#Preview {
    ContentView()
}
