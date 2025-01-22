import SwiftUI

struct ContentView: View {
    @State private var score = 0
    @State private var highScore = 0
    @State private var showAlert = false
    @State private var scores: [ScoreEntry] = []
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("The Square Game")
                    .font(.title)
                    .padding()
                
                HStack {
                    Text("High Score: \(highScore)")
                        .font(.footnote)
                    Spacer()
                    Text("Score: \(score)")
                        .font(.footnote)
                }
                .padding()
                
                LazyGridView(score: $score, showAlert: $showAlert, highScore: $highScore)
            }
            .padding()
            .alert("Game Over", isPresented: $showAlert) {
                Button("Start Again") { restartGame() }
                Button("Main Menu") { presentationMode.wrappedValue.dismiss() }
            }
            .onAppear(perform: loadScores)
        }
    }
    
    private func restartGame() {
        score = 0
    }
    
    private func loadScores() {
        if let data = UserDefaults.standard.data(forKey: "scores"),
           let savedScores = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            scores = savedScores
            highScore = scores.map(\.score).max() ?? 0
        }
    }
}

struct LazyGridView: View {
    @Binding var score: Int
    @Binding var showAlert: Bool
    @Binding var highScore: Int
    
    @State private var colors: [NamedColor] = []
    @State private var selectedColors: [NamedColor] = []
    
    private let predefinedColors: [NamedColor] = [
        .init(color: .red, name: "Red"),
        .init(color: .blue, name: "Blue"),
        .init(color: .green, name: "Green"),
        .init(color: .yellow, name: "Yellow"),
        .init(color: .orange, name: "Orange"),
        .init(color: .purple, name: "Purple"),
        .init(color: .brown, name: "Brown"),
        .init(color: .gray, name: "Gray")
    ]
    
    private let columns = Array(repeating: GridItem(.fixed(100), spacing: 10), count: 3)
    
    init(score: Binding<Int>, showAlert: Binding<Bool>, highScore: Binding<Int>) {
        self._score = score
        self._showAlert = showAlert
        self._highScore = highScore
        _colors = State(initialValue: LazyGridView.generateColors(from: predefinedColors))
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(colors) { namedColor in
                Button(action: { handleSelection(namedColor) }) {
                    Rectangle()
                        .fill(namedColor.color)
                        .frame(height: 100)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    private func handleSelection(_ namedColor: NamedColor) {
        selectedColors.append(namedColor)
        if selectedColors.count == 2 {
            if selectedColors[0].name == selectedColors[1].name {
                score += 1
                colors = LazyGridView.generateColors(from: predefinedColors)
            } else {
                highScore = max(highScore, score)
                score = 0
                showAlert = true
            }
            selectedColors.removeAll()
        }
    }
    
    static func generateColors(from predefinedColors: [NamedColor]) -> [NamedColor] {
        var newColors = predefinedColors
        if let duplicateColor = predefinedColors.randomElement() {
            newColors.append(duplicateColor)
        }
        return newColors.shuffled()
    }
}

struct NamedColor: Identifiable {
    let id = UUID()
    let color: Color
    let name: String
}

struct ScoreEntry: Codable {
    let score: Int
    let date: Date
}

#Preview {
    ContentView()
}
