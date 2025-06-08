import SwiftUI

struct CircularTimerView: View {
    @State private var totalSeconds: Int = 300 // 5분 기본값
    @State private var timeLeft: Int = 300
    @State private var isRunning = false
    @State private var isFinished = false
    @State private var rotation: Double = 0
    @State private var isAnimating = false
    @State private var lastRotationTime: Int = -1  // 마지막 회전한 시간 추적
    
    // 설정용 변수들
    @State private var inputMinutes: Int = 5
    @State private var inputSeconds: Int = 0
    @State private var showingSettings = false
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // 힙한 검정 배경
            Color.black
                .ignoresSafeArea()
            
            // 가로/세로 모드에 따른 레이아웃
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height {
                    // 가로모드 - 원형 타이머와 버튼을 나란히
                    HStack(spacing: 50) {
                        // 메인 원형 타이머
                        ZStack {
                            // 외부 테두리
                            Circle()
                                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                                .frame(width: 320, height: 320)
                            
                            // 진행률 링
                            Circle()
                                .stroke(Color.orange.opacity(0.2), lineWidth: 8)
                                .frame(width: 300, height: 300)
                            
                            Circle()
                                .trim(from: 0, to: progress())
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange, .red]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 300, height: 300)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: .orange, radius: getGlowRadius())
                            
                            // 내부 글로우 효과
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            getGlowColor().opacity(0.1),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 50,
                                        endRadius: 150
                                    )
                                )
                                .frame(width: 280, height: 280)
                            
                            // 회전하는 원형 텍스트
                            CircularText(
                                text: formatTimeForCircle(),
                                radius: 130,
                                rotation: rotation,
                                glowColor: getGlowColor()
                            )
                            .animation(
                                isAnimating ?
                                .easeInOut(duration: 3.0).delay(0.1) :
                                .none,
                                value: rotation
                            )
                            
                            // 중앙 시간 표시
                            VStack(spacing: 4) {
                                Text(formatTime(timeLeft))
                                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .shadow(color: getGlowColor(), radius: 15, x: 0, y: 0)
                                
                                Text(getStatusText())
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(getGlowColor().opacity(0.8))
                            }
                        }
                        
                        // 우측 세로 버튼들
                        VStack(spacing: 30) {
                            // TIME SET 버튼
                            Button(action: {
                                if !isRunning {
                                    showingSettings = true
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text("TIME")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("SET")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Circle())
                            }
                            .disabled(isRunning)
                            .opacity(isRunning ? 0.5 : 1.0)
                            
                            // 시작/일시정지 버튼
                            Button(action: toggleTimer) {
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 80)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.orange, .red]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: .orange, radius: 10)
                            }
                            .disabled(totalSeconds == 0)
                            
                            // 리셋 버튼
                            Button(action: resetTimer) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 세로모드 - 진짜 중앙 배치
                    VStack(spacing: 0) {
                        // 메인 원형 타이머 (중앙 정렬)
                        ZStack {
                            // 외부 테두리
                            Circle()
                                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                                .frame(width: 320, height: 320)
                            
                            // 진행률 링
                            Circle()
                                .stroke(Color.orange.opacity(0.2), lineWidth: 8)
                                .frame(width: 300, height: 300)
                            
                            Circle()
                                .trim(from: 0, to: progress())
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange, .red]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 300, height: 300)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: .orange, radius: getGlowRadius())
                            
                            // 내부 글로우 효과
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            getGlowColor().opacity(0.1),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 50,
                                        endRadius: 150
                                    )
                                )
                                .frame(width: 280, height: 280)
                            
                            // 회전하는 원형 텍스트
                            CircularText(
                                text: formatTimeForCircle(),
                                radius: 130,
                                rotation: rotation,
                                glowColor: getGlowColor()
                            )
                            .animation(
                                isAnimating ?
                                .easeInOut(duration: 3.0).delay(0.1) :
                                .none,
                                value: rotation
                            )
                            
                            // 중앙 시간 표시
                            VStack(spacing: 4) {
                                Text(formatTime(timeLeft))
                                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .shadow(color: getGlowColor(), radius: 15, x: 0, y: 0)
                                
                                Text(getStatusText())
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(getGlowColor().opacity(0.8))
                            }
                        }
                        .frame(maxWidth: .infinity) // 중앙 정렬 강제
                        
                        // 고정 간격
                        Spacer()
                            .frame(height: 60)
                        
                        // 컨트롤 버튼들
                        HStack(spacing: 20) {
                            // 설정 버튼
                            Button(action: {
                                if !isRunning {
                                    showingSettings = true
                                }
                            }) {
                                Text("TIME\nSET")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .disabled(isRunning)
                            .opacity(isRunning ? 0.5 : 1.0)
                            
                            // 시작/일시정지 버튼
                            Button(action: toggleTimer) {
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.orange, .red]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: .orange, radius: 10)
                            }
                            .disabled(totalSeconds == 0)
                            
                            // 리셋 버튼
                            Button(action: resetTimer) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                        .frame(maxWidth: .infinity) // 버튼들도 중앙 정렬
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // 전체 화면 사용
                    .clipped() // 안전 영역 처리
                }
            }
        }
        .onReceive(timer) { _ in
            if isRunning && timeLeft > 0 {
                timeLeft -= 1
                
                // 2초마다 회전 (2의 배수 초에 도달할 때) - 중복 방지
                if timeLeft % 2 == 0 && timeLeft != lastRotationTime && !isAnimating {
                    lastRotationTime = timeLeft
                    isAnimating = true
                    rotation = 360
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
                        rotation = 0
                        isAnimating = false
                    }
                }
                
                if timeLeft <= 0 {
                    isRunning = false
                    isFinished = true
                    timeLeft = 0
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            TimerPickerSheet(
                minutes: $inputMinutes,
                seconds: $inputSeconds,
                onSave: updateTimerSettings
            )
            .presentationDetents([.height(350)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func toggleTimer() {
        if timeLeft == 0 && !isRunning {
            // 타이머가 끝났을 때 다시 시작
            resetTimer()
        }
        isRunning.toggle()
        if isRunning {
            isFinished = false
        }
    }
    
    private func resetTimer() {
        isRunning = false
        isFinished = false
        timeLeft = totalSeconds
        rotation = 0
        lastRotationTime = -1  // 회전 추적 리셋
    }
    
    private func updateTimerSettings() {
        let newTotal = inputMinutes * 60 + inputSeconds
        totalSeconds = newTotal
        timeLeft = newTotal
        isFinished = false
    }
    
    private func progress() -> Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - timeLeft) / Double(totalSeconds)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func formatTimeForCircle() -> String {
        let timeString = formatTime(timeLeft)
        return "\(timeString)    \(timeString)    \(timeString)    \(timeString)    "
    }
    
    private func getStatusText() -> String {
        if isFinished {
            return "완료!"
        } else if isRunning {
            return "진행 중"
        } else {
            return "대기 중"
        }
    }
    
    private func getGlowColor() -> Color {
        if isFinished {
            return .red
        } else if timeLeft < totalSeconds / 10 {
            return .red
        } else if timeLeft < totalSeconds / 3 {
            return .orange
        } else {
            return .orange
        }
    }
    
    private func getGlowRadius() -> CGFloat {
        if isFinished {
            return 20
        } else if timeLeft < totalSeconds / 10 {
            return 15
        } else {
            return 10
        }
    }
}

struct CircularText: View {
    let text: String
    let radius: CGFloat
    let rotation: Double
    let glowColor: Color
    
    var body: some View {
        ZStack {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(glowColor)
                    .shadow(color: glowColor, radius: 8, x: 0, y: 0)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(text.count))))
            }
        }
        .rotationEffect(.degrees(rotation))
    }
}

struct TimerPickerSheet: View {
    @Binding var minutes: Int
    @Binding var seconds: Int
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // 상단 핸들
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 6)
                .padding(.top, 10)
            
            // 타이틀
            Text("타이머 설정")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            // 피커 영역
            HStack(spacing: 0) {
                // 분 피커
                VStack {
                    Text("분")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.bottom, 8)
                    
                    Picker("분", selection: $minutes) {
                        ForEach(0...99, id: \.self) { minute in
                            Text("\(minute)")
                                .font(.system(size: 20, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                }
                
                // 구분자
                Text(":")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 20)
                    .offset(y: -15)
                
                // 초 피커
                VStack {
                    Text("초")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.bottom, 8)
                    
                    Picker("초", selection: $seconds) {
                        ForEach(0...59, id: \.self) { second in
                            Text("\(second)")
                                .font(.system(size: 20, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .tag(second)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 120)
                }
            }
            .padding(.vertical, 10)
            
            // 하단 버튼
            Button(action: {
                onSave()
                dismiss()
            }) {
                Text("설정 완료")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.black)
    }
}

// 메인 뷰
struct ContentView: View {
    var body: some View {
        CircularTimerView()
    }
}

#Preview {
    ContentView()
}
