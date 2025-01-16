//
//  ContentView.swift
//  VisionSports
//
//  Created by Sophia Bao on 2024-09-23.
//
import SwiftUI
import RealityKit
import RealityKitContent
import AVKit

@main
struct PanoramaVideoApp: SwiftUI.App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedVideo: URL? = Bundle.main.url(forResource: "spatial_video", withExtension: "mp4")
    @State private var showVideoPicker = false

    var body: some View {
        VStack {
            Text("Panorama Video Player")
                .font(.largeTitle)
                .padding()

            if let video = selectedVideo {
                NavigationLink(destination: PanoramaPlayerView(videoURL: video)) {
                    Text("Play Spatial Video")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Text("No video found")
                    .padding()
                    .foregroundColor(.red)
            }

            Button(action: {
                showVideoPicker = true
            }) {
                Text("Select Video")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showVideoPicker) {
            VideoPicker(selectedVideo: $selectedVideo)
        }
    }
}

struct PanoramaPlayerView: View {
    let videoURL: URL
    @State private var isPlaying = true

    var body: some View {
        RealityKitPanoramaPlayer(videoURL: videoURL, isPlaying: $isPlaying)
            .edgesIgnoringSafeArea(.all)
    }
}

struct RealityKitPanoramaPlayer: UIViewControllerRepresentable {
    let videoURL: URL
    @Binding var isPlaying: Bool

    func makeUIViewController(context: Context) -> PanoramaPlayerController {
        let controller = PanoramaPlayerController(videoURL: videoURL)
        controller.gestureDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PanoramaPlayerController, context: Context) {
        uiViewController.setPlaybackState(isPlaying)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GestureDelegate {
        let parent: RealityKitPanoramaPlayer

        init(_ parent: RealityKitPanoramaPlayer) {
            self.parent = parent
        }

        func gestureRecognized() {
            parent.isPlaying = true
        }
    }
}

class PanoramaPlayerController: UIViewController {
    private let videoURL: URL
    private var videoPlayer: AVPlayer!
    private var videoNode: ModelEntity!
    private var anchorEntity: AnchorEntity!
    private var realityView: RealityView<Entity>!
    var gestureDelegate: GestureDelegate?

    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create RealityView
        realityView = RealityView { content in
            self.setupPanoramaScene(for: content)
        }

        view.addSubview(realityView)
        realityView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            realityView.topAnchor.constraint(equalTo: view.topAnchor),
            realityView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            realityView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            realityView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        setupGestureRecognition()
    }

    private func setupPanoramaScene(for content: RealityView<Entity>.Content) {
        let sphere = MeshResource.generateSphere(radius: 10)
        videoPlayer = AVPlayer(url: videoURL)
        let material = VideoMaterial(avPlayer: videoPlayer)

        videoNode = ModelEntity(mesh: sphere, materials: [material])
        videoNode.transform = Transform(pitch: .pi / 2, yaw: 0, roll: 0)

        anchorEntity = AnchorEntity(world: .zero)
        anchorEntity.addChild(videoNode)

        content.add(anchorEntity)
        videoPlayer.play()
    }

    private func setupGestureRecognition() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleGesture))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleGesture() {
        if videoPlayer.timeControlStatus == .playing {
            videoPlayer.pause()
        } else {
            videoPlayer.play()
        }
        gestureDelegate?.gestureRecognized()
    }

    func setPlaybackState(_ playing: Bool) {
        if playing {
            videoPlayer.play()
        } else {
            videoPlayer.pause()
        }
    }
}

protocol GestureDelegate {
    func gestureRecognized()
}

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideo: URL?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL {
                parent.selectedVideo = url
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
