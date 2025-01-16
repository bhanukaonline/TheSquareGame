//
//  LandingPage.swift
//  TheSquareGame
//
//  Created by Bhanuka on 1/9/25.
//


import SwiftUI

struct LandingPage: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to The Square Game")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                // Start Game Button
                NavigationLink(destination: ContentView()) {
                    Text("START GAME")
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer().frame(height: 20)
                
                NavigationLink(destination: GuideView()) {
                    Text("User Guide")
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer().frame(height: 20)
                
                // High Score Button
                NavigationLink(destination: HighScoreView()) {
                    Text("HIGH SCORES")
                        .font(.title)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer().frame(height: 20)
                
                // Exit Button
                Button(action: {
                    exit(0) // Exits the app
                }) {
                    Text("EXIT GAME")
                        .font(.title)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .navigationBarHidden(true) // Hide the navigation bar for this screen
            .padding()
        }
    }
}

struct HighScoreView: View {
    @State private var scores: [ScoreEntry] = []
    
    var body: some View {
        VStack {
            Text("High Scores")
                .font(.largeTitle)
                .padding()
            
            List(scores, id: \.date) { scoreEntry in
                HStack {
                    Text("Score: \(scoreEntry.score)")
                    Spacer()
                    Text("\(scoreEntry.date, formatter: DateFormatter.shortDateFormatter)")
                }
            }
            .onAppear {
                loadScores()
            }
        }
    }
    
    // Load scores from UserDefaults
    func loadScores() {
        if let data = UserDefaults.standard.data(forKey: "scores"),
           let savedScores = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            scores = savedScores
        }
    }
}

struct GuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("How to Play The Square Game")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Text("1. Start the game by clicking 'START GAME' on the landing page.")
                    .font(.body)
                
                Text("2. Match pairs of squares with the same color to score points.")
                    .font(.body)
                
                Text("3. If you make a wrong match, the game ends.")
                    .font(.body)
                
                Text("4. Check your high scores by clicking 'HIGH SCORES' on the landing page.")
                    .font(.body)
                
                Text("5. If you want to exit, click 'EXIT GAME'.")
                    .font(.body)
                
                Spacer()
                
                Text("Enjoy the game!")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .navigationTitle("User Guide")
    }
}

extension DateFormatter {
    static var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    LandingPage()
}
