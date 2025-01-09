import SwiftUI

struct ContentView: View {
    @State private var score = 0
    @State private var highScore = 0
    @State private var showAlert = false
    @State private var gameOver = false
    @State private var scores: [ScoreEntry] = []
    
    @Environment(\.presentationMode) var presentationMode // To control view navigation
    
    var body: some View {
        NavigationView {
            VStack {
                Text("The Square Game")
                    .font(.title)
                    .padding()
                
                HStack {
                    Text("High Score: \(highScore)")
                        .font(.footnote)
                    Text("Score: \(score)")
                        .font(.footnote)
                        .padding()
                }
                
                LazyGridView(score: $score, showAlert: $showAlert, gameOver: $gameOver, scores: $scores, highScore: $highScore)
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Game Over"),
                    message: Text("Do you want to start again?"),
                    primaryButton: .destructive(Text("Start Again")) {
                        restartGame()
                    },
                    secondaryButton: .cancel(Text("Main Menu")) {
                        presentationMode.wrappedValue.dismiss() // Go back to the landing page
                    }
                )
            }
            .onAppear {
                loadScores()
            }
            .onDisappear {
                saveScoreIfNeeded()
            }
        }
    }
    
    func restartGame() {
        score = 0
        gameOver = false
    }
    
    func loadScores() {
        if let data = UserDefaults.standard.data(forKey: "scores"),
           let savedScores = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            scores = savedScores
            highScore = scores.max { $0.score < $1.score }?.score ?? 0
        }
    }
    
    func saveScores() {
        if let encodedData = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(encodedData, forKey: "scores")
        }
    }
    
    func saveScoreIfNeeded() {
        if score > 0 {
            let newScore = ScoreEntry(score: score, date: Date())
            scores.append(newScore)
            saveScores()
        }
    }
}

struct LazyGridView: View {
    @Binding var score: Int
    @Binding var showAlert: Bool
    @Binding var gameOver: Bool
    @Binding var scores: [ScoreEntry]
    @Binding var highScore: Int
    
    @State private var selectedColors: [NamedColor] = []
    @State private var colors: [NamedColor] = []
    
    let columns = Array(repeating: GridItem(.fixed(100), spacing: 10), count: 3)
    
    let predefinedColors: [NamedColor] = [
        NamedColor(color: .red, name: "Red"),
        NamedColor(color: .blue, name: "Blue"),
        NamedColor(color: .green, name: "Green"),
        NamedColor(color: .yellow, name: "Yellow"),
        NamedColor(color: .orange, name: "Orange"),
        NamedColor(color: .purple, name: "Purple"),
        NamedColor(color: .brown, name: "Brown"),
        NamedColor(color: .gray, name: "Gray")
    ]
    
    init(score: Binding<Int>, showAlert: Binding<Bool>, gameOver: Binding<Bool>, scores: Binding<[ScoreEntry]>, highScore: Binding<Int>) {
        self._score = score
        self._showAlert = showAlert
        self._gameOver = gameOver
        self._scores = scores
        self._highScore = highScore
        var initialColors = predefinedColors
        let duplicateColor = predefinedColors.randomElement()!
        initialColors.append(NamedColor(color: duplicateColor.color, name: duplicateColor.name))
        _colors = State(initialValue: initialColors.shuffled())
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(colors) { namedColor in
                Button(action: {
                    handleSelection(namedColor: namedColor)
                }) {
                    Rectangle()
                        .fill(namedColor.color)
                        .frame(height: 100)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    func handleSelection(namedColor: NamedColor) {
        selectedColors.append(namedColor)
        
        if selectedColors.count == 2 {
            if selectedColors[0].name == selectedColors[1].name {
                score += 1
                shuffleColors()
            } else {
                if score > highScore {
                    highScore = score
                }
                let newScore = ScoreEntry(score: score, date: Date())
                scores.append(newScore)
                saveScores()
                
                score = 0
                shuffleColors()
                gameOver = true
                showAlert = true
            }
            selectedColors.removeAll()
        }
    }
    
    func shuffleColors() {
        var newColors = predefinedColors
        let duplicateColor = predefinedColors.randomElement()!
        newColors.append(NamedColor(color: duplicateColor.color, name: duplicateColor.name))
        colors = newColors.shuffled()
    }
    
    func saveScores() {
        if let encodedData = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(encodedData, forKey: "scores")
        }
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
