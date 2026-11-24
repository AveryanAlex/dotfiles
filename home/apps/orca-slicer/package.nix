{ pkgs }:
let
  inherit (pkgs) lib;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  mergedBambuCa = import ../../../roles/desktop/bambu-certs/package.nix { inherit pkgs; };

  version = "2.5.1";
  orcaSource = pkgs.fetchFromGitHub {
    owner = "OrcaSlicer";
    repo = "OrcaSlicer";
    tag = "v${version}";
    hash = "sha256-jT6kD8vdHkdwdzomrOG2q5s39Wme894lGPZvS7P+Pkw=";
  };

  # Match Orca's CAD dependencies and its OCCT triangulation fix.
  opencascade = pkgs.stdenv.mkDerivation {
    pname = "opencascade-occt";
    version = "8.0.1";
    src = pkgs.fetchurl {
      url = "https://github.com/Open-Cascade-SAS/OCCT/archive/refs/tags/V8_0_1.zip";
      hash = "sha256-fAM9kX7o8EDAUS0oncxfAsFIiJ1brBfD4lY5rMtE8No=";
    };
    patches = [ "${orcaSource}/deps/OCCT/0001-BRepMesh-seam-pcurve-at-edge-parameter.patch" ];
    nativeBuildInputs = [
      pkgs.cmake
      pkgs.ninja
      pkgs.unzip
    ];
    buildInputs = [ pkgs.freetype ];
    cmakeFlags = [
      (lib.cmakeFeature "CMAKE_CXX_STANDARD" "17")
      (lib.cmakeFeature "BUILD_LIBRARY_TYPE" "Shared")
      (lib.cmakeBool "USE_TK" false)
      (lib.cmakeBool "USE_TBB" false)
      (lib.cmakeBool "USE_FFMPEG" false)
      (lib.cmakeBool "USE_VTK" false)
      (lib.cmakeBool "BUILD_DOC_Overview" false)
      (lib.cmakeBool "BUILD_MODULE_ApplicationFramework" false)
      (lib.cmakeBool "BUILD_MODULE_Draw" false)
      (lib.cmakeBool "BUILD_MODULE_FoundationClasses" false)
      (lib.cmakeBool "BUILD_MODULE_ModelingAlgorithms" true)
      (lib.cmakeBool "BUILD_MODULE_ModelingData" false)
      (lib.cmakeBool "BUILD_MODULE_Visualization" false)
    ];
  };

  slvs = pkgs.stdenv.mkDerivation {
    pname = "libslvs";
    version = "0-unstable-2018-10-16";
    src = pkgs.fetchurl {
      url = "https://github.com/JacobStoren/SolveSpaceLib/archive/4d8704523e4bf212fadf5189f92484244f670fea.zip";
      hash = "sha256-HEvd6cPG7yDqS1C3NgHeVnafLrExs2kn18ZInxAubDA=";
    };
    nativeBuildInputs = [
      pkgs.cmake
      pkgs.unzip
    ];
    postPatch = ''
      cp ${orcaSource}/deps/SLVS/CMakeLists.txt.in CMakeLists.txt
    '';
  };

  cgal = pkgs.cgal.overrideAttrs (old: {
    version = "6.2.1";
    src = pkgs.fetchurl {
      url = "https://github.com/CGAL/cgal/releases/download/v6.2.1/CGAL-6.2.1.zip";
      hash = "sha256-7r1zfZt/AZlke6XB+fbHo9BlGqzvnC/U3txS2mwl7b4=";
    };
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.unzip ];
  });

  # Orca 2.5.1 requires Expat 2.10. Its Autotools build enables the entity amplification guard.
  expat = pkgs.expat.overrideAttrs {
    version = "2.10.0";
    src = pkgs.fetchurl {
      url = "https://github.com/libexpat/libexpat/releases/download/R_2_10_0/expat-2.10.0.tar.xz";
      hash = "sha256-xiS6KZj8Zd8RY6SWQf8/mrcxOLEWQdkshr7g+wGxvH8=";
    };
  };

  # The 2.4.2 nixpkgs recipe pins Boost 1.86, but current OpenVDB uses 1.89.
  # Keep Orca on the same Boost ABI so both versions are not loaded at once.
  boost = pkgs.boost.override {
    enableShared = true;
    enableStatic = false;
    extraFeatures = [
      "log"
      "thread"
      "filesystem"
    ];
  };

  wxWidgets =
    if isDarwin then
      (pkgs.wxwidgets_3_3.override { withEGL = false; }).overrideAttrs (old: {
        configureFlags = old.configureFlags ++ [
          "--enable-debug=no"
          "--enable-secretstore"
          "--with-opengl"
          # Orca extends wxWidgets' Objective-C classes with categories.
          # These classes must remain visible when linking shared wxWidgets.
          "--disable-visibility"
        ];
      })
    else
      (pkgs.wxwidgets_3_3.override {
        withPrivateFonts = true;
        withWebKit = true;
        withEGL = true;
      }).overrideAttrs
        (old: {
          buildInputs = old.buildInputs ++ [ pkgs.libsecret ];
          configureFlags = old.configureFlags ++ [
            "--enable-debug=no"
            "--enable-secretstore"
          ];
        });

  # Orca requires wxInspector even in release builds, where its
  # UI is disabled. It is not packaged in nixpkgs yet.
  wxInspector = pkgs.stdenv.mkDerivation {
    pname = "wxInspector";
    version = "1.0.0";

    src = pkgs.fetchurl {
      url = "https://github.com/Noisyfox/wxInspector/archive/refs/tags/v1.0.0.zip";
      hash = "sha256-C6FjlW8tRosZqRuWxaumbulhCEPqQd2mKOpEza/efbc=";
    };

    nativeBuildInputs = [
      pkgs.cmake
      pkgs.pkg-config
      pkgs.unzip
      wxWidgets
    ];
    buildInputs = lib.optional (!isDarwin) pkgs.gtk3 ++ [ wxWidgets ];

    cmakeFlags = [
      (pkgs.lib.cmakeBool "wxBUILD_SAMPLES" false)
      (pkgs.lib.cmakeFeature "CMAKE_CXX_FLAGS" "-DwxDEBUG_LEVEL=0")
    ];
  };

  orca-slicer = pkgs.orca-slicer.overrideAttrs (old: {
    inherit version;
    src = orcaSource;

    # Use the rebased OpenCV and update-check patches. Orca 2.5.1 includes
    # nixpkgs' OpenGL context fixes for slicing and toolpath preview.
    patches =
      pkgs.lib.filter (
        patch:
        !(pkgs.lib.hasInfix "dont-link-opencv-world-orca.patch" (toString patch))
        && !(pkgs.lib.hasInfix "pr-7650-configurable-update-check.patch" (toString patch))
        && !(pkgs.lib.hasInfix "pr-15873-fix-slice-crash.patch" (toString patch))
        && !(pkgs.lib.hasInfix "pr-16109-fix-toolpath-freeze.patch" (toString patch))
        && !(isDarwin && pkgs.lib.hasInfix "Link-against-webkit2gtk" (toString patch))
      ) (old.patches or [ ])
      ++ [
        ./patches/orca-slicer-dont-link-opencv-world.patch
        ./patches/orca-slicer-configurable-update-check.patch
        ./patches/x2d-ams-sync-filament-arrays.patch
      ];

    nativeBuildInputs =
      (
        if isDarwin then
          [
            pkgs.cmake
            pkgs.gettext
            pkgs.pkg-config
            wxWidgets
          ]
        else
          old.nativeBuildInputs or [ ]
      )
      ++ [ pkgs.python312 ];

    # gcc-unwrapped exposes only libstdc++.a in its top-level lib directory.
    # When it precedes Clang's shared runtime, Orca embeds a second libstdc++;
    # Bambu's downloaded network plugin then corrupts std::locale across the
    # static/shared ABI boundary. Clang already provides the needed GCC headers
    # and shared runtime, so the inherited input is both redundant and unsafe.
    buildInputs =
      (
        if isDarwin then
          (with pkgs; [
            cereal
            curl
            draco
            eigen_5
            ffmpeg
            freetype
            glew
            glfw
            gmp
            libjpeg_turbo
            libpng
            mpfr
            nlopt
            openvdb
            onetbb
            wxWidgets
            opencv.cxxdev
            libnoise
          ])
        else
          pkgs.lib.filter (
            input:
            !(builtins.elem (input.pname or "") [
              "boost"
              "cgal"
              "expat"
              "opencascade-occt"
            ])
            && (toString input) != (toString pkgs.gcc-unwrapped)
          ) (old.buildInputs or [ ])
      )
      ++ [
        # Boost's default output is `dev`; CMake also needs component libraries.
        boost.out
        pkgs.boost.dev
        pkgs.assimp
        pkgs.libdatachannel
        pkgs.openssl
        pkgs.python312
        cgal
        expat
        opencascade
        slvs
        wxInspector
      ];

    env = old.env // {
      NIX_LDFLAGS = toString (
        [
          (lib.optionalString (!isDarwin) "-ludev")
          "-L${boost}/lib"
          "-lboost_log"
          "-lboost_log_setup"
        ]
        ++ lib.optional isDarwin "-framework WebKit"
      );
    };

    # Orca expects its dependency build to provide a bundled Python 3.12.13.
    # Point both configure and the post-build staging step at nixpkgs' 3.12
    # runtime instead, while tracking its patch release.
    #
    # Boost.System is header-only in nixpkgs' Boost 1.89, so there is no
    # boost_system CMake component or shared library to request. Orca and its
    # bundled FindOpenVDB module still list the obsolete compiled component.
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace src/libslic3r/Feature/FuzzySkin/FuzzySkin.cpp \
          --replace-fail '<libnoise/module/modulebase.h>' \
            '<noise/module/modulebase.h>'
        substituteInPlace CMakeLists.txt \
          --replace-fail 'set(_bundled_python_version "3.12.13")' \
            'set(_bundled_python_version "${pkgs.python312.version}")' \
          --replace-fail 'set(_bundled_python_root "''${CMAKE_PREFIX_PATH}/libpython")' \
            'set(_bundled_python_root "${pkgs.python312}")'
        substituteInPlace src/CMakeLists.txt \
          --replace-fail '"''${CMAKE_PREFIX_PATH}/libpython"' \
            '"''${_bundled_python_root}"'
        substituteInPlace CMakeLists.txt \
          --replace-fail 'COMPONENTS system filesystem' \
            'COMPONENTS filesystem'
        substituteInPlace cmake/modules/FindOpenVDB.cmake \
          --replace-fail 'COMPONENTS iostreams system' \
            'COMPONENTS iostreams' \
          --replace-fail $'  Boost::system\n' '''
        substituteInPlace src/slic3r/Utils/TCPConsole.cpp \
          --replace-fail 'endpoints->endpoint()' \
            'endpoints.begin()->endpoint()'
      ''
      + lib.optionalString isDarwin ''
        # The macOS process launcher still includes pre-1.88 Boost.Process headers.
        substituteInPlace src/slic3r/Utils/Process.cpp \
          --replace-fail $'#include <boost/process/spawn.hpp>\n    #include <boost/process/args.hpp>' \
            '#include "BoostProcessCompat.hpp"'
        # Orca's Cocoa WebView uses this header-only helper, which wxWidgets'
        # Autotools installation omits. Use the exact same wxWidgets source.
        mkdir -p src/wx/private
        cp ${wxWidgets.src}/include/wx/private/jsscriptwrapper.h src/wx/private/
        # The private Objective-C ivar is not exported from shared wxWidgets;
        # use its existing accessor instead of linking directly to the ivar.
        substituteInPlace src/slic3r/Utils/MacDarkMode.mm \
          --replace-fail 'implementation->GetDataViewCtrl()' \
            '[self implementation]->GetDataViewCtrl()'
        # This copy path is excluded on Linux and still uses pre-1.85 Boost APIs.
        substituteInPlace src/libslic3r/utils.cpp \
          --replace-fail 'boost::filesystem::copy_option::overwrite_if_exists' \
            'boost::filesystem::copy_options::overwrite_existing'
        # nixpkgs builds wxWidgets with Autotools and exposes wx-config rather
        # than the CMake package configuration expected by upstream on macOS.
        substituteInPlace src/CMakeLists.txt \
          --replace-fail 'find_package(wxWidgets 3.3 CONFIG REQUIRED' \
            'find_package(wxWidgets 3.3 REQUIRED'
        # Use nixpkgs' shared FFmpeg instead of upstream's static deps bundle.
        substituteInPlace src/slic3r/CMakeLists.txt \
          --replace-fail $'if (APPLE)\n    # Static FFmpeg' \
            $'find_package(PkgConfig REQUIRED)\nif (APPLE AND SLIC3R_STATIC)\n    # Static FFmpeg'
      '';

    # Prevent CMake from downloading uv in the network-isolated Nix build.
    cmakeFlags =
      (lib.filter (
        flag:
        !(
          isDarwin && (lib.hasPrefix "-DSLIC3R_FHS:" flag || lib.hasPrefix "-DCMAKE_EXE_LINKER_FLAGS:" flag)
        )
      ) (old.cmakeFlags or [ ]))
      ++ lib.optionals isDarwin [
        (lib.cmakeBool "SLIC3R_FHS" false)
        (lib.cmakeBool "CMAKE_MACOSX_BUNDLE" true)
        (lib.cmakeFeature "CMAKE_OSX_DEPLOYMENT_TARGET" pkgs.stdenv.hostPlatform.darwinMinVersion)
      ]
      ++ [
        (pkgs.lib.cmakeFeature "ORCA_BUNDLED_UV_EXECUTABLE" "${pkgs.uv}/bin/uv")
      ];

    preFixup = if isDarwin then "" else old.preFixup or "";
    separateDebugInfo = !isDarwin;
    meta = old.meta // {
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };

    installPhase =
      if isDarwin then
        ''
          runHook preInstall
          mkdir -p "$out/Applications" "$out/bin"
          cp -R src/OrcaSlicer.app "$out/Applications/"
          resources="$out/Applications/OrcaSlicer.app/Contents/Resources"
          rm "$resources"
          cp -R ../resources "$resources"
          # Match upstream's bundle layout: Python belongs in Resources, not
          # under MacOS, where codesign treats its dotted directories as bundles.
          mv "$out/Applications/OrcaSlicer.app/Contents/MacOS/python" "$resources/python"
          ln -s ../Resources/python "$out/Applications/OrcaSlicer.app/Contents/MacOS/python"
          install -m0644 ${mergedBambuCa}/share/bambu-certs/printer.cer "$resources/cert/printer.cer"
          ln -s "$out/Applications/OrcaSlicer.app/Contents/MacOS/OrcaSlicer" "$out/bin/orca-slicer"
          runHook postInstall
        ''
      else
        old.installPhase or null;

    postInstall = lib.optionalString (!isDarwin) (
      (old.postInstall or "")
      + ''
        install -Dm0644 ${mergedBambuCa}/share/bambu-certs/printer.cer \
          "$out/share/OrcaSlicer/cert/printer.cer"
      ''
    );
  });
in
if isDarwin then
  # Seal the complete bundle after stripping and installing the custom CA.
  # Keeping signing separate also avoids recompiling Orca for bundle-only changes.
  pkgs.runCommand orca-slicer.name
    {
      inherit (orca-slicer) pname version meta;
      nativeBuildInputs = [ pkgs.rcodesign ];
      passthru.unwrapped = orca-slicer;
    }
    ''
      mkdir -p "$out/bin"
      cp -R ${orca-slicer}/Applications "$out/Applications"
      chmod -R u+w "$out/Applications"
      rcodesign sign "$out/Applications/OrcaSlicer.app"
      ln -s "$out/Applications/OrcaSlicer.app/Contents/MacOS/OrcaSlicer" "$out/bin/orca-slicer"
    ''
else
  orca-slicer
