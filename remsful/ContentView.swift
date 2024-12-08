import SwiftUI
import pulsar
import HealthKit

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager(respiratoryRate: 15.0)
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("err is this thing on?")
            
            Text("Respiratory Rate: \(healthKitManager.respiratoryRate, specifier: "%.1f") breaths/min")
            
            PulseViewRepresentable(duration: 60 / healthKitManager.respiratoryRate)
                .frame(width: 100, height: 100)
        }
        .padding()
        .onAppear {
            healthKitManager.requestAuthorization()
        }
    }
}

struct PulseViewRepresentable: UIViewRepresentable {
    var duration: TimeInterval
    
    func makeUIView(context: Context) -> PulseView {
        let pulseView = PulseView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        pulseView.startPulsing(duration: duration, repeatCount: .infinity, color: .blue)
        return pulseView
    }
    
    func updateUIView(_ uiView: PulseView, context: Context) {
        uiView.stopPulsing()
        uiView.startPulsing(duration: duration, repeatCount: .infinity, color: .blue)
    }
}

#Preview {
    ContentView()
}
