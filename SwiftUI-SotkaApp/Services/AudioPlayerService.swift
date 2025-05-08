//
//  AudioPlayerService.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 08.05.2025.
//

import AVFoundation
import OSLog

final class AudioPlayerManager {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AudioPlayerManager.self)
    )
    private var audioPlayer: AVAudioPlayer?
    private let session: AVAudioSession
    
    init(
        fileName: String,
        fileExtension: String,
        session: AVAudioSession = .sharedInstance()
    ) {
        self.session = session
        configureAudioSession()
        setupAudioPlayer(fileName: fileName, fileExtension: fileExtension)
    }
    
    private func configureAudioSession() {
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            logger.error("Ошибка audioSession: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private func setupAudioPlayer(fileName: String, fileExtension: String) {
        guard let url = Bundle.main.url(
            forResource: fileName,
            withExtension: fileExtension
        ) else {
            logger.error("Звуковой файл с названием \(fileName).\(fileExtension) не найден")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            logger.error("Ошибка инициализации аудиоплеера: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func play() {
        audioPlayer?.play()
    }
}
