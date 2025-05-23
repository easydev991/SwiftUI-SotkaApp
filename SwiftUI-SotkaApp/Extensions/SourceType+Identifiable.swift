//
//  SourceType+Identifiable.swift
//  SwiftUI-SotkaApp
//
//  Created by Oleg991 on 23.05.2025.
//

import UIKit

extension UIImagePickerController.SourceType: @retroactive Identifiable {
    public var id: String {
        switch self {
        case .camera: "camera"
        case .photoLibrary: "photoLibrary"
        case .savedPhotosAlbum: "savedPhotosAlbum"
        @unknown default: fatalError()
        }
    }
}
