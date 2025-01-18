//
//  ContentView.swift
//  VisionSports
//
//  Created by Sophia Bao on 2024-09-23.
//
//
//  ContentView.swift
//  VisionSports
//
//  Created by Sophia Bao on 2024-09-23.
//
import SwiftUI
import AVKit

struct VideoItem: Identifiable {
    let id = UUID()
    let name: String
}

struct ContentView: View {
    @State private var selectedVideo: VideoItem? = nil

    let videoSources = [
        "sailing1.mp4",
        "sailing2.mp4",
        "snowboarding.mp4"
    ]

    var body: some View {
        VStack {
            Text("Video Library")
                .font(.largeTitle)
                .padding()

            List(videoSources, id: \.self) { video in
                Button(action: {
                    selectedVideo = VideoItem(name: video)
                }) {
                    Text(video)
                        .font(.headline)
                }
            }
        }
        .sheet(item: $selectedVideo) { videoItem in
            VideoPlayerView(videoName: videoItem.name)
                .frame(minWidth: 1000, minHeight: 800)
                .background(ResizableBackground()) // Add a resizable background for corner dragging
        }
    }
}

struct VideoPlayerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer? = nil
    @State private var isPaused = true

    let videoName: String

    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .onAppear {
                    if let path = Bundle.main.path(forResource: videoName, ofType: nil) {
                        player = AVPlayer(url: URL(fileURLWithPath: path))
                        player?.play()
                        isPaused = false
                        addPauseAtSpecificTime(player: player, pauseTime: 5)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    MagnificationGesture()
                        .onEnded { value in
                            if value < 1.0 { // Simulating a pinching motion
                                if isPaused {
                                    player?.play()
                                    isPaused = false
                                }
                            }
                        }
                )

            HStack {
                Button(action: {
                    player?.pause()
                    dismiss()
                }) {
                    Text("Back to Library")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Button(action: {
                    player?.seek(to: .zero)
                    player?.play()
                }) {
                    Text("Restart Video")
                        .font(.title2)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }

    private func addPauseAtSpecificTime(player: AVPlayer?, pauseTime: Double) {
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            let currentTime = CMTimeGetSeconds(time)
            if abs(currentTime - pauseTime) < 0.1 && !isPaused {
                player?.pause()
                isPaused = true
            }
        }
    }
}

struct ResizableBackground: View {
    @State private var size: CGSize = CGSize(width: 600, height: 400)

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            size.width = max(2000, size.width + value.translation.width)
                            size.height = max(1600, size.height + value.translation.height)
                        }
                )
                .frame(width: size.width, height: size.height)
        }
    }
}

@main
struct VisionProVideoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
