// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Aubio",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Aubio",
            targets: ["Aubio"]
        ),
    ],
    targets: [
        .target(
            name: "Aubio",
            path: "src",
            exclude: [
                // Exclude alternative FFT implementations (using Accelerate instead)
                "spectral/dct_fftw.c",
                "spectral/dct_ipp.c",
                "spectral/dct_ooura.c",

                // Exclude external library-dependent audio I/O
                "io/source_sndfile.c",
                "io/sink_sndfile.c",

                // Exclude wscript build files
                "wscript_build",
            ],
            publicHeadersPath: "include",
            cSettings: [
                // Define Apple platform features
                .define("HAVE_ACCELERATE", .when(platforms: [.iOS, .macOS])),
                .define("HAVE_SOURCE_APPLE_AUDIO", .when(platforms: [.iOS, .macOS])),
                .define("HAVE_SINK_APPLE_AUDIO", .when(platforms: [.iOS, .macOS])),
                .define("HAVE_AUDIO_UNIT", .when(platforms: [.iOS])),

                // Enable basic WAV support
                .define("HAVE_WAVREAD"),
                .define("HAVE_WAVWRITE"),

                // Aubio configuration
                .define("AUBIO_VERSION", to: "\"0.5.0-alpha\""),
                .define("AUBIO_UNSTABLE", to: "0"),

                // Include path for headers
                .headerSearchPath("."),
            ],
            linkerSettings: [
                // Link Apple frameworks
                .linkedFramework("Accelerate", .when(platforms: [.iOS, .macOS])),
                .linkedFramework("CoreFoundation", .when(platforms: [.iOS, .macOS])),
                .linkedFramework("AudioToolbox", .when(platforms: [.iOS, .macOS])),
            ]
        ),
    ],
    cLanguageStandard: .c11
)
